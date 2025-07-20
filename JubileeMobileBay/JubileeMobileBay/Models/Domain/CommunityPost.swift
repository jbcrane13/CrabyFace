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
    var likeCount: Int
    var commentCount: Int
    var isLikedByCurrentUser: Bool
    
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
        likeCount: Int = 0,
        commentCount: Int = 0,
        isLikedByCurrentUser: Bool = false
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
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.isLikedByCurrentUser = isLikedByCurrentUser
    }
    
    // MARK: - Computed Properties
    
    var hasPhotos: Bool {
        !photoURLs.isEmpty
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
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

// MARK: - CommunityComment

struct CommunityComment: Identifiable, Equatable, Hashable {
    let id: String
    let postId: String
    let userId: String
    let userName: String
    let text: String
    let createdAt: Date
    
    init(
        id: String,
        postId: String,
        userId: String,
        userName: String,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.postId = postId
        self.userId = userId
        self.userName = userName
        self.text = text
        self.createdAt = createdAt
    }
    
    // MARK: - Computed Properties
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    // MARK: - Equatable
    
    static func == (lhs: CommunityComment, rhs: CommunityComment) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}