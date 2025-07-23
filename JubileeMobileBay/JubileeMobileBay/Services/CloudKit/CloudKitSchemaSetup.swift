//
//  CloudKitSchemaSetup.swift
//  JubileeMobileBay
//
//  Created by Assistant on 1/23/25.
//

import Foundation
import CloudKit

/// Service to setup CloudKit schema for community features
class CloudKitSchemaSetup {
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    
    init(containerIdentifier: String = "iCloud.com.jubileemobilebay.app") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.privateDatabase = container.privateCloudDatabase
        self.publicDatabase = container.publicCloudDatabase
    }
    
    /// Setup all CloudKit schemas for community features
    func setupSchemas() async throws {
        // Note: In production, schema creation is typically done through CloudKit Dashboard
        // This code documents the schema structure needed
        
        print("CloudKit Schema Setup")
        print("=====================")
        print("Please create the following record types in CloudKit Dashboard:")
        print("")
        
        printMessageSchema()
        printChatRoomSchema()
        printUserProfileSchema()
        
        // Setup subscriptions for real-time features
        try await setupSubscriptions()
        
        // Setup security roles
        setupSecurityRoles()
    }
    
    // MARK: - Schema Definitions
    
    private func printMessageSchema() {
        print("Record Type: Message")
        print("-------------------")
        print("Fields:")
        print("  - id: String (indexed)")
        print("  - text: String (searchable)")
        print("  - timestamp: Date/Time (queryable, sortable)")
        print("  - roomId: String (indexed, queryable)")
        print("  - userId: String (indexed)")
        print("  - userName: String")
        print("  - isDeleted: Boolean")
        print("  - lastModified: Date/Time (queryable, sortable)")
        print("")
        print("Indexes:")
        print("  - roomId + timestamp (for efficient room queries)")
        print("  - userId (for user's messages)")
        print("")
    }
    
    private func printChatRoomSchema() {
        print("Record Type: ChatRoom")
        print("--------------------")
        print("Fields:")
        print("  - id: String (indexed)")
        print("  - name: String (searchable)")
        print("  - createdAt: Date/Time")
        print("  - lastMessageAt: Date/Time (queryable, sortable)")
        print("  - unreadCount: Int")
        print("")
        print("Indexes:")
        print("  - lastMessageAt (for sorting rooms)")
        print("")
    }
    
    private func printUserProfileSchema() {
        print("Record Type: UserProfile")
        print("-----------------------")
        print("Fields:")
        print("  - id: String (indexed)")
        print("  - displayName: String (searchable)")
        print("  - points: Int (queryable, sortable)")
        print("  - joinedAt: Date/Time")
        print("  - badges: String (JSON array)")
        print("")
        print("Indexes:")
        print("  - points (for leaderboard)")
        print("  - displayName (for search)")
        print("")
    }
    
    // MARK: - Subscriptions Setup
    
    private func setupSubscriptions() async throws {
        // Setup database-wide subscription for new messages
        let messageSubscription = CKDatabaseSubscription(subscriptionID: "all-messages-subscription")
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.shouldBadge = true
        messageSubscription.notificationInfo = notificationInfo
        
        do {
            _ = try await privateDatabase.save(messageSubscription)
            print("Database subscription created for messages")
        } catch {
            // Subscription might already exist
            print("Message subscription may already exist: \(error)")
        }
    }
    
    // MARK: - Security Roles
    
    private func setupSecurityRoles() {
        print("Security Roles:")
        print("--------------")
        print("Message Records:")
        print("  - Creator: Read/Write")
        print("  - Authenticated: Read (for room members)")
        print("  - World: No Access")
        print("")
        print("ChatRoom Records:")
        print("  - Creator: Read/Write")
        print("  - Authenticated: Read")
        print("  - World: No Access")
        print("")
        print("UserProfile Records:")
        print("  - Creator: Read/Write")
        print("  - Authenticated: Read")
        print("  - World: Read (public leaderboard)")
        print("")
    }
    
    // MARK: - Validation
    
    /// Validate that required record types exist
    func validateSchema() async throws -> Bool {
        print("Validating CloudKit schema...")
        
        // Try to query each record type
        let recordTypes = ["Message", "ChatRoom", "UserProfile"]
        var allValid = true
        
        for recordType in recordTypes {
            let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: false))
            
            do {
                _ = try await privateDatabase.records(matching: query, resultsLimit: 1)
                print("✓ Record type '\(recordType)' exists")
            } catch {
                print("✗ Record type '\(recordType)' not found: \(error)")
                allValid = false
            }
        }
        
        return allValid
    }
    
    // MARK: - Sample Data
    
    /// Create sample data for testing
    func createSampleData() async throws {
        print("Creating sample data...")
        
        // Create sample chat room
        let roomRecord = CKRecord(recordType: "ChatRoom", recordID: CKRecord.ID(recordName: "general"))
        roomRecord["id"] = "general"
        roomRecord["name"] = "General Discussion"
        roomRecord["createdAt"] = Date()
        roomRecord["lastMessageAt"] = Date()
        roomRecord["unreadCount"] = 0
        
        do {
            _ = try await publicDatabase.save(roomRecord)
            print("Created sample chat room: General Discussion")
        } catch {
            print("Sample room may already exist: \(error)")
        }
        
        // Create sample user profile
        let profileRecord = CKRecord(recordType: "UserProfile")
        profileRecord["id"] = "sample-user"
        profileRecord["displayName"] = "Sample User"
        profileRecord["points"] = 100
        profileRecord["joinedAt"] = Date()
        profileRecord["badges"] = "[]"
        
        do {
            _ = try await privateDatabase.save(profileRecord)
            print("Created sample user profile")
        } catch {
            print("Sample profile creation failed: \(error)")
        }
    }
}

// MARK: - CloudKit Schema Documentation
extension CloudKitSchemaSetup {
    
    /// Generate markdown documentation for the schema
    func generateDocumentation() -> String {
        return """
        # CloudKit Schema Documentation
        
        ## Overview
        The JubileeMobileBay app uses CloudKit for community features with offline-first support.
        
        ## Record Types
        
        ### Message
        Represents a chat message in a room.
        
        | Field | Type | Attributes |
        |-------|------|------------|
        | id | String | Indexed, Unique |
        | text | String | Searchable |
        | timestamp | Date/Time | Queryable, Sortable |
        | roomId | String | Indexed, Queryable |
        | userId | String | Indexed |
        | userName | String | - |
        | isDeleted | Boolean | - |
        | lastModified | Date/Time | Queryable, Sortable |
        
        ### ChatRoom
        Represents a chat room or channel.
        
        | Field | Type | Attributes |
        |-------|------|------------|
        | id | String | Indexed, Unique |
        | name | String | Searchable |
        | createdAt | Date/Time | - |
        | lastMessageAt | Date/Time | Queryable, Sortable |
        | unreadCount | Int | - |
        
        ### UserProfile
        Represents a user's profile with gamification data.
        
        | Field | Type | Attributes |
        |-------|------|------------|
        | id | String | Indexed, Unique |
        | displayName | String | Searchable |
        | points | Int | Queryable, Sortable |
        | joinedAt | Date/Time | - |
        | badges | String | JSON Array |
        
        ## Subscriptions
        
        - **all-messages-subscription**: Database-wide subscription for new messages
        - **message-subscription-{roomId}**: Per-room subscriptions for real-time updates
        
        ## Security Model
        
        - **Private Database**: User's own data (messages, profile)
        - **Public Database**: Shared data (chat rooms, leaderboard)
        - **Record-level permissions**: Creator has read/write, others have read-only
        
        ## Best Practices
        
        1. Always use record IDs for relationships
        2. Index fields used in queries
        3. Use subscriptions sparingly to avoid quota limits
        4. Implement proper error handling for network failures
        5. Cache data locally using Core Data
        """
    }
}