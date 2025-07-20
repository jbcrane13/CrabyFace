//
//  CloudKitServiceProtocol.swift
//  JubileeMobileBay
//
//  Created on 1/19/25.
//

import Foundation
import CloudKit

protocol CloudKitServiceProtocol {
    // Jubilee Events
    func saveJubileeEvent(_ event: JubileeEvent) async throws -> JubileeEvent
    func fetchJubileeEvents() async throws -> [JubileeEvent]
    func fetchRecentJubileeEvents(limit: Int) async throws -> [JubileeEvent]
    
    // User Reports
    func saveUserReport(_ report: UserReport) async throws -> UserReport
    func fetchUserReports(for eventId: UUID) async throws -> [UserReport]
    
    // Photos
    func uploadPhoto(_ data: Data) async throws -> String
    
    // Subscriptions
    func subscribeToJubileeEvents() async throws -> CKQuerySubscription
    
    // Community Posts
    func fetchCommunityPosts(cursor: CKQueryOperation.Cursor?) async throws -> (posts: [CommunityPost], cursor: CKQueryOperation.Cursor?)
    func createCommunityPost(from report: UserReport) async throws -> CommunityPost
    func likePost(postId: String) async throws
    func unlikePost(postId: String) async throws
    func fetchComments(for postId: String) async throws -> [CommunityComment]
    func addComment(to postId: String, text: String) async throws -> CommunityComment
}