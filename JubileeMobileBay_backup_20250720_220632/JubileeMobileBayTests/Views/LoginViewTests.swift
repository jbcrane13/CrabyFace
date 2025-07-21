//
//  LoginViewTests.swift
//  JubileeMobileBayTests
//
//  Tests for LoginView
//

import XCTest
import ViewInspector
import SwiftUI
@testable import JubileeMobileBay

final class LoginViewTests: XCTestCase {
    
    var mockAuthService: MockAuthenticationService!
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthenticationService()
    }
    
    override func tearDown() {
        mockAuthService = nil
        super.tearDown()
    }
    
    // MARK: - LoginView Tests
    
    func test_loginView_displaysAppTitle() throws {
        let view = LoginView(authenticationService: mockAuthService)
        
        let title = try view.inspect().find(text: "Jubilee Mobile Bay")
        XCTAssertNotNil(title)
    }
    
    func test_loginView_displaysSubtitle() throws {
        let view = LoginView(authenticationService: mockAuthService)
        
        let subtitle = try view.inspect().find(text: "Track and share jubilee events")
        XCTAssertNotNil(subtitle)
    }
    
    func test_loginView_displaysCommunityMessage() throws {
        let view = LoginView(authenticationService: mockAuthService)
        
        let message = try view.inspect().find(text: "Join the Community")
        XCTAssertNotNil(message)
    }
    
    func test_loginView_hasSkipButton() throws {
        let view = LoginView(authenticationService: mockAuthService)
        
        let skipButton = try view.inspect().find(button: "Skip for now")
        XCTAssertNotNil(skipButton)
    }
    
    func test_loginView_hasCloseButton() throws {
        let view = LoginView(authenticationService: mockAuthService)
        
        let closeButton = try view.inspect().find(button: "Close")
        XCTAssertNotNil(closeButton)
    }
    
    // MARK: - LoginPromptView Tests
    
    func test_loginPromptView_displaysSignInRequired() throws {
        @State var showLogin = false
        let view = LoginPromptView(showLogin: $showLogin)
        
        let title = try view.inspect().find(text: "Sign in Required")
        XCTAssertNotNil(title)
    }
    
    func test_loginPromptView_hasSignInButton() throws {
        @State var showLogin = false
        let view = LoginPromptView(showLogin: $showLogin)
        
        let button = try view.inspect().find(button: "Sign in with Apple")
        XCTAssertNotNil(button)
    }
    
    func test_loginPromptView_tapSignInButton_setsShowLogin() throws {
        var showLogin = false
        let binding = Binding(
            get: { showLogin },
            set: { showLogin = $0 }
        )
        let view = LoginPromptView(showLogin: binding)
        
        let button = try view.inspect().find(button: "Sign in with Apple")
        try button.tap()
        
        XCTAssertTrue(showLogin)
    }
    
    // MARK: - AuthenticatedUserView Tests
    
    func test_authenticatedUserView_displaysUserName() throws {
        let user = User(
            appleUserID: "123",
            email: "test@example.com",
            displayName: "Test User"
        )
        let view = AuthenticatedUserView(user: user, onSignOut: {})
        
        let name = try view.inspect().find(text: "Test User")
        XCTAssertNotNil(name)
    }
    
    func test_authenticatedUserView_displaysUserEmail() throws {
        let user = User(
            appleUserID: "123",
            email: "test@example.com",
            displayName: "Test User"
        )
        let view = AuthenticatedUserView(user: user, onSignOut: {})
        
        let email = try view.inspect().find(text: "test@example.com")
        XCTAssertNotNil(email)
    }
    
    func test_authenticatedUserView_hasSignOutButton() throws {
        let user = User(
            appleUserID: "123",
            email: "test@example.com",
            displayName: "Test User"
        )
        let view = AuthenticatedUserView(user: user, onSignOut: {})
        
        let button = try view.inspect().find(button: "Sign Out")
        XCTAssertNotNil(button)
    }
    
    func test_authenticatedUserView_signOutButton_callsClosure() throws {
        let user = User(
            appleUserID: "123",
            email: "test@example.com",
            displayName: "Test User"
        )
        
        let expectation = XCTestExpectation(description: "Sign out called")
        let view = AuthenticatedUserView(user: user) {
            expectation.fulfill()
        }
        
        let button = try view.inspect().find(button: "Sign Out")
        try button.tap()
        
        wait(for: [expectation], timeout: 1.0)
    }
}

// Extension to help inspect SignInWithAppleButton
extension InspectableView {
    func signInWithAppleButton() throws -> InspectableView<ViewType.View> {
        return try find(ViewType.View.self)
    }
}