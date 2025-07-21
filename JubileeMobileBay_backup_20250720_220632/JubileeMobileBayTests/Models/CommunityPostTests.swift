//
//  CommunityPostTests.swift
//  JubileeMobileBayTests
//
//  Created on 1/19/25.
//

import XCTest
@testable import JubileeMobileBay

final class CommunityPostTests: XCTestCase {
    
    // MARK: - Test Data
    
    private let samplePostId = "post123"
    private let sampleUserId = "user456"
    private let sampleUserName = "Marine Biologist"
    private let sampleTitle = "Jubilee Event Spotted"
    private let sampleDescription = "Large concentration of marine life observed near Dog River"
    private let sampleLocation = CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399)
    private let samplePhotoURLs = ["https://example.com/photo1.jpg", "https://example.com/photo2.jpg"]
    private let sampleMarineLifeTypes: Set<MarineLifeType> = [.crab, .fish]
    private let sampleDate = Date()
    private let sampleLikeCount = 42
    private let sampleCommentCount = 7
    
    // MARK: - Initialization Tests
    
    func test_communityPost_initialization_shouldSetAllProperties() {
        // Given/When
        let post = CommunityPost(
            id: samplePostId,
            userId: sampleUserId,
            userName: sampleUserName,
            title: sampleTitle,
            description: sampleDescription,
            location: sampleLocation,
            photoURLs: samplePhotoURLs,
            marineLifeTypes: sampleMarineLifeTypes,
            createdAt: sampleDate,
            likeCount: sampleLikeCount,
            commentCount: sampleCommentCount,
            isLikedByCurrentUser: true
        )
        
        // Then
        XCTAssertEqual(post.id, samplePostId)
        XCTAssertEqual(post.userId, sampleUserId)
        XCTAssertEqual(post.userName, sampleUserName)
        XCTAssertEqual(post.title, sampleTitle)
        XCTAssertEqual(post.description, sampleDescription)
        XCTAssertEqual(post.location.latitude, sampleLocation.latitude)
        XCTAssertEqual(post.location.longitude, sampleLocation.longitude)
        XCTAssertEqual(post.photoURLs, samplePhotoURLs)
        XCTAssertEqual(post.marineLifeTypes, sampleMarineLifeTypes)
        XCTAssertEqual(post.createdAt, sampleDate)
        XCTAssertEqual(post.likeCount, sampleLikeCount)
        XCTAssertEqual(post.commentCount, sampleCommentCount)
        XCTAssertTrue(post.isLikedByCurrentUser)
    }
    
    func test_communityPost_initialization_withDefaultValues_shouldUseDefaults() {
        // Given/When
        let post = CommunityPost(
            id: samplePostId,
            userId: sampleUserId,
            userName: sampleUserName,
            title: sampleTitle,
            description: sampleDescription,
            location: sampleLocation
        )
        
        // Then
        XCTAssertTrue(post.photoURLs.isEmpty)
        XCTAssertTrue(post.marineLifeTypes.isEmpty)
        XCTAssertEqual(post.likeCount, 0)
        XCTAssertEqual(post.commentCount, 0)
        XCTAssertFalse(post.isLikedByCurrentUser)
    }
    
    // MARK: - Computed Properties Tests
    
    func test_hasPhotos_whenPhotoURLsNotEmpty_shouldReturnTrue() {
        // Given
        let post = CommunityPost(
            id: samplePostId,
            userId: sampleUserId,
            userName: sampleUserName,
            title: sampleTitle,
            description: sampleDescription,
            location: sampleLocation,
            photoURLs: samplePhotoURLs
        )
        
        // Then
        XCTAssertTrue(post.hasPhotos)
    }
    
    func test_hasPhotos_whenPhotoURLsEmpty_shouldReturnFalse() {
        // Given
        let post = CommunityPost(
            id: samplePostId,
            userId: sampleUserId,
            userName: sampleUserName,
            title: sampleTitle,
            description: sampleDescription,
            location: sampleLocation,
            photoURLs: []
        )
        
        // Then
        XCTAssertFalse(post.hasPhotos)
    }
    
    func test_formattedDate_shouldReturnCorrectFormat() {
        // Given
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let expectedFormat = formatter.string(from: sampleDate)
        
        let post = CommunityPost(
            id: samplePostId,
            userId: sampleUserId,
            userName: sampleUserName,
            title: sampleTitle,
            description: sampleDescription,
            location: sampleLocation,
            createdAt: sampleDate
        )
        
        // Then
        XCTAssertEqual(post.formattedDate, expectedFormat)
    }
    
    func test_marineLifeText_withMultipleTypes_shouldReturnCommaSeparated() {
        // Given
        let post = CommunityPost(
            id: samplePostId,
            userId: sampleUserId,
            userName: sampleUserName,
            title: sampleTitle,
            description: sampleDescription,
            location: sampleLocation,
            marineLifeTypes: [.crab, .fish, .shrimp]
        )
        
        // Then
        let marineLifeText = post.marineLifeText
        XCTAssertTrue(marineLifeText.contains("Crab"))
        XCTAssertTrue(marineLifeText.contains("Fish"))
        XCTAssertTrue(marineLifeText.contains("Shrimp"))
        XCTAssertTrue(marineLifeText.contains(", "))
    }
    
    func test_marineLifeText_withNoTypes_shouldReturnNone() {
        // Given
        let post = CommunityPost(
            id: samplePostId,
            userId: sampleUserId,
            userName: sampleUserName,
            title: sampleTitle,
            description: sampleDescription,
            location: sampleLocation,
            marineLifeTypes: []
        )
        
        // Then
        XCTAssertEqual(post.marineLifeText, "None specified")
    }
    
    // MARK: - Equatable Tests
    
    func test_equatable_whenPostsHaveSameId_shouldBeEqual() {
        // Given
        let post1 = CommunityPost(
            id: samplePostId,
            userId: sampleUserId,
            userName: sampleUserName,
            title: sampleTitle,
            description: sampleDescription,
            location: sampleLocation
        )
        
        let post2 = CommunityPost(
            id: samplePostId,
            userId: "differentUser",
            userName: "Different Name",
            title: "Different Title",
            description: "Different Description",
            location: CLLocationCoordinate2D(latitude: 0, longitude: 0)
        )
        
        // Then
        XCTAssertEqual(post1, post2)
    }
    
    func test_equatable_whenPostsHaveDifferentIds_shouldNotBeEqual() {
        // Given
        let post1 = CommunityPost(
            id: "post1",
            userId: sampleUserId,
            userName: sampleUserName,
            title: sampleTitle,
            description: sampleDescription,
            location: sampleLocation
        )
        
        let post2 = CommunityPost(
            id: "post2",
            userId: sampleUserId,
            userName: sampleUserName,
            title: sampleTitle,
            description: sampleDescription,
            location: sampleLocation
        )
        
        // Then
        XCTAssertNotEqual(post1, post2)
    }
    
    // MARK: - Hashable Tests
    
    func test_hashable_whenPostsHaveSameId_shouldHaveSameHashValue() {
        // Given
        let post1 = CommunityPost(
            id: samplePostId,
            userId: sampleUserId,
            userName: sampleUserName,
            title: sampleTitle,
            description: sampleDescription,
            location: sampleLocation
        )
        
        let post2 = CommunityPost(
            id: samplePostId,
            userId: "differentUser",
            userName: "Different Name",
            title: "Different Title",
            description: "Different Description",
            location: CLLocationCoordinate2D(latitude: 0, longitude: 0)
        )
        
        // Then
        XCTAssertEqual(post1.hashValue, post2.hashValue)
    }
}

// MARK: - CommunityComment Tests

final class CommunityCommentTests: XCTestCase {
    
    // MARK: - Test Data
    
    private let sampleCommentId = "comment123"
    private let samplePostId = "post456"
    private let sampleUserId = "user789"
    private let sampleUserName = "Ocean Observer"
    private let sampleText = "Amazing sighting! I saw similar activity last week."
    private let sampleDate = Date()
    
    // MARK: - Initialization Tests
    
    func test_communityComment_initialization_shouldSetAllProperties() {
        // Given/When
        let comment = CommunityComment(
            id: sampleCommentId,
            postId: samplePostId,
            userId: sampleUserId,
            userName: sampleUserName,
            text: sampleText,
            createdAt: sampleDate
        )
        
        // Then
        XCTAssertEqual(comment.id, sampleCommentId)
        XCTAssertEqual(comment.postId, samplePostId)
        XCTAssertEqual(comment.userId, sampleUserId)
        XCTAssertEqual(comment.userName, sampleUserName)
        XCTAssertEqual(comment.text, sampleText)
        XCTAssertEqual(comment.createdAt, sampleDate)
    }
    
    // MARK: - Computed Properties Tests
    
    func test_formattedDate_shouldReturnCorrectFormat() {
        // Given
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let expectedFormat = formatter.string(from: sampleDate)
        
        let comment = CommunityComment(
            id: sampleCommentId,
            postId: samplePostId,
            userId: sampleUserId,
            userName: sampleUserName,
            text: sampleText,
            createdAt: sampleDate
        )
        
        // Then
        XCTAssertEqual(comment.formattedDate, expectedFormat)
    }
    
    // MARK: - Equatable Tests
    
    func test_equatable_whenCommentsHaveSameId_shouldBeEqual() {
        // Given
        let comment1 = CommunityComment(
            id: sampleCommentId,
            postId: samplePostId,
            userId: sampleUserId,
            userName: sampleUserName,
            text: sampleText,
            createdAt: sampleDate
        )
        
        let comment2 = CommunityComment(
            id: sampleCommentId,
            postId: "differentPost",
            userId: "differentUser",
            userName: "Different Name",
            text: "Different text",
            createdAt: Date()
        )
        
        // Then
        XCTAssertEqual(comment1, comment2)
    }
    
    func test_equatable_whenCommentsHaveDifferentIds_shouldNotBeEqual() {
        // Given
        let comment1 = CommunityComment(
            id: "comment1",
            postId: samplePostId,
            userId: sampleUserId,
            userName: sampleUserName,
            text: sampleText,
            createdAt: sampleDate
        )
        
        let comment2 = CommunityComment(
            id: "comment2",
            postId: samplePostId,
            userId: sampleUserId,
            userName: sampleUserName,
            text: sampleText,
            createdAt: sampleDate
        )
        
        // Then
        XCTAssertNotEqual(comment1, comment2)
    }
}