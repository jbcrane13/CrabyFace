//
//  AuthenticationService.swift
//  JubileeMobileBay
//
//  Handles Sign in with Apple authentication
//

import Foundation
import AuthenticationServices
import CryptoKit

@MainActor
public class AuthenticationService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentUser: User?
    @Published var authenticationState: AuthenticationState = .unauthenticated
    
    // MARK: - Properties
    
    private let cloudKitService: CloudKitService
    
    // MARK: - Computed Properties
    
    var isAuthenticated: Bool {
        currentUser != nil && authenticationState == .authenticated
    }
    
    // MARK: - Initialization
    
    init(cloudKitService: CloudKitService) {
        self.cloudKitService = cloudKitService
    }
    
    // MARK: - Public Methods
    
    func handleSignInWithAppleSuccess(credential: ASAuthorizationAppleIDCredential) async throws {
        let userID = credential.user
        
        // Try to fetch existing user first
        if let existingUser = try await cloudKitService.fetchCurrentUser() {
            // User already exists, just update local state
            self.currentUser = existingUser
            self.authenticationState = .authenticated
            return
        }
        
        // New user - create profile
        let email = credential.email
        let fullName = credential.fullName
        
        // Create display name from full name components
        var displayName = "User"
        if let givenName = fullName?.givenName,
           let familyName = fullName?.familyName {
            displayName = "\(givenName) \(familyName)"
        } else if let givenName = fullName?.givenName {
            displayName = givenName
        } else if let familyName = fullName?.familyName {
            displayName = familyName
        }
        
        // If still just "User", generate a unique name
        if displayName == "User" {
            displayName = "JubileeSpotter\(Int.random(in: 100...999))"
        }
        
        // Create user object
        let user = User(
            appleUserID: userID,
            email: email ?? "",
            displayName: displayName
        )
        
        // Save to CloudKit
        try await cloudKitService.saveUser(user)
        
        // Update local state
        self.currentUser = user
        self.authenticationState = .authenticated
        
        // Update UserSessionManager
        UserSessionManager.shared.setCurrentUser(user)
    }
    
    func handleSignInWithAppleError(_ error: Error) async {
        self.currentUser = nil
        self.authenticationState = .failed(error.localizedDescription)
    }
    
    func signOut() async {
        self.currentUser = nil
        self.authenticationState = .unauthenticated
        
        // Clear any stored credentials
        // In a real app, you might also want to clear keychain items
    }
    
    func checkAuthentication() async throws {
        // Check if user is already signed in
        if let user = try await cloudKitService.fetchCurrentUser() {
            self.currentUser = user
            self.authenticationState = .authenticated
        } else {
            self.currentUser = nil
            self.authenticationState = .unauthenticated
        }
    }
    
    // MARK: - Sign in with Apple Request
    
    func createSignInWithAppleRequest() throws -> ASAuthorizationAppleIDRequest {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        // Generate nonce for added security
        let nonce = try randomNonceString()
        request.nonce = sha256(nonce)
        
        return request
    }
    
    // MARK: - Helper Methods
    
    private func randomNonceString(length: Int = 32) throws -> String {
        guard length > 0 else {
            throw NonceGenerationError.invalidLength
        }
        
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = try (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    throw NonceGenerationError.randomGenerationFailed(errorCode)
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - Authentication State

public enum AuthenticationState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated
    case failed(String)
}

// MARK: - Error Types

enum NonceGenerationError: LocalizedError {
    case invalidLength
    case randomGenerationFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .invalidLength:
            return "Invalid nonce length specified"
        case .randomGenerationFailed(let status):
            return "Failed to generate secure random bytes. OSStatus: \(status)"
        }
    }
}

// MARK: - User Model

public struct User: Identifiable, Codable, Equatable {
    public let id: String
    public let appleUserID: String
    public let email: String
    public let displayName: String
    public let createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        appleUserID: String,
        email: String,
        displayName: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.appleUserID = appleUserID
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
    }
}