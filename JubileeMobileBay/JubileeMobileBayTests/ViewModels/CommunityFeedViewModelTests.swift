//
//  CommunityFeedViewModelTests.swift
//  JubileeMobileBayTests
//
//  Created on 1/19/25.
//

import XCTest
import Combine
import CloudKit
import CoreLocation
@testable import JubileeMobileBay

@MainActor
final class CommunityFeedViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: CommunityFeedViewModel!
    private var mockCloudKitService: MockCloudKitService!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockCloudKitService = MockCloudKitService()
        sut = CommunityFeedViewModel(cloudKitService: mockCloudKitService)
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockCloudKitService = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func test_initialState_shouldHaveEmptyPosts() {
        XCTAssertTrue(sut.posts.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isRefreshing)
        XCTAssertNil(sut.error)
        XCTAssertTrue(sut.hasMorePosts)
    }
    
    // MARK: - Load Posts Tests
    
    func test_loadPosts_whenSuccessful_shouldUpdatePosts() async {
        // Given
        let mockPosts = [
            CommunityPost.mock(id: "1"),
            CommunityPost.mock(id: "2"),
            CommunityPost.mock(id: "3")
        ]
        mockCloudKitService.mockPosts = mockPosts
        
        // When
        await sut.loadPosts()
        
        // Then
        XCTAssertEqual(sut.posts.count, 3)
        XCTAssertEqual(sut.posts, mockPosts)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    func test_loadPosts_whenFailed_shouldSetError() async {
        // Given
        mockCloudKitService.shouldFail = true
        mockCloudKitService.mockError = CloudKitError.networkError
        
        // When
        await sut.loadPosts()
        
        // Then
        XCTAssertTrue(sut.posts.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.error)
        XCTAssertEqual(sut.error, "Failed to load posts. Please try again.")
    }
    
    func test_loadPosts_shouldSetLoadingState() {
        // Given
        let expectation = expectation(description: "Loading state updated")
        var loadingStates: [Bool] = []
        
        sut.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count == 3 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        Task {
            await sut.loadPosts()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(loadingStates, [false, true, false])
    }
    
    // MARK: - Refresh Tests
    
    func test_refresh_shouldReloadAllPosts() async {
        // Given
        let initialPosts = [CommunityPost.mock(id: "1")]
        mockCloudKitService.mockPosts = initialPosts
        await sut.loadPosts()
        
        let newPosts = [
            CommunityPost.mock(id: "2"),
            CommunityPost.mock(id: "3")
        ]
        mockCloudKitService.mockPosts = newPosts
        
        // When
        await sut.refresh()
        
        // Then
        XCTAssertEqual(sut.posts.count, 2)
        XCTAssertEqual(sut.posts, newPosts)
        XCTAssertFalse(sut.isRefreshing)
    }
    
    func test_refresh_shouldSetRefreshingState() {
        // Given
        let expectation = expectation(description: "Refreshing state updated")
        var refreshingStates: [Bool] = []
        
        sut.$isRefreshing
            .sink { isRefreshing in
                refreshingStates.append(isRefreshing)
                if refreshingStates.count == 3 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        Task {
            await sut.refresh()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(refreshingStates, [false, true, false])
    }
    
    // MARK: - Load More Tests
    
    func test_loadMoreIfNeeded_whenHasMorePosts_shouldLoadMore() async {
        // Given
        let initialPosts = (1...10).map { CommunityPost.mock(id: "\($0)") }
        mockCloudKitService.mockPosts = initialPosts
        await sut.loadPosts()
        
        let morePosts = (11...15).map { CommunityPost.mock(id: "\($0)") }
        mockCloudKitService.mockPosts = morePosts
        
        // When
        await sut.loadMoreIfNeeded()
        
        // Then
        XCTAssertEqual(sut.posts.count, 15)
    }
    
    func test_loadMoreIfNeeded_whenNoMorePosts_shouldNotLoad() async {
        // Given
        let posts = (1...5).map { CommunityPost.mock(id: "\($0)") }
        mockCloudKitService.mockPosts = posts
        mockCloudKitService.hasMoreToLoad = false
        await sut.loadPosts()
        
        let initialCount = sut.posts.count
        
        // When
        await sut.loadMoreIfNeeded()
        
        // Then
        XCTAssertEqual(sut.posts.count, initialCount)
        XCTAssertFalse(sut.hasMorePosts)
    }
    
    func test_loadMoreIfNeeded_whenAlreadyLoading_shouldNotLoadAgain() async {
        // Given
        sut.isLoadingMore = true
        let initialCount = sut.posts.count
        
        // When
        await sut.loadMoreIfNeeded()
        
        // Then
        XCTAssertEqual(sut.posts.count, initialCount)
    }
    
    // MARK: - Like/Unlike Tests
    
    func test_toggleLike_whenNotLiked_shouldLikePost() async {
        // Given
        let post = CommunityPost.mock(id: "1", isLikedByCurrentUser: false, likeCount: 5)
        sut.posts = [post]
        
        // When
        await sut.toggleLike(for: post)
        
        // Then
        XCTAssertTrue(sut.posts[0].isLikedByCurrentUser)
        XCTAssertEqual(sut.posts[0].likeCount, 6)
        XCTAssertTrue(mockCloudKitService.likedPostIds.contains("1"))
    }
    
    func test_toggleLike_whenAlreadyLiked_shouldUnlikePost() async {
        // Given
        let post = CommunityPost.mock(id: "1", isLikedByCurrentUser: true, likeCount: 5)
        sut.posts = [post]
        mockCloudKitService.likedPostIds = ["1"]
        
        // When
        await sut.toggleLike(for: post)
        
        // Then
        XCTAssertFalse(sut.posts[0].isLikedByCurrentUser)
        XCTAssertEqual(sut.posts[0].likeCount, 4)
        XCTAssertFalse(mockCloudKitService.likedPostIds.contains("1"))
    }
    
    func test_toggleLike_whenFailed_shouldRevertChanges() async {
        // Given
        let post = CommunityPost.mock(id: "1", isLikedByCurrentUser: false, likeCount: 5)
        sut.posts = [post]
        mockCloudKitService.shouldFail = true
        
        // When
        await sut.toggleLike(for: post)
        
        // Then
        XCTAssertFalse(sut.posts[0].isLikedByCurrentUser)
        XCTAssertEqual(sut.posts[0].likeCount, 5)
    }
    
    // MARK: - Filter Tests
    
    func test_filterByMarineLife_shouldShowOnlyMatchingPosts() async {
        // Given
        let posts = [
            CommunityPost.mock(id: "1", marineLifeTypes: [.crab]),
            CommunityPost.mock(id: "2", marineLifeTypes: [.fish]),
            CommunityPost.mock(id: "3", marineLifeTypes: [.crab, .shrimp])
        ]
        mockCloudKitService.mockPosts = posts
        await sut.loadPosts()
        
        // When
        sut.selectedMarineLifeFilter = .crab
        
        // Then
        XCTAssertEqual(sut.filteredPosts.count, 2)
        XCTAssertTrue(sut.filteredPosts.allSatisfy { $0.marineLifeTypes.contains(.crab) })
    }
    
    func test_filterByMarineLife_whenNone_shouldShowAllPosts() async {
        // Given
        let posts = [
            CommunityPost.mock(id: "1", marineLifeTypes: [.crab]),
            CommunityPost.mock(id: "2", marineLifeTypes: [.fish]),
            CommunityPost.mock(id: "3", marineLifeTypes: [.shrimp])
        ]
        mockCloudKitService.mockPosts = posts
        await sut.loadPosts()
        
        // When
        sut.selectedMarineLifeFilter = nil
        
        // Then
        XCTAssertEqual(sut.filteredPosts.count, 3)
    }
    
    // MARK: - Sort Tests
    
    func test_sortByDate_shouldOrderPostsCorrectly() async {
        // Given
        let date1 = Date()
        let date2 = Date().addingTimeInterval(-3600) // 1 hour ago
        let date3 = Date().addingTimeInterval(-7200) // 2 hours ago
        
        let posts = [
            CommunityPost.mock(id: "1", createdAt: date2),
            CommunityPost.mock(id: "2", createdAt: date1),
            CommunityPost.mock(id: "3", createdAt: date3)
        ]
        mockCloudKitService.mockPosts = posts
        await sut.loadPosts()
        
        // When
        sut.sortOption = .newest
        
        // Then
        XCTAssertEqual(sut.filteredPosts[0].id, "2")
        XCTAssertEqual(sut.filteredPosts[1].id, "1")
        XCTAssertEqual(sut.filteredPosts[2].id, "3")
    }
    
    func test_sortByLikes_shouldOrderPostsCorrectly() async {
        // Given
        let posts = [
            CommunityPost.mock(id: "1", likeCount: 5),
            CommunityPost.mock(id: "2", likeCount: 10),
            CommunityPost.mock(id: "3", likeCount: 3)
        ]
        mockCloudKitService.mockPosts = posts
        await sut.loadPosts()
        
        // When
        sut.sortOption = .mostLiked
        
        // Then
        XCTAssertEqual(sut.filteredPosts[0].id, "2")
        XCTAssertEqual(sut.filteredPosts[1].id, "1")
        XCTAssertEqual(sut.filteredPosts[2].id, "3")
    }
}

// MARK: - Mock CloudKit Service

private class MockCloudKitService: CloudKitServiceProtocol {
    var mockPosts: [CommunityPost] = []
    var shouldFail = false
    var mockError: Error = CloudKitError.networkError
    var hasMoreToLoad = true
    var likedPostIds: Set<String> = []
    
    func fetchCommunityPosts(cursor: CKQueryOperation.Cursor?) async throws -> (posts: [CommunityPost], cursor: CKQueryOperation.Cursor?) {
        if shouldFail {
            throw mockError
        }
        
        let nextCursor = hasMoreToLoad ? CKQueryOperation.Cursor() : nil
        return (mockPosts, nextCursor)
    }
    
    func likePost(postId: String) async throws {
        if shouldFail {
            throw mockError
        }
        likedPostIds.insert(postId)
    }
    
    func unlikePost(postId: String) async throws {
        if shouldFail {
            throw mockError
        }
        likedPostIds.remove(postId)
    }
    
    // Other protocol requirements with default implementations
    func saveJubileeEvent(_ event: JubileeEvent) async throws -> JubileeEvent {
        fatalError("Not implemented for tests")
    }
    
    func fetchJubileeEvents() async throws -> [JubileeEvent] {
        return []
    }
    
    func saveUserReport(_ report: UserReport) async throws -> UserReport {
        fatalError("Not implemented for tests")
    }
    
    func uploadPhoto(_ data: Data) async throws -> String {
        return "mock-photo-url"
    }
    
    func subscribeToJubileeEvents() async throws -> CKQuerySubscription {
        fatalError("Not implemented for tests")
    }
}

// MARK: - CommunityPost Mock Extension

extension CommunityPost {
    static func mock(
        id: String = UUID().uuidString,
        userId: String = "mock-user",
        userName: String = "Test User",
        title: String = "Test Post",
        description: String = "Test Description",
        location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
        photoURLs: [String] = [],
        marineLifeTypes: Set<MarineLifeType> = [],
        createdAt: Date = Date(),
        likeCount: Int = 0,
        commentCount: Int = 0,
        isLikedByCurrentUser: Bool = false
    ) -> CommunityPost {
        CommunityPost(
            id: id,
            userId: userId,
            userName: userName,
            title: title,
            description: description,
            location: location,
            photoURLs: photoURLs,
            marineLifeTypes: marineLifeTypes,
            createdAt: createdAt,
            likeCount: likeCount,
            commentCount: commentCount,
            isLikedByCurrentUser: isLikedByCurrentUser
        )
    }
}