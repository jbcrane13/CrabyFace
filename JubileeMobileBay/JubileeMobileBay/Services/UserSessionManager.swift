//
//  UserSessionManager.swift
//  JubileeMobileBay
//
//  Manages user session state and provides consistent user ID tracking
//

import Foundation

protocol UserSessionManagerProtocol {
    var currentUserId: String? { get }
    var currentUserUUID: UUID? { get }
    var currentUser: User? { get }
    func setCurrentUser(_ user: User)
    func clearSession()
    func generateAnonymousUserId() -> String
}

@MainActor
final class UserSessionManager: ObservableObject, @preconcurrency UserSessionManagerProtocol {
    
    // MARK: - Singleton
    
    static let shared = UserSessionManager()
    
    // MARK: - Properties
    
    @Published private(set) var currentUser: User?
    
    private let userDefaults = UserDefaults.standard
    private let currentUserKey = "com.jubileemobilebay.currentUser"
    private let anonymousUserIdKey = "com.jubileemobilebay.anonymousUserId"
    
    // MARK: - Computed Properties
    
    var currentUserId: String? {
        // First priority: authenticated user
        if let user = currentUser {
            return user.id
        }
        
        // Second priority: stored anonymous ID
        if let anonymousId = userDefaults.string(forKey: anonymousUserIdKey) {
            return anonymousId
        }
        
        // Last resort: generate and store new anonymous ID
        let newId = generateAnonymousUserId()
        userDefaults.set(newId, forKey: anonymousUserIdKey)
        return newId
    }
    
    var currentUserUUID: UUID? {
        guard let userId = currentUserId else { return nil }
        return UUID(uuidString: userId)
    }
    
    // MARK: - Initialization
    
    private init() {
        loadStoredUser()
    }
    
    // MARK: - Public Methods
    
    func setCurrentUser(_ user: User) {
        self.currentUser = user
        
        // Store user data for persistence
        if let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: currentUserKey)
        }
        
        // Clear anonymous ID when user authenticates
        userDefaults.removeObject(forKey: anonymousUserIdKey)
    }
    
    func clearSession() {
        currentUser = nil
        userDefaults.removeObject(forKey: currentUserKey)
        // Keep anonymous ID for continuity
    }
    
    func generateAnonymousUserId() -> String {
        // Generate a proper UUID string for anonymous users
        return UUID().uuidString
    }
    
    // MARK: - Private Methods
    
    private func loadStoredUser() {
        guard let userData = userDefaults.data(forKey: currentUserKey),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return
        }
        
        self.currentUser = user
    }
}

// MARK: - CloudKit Integration Extension

extension UserSessionManager {
    
    /// Migrates anonymous user data to authenticated user
    /// - Parameter authenticatedUserId: The authenticated user's ID
    func migrateAnonymousData(to authenticatedUserId: String) async {
        guard userDefaults.string(forKey: anonymousUserIdKey) != nil else {
            return
        }
        
        // This would be called by CloudKitService to migrate data
        // Implementation would involve updating all records with anonymous ID
        // to use the authenticated user ID instead
        
        // Clear anonymous ID after migration
        userDefaults.removeObject(forKey: anonymousUserIdKey)
    }
}