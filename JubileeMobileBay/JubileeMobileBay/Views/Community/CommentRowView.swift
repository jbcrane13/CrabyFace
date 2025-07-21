//
//  CommentRowView.swift
//  JubileeMobileBay
//
//  View for displaying a single comment with threading support
//

import SwiftUI

struct CommentRowView: View {
    
    // MARK: - Properties
    
    let comment: CommunityComment
    let onAction: (CommentAction) -> Void
    
    @State private var showReplyComposer = false
    @State private var showReportSheet = false
    @State private var isAnimatingLike = false
    
    // Threading UI
    private let indentWidth: CGFloat = 20
    private let maxIndentLevel = 4
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Threading indent
            if comment.depth > 0 {
                threadingIndicator
            }
            
            // Comment content
            VStack(alignment: .leading, spacing: 8) {
                // Header
                commentHeader
                
                // Text content
                commentText
                
                // Actions
                if !comment.isDeleted {
                    commentActions
                }
                
                // Reply composer
                if showReplyComposer {
                    replyComposer
                }
                
                // Nested replies
                if comment.isExpanded && !comment.replies.isEmpty {
                    repliesSection
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(commentBackground)
            .cornerRadius(8)
        }
        .padding(.leading, CGFloat(min(comment.depth, maxIndentLevel)) * indentWidth)
        .sheet(isPresented: $showReportSheet) {
            CommentReportView(
                itemType: .comment,
                itemId: comment.id,
                onSubmit: { reason in
                    onAction(.report(commentId: comment.id, reason: reason))
                }
            )
        }
    }
    
    // MARK: - Threading Indicator
    
    private var threadingIndicator: some View {
        GeometryReader { geometry in
            Path { path in
                let x = indentWidth / 2
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: geometry.size.height))
            }
            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        }
        .frame(width: indentWidth)
    }
    
    // MARK: - Comment Header
    
    private var commentHeader: some View {
        HStack(spacing: 8) {
            // User avatar placeholder
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(comment.displayUserName.prefix(1).uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(comment.displayUserName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(comment.isDeleted ? .secondary : .primary)
                    
                    if comment.isEdited && !comment.isDeleted {
                        Text("(edited)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(formatRelativeTime(comment.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !comment.isDeleted {
                Menu {
                    Button(action: { showReportSheet = true }) {
                        Label("Report", systemImage: "flag")
                    }
                    
                    if comment.userId == UserSessionManager.shared.currentUserId {
                        Divider()
                        
                        Button(role: .destructive, action: {
                            onAction(.delete(commentId: comment.id))
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                }
            }
        }
    }
    
    // MARK: - Comment Text
    
    private var commentText: some View {
        Text(comment.displayText)
            .font(.system(size: 15))
            .foregroundColor(comment.isDeleted ? .secondary : .primary)
            .italic(comment.isDeleted)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Comment Actions
    
    private var commentActions: some View {
        HStack(spacing: 20) {
            // Like button
            Button(action: handleLike) {
                HStack(spacing: 4) {
                    Image(systemName: comment.isLikedByCurrentUser ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundColor(comment.isLikedByCurrentUser ? .red : .secondary)
                        .scaleEffect(isAnimatingLike ? 1.2 : 1.0)
                    
                    if comment.likeCount > 0 {
                        Text("\(comment.likeCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Reply button
            Button(action: { showReplyComposer.toggle() }) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text("Reply")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expand/Collapse replies
            if comment.hasReplies {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onAction(comment.isExpanded ? .collapse(commentId: comment.id) : .expand(commentId: comment.id))
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: comment.isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("\(comment.replyCount) \(comment.replyCount == 1 ? "reply" : "replies")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
    }
    
    // MARK: - Reply Composer
    
    private var replyComposer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            
            HStack(alignment: .top, spacing: 8) {
                // Reply indicator
                Image(systemName: "arrow.turn.down.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                
                CommentComposerView(
                    placeholder: "Write a reply...",
                    onSubmit: { text in
                        onAction(.reply(to: comment.id, text: text))
                        showReplyComposer = false
                    },
                    onCancel: {
                        showReplyComposer = false
                    }
                )
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        ))
    }
    
    // MARK: - Replies Section
    
    private var repliesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(comment.replies) { reply in
                CommentRowView(
                    comment: reply,
                    onAction: onAction
                )
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Comment Background
    
    private var commentBackground: Color {
        if comment.isDeleted {
            return Color.gray.opacity(0.1)
        } else if comment.depth == 0 {
            return Color(UIColor.secondarySystemBackground)
        } else {
            return Color(UIColor.tertiarySystemBackground)
        }
    }
    
    // MARK: - Actions
    
    private func handleLike() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isAnimatingLike = true
        }
        
        onAction(comment.isLikedByCurrentUser ? .unlike(commentId: comment.id) : .like(commentId: comment.id))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimatingLike = false
        }
    }
    
    // MARK: - Helpers
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Comment Composer View

struct CommentComposerView: View {
    
    let placeholder: String
    let onSubmit: (String) -> Void
    let onCancel: () -> Void
    
    @State private var text = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Text editor
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }
                
                TextEditor(text: $text)
                    .focused($isFocused)
                    .frame(minHeight: 60, maxHeight: 120)
                    .padding(4)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Button("Post") {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSubmit(text)
                        text = ""
                    }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.gray : Color.blue
                )
                .cornerRadius(16)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - Report View

struct CommentReportView: View {
    
    enum ItemType {
        case post
        case comment
    }
    
    let itemType: ItemType
    let itemId: String
    let onSubmit: (ReportReason) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason?
    @State private var additionalDetails = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Why are you reporting this \(itemType == .post ? "post" : "comment")?")
                        .font(.headline)
                        .padding(.vertical, 8)
                }
                
                Section {
                    ForEach(ReportReason.allCases, id: \.self) { reason in
                        Button(action: { selectedReason = reason }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(reason.displayName)
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)
                                    
                                    Text(reason.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedReason == reason {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4)
                    }
                }
                
                if selectedReason == .other {
                    Section(header: Text("Additional Details")) {
                        TextEditor(text: $additionalDetails)
                            .frame(minHeight: 100)
                    }
                }
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        if let reason = selectedReason {
                            onSubmit(reason)
                            dismiss()
                        }
                    }
                    .disabled(selectedReason == nil)
                }
            }
        }
    }
}

// MARK: - Preview

struct CommentRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CommentRowView(
                comment: CommunityComment.mockComments[0],
                onAction: { _ in }
            )
            
            CommentRowView(
                comment: CommunityComment.mockComments[1],
                onAction: { _ in }
            )
        }
        .padding()
    }
}