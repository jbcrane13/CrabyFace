//
//  CommunityComment.swift
//  JubileeMobileBay
//
//  Model for community post comments with threading support
//

import Foundation

// MARK: - Community Comment

struct CommunityComment: Identifiable, Codable, Equatable {
    let id: String
    let postId: String
    let parentCommentId: String? // nil for top-level comments
    let userId: String
    let userName: String
    let text: String
    let createdAt: Date
    let updatedAt: Date?
    let likeCount: Int
    let replyCount: Int
    let depth: Int // 0 for top-level, increases with nesting
    let isDeleted: Bool
    let isEdited: Bool
    
    // Client-side properties
    var isLikedByCurrentUser: Bool = false
    var replies: [CommunityComment] = []
    var isExpanded: Bool = true
    var isLoading: Bool = false
    
    // Computed properties
    var isTopLevel: Bool {
        parentCommentId == nil
    }
    
    var hasReplies: Bool {
        replyCount > 0 || !replies.isEmpty
    }
    
    var displayText: String {
        isDeleted ? "[Comment deleted]" : text
    }
    
    var displayUserName: String {
        isDeleted ? "[Deleted]" : userName
    }
    
    // Thread management
    mutating func addReply(_ comment: CommunityComment) {
        replies.append(comment)
        replies.sort { $0.createdAt < $1.createdAt }
    }
    
    mutating func removeReply(withId id: String) {
        replies.removeAll { $0.id == id }
    }
    
    mutating func toggleExpanded() {
        isExpanded.toggle()
    }
    
    // Like management
    mutating func toggleLike() {
        if isLikedByCurrentUser {
            isLikedByCurrentUser = false
        } else {
            isLikedByCurrentUser = true
        }
    }
}

// MARK: - Comment Thread

struct CommentThread {
    let postId: String
    var comments: [CommunityComment]
    var totalCommentCount: Int
    var lastUpdated: Date
    
    // Get all top-level comments
    var topLevelComments: [CommunityComment] {
        comments.filter { $0.isTopLevel }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    // Build comment tree
    func buildCommentTree() -> [CommunityComment] {
        var commentMap: [String: CommunityComment] = [:]
        var rootComments: [CommunityComment] = []
        
        // First pass: create map of all comments
        for comment in comments {
            commentMap[comment.id] = comment
        }
        
        // Second pass: build tree structure
        for comment in comments {
            if let parentId = comment.parentCommentId,
               var parentComment = commentMap[parentId] {
                parentComment.addReply(comment)
                commentMap[parentId] = parentComment
            } else {
                rootComments.append(comment)
            }
        }
        
        // Sort root comments by newest first
        return rootComments.sorted { $0.createdAt > $1.createdAt }
    }
    
    // Find a specific comment in the tree
    func findComment(withId id: String) -> CommunityComment? {
        return comments.first { $0.id == id }
    }
    
    // Get reply chain for a comment
    func getReplyChain(for commentId: String) -> [CommunityComment] {
        var chain: [CommunityComment] = []
        var currentId: String? = commentId
        
        while let id = currentId,
              let comment = findComment(withId: id) {
            chain.insert(comment, at: 0)
            currentId = comment.parentCommentId
        }
        
        return chain
    }
}

// MARK: - Comment Action

enum CommentAction {
    case like(commentId: String)
    case unlike(commentId: String)
    case reply(to: String, text: String)
    case edit(commentId: String, newText: String)
    case delete(commentId: String)
    case report(commentId: String, reason: ReportReason)
    case expand(commentId: String)
    case collapse(commentId: String)
    case loadReplies(commentId: String)
}

// MARK: - Report Reason

enum ReportReason: String, CaseIterable, Codable {
    case spam = "spam"
    case harassment = "harassment"
    case inappropriate = "inappropriate"
    case misinformation = "misinformation"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .spam:
            return "Spam or Advertisement"
        case .harassment:
            return "Harassment or Bullying"
        case .inappropriate:
            return "Inappropriate Content"
        case .misinformation:
            return "False Information"
        case .other:
            return "Other"
        }
    }
    
    var description: String {
        switch self {
        case .spam:
            return "Unwanted commercial content or spam"
        case .harassment:
            return "Targeted harassment or bullying behavior"
        case .inappropriate:
            return "Content that violates community guidelines"
        case .misinformation:
            return "Deliberately false or misleading information"
        case .other:
            return "Another reason not listed here"
        }
    }
}

// MARK: - Comment Notification

struct CommentNotification: Identifiable, Codable {
    let id: String
    let type: NotificationType
    let commentId: String
    let postId: String
    let postTitle: String
    let fromUserId: String
    let fromUserName: String
    let toUserId: String
    let createdAt: Date
    let isRead: Bool
    let preview: String // Preview of the comment text
    
    enum NotificationType: String, Codable {
        case reply = "reply"
        case mention = "mention"
        case like = "like"
        
        var icon: String {
            switch self {
            case .reply:
                return "bubble.left.fill"
            case .mention:
                return "at"
            case .like:
                return "heart.fill"
            }
        }
        
        var actionText: String {
            switch self {
            case .reply:
                return "replied to your comment"
            case .mention:
                return "mentioned you"
            case .like:
                return "liked your comment"
            }
        }
    }
}

// MARK: - Mock Data

extension CommunityComment {
    static let mockComments: [CommunityComment] = [
        CommunityComment(
            id: "comment1",
            postId: "post1",
            parentCommentId: nil,
            userId: "user1",
            userName: "MarineExpert",
            text: "Great observation! The water temperature spike definitely correlates with increased jubilee activity.",
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: nil,
            likeCount: 5,
            replyCount: 2,
            depth: 0,
            isDeleted: false,
            isEdited: false
        ),
        CommunityComment(
            id: "comment2",
            postId: "post1",
            parentCommentId: "comment1",
            userId: "user2",
            userName: "BayWatcher",
            text: "I noticed the same pattern last month. Do you think the lunar cycle plays a role?",
            createdAt: Date().addingTimeInterval(-1800),
            updatedAt: nil,
            likeCount: 2,
            replyCount: 1,
            depth: 1,
            isDeleted: false,
            isEdited: false
        ),
        CommunityComment(
            id: "comment3",
            postId: "post1",
            parentCommentId: "comment2",
            userId: "user1",
            userName: "MarineExpert",
            text: "Absolutely! Full moon tides seem to be a major trigger.",
            createdAt: Date().addingTimeInterval(-900),
            updatedAt: nil,
            likeCount: 1,
            replyCount: 0,
            depth: 2,
            isDeleted: false,
            isEdited: false
        )
    ]
}

// MARK: - CloudKit Integration

import CloudKit

extension CommunityComment {
    static func fromCloudKitRecord(_ record: CKRecord) throws -> CommunityComment {
        guard let postId = record["postId"] as? String,
              let userId = record["userId"] as? String,
              let userName = record["userName"] as? String,
              let text = record["text"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            throw CloudKitError.invalidData
        }
        
        let parentCommentId = record["parentCommentId"] as? String
        let depth = record["depth"] as? Int ?? 0
        let likeCount = record["likeCount"] as? Int ?? 0
        let replyCount = record["replyCount"] as? Int ?? 0
        let isDeleted = record["isDeleted"] as? Bool ?? false
        let isEdited = record["isEdited"] as? Bool ?? false
        let updatedAt = record["updatedAt"] as? Date
        
        return CommunityComment(
            id: record.recordID.recordName,
            postId: postId,
            parentCommentId: parentCommentId?.isEmpty == true ? nil : parentCommentId,
            userId: userId,
            userName: userName,
            text: text,
            createdAt: createdAt,
            updatedAt: updatedAt,
            likeCount: likeCount,
            replyCount: replyCount,
            depth: depth,
            isDeleted: isDeleted,
            isEdited: isEdited
        )
    }
}