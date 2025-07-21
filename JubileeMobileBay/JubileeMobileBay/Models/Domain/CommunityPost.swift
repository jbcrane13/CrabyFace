//
//  CommunityPost.swift
//  JubileeMobileBay
//
//  Created on 1/19/25.
//

import Foundation
import CoreLocation

struct CommunityPost: Identifiable, Equatable, Hashable {
    let id: String
    let userId: String
    let userName: String
    let title: String
    let description: String
    let location: CLLocationCoordinate2D
    let photoURLs: [String]
    let marineLifeTypes: Set<MarineLifeType>
    let createdAt: Date
    let updatedAt: Date?
    var likeCount: Int
    var commentCount: Int
    var isLikedByCurrentUser: Bool
    var isPinned: Bool
    var isLocked: Bool // Prevents new comments
    
    init(
        id: String,
        userId: String,
        userName: String,
        title: String,
        description: String,
        location: CLLocationCoordinate2D,
        photoURLs: [String] = [],
        marineLifeTypes: Set<MarineLifeType> = [],
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        likeCount: Int = 0,
        commentCount: Int = 0,
        isLikedByCurrentUser: Bool = false,
        isPinned: Bool = false,
        isLocked: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.title = title
        self.description = description
        self.location = location
        self.photoURLs = photoURLs
        self.marineLifeTypes = marineLifeTypes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.isLikedByCurrentUser = isLikedByCurrentUser
        self.isPinned = isPinned
        self.isLocked = isLocked
    }
    
    // MARK: - Computed Properties
    
    var hasPhotos: Bool {
        !photoURLs.isEmpty
    }
    
    var hasComments: Bool {
        commentCount > 0
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var marineLifeText: String {
        guard !marineLifeTypes.isEmpty else {
            return "None specified"
        }
        
        let sortedTypes = marineLifeTypes.sorted { $0.rawValue < $1.rawValue }
        return sortedTypes
            .map { $0.displayName }
            .joined(separator: ", ")
    }
    
    // MARK: - Mutation Methods
    
    mutating func incrementCommentCount() {
        commentCount += 1
    }
    
    mutating func decrementCommentCount() {
        commentCount = max(0, commentCount - 1)
    }
    
    mutating func toggleLike() {
        if isLikedByCurrentUser {
            likeCount = max(0, likeCount - 1)
            isLikedByCurrentUser = false
        } else {
            likeCount += 1
            isLikedByCurrentUser = true
        }
    }
    
    // MARK: - Equatable
    
    static func == (lhs: CommunityPost, rhs: CommunityPost) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - CLLocationCoordinate2D Extension for Equatable

// Note: Commented out due to warning about conformance in imported type
// If needed, use a custom equality check function instead
/*
extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
*/

