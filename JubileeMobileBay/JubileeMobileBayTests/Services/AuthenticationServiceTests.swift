//
//  AuthenticationServiceTests.swift
//  JubileeMobileBayTests
//
//  Tests for AuthenticationService
//

import XCTest
@testable import JubileeMobileBay

final class AuthenticationServiceTests: XCTestCase {
    var sut: AuthenticationService!
    var mockCloudKitService: MockCloudKitService!
    
    override func setUp() {
        super.setUp()
        mockCloudKitService = MockCloudKitService()
        sut = AuthenticationService(cloudKitService: mockCloudKitService)
    }
    
    override func tearDown() {
        sut = nil
        mockCloudKitService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_setsCorrectDefaults() {
        XCTAssertNil(sut.currentUser)
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertEqual(sut.authenticationState, .unauthenticated)
    }
    
    // MARK: - Sign In Tests
    
    func test_signInWithApple_error_updatesState() async {
        // Given
        let error = NSError(domain: "test", code: 1001, userInfo: nil)
        
        // When
        await sut.handleSignInWithAppleError(error)
        
        // Then
        XCTAssertNil(sut.currentUser)
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertEqual(sut.authenticationState, .failed(error.localizedDescription))
    }
    
    // MARK: - Sign Out Tests
    
    func test_signOut_clearsUserAndUpdatesState() async {
        // Given
        sut.currentUser = User(
            appleUserID: "test-user",
            email: "test@example.com",
            displayName: "Test User"
        )
        sut.authenticationState = .authenticated
        
        // When
        await sut.signOut()
        
        // Then
        XCTAssertNil(sut.currentUser)
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertEqual(sut.authenticationState, .unauthenticated)
    }
    
    // MARK: - Check Authentication Tests
    
    func test_checkAuthentication_withStoredCredentials_restoresUser() async throws {
        // Given
        mockCloudKitService.mockStoredUser = User(
            appleUserID: "stored-user",
            email: "stored@example.com",
            displayName: "Stored User"
        )
        
        // When
        try await sut.checkAuthentication()
        
        // Then
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(sut.currentUser?.appleUserID, "stored-user")
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.authenticationState, .authenticated)
    }
    
    func test_checkAuthentication_withoutStoredCredentials_remainsUnauthenticated() async throws {
        // Given
        mockCloudKitService.mockStoredUser = nil
        
        // When
        try await sut.checkAuthentication()
        
        // Then
        XCTAssertNil(sut.currentUser)
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertEqual(sut.authenticationState, .unauthenticated)
    }
    
    // MARK: - Helper Method Tests
    
    func test_createSignInWithAppleRequest_setsCorrectScopes() {
        // When
        let request = sut.createSignInWithAppleRequest()
        
        // Then
        XCTAssertEqual(request.requestedScopes, [.fullName, .email])
        XCTAssertNotNil(request.nonce)
    }
}

// MARK: - Mock Objects

class MockCloudKitService: CloudKitService {
    var saveUserCalled = false
    var savedUser: User?
    var mockStoredUser: User?
    var saveUserShouldSucceed = true
    
    override func saveUser(_ user: User) async throws {
        saveUserCalled = true
        savedUser = user
        
        if !saveUserShouldSucceed {
            throw CloudKitError.serverError
        }
    }
    
    override func fetchCurrentUser() async throws -> User? {
        return mockStoredUser
    }
}