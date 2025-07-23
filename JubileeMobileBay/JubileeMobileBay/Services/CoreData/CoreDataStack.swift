//
//  CoreDataStack.swift
//  JubileeMobileBay
//
//  Created by Assistant on 1/23/25.
//

import Foundation
import CoreData
import CloudKit

/// Core Data stack with CloudKit integration for offline-first sync
class CoreDataStack {
    
    // MARK: - Singleton
    static let shared = CoreDataStack()
    
    // MARK: - Properties
    private let modelName = "JubileeMobileBay"
    
    /// The main persistent container with CloudKit support
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: modelName)
        
        // Configure for CloudKit sync
        container.persistentStoreDescriptions.forEach { storeDescription in
            // Enable persistent history tracking
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            
            // Enable remote change notifications
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // CloudKit container identifier
            storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.jubileemobilebay.app"
            )
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Core Data failed to load: \(error), \(error.userInfo)")
                fatalError("Core Data failed to load: \(error)")
            }
            
            print("Core Data loaded successfully")
            print("Store URL: \(storeDescription.url?.absoluteString ?? "unknown")")
            print("CloudKit enabled: \(storeDescription.cloudKitContainerOptions != nil)")
        }
        
        // Configure for automatic merging of CloudKit changes
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    /// The main managed object context
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Initialization
    private init() {
        setupNotifications()
    }
    
    // MARK: - Core Data Operations
    
    /// Save the context if there are changes
    func save() {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save Core Data context: \(error)")
        }
    }
    
    /// Create a background context for heavy operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    /// Perform a background task
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
    
    // MARK: - CloudKit Sync Management
    
    /// Force a sync with CloudKit
    func forceSyncWithCloudKit() {
        // Trigger a manual sync by saving the context
        save()
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .coreDataDidSyncWithCloudKit,
            object: nil
        )
    }
    
    /// Check if CloudKit sync is available
    var isCloudKitSyncAvailable: Bool {
        CKContainer.default().accountStatus { status, error in
            if let error = error {
                print("CloudKit account status error: \(error)")
            }
        }
        return true // Simplified for now
    }
    
    // MARK: - Fetch Helpers
    
    /// Fetch all pending messages that need sync
    func fetchPendingMessages() -> [MessageEntity] {
        let request = MessageEntity.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus == %d", MessageEntity.SyncStatus.pending.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch pending messages: \(error)")
            return []
        }
    }
    
    /// Fetch messages for a specific room
    func fetchMessages(for roomId: String, limit: Int = 50) -> [MessageEntity] {
        let request = MessageEntity.fetchRequest()
        request.predicate = NSPredicate(format: "roomId == %@ AND isDeleted == NO", roomId)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch messages: \(error)")
            return []
        }
    }
    
    /// Fetch or create a chat room
    func fetchOrCreateChatRoom(id: String, name: String) -> ChatRoomEntity {
        let request = ChatRoomEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        do {
            if let existingRoom = try viewContext.fetch(request).first {
                return existingRoom
            }
        } catch {
            print("Failed to fetch chat room: \(error)")
        }
        
        // Create new room
        let newRoom = ChatRoomEntity(context: viewContext)
        newRoom.id = id
        newRoom.name = name
        newRoom.createdAt = Date()
        newRoom.syncStatusEnum = .pending
        
        save()
        return newRoom
    }
    
    /// Fetch user profile
    func fetchUserProfile(id: String) -> UserProfileEntity? {
        let request = UserProfileEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Failed to fetch user profile: \(error)")
            return nil
        }
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        // Listen for CloudKit remote changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteStoreChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: persistentContainer.persistentStoreCoordinator
        )
    }
    
    @objc private func handleRemoteStoreChange(_ notification: Notification) {
        print("Received remote store change notification")
        
        // Post notification for UI updates
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .coreDataDidReceiveRemoteChanges,
                object: nil,
                userInfo: notification.userInfo
            )
        }
    }
    
    // MARK: - Migration Support
    
    /// Check if migration is needed
    var needsMigration: Bool {
        // Simplified check - in production, compare model versions
        return false
    }
    
    /// Perform lightweight migration if needed
    func performMigrationIfNeeded() {
        guard needsMigration else { return }
        
        // Migration logic would go here
        print("Performing Core Data migration...")
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let coreDataDidSyncWithCloudKit = Notification.Name("coreDataDidSyncWithCloudKit")
    static let coreDataDidReceiveRemoteChanges = Notification.Name("coreDataDidReceiveRemoteChanges")
}