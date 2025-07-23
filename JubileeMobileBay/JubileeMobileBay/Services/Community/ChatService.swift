//
//  ChatService.swift
//  JubileeMobileBay
//
//  Created by Assistant on 1/23/25.
//

import Foundation
import CoreData
import CloudKit
import Combine

/// Protocol for chat service operations
protocol ChatServiceProtocol {
    func sendMessage(text: String, roomId: String) async throws -> MessageEntity
    func fetchMessages(for roomId: String, limit: Int) -> [MessageEntity]
    func subscribeToRoom(_ roomId: String) async throws
    func unsubscribeFromRoom(_ roomId: String) async throws
    func createOrJoinRoom(id: String, name: String) async throws -> ChatRoomEntity
}

/// Service that manages chat functionality with offline-first support
@MainActor
class ChatService: ObservableObject, ChatServiceProtocol {
    
    // MARK: - Properties
    @Published var messages: [String: [MessageEntity]] = [:] // roomId -> messages
    @Published var rooms: [ChatRoomEntity] = []
    @Published var isSending = false
    @Published var error: Error?
    
    private let coreDataStack: CoreDataStack
    private let cloudKitSyncService: CloudKitSyncServiceProtocol
    private let userSession: UserSessionManager
    
    private var subscriptions: Set<String> = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(coreDataStack: CoreDataStack = .shared,
         cloudKitSyncService: CloudKitSyncServiceProtocol,
         userSession: UserSessionManager = .shared) {
        self.coreDataStack = coreDataStack
        self.cloudKitSyncService = cloudKitSyncService
        self.userSession = userSession
        
        setupNotifications()
        loadRooms()
    }
    
    // MARK: - Public Methods
    
    /// Send a message with offline-first support
    func sendMessage(text: String, roomId: String) async throws -> MessageEntity {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ChatError.emptyMessage
        }
        
        guard let currentUser = userSession.currentUser else {
            throw ChatError.notAuthenticated
        }
        
        isSending = true
        defer { isSending = false }
        
        // 1. Save to Core Data immediately (optimistic UI)
        let message = await coreDataStack.performBackgroundTask { context in
            let newMessage = MessageEntity(context: context)
            newMessage.id = UUID()
            newMessage.text = text
            newMessage.timestamp = Date()
            newMessage.roomId = roomId
            newMessage.userId = currentUser.id
            newMessage.userName = currentUser.displayName
            newMessage.isDeleted = false
            newMessage.lastModified = Date()
            newMessage.syncStatusEnum = .pending
            
            do {
                try context.save()
                return newMessage
            } catch {
                print("Failed to save message: \(error)")
                throw ChatError.saveFailed(error)
            }
        }
        
        // 2. Update UI immediately
        await MainActor.run {
            if messages[roomId] == nil {
                messages[roomId] = []
            }
            messages[roomId]?.insert(message, at: 0)
            
            // Update room's last message time
            if let room = rooms.first(where: { $0.id == roomId }) {
                room.lastMessageAt = Date()
            }
        }
        
        // 3. Trigger sync to CloudKit (fire and forget)
        Task {
            do {
                try await cloudKitSyncService.syncPendingChanges()
            } catch {
                print("Sync failed, will retry later: \(error)")
                // Message is saved locally, will sync when network available
            }
        }
        
        return message
    }
    
    /// Fetch messages for a room from Core Data
    func fetchMessages(for roomId: String, limit: Int = 50) -> [MessageEntity] {
        let fetchedMessages = coreDataStack.fetchMessages(for: roomId, limit: limit)
        
        // Update cache
        messages[roomId] = fetchedMessages
        
        return fetchedMessages
    }
    
    /// Subscribe to real-time updates for a room
    func subscribeToRoom(_ roomId: String) async throws {
        guard !subscriptions.contains(roomId) else { return }
        
        try await cloudKitSyncService.setupSubscriptions(for: roomId)
        subscriptions.insert(roomId)
        
        // Fetch latest messages
        _ = fetchMessages(for: roomId)
        
        // Sync any messages we might have missed
        Task {
            do {
                let latestMessages = try await cloudKitSyncService.fetchLatestMessages(
                    for: roomId,
                    since: messages[roomId]?.first?.timestamp
                )
                
                await MainActor.run {
                    // Merge new messages
                    if !latestMessages.isEmpty {
                        messages[roomId] = fetchMessages(for: roomId)
                    }
                }
            } catch {
                print("Failed to fetch latest messages: \(error)")
            }
        }
    }
    
    /// Unsubscribe from a room
    func unsubscribeFromRoom(_ roomId: String) async throws {
        subscriptions.remove(roomId)
        messages[roomId] = nil
    }
    
    /// Create or join a chat room
    func createOrJoinRoom(id: String, name: String) async throws -> ChatRoomEntity {
        let room = coreDataStack.fetchOrCreateChatRoom(id: id, name: name)
        
        // Ensure room is in our list
        if !rooms.contains(where: { $0.id == id }) {
            rooms.append(room)
        }
        
        // Subscribe to updates
        try await subscribeToRoom(id)
        
        // Trigger sync
        Task {
            try? await cloudKitSyncService.syncPendingChanges()
        }
        
        return room
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        // Listen for Core Data changes
        NotificationCenter.default.publisher(for: .coreDataDidReceiveRemoteChanges)
            .sink { [weak self] notification in
                self?.handleRemoteChanges(notification)
            }
            .store(in: &cancellables)
        
        // Listen for CloudKit notifications
        NotificationCenter.default.publisher(for: .cloudKitNotificationReceived)
            .sink { [weak self] notification in
                self?.handleCloudKitNotification(notification)
            }
            .store(in: &cancellables)
    }
    
    private func loadRooms() {
        let request = ChatRoomEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastMessageAt", ascending: false)]
        
        do {
            rooms = try coreDataStack.viewContext.fetch(request)
        } catch {
            print("Failed to load rooms: \(error)")
            self.error = error
        }
    }
    
    private func handleRemoteChanges(_ notification: Notification) {
        // Refresh messages for active rooms
        for roomId in subscriptions {
            _ = fetchMessages(for: roomId)
        }
        
        // Reload rooms
        loadRooms()
    }
    
    private func handleCloudKitNotification(_ notification: Notification) {
        // Handle real-time updates from CloudKit
        // The sync service will have already updated Core Data
        // We just need to refresh our UI
        
        DispatchQueue.main.async { [weak self] in
            self?.handleRemoteChanges(notification)
        }
    }
    
    // MARK: - Gamification
    
    /// Award points for chat activity
    func awardPoints(for action: ChatAction) async {
        guard let currentUser = userSession.currentUser else { return }
        
        let points: Int32
        switch action {
        case .sentMessage:
            points = 1
        case .helpfulMessage: // Message got 5+ likes
            points = 10
        case .dailyActive:
            points = 5
        case .weeklyStreak:
            points = 25
        }
        
        // Update user profile
        await coreDataStack.performBackgroundTask { context in
            let request = UserProfileEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", currentUser.id)
            request.fetchLimit = 1
            
            if let profile = try? context.fetch(request).first {
                profile.points += points
                profile.syncStatusEnum = .pending
                try? context.save()
            }
        }
    }
}

// MARK: - Chat Errors
enum ChatError: LocalizedError {
    case emptyMessage
    case notAuthenticated
    case roomNotFound
    case saveFailed(Error)
    case syncFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .emptyMessage:
            return "Message cannot be empty"
        case .notAuthenticated:
            return "You must be logged in to send messages"
        case .roomNotFound:
            return "Chat room not found"
        case .saveFailed(let error):
            return "Failed to save message: \(error.localizedDescription)"
        case .syncFailed(let error):
            return "Failed to sync: \(error.localizedDescription)"
        }
    }
}

// MARK: - Chat Actions
enum ChatAction {
    case sentMessage
    case helpfulMessage
    case dailyActive
    case weeklyStreak
}