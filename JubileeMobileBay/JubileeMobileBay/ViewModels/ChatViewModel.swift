//
//  ChatViewModel.swift
//  JubileeMobileBay
//
//  Created by Assistant on 1/23/25.
//

import Foundation
import SwiftUI
import Combine
import CoreData

@MainActor
class ChatViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var messages: [MessageEntity] = []
    @Published var newMessageText = ""
    @Published var isSending = false
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    
    // Room information
    let roomId: String
    let roomName: String
    
    // MARK: - Private Properties
    private let chatService: ChatServiceProtocol
    private let userSession: UserSessionManager
    private var cancellables = Set<AnyCancellable>()
    
    // Pagination
    private var hasMoreMessages = true
    private let pageSize = 50
    
    // MARK: - Initialization
    init(roomId: String,
         roomName: String,
         chatService: ChatServiceProtocol,
         userSession: UserSessionManager = .shared) {
        self.roomId = roomId
        self.roomName = roomName
        self.chatService = chatService
        self.userSession = userSession
        
        setupBindings()
        loadInitialData()
    }
    
    deinit {
        // Unsubscribe when leaving room
        Task {
            try? await chatService.unsubscribeFromRoom(roomId)
        }
    }
    
    // MARK: - Public Methods
    
    /// Send a new message
    func sendMessage() {
        guard !newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let messageText = newMessageText
        newMessageText = "" // Clear immediately for better UX
        
        Task {
            do {
                isSending = true
                let message = try await chatService.sendMessage(text: messageText, roomId: roomId)
                
                // Message will appear via Core Data notification
                // Award points for activity
                if let chatService = chatService as? ChatService {
                    await chatService.awardPoints(for: .sentMessage)
                }
                
                isSending = false
            } catch {
                isSending = false
                self.error = error
                showError = true
                
                // Restore message text on error
                newMessageText = messageText
            }
        }
    }
    
    /// Load more messages (pagination)
    func loadMoreMessages() {
        guard hasMoreMessages, !isLoading else { return }
        
        let currentCount = messages.count
        let newMessages = chatService.fetchMessages(for: roomId, limit: currentCount + pageSize)
        
        if newMessages.count <= currentCount {
            hasMoreMessages = false
        } else {
            messages = newMessages
        }
    }
    
    /// Refresh messages
    func refresh() async {
        isLoading = true
        
        do {
            // Force sync with CloudKit
            if let syncService = chatService as? ChatService {
                _ = try? await syncService.cloudKitSyncService.syncPendingChanges()
            }
            
            // Reload messages
            messages = chatService.fetchMessages(for: roomId, limit: pageSize)
            hasMoreMessages = true
            
        } catch {
            self.error = error
            showError = true
        }
        
        isLoading = false
    }
    
    /// Delete a message (soft delete)
    func deleteMessage(_ message: MessageEntity) {
        guard message.userId == userSession.currentUser?.id else { return }
        
        Task {
            await CoreDataStack.shared.performBackgroundTask { context in
                guard let messageInContext = try? context.existingObject(with: message.objectID) as? MessageEntity else { return }
                
                messageInContext.isDeleted = true
                messageInContext.lastModified = Date()
                messageInContext.syncStatusEnum = .pending
                
                try? context.save()
            }
            
            // Trigger sync
            if let syncService = chatService as? ChatService {
                _ = try? await syncService.cloudKitSyncService.syncPendingChanges()
            }
            
            // Refresh UI
            messages = chatService.fetchMessages(for: roomId, limit: messages.count)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Listen for message updates
        if let chatService = chatService as? ChatService {
            chatService.$messages
                .compactMap { $0[self.roomId] }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] updatedMessages in
                    self?.messages = updatedMessages
                }
                .store(in: &cancellables)
            
            // Listen for errors
            chatService.$error
                .compactMap { $0 }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] error in
                    self?.error = error
                    self?.showError = true
                }
                .store(in: &cancellables)
        }
        
        // Listen for remote changes
        NotificationCenter.default.publisher(for: .coreDataDidReceiveRemoteChanges)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.messages = self.chatService.fetchMessages(for: self.roomId, limit: self.messages.count)
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        Task {
            isLoading = true
            
            do {
                // Subscribe to room for real-time updates
                try await chatService.subscribeToRoom(roomId)
                
                // Load initial messages
                messages = chatService.fetchMessages(for: roomId, limit: pageSize)
                
            } catch {
                self.error = error
                showError = true
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Computed Properties
    
    var canSendMessage: Bool {
        !newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isSending &&
        userSession.isAuthenticated
    }
    
    var sortedMessages: [MessageEntity] {
        // Messages are already sorted by timestamp descending from fetch
        messages
    }
    
    // MARK: - Helper Methods
    
    func formattedTimestamp(for message: MessageEntity) -> String {
        guard let timestamp = message.timestamp else { return "" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    func isCurrentUser(_ message: MessageEntity) -> Bool {
        message.userId == userSession.currentUser?.id
    }
}