//
//  CommunityFeedViewModel.swift
//  JubileeMobileBay
//
//  Created on 1/19/25.
//

import Foundation
import Combine
import CloudKit

@MainActor
class CommunityFeedViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var posts: [CommunityPost] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var isLoadingMore = false
    @Published var error: String?
    @Published var selectedMarineLifeFilter: MarineLifeType?
    @Published var sortOption: SortOption = .newest
    
    // MARK: - Properties
    
    private let cloudKitService: CloudKitServiceProtocol
    private var currentCursor: CKQueryOperation.Cursor?
    private(set) var hasMorePosts = true
    
    // MARK: - Computed Properties
    
    var filteredPosts: [CommunityPost] {
        let filtered = posts.filter { post in
            if let filter = selectedMarineLifeFilter {
                return post.marineLifeTypes.contains(filter)
            }
            return true
        }
        
        switch sortOption {
        case .newest:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return filtered.sorted { $0.createdAt < $1.createdAt }
        case .mostLiked:
            return filtered.sorted { $0.likeCount > $1.likeCount }
        }
    }
    
    // MARK: - Sort Options
    
    enum SortOption: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case mostLiked = "Most Liked"
    }
    
    // MARK: - Initialization
    
    init(cloudKitService: CloudKitServiceProtocol) {
        self.cloudKitService = cloudKitService
    }
    
    // MARK: - Public Methods
    
    func loadPosts() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            let result = try await cloudKitService.fetchCommunityPosts(cursor: nil)
            posts = result.posts
            currentCursor = result.cursor
            hasMorePosts = result.cursor != nil
        } catch {
            self.error = "Failed to load posts. Please try again."
            posts = []
        }
        
        isLoading = false
    }
    
    func refresh() async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        error = nil
        
        do {
            let result = try await cloudKitService.fetchCommunityPosts(cursor: nil)
            posts = result.posts
            currentCursor = result.cursor
            hasMorePosts = result.cursor != nil
        } catch {
            self.error = "Failed to refresh posts. Please try again."
        }
        
        isRefreshing = false
    }
    
    func loadMoreIfNeeded() async {
        guard hasMorePosts,
              !isLoadingMore,
              let cursor = currentCursor else { return }
        
        isLoadingMore = true
        
        do {
            let result = try await cloudKitService.fetchCommunityPosts(cursor: cursor)
            posts.append(contentsOf: result.posts)
            currentCursor = result.cursor
            hasMorePosts = result.cursor != nil
        } catch {
            self.error = "Failed to load more posts."
        }
        
        isLoadingMore = false
    }
    
    func toggleLike(for post: CommunityPost) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        // Optimistic update
        var updatedPost = post
        updatedPost.isLikedByCurrentUser.toggle()
        updatedPost.likeCount += updatedPost.isLikedByCurrentUser ? 1 : -1
        posts[index] = updatedPost
        
        do {
            if updatedPost.isLikedByCurrentUser {
                try await cloudKitService.likePost(postId: post.id)
            } else {
                try await cloudKitService.unlikePost(postId: post.id)
            }
        } catch {
            // Revert on failure
            posts[index] = post
            self.error = "Failed to update like status."
        }
    }
}

