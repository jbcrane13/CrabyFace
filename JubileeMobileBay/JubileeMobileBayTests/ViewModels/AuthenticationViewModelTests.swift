//
//  AuthenticationViewModelTests.swift
//  JubileeMobileBayTests
//
//  Tests for AuthenticationViewModel
//

import XCTest
import AuthenticationServices
@testable import JubileeMobileBay

@MainActor
final class AuthenticationViewModelTests: XCTestCase {
    var sut: AuthenticationViewModel!
    var mockAuthService: MockAuthenticationService!
    
    override func setUp() async throws {
        try await super.setUp()
        mockAuthService = MockAuthenticationService()
        sut = AuthenticationViewModel(authenticationService: mockAuthService)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockAuthService = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_setsCorrectDefaults() {
        XCTAssertFalse(sut.isAuthenticating)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
    }
    
    // MARK: - Sign In Tests
    
    func test_signInWithApple_startsAuthenticationFlow() async {
        // Given
        XCTAssertFalse(sut.isAuthenticating)
        
        // When
        sut.startSignInWithApple()
        
        // Then
        XCTAssertTrue(sut.isAuthenticating)
        XCTAssertNil(sut.errorMessage)
    }
    
    func test_handleSignInCompletion_success_updatesState() async {
        // Given
        let testUser = User(
            appleUserID: "test-user",
            email: "test@example.com",
            displayName: "Test User"
        )
        mockAuthService.mockUser = testUser
        mockAuthService.authState = .authenticated
        
        // When
        await sut.handleSignInCompletion()
        
        // Then
        XCTAssertFalse(sut.isAuthenticating)
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentUser?.appleUserID, testUser.appleUserID)
    }
    
    func test_handleSignInCompletion_failure_showsError() async {
        // Given
        let errorMessage = "Sign in failed"
        mockAuthService.authState = .failed(errorMessage)
        
        // When
        await sut.handleSignInCompletion()
        
        // Then
        XCTAssertFalse(sut.isAuthenticating)
        XCTAssertEqual(sut.errorMessage, errorMessage)
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
    }
    
    // MARK: - Sign Out Tests
    
    func test_signOut_callsAuthService() async {
        // Given
        mockAuthService.signOutCalled = false
        
        // When
        await sut.signOut()
        
        // Then
        XCTAssertTrue(mockAuthService.signOutCalled)
    }
    
    // MARK: - Check Authentication Tests
    
    func test_checkAuthentication_updatesStateFromService() async {
        // Given
        let testUser = User(
            appleUserID: "existing-user",
            email: "existing@example.com",
            displayName: "Existing User"
        )
        mockAuthService.mockUser = testUser
        mockAuthService.authState = .authenticated
        
        // When
        await sut.checkAuthentication()
        
        // Then
        XCTAssertTrue(mockAuthService.checkAuthenticationCalled)
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentUser?.appleUserID, testUser.appleUserID)
    }
    
    // MARK: - Error Handling Tests
    
    func test_dismissError_clearsErrorMessage() {
        // Given
        sut.errorMessage = "Test error"
        
        // When
        sut.dismissError()
        
        // Then
        XCTAssertNil(sut.errorMessage)
    }
}

// MARK: - Mock Authentication Service

@MainActor
class MockAuthenticationService: AuthenticationService {
    var mockUser: User?
    var authState: AuthenticationState = .unauthenticated
    var signOutCalled = false
    var checkAuthenticationCalled = false
    
    override var currentUser: User? {
        get { mockUser }
        set { mockUser = newValue }
    }
    
    override var authenticationState: AuthenticationState {
        get { authState }
        set { authState = newValue }
    }
    
    init() {
        super.init(cloudKitService: CloudKitService())
    }
    
    override func signOut() async {
        signOutCalled = true
        mockUser = nil
        authState = .unauthenticated
    }
    
    override func checkAuthentication() async throws {
        checkAuthenticationCalled = true
        // Simulate checking authentication
        if mockUser != nil {
            authState = .authenticated
        }
    }
    
    override func createSignInWithAppleRequest() -> ASAuthorizationAppleIDRequest {
        // Return a mock request for testing
        return ASAuthorizationAppleIDProvider().createRequest()
    }
}