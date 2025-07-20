//
//  MockServices.swift
//  JubileeMobileBayTests
//
//  Mock services for testing
//

import Foundation
import CloudKit
import CoreLocation
import PhotosUI
@testable import JubileeMobileBay

// MARK: - Mock CloudKit Service

class MockCloudKitService: CloudKitService {
    var saveUserReportCalled = false
    var saveUserReportResult: Result<UserReport, Error>?
    var fetchJubileeEventsCalled = false
    var fetchJubileeEventsResult: [JubileeEvent] = []
    
    override func saveUserReport(_ report: UserReport) async throws -> UserReport {
        saveUserReportCalled = true
        
        if let result = saveUserReportResult {
            switch result {
            case .success(let report):
                return report
            case .failure(let error):
                throw error
            }
        }
        
        return report
    }
    
    override func fetchRecentJubileeEvents(limit: Int = 50) async throws -> [JubileeEvent] {
        fetchJubileeEventsCalled = true
        return fetchJubileeEventsResult
    }
}

// MARK: - Mock Location Service

class MockLocationService: LocationServiceProtocol {
    var isAuthorized: Bool = true
    var currentLocation: CLLocation?
    var requestLocationCalled = false
    
    func requestAuthorization() {
        // No-op for testing
    }
    
    func requestLocation() {
        requestLocationCalled = true
    }
    
    func startUpdatingLocation() {
        // No-op for testing
    }
    
    func stopUpdatingLocation() {
        // No-op for testing
    }
}

// MARK: - Mock User Session Manager

class MockUserSessionManager: UserSessionManagerProtocol {
    var currentUserId: String?
    var currentUserUUID: UUID?
    var currentUser: User?
    var generateAnonymousUserIdCalled = false
    
    func setCurrentUser(_ user: User) {
        self.currentUser = user
        self.currentUserId = user.appleUserID
        self.currentUserUUID = UUID(uuidString: user.id)
    }
    
    func clearSession() {
        currentUser = nil
        currentUserId = nil
        currentUserUUID = nil
    }
    
    func generateAnonymousUserId() -> String {
        generateAnonymousUserIdCalled = true
        let id = UUID().uuidString
        currentUserId = id
        currentUserUUID = UUID(uuidString: id)
        return id
    }
}

// MARK: - Mock Photo Upload Service

class MockPhotoUploadService: PhotoUploadService {
    var uploadPhotosCalled = false
    var uploadPhotosResult: Result<[PhotoReference], Error>?
    
    override func uploadPhotos(from items: [PhotosPickerItem]) async throws -> [PhotoReference] {
        uploadPhotosCalled = true
        
        if let result = uploadPhotosResult {
            switch result {
            case .success(let references):
                return references
            case .failure(let error):
                throw error
            }
        }
        
        // Return mock references
        return items.map { _ in
            PhotoReference(
                id: UUID(),
                url: URL(string: "https://mock.cloudkit.com/photo/\(UUID())")!,
                thumbnailUrl: URL(string: "https://mock.cloudkit.com/thumb/\(UUID())")!
            )
        }
    }
}

// MARK: - Mock Authentication Service

class MockAuthenticationService: AuthenticationService {
    var signInCalled = false
    var signOutCalled = false
    var mockUser: User?
    var shouldFailSignIn = false
    
    override func signIn() async throws {
        signInCalled = true
        
        if shouldFailSignIn {
            throw AuthenticationError.signInFailed
        }
        
        if let user = mockUser {
            currentUser = user
        }
    }
    
    override func signOut() async {
        signOutCalled = true
        currentUser = nil
    }
}