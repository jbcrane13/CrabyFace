//
//  AuthenticationViewModel.swift
//  JubileeMobileBay
//
//  ViewModel for authentication flow
//

import Foundation
import AuthenticationServices
import SwiftUI

@MainActor
class AuthenticationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isAuthenticating = false
    @Published var errorMessage: String?
    
    // MARK: - Properties
    
    private let authenticationService: AuthenticationService
    
    // MARK: - Computed Properties
    
    var isAuthenticated: Bool {
        authenticationService.currentUser != nil &&
        authenticationService.authenticationState == .authenticated
    }
    
    var currentUser: User? {
        authenticationService.currentUser
    }
    
    var showError: Binding<Bool> {
        Binding(
            get: { self.errorMessage != nil },
            set: { if !$0 { self.errorMessage = nil } }
        )
    }
    
    // MARK: - Initialization
    
    init(authenticationService: AuthenticationService) {
        self.authenticationService = authenticationService
    }
    
    // MARK: - Public Methods
    
    func startSignInWithApple() {
        isAuthenticating = true
        errorMessage = nil
    }
    
    func handleSignInCompletion() async {
        isAuthenticating = false
        
        // Check the authentication state from the service
        switch authenticationService.authenticationState {
        case .authenticated:
            // Success - user is now authenticated
            errorMessage = nil
        case .failed(let error):
            errorMessage = error
        case .unauthenticated, .authenticating:
            // No action needed
            break
        }
    }
    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        // Configure the request using the authentication service
        do {
            let serviceRequest = try authenticationService.createSignInWithAppleRequest()
            request.requestedScopes = serviceRequest.requestedScopes
            request.nonce = serviceRequest.nonce
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                do {
                    try await authenticationService.handleSignInWithAppleSuccess(credential: appleIDCredential)
                    await handleSignInCompletion()
                } catch {
                    errorMessage = error.localizedDescription
                    isAuthenticating = false
                }
            }
        case .failure(let error):
            await authenticationService.handleSignInWithAppleError(error)
            await handleSignInCompletion()
        }
    }
    
    func signOut() async {
        await authenticationService.signOut()
    }
    
    func checkAuthentication() async {
        do {
            try await authenticationService.checkAuthentication()
        } catch {
            // If check fails, user remains unauthenticated
            print("Authentication check failed: \(error)")
        }
    }
    
    func dismissError() {
        errorMessage = nil
    }
}

// MARK: - Sign in with Apple Button Style

struct SignInWithAppleButtonStyle: ButtonStyle {
    let isDarkMode: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isDarkMode ? Color.white : Color.black)
            .foregroundColor(isDarkMode ? Color.black : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}