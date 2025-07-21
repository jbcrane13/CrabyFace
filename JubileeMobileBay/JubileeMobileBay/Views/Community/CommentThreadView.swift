//
//  CommentThreadView.swift
//  JubileeMobileBay
//
//  View for displaying and managing a complete comment thread
//

import SwiftUI
import CloudKit

struct CommentThreadView: View {
    
    // MARK: - Properties
    
    let post: CommunityPost
    @StateObject private var viewModel: CommentThreadViewModel
    @FocusState private var isComposerFocused: Bool
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showNotificationPermission = false
    
    // MARK: - Initialization
    
    init(post: CommunityPost, cloudKitService: CloudKitServiceProtocol? = nil) {
        self.post = post
        self._viewModel = StateObject(
            wrappedValue: CommentThreadViewModel(
                postId: post.id,
                cloudKitService: cloudKitService ?? CloudKitService()
            )
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.comments.isEmpty {
                loadingView
            } else {
                contentView
            }
        }
        .task {
            await viewModel.loadComments()
        }
        .refreshable {
            await viewModel.refreshComments()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .sheet(isPresented: $showNotificationPermission) {
            NotificationPermissionView(showPermissionRequest: $showNotificationPermission)
        }
        .onAppear {
            checkNotificationPermission()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading comments...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        VStack(spacing: 0) {
            // Comments list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        // Comments header
                        commentsHeader
                        
                        // Comment tree
                        if viewModel.comments.isEmpty {
                            emptyCommentsView
                        } else {
                            ForEach(viewModel.commentTree) { comment in
                                CommentRowView(
                                    comment: comment,
                                    onAction: viewModel.handleCommentAction
                                )
                                .id(comment.id)
                            }
                        }
                        
                        // Loading more indicator
                        if viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.scrollToCommentId) { _, newId in
                    if let commentId = newId {
                        withAnimation {
                            proxy.scrollTo(commentId, anchor: .center)
                        }
                        viewModel.clearScrollTarget()
                    }
                }
            }
            
            // Bottom composer (if post is not locked)
            if !post.isLocked {
                Divider()
                bottomComposer
            }
        }
    }
    
    // MARK: - Comments Header
    
    private var commentsHeader: some View {
        HStack {
            Text("Comments")
                .font(.title2)
                .fontWeight(.bold)
            
            if viewModel.totalCommentCount > 0 {
                Text("(\(viewModel.totalCommentCount))")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Sort options
            Menu {
                ForEach(CommentSortOption.allCases, id: \.self) { option in
                    Button(action: { viewModel.sortOption = option }) {
                        HStack {
                            Text(option.displayName)
                            if viewModel.sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14))
                    Text(viewModel.sortOption.displayName)
                        .font(.subheadline)
                }
                .foregroundColor(.blue)
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Empty Comments View
    
    private var emptyCommentsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No comments yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Be the first to share your thoughts!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Bottom Composer
    
    private var bottomComposer: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // User avatar
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(UserSessionManager.shared.currentUser?.displayName.prefix(1).uppercased() ?? "?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                )
            
            // Comment field
            HStack(alignment: .bottom) {
                ZStack(alignment: .leading) {
                    if viewModel.newCommentText.isEmpty {
                        Text("Add a comment...")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    
                    TextField("", text: $viewModel.newCommentText, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .focused($isComposerFocused)
                        .lineLimit(1...5)
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(20)
                
                // Send button
                Button(action: {
                    Task {
                        await viewModel.postComment()
                        isComposerFocused = false
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(viewModel.canPostComment ? .blue : .gray)
                }
                .disabled(!viewModel.canPostComment)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - Helper Methods
    
    private func checkNotificationPermission() {
        // Check if we should show notification permission request
        if !notificationManager.hasNotificationPermission &&
           !UserDefaults.standard.bool(forKey: "hasDeclinedNotificationPermission") {
            // Only show if user has comments or is actively engaging
            if !viewModel.comments.isEmpty || !viewModel.newCommentText.isEmpty {
                showNotificationPermission = true
            }
        }
        
        // Subscribe to comment notifications for this post
        if notificationManager.hasNotificationPermission {
            notificationManager.subscribeToCommentReplies(for: post.id)
        }
    }
}

// MARK: - Comment Sort Options

enum CommentSortOption: String, CaseIterable {
    case newest = "newest"
    case oldest = "oldest"
    case mostLiked = "most_liked"
    case mostReplies = "most_replies"
    
    var displayName: String {
        switch self {
        case .newest:
            return "Newest"
        case .oldest:
            return "Oldest"
        case .mostLiked:
            return "Most Liked"
        case .mostReplies:
            return "Most Replies"
        }
    }
}

// MARK: - Comment Thread View Model

@MainActor
class CommentThreadViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var comments: [CommunityComment] = []
    @Published var commentTree: [CommunityComment] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var newCommentText = ""
    @Published var sortOption: CommentSortOption = .newest {
        didSet {
            rebuildCommentTree()
        }
    }
    @Published var scrollToCommentId: String?
    
    // MARK: - Properties
    
    let postId: String
    private let cloudKitService: CloudKitServiceProtocol
    private var commentThread: CommentThread?
    private var subscription: CKQuerySubscription?
    private var notificationToken: Any?
    
    var totalCommentCount: Int {
        commentThread?.totalCommentCount ?? comments.count
    }
    
    var canPostComment: Bool {
        !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
    
    // MARK: - Initialization
    
    init(postId: String, cloudKitService: CloudKitServiceProtocol) {
        self.postId = postId
        self.cloudKitService = cloudKitService
        
        // Set up real-time updates
        Task {
            await setupSubscription()
        }
    }
    
    deinit {
        // Clean up subscription
        Task { @MainActor in
            await cleanupSubscription()
            NotificationManager.shared.unsubscribeFromCommentReplies(for: postId)
        }
    }
    
    // MARK: - Public Methods
    
    func loadComments() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedComments = try await cloudKitService.fetchComments(for: postId)
            self.comments = fetchedComments
            
            // Build comment thread
            self.commentThread = CommentThread(
                postId: postId,
                comments: fetchedComments,
                totalCommentCount: fetchedComments.count,
                lastUpdated: Date()
            )
            
            rebuildCommentTree()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func refreshComments() async {
        await loadComments()
    }
    
    func postComment() async {
        let text = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Clear text immediately for better UX
        newCommentText = ""
        
        do {
            let newComment = try await cloudKitService.addComment(to: postId, text: text)
            
            // Add to local comments
            comments.append(newComment)
            
            // Update thread
            commentThread?.comments = comments
            commentThread?.totalCommentCount += 1
            
            rebuildCommentTree()
            
            // Scroll to new comment
            scrollToCommentId = newComment.id
        } catch {
            // Restore text on error
            newCommentText = text
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func handleCommentAction(_ action: CommentAction) {
        Task {
            do {
                switch action {
                case .like(let commentId):
                    try await handleLike(commentId: commentId)
                    
                case .unlike(let commentId):
                    try await handleUnlike(commentId: commentId)
                    
                case .reply(let parentId, let text):
                    let reply = try await handleReply(to: parentId, text: text)
                    scrollToCommentId = reply.id
                    
                case .delete(let commentId):
                    try await handleDelete(commentId: commentId)
                    
                case .report(let commentId, let reason):
                    try await handleReport(commentId: commentId, reason: reason)
                    
                case .expand(let commentId):
                    handleExpand(commentId: commentId)
                    
                case .collapse(let commentId):
                    handleCollapse(commentId: commentId)
                    
                case .loadReplies(let commentId):
                    try await loadReplies(for: commentId)
                    
                case .edit:
                    // Not implemented in this version
                    break
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    func clearScrollTarget() {
        scrollToCommentId = nil
    }
    
    // MARK: - Private Methods
    
    private func rebuildCommentTree() {
        guard let thread = commentThread else {
            commentTree = []
            return
        }
        
        // Build tree structure
        var tree = thread.buildCommentTree()
        
        // Apply sorting
        switch sortOption {
        case .newest:
            tree.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            tree.sort { $0.createdAt < $1.createdAt }
        case .mostLiked:
            tree.sort { $0.likeCount > $1.likeCount }
        case .mostReplies:
            tree.sort { $0.replyCount > $1.replyCount }
        }
        
        commentTree = tree
    }
    
    private func handleLike(commentId: String) async throws {
        // Update local state immediately for responsive UI
        if let index = comments.firstIndex(where: { $0.id == commentId }) {
            comments[index].toggleLike()
            rebuildCommentTree()
        }
        
        // Send to server
        do {
            try await cloudKitService.likeComment(commentId: commentId)
        } catch {
            // Revert on error
            if let index = comments.firstIndex(where: { $0.id == commentId }) {
                comments[index].toggleLike()
                rebuildCommentTree()
            }
            throw error
        }
    }
    
    private func handleUnlike(commentId: String) async throws {
        // Update local state immediately for responsive UI
        if let index = comments.firstIndex(where: { $0.id == commentId }) {
            comments[index].toggleLike()
            rebuildCommentTree()
        }
        
        // Send to server
        do {
            try await cloudKitService.unlikeComment(commentId: commentId)
        } catch {
            // Revert on error
            if let index = comments.firstIndex(where: { $0.id == commentId }) {
                comments[index].toggleLike()
                rebuildCommentTree()
            }
            throw error
        }
    }
    
    private func handleReply(to parentId: String, text: String) async throws -> CommunityComment {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw CloudKitError.invalidData
        }
        
        // Create reply using the new addReply method
        let reply = try await cloudKitService.addReply(to: postId, parentCommentId: parentId, text: trimmedText)
        
        // Add to comments
        comments.append(reply)
        
        // Update parent's reply count locally
        if let parentIndex = comments.firstIndex(where: { $0.id == parentId }) {
            var parent = comments[parentIndex]
            parent.replies.append(reply)
            comments[parentIndex] = parent
        }
        
        rebuildCommentTree()
        
        return reply
    }
    
    private func handleDelete(commentId: String) async throws {
        // Mark as deleted locally
        if let index = comments.firstIndex(where: { $0.id == commentId }) {
            var comment = comments[index]
            let originalText = comment.text
            let originalDeleted = comment.isDeleted
            
            // Update locally
            comment = CommunityComment(
                id: comment.id,
                postId: comment.postId,
                parentCommentId: comment.parentCommentId,
                userId: comment.userId,
                userName: comment.userName,
                text: "[Comment deleted]",
                createdAt: comment.createdAt,
                updatedAt: Date(),
                likeCount: comment.likeCount,
                replyCount: comment.replyCount,
                depth: comment.depth,
                isDeleted: true,
                isEdited: comment.isEdited
            )
            comments[index] = comment
            rebuildCommentTree()
            
            // Send to server
            do {
                try await cloudKitService.deleteComment(commentId: commentId)
            } catch {
                // Revert on error
                comment = CommunityComment(
                    id: comment.id,
                    postId: comment.postId,
                    parentCommentId: comment.parentCommentId,
                    userId: comment.userId,
                    userName: comment.userName,
                    text: originalText,
                    createdAt: comment.createdAt,
                    updatedAt: comment.updatedAt,
                    likeCount: comment.likeCount,
                    replyCount: comment.replyCount,
                    depth: comment.depth,
                    isDeleted: originalDeleted,
                    isEdited: comment.isEdited
                )
                comments[index] = comment
                rebuildCommentTree()
                throw error
            }
        }
    }
    
    private func handleReport(commentId: String, reason: ReportReason) async throws {
        // Send report to CloudKit
        try await cloudKitService.reportComment(commentId: commentId, reason: reason)
        
        // Show confirmation to user
        errorMessage = "Comment reported. Thank you for helping keep our community safe."
        showError = true
    }
    
    private func handleExpand(commentId: String) {
        if let index = comments.firstIndex(where: { $0.id == commentId }) {
            comments[index].toggleExpanded()
            rebuildCommentTree()
        }
    }
    
    private func handleCollapse(commentId: String) {
        if let index = comments.firstIndex(where: { $0.id == commentId }) {
            comments[index].toggleExpanded()
            rebuildCommentTree()
        }
    }
    
    private func loadReplies(for commentId: String) async throws {
        // In real implementation, this would load more replies from CloudKit
        print("Loading replies for comment \(commentId)")
    }
    
    // MARK: - Subscription Management
    
    private func setupSubscription() async {
        do {
            // Subscribe to comment updates for this post
            subscription = try await cloudKitService.subscribeToComments(for: postId)
            
            // Set up notification observer for real-time updates
            await MainActor.run {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(handleCloudKitNotification(_:)),
                    name: NSNotification.Name("CKQueryNotification"),
                    object: nil
                )
            }
        } catch {
            print("Failed to set up comment subscription: \(error)")
        }
    }
    
    private func cleanupSubscription() async {
        // Remove notification observer
        await MainActor.run {
            NotificationCenter.default.removeObserver(self)
        }
        
        // Unsubscribe from CloudKit
        do {
            try await cloudKitService.unsubscribeFromComments(for: postId)
        } catch {
            print("Failed to unsubscribe from comments: \(error)")
        }
    }
    
    @objc private func handleCloudKitNotification(_ notification: Notification) {
        // Process CloudKit notification for real-time updates
        guard let userInfo = notification.userInfo,
              let queryNotification = userInfo["notification"] as? CKQueryNotification,
              queryNotification.subscriptionID == "comment-subscription-\(postId)" else {
            return
        }
        
        Task {
            switch queryNotification.queryNotificationReason {
            case .recordCreated:
                await handleNewComment(recordID: queryNotification.recordID)
            case .recordUpdated:
                await handleUpdatedComment(recordID: queryNotification.recordID)
            case .recordDeleted:
                await handleDeletedComment(recordID: queryNotification.recordID)
            @unknown default:
                break
            }
        }
    }
    
    private func handleNewComment(recordID: CKRecord.ID?) async {
        guard let recordID = recordID else { return }
        
        // Fetch the new comment and add it to our list
        // In a real implementation, we'd fetch just the new record
        // For now, refresh all comments
        await refreshComments()
    }
    
    private func handleUpdatedComment(recordID: CKRecord.ID?) async {
        guard let recordID = recordID else { return }
        
        // Update the specific comment
        // For now, refresh all comments
        await refreshComments()
    }
    
    private func handleDeletedComment(recordID: CKRecord.ID?) async {
        guard let recordID = recordID else { return }
        
        // Mark comment as deleted
        if let index = comments.firstIndex(where: { $0.id == recordID.recordName }) {
            var comment = comments[index]
            comment = CommunityComment(
                id: comment.id,
                postId: comment.postId,
                parentCommentId: comment.parentCommentId,
                userId: comment.userId,
                userName: comment.userName,
                text: "[Comment deleted]",
                createdAt: comment.createdAt,
                updatedAt: Date(),
                likeCount: comment.likeCount,
                replyCount: comment.replyCount,
                depth: comment.depth,
                isDeleted: true,
                isEdited: comment.isEdited
            )
            comments[index] = comment
            rebuildCommentTree()
        }
    }
}

// MARK: - Preview

struct CommentThreadView_Previews: PreviewProvider {
    static var previews: some View {
        let mockPost = CommunityPost(
            id: "post1",
            userId: "user1",
            userName: "TestUser",
            title: "Amazing Jubilee Event!",
            description: "Just witnessed an incredible jubilee event",
            location: CLLocationCoordinate2D(latitude: 30.5, longitude: -87.9)
        )
        
        CommentThreadView(post: mockPost)
    }
}