//
//  CoreDataStackTests.swift
//  JubileeMobileBayTests
//
//  Created by Assistant on 1/23/25.
//

import XCTest
import CoreData
@testable import JubileeMobileBay

class CoreDataStackTests: XCTestCase {
    
    var sut: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        // Use in-memory store for testing
        sut = CoreDataStack.shared
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Message Entity Tests
    
    func test_createMessage_shouldPersistWithCorrectProperties() {
        // Given
        let context = sut.viewContext
        let messageId = UUID()
        let text = "Test message"
        let roomId = "test-room"
        let userId = "test-user"
        
        // When
        let message = MessageEntity(context: context)
        message.id = messageId
        message.text = text
        message.timestamp = Date()
        message.roomId = roomId
        message.userId = userId
        message.syncStatusEnum = .pending
        
        sut.save()
        
        // Then
        let fetchRequest = MessageEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", messageId as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            XCTAssertEqual(results.count, 1)
            
            let fetchedMessage = results.first
            XCTAssertEqual(fetchedMessage?.id, messageId)
            XCTAssertEqual(fetchedMessage?.text, text)
            XCTAssertEqual(fetchedMessage?.roomId, roomId)
            XCTAssertEqual(fetchedMessage?.userId, userId)
            XCTAssertEqual(fetchedMessage?.syncStatus, 0) // pending
        } catch {
            XCTFail("Failed to fetch message: \(error)")
        }
    }
    
    func test_fetchPendingMessages_shouldReturnOnlyPendingMessages() {
        // Given
        let context = sut.viewContext
        
        // Create pending message
        let pendingMessage = MessageEntity(context: context)
        pendingMessage.id = UUID()
        pendingMessage.text = "Pending message"
        pendingMessage.timestamp = Date()
        pendingMessage.roomId = "test-room"
        pendingMessage.userId = "test-user"
        pendingMessage.syncStatusEnum = .pending
        
        // Create synced message
        let syncedMessage = MessageEntity(context: context)
        syncedMessage.id = UUID()
        syncedMessage.text = "Synced message"
        syncedMessage.timestamp = Date()
        syncedMessage.roomId = "test-room"
        syncedMessage.userId = "test-user"
        syncedMessage.syncStatusEnum = .synced
        
        sut.save()
        
        // When
        let pendingMessages = sut.fetchPendingMessages()
        
        // Then
        XCTAssertEqual(pendingMessages.count, 1)
        XCTAssertEqual(pendingMessages.first?.text, "Pending message")
    }
    
    // MARK: - Chat Room Entity Tests
    
    func test_fetchOrCreateChatRoom_shouldCreateNewRoom() {
        // Given
        let roomId = "new-room"
        let roomName = "New Chat Room"
        
        // When
        let room = sut.fetchOrCreateChatRoom(id: roomId, name: roomName)
        
        // Then
        XCTAssertEqual(room.id, roomId)
        XCTAssertEqual(room.name, roomName)
        XCTAssertNotNil(room.createdAt)
        XCTAssertEqual(room.syncStatus, 0) // pending
    }
    
    func test_fetchOrCreateChatRoom_shouldReturnExistingRoom() {
        // Given
        let roomId = "existing-room"
        let roomName = "Existing Room"
        
        // Create room first
        _ = sut.fetchOrCreateChatRoom(id: roomId, name: roomName)
        
        // When - try to create again with different name
        let room = sut.fetchOrCreateChatRoom(id: roomId, name: "Different Name")
        
        // Then - should return existing room
        XCTAssertEqual(room.id, roomId)
        XCTAssertEqual(room.name, roomName) // Original name preserved
    }
    
    // MARK: - User Profile Entity Tests
    
    func test_createUserProfile_shouldPersistWithGamificationData() {
        // Given
        let context = sut.viewContext
        let userId = "test-user"
        let displayName = "Test User"
        let points: Int32 = 150
        let badges = ["early_adopter", "helpful_member"]
        
        // When
        let profile = UserProfileEntity(context: context)
        profile.id = userId
        profile.displayName = displayName
        profile.points = points
        profile.joinedAt = Date()
        profile.badges = badges as NSObject
        profile.syncStatusEnum = .pending
        
        sut.save()
        
        // Then
        let fetchedProfile = sut.fetchUserProfile(id: userId)
        XCTAssertNotNil(fetchedProfile)
        XCTAssertEqual(fetchedProfile?.id, userId)
        XCTAssertEqual(fetchedProfile?.displayName, displayName)
        XCTAssertEqual(fetchedProfile?.points, points)
        XCTAssertEqual(fetchedProfile?.badges as? [String], badges)
    }
    
    // MARK: - CloudKit Integration Tests
    
    func test_messageEntity_toCloudKitRecord_shouldCreateValidRecord() {
        // Given
        let context = sut.viewContext
        let message = MessageEntity(context: context)
        message.id = UUID()
        message.text = "Test message"
        message.timestamp = Date()
        message.roomId = "test-room"
        message.userId = "test-user"
        message.userName = "Test User"
        
        // When
        let record = message.toCloudKitRecord()
        
        // Then
        XCTAssertEqual(record.recordType, "Message")
        XCTAssertEqual(record["id"] as? String, message.id?.uuidString)
        XCTAssertEqual(record["text"] as? String, message.text)
        XCTAssertEqual(record["roomId"] as? String, message.roomId)
        XCTAssertEqual(record["userId"] as? String, message.userId)
        XCTAssertEqual(record["userName"] as? String, message.userName)
    }
    
    // MARK: - Background Context Tests
    
    func test_backgroundContext_shouldBeIndependent() {
        // Given
        let backgroundContext = sut.newBackgroundContext()
        
        // When
        let message = MessageEntity(context: backgroundContext)
        message.id = UUID()
        message.text = "Background message"
        message.timestamp = Date()
        message.roomId = "test-room"
        message.userId = "test-user"
        
        do {
            try backgroundContext.save()
        } catch {
            XCTFail("Failed to save background context: \(error)")
        }
        
        // Then - verify it doesn't exist in view context yet
        let viewContextMessages = sut.fetchMessages(for: "test-room")
        XCTAssertTrue(viewContextMessages.isEmpty || !viewContextMessages.contains { $0.text == "Background message" })
    }
    
    // MARK: - Performance Tests
    
    func test_fetchMessages_performance() {
        // Given - create many messages
        let context = sut.viewContext
        let roomId = "performance-test"
        
        for i in 0..<100 {
            let message = MessageEntity(context: context)
            message.id = UUID()
            message.text = "Message \(i)"
            message.timestamp = Date().addingTimeInterval(TimeInterval(i))
            message.roomId = roomId
            message.userId = "test-user"
        }
        
        sut.save()
        
        // When/Then
        measure {
            _ = sut.fetchMessages(for: roomId, limit: 50)
        }
    }
}

// MARK: - Test Helpers
extension CoreDataStackTests {
    
    func clearAllData() {
        let context = sut.viewContext
        
        // Delete all messages
        let messageFetch = MessageEntity.fetchRequest()
        if let messages = try? context.fetch(messageFetch) {
            messages.forEach { context.delete($0) }
        }
        
        // Delete all rooms
        let roomFetch = ChatRoomEntity.fetchRequest()
        if let rooms = try? context.fetch(roomFetch) {
            rooms.forEach { context.delete($0) }
        }
        
        // Delete all profiles
        let profileFetch = UserProfileEntity.fetchRequest()
        if let profiles = try? context.fetch(profileFetch) {
            profiles.forEach { context.delete($0) }
        }
        
        sut.save()
    }
}