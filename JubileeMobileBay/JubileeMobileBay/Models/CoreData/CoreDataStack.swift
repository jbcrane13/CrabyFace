//
//  CoreDataStack.swift
//  JubileeMobileBay
//
//  Core Data stack with CloudKit integration for offline sync
//

import Foundation
import CoreData
import CloudKit

class CoreDataStack {
    static let shared = CoreDataStack()
    
    private init() {}
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        // Use programmatic model
        let model = CoreDataModelBuilder.createModel()
        let container = NSPersistentCloudKitContainer(name: "JubileeMobileBay", managedObjectModel: model)
        
        // Configure for CloudKit sync
        let storeDescription = container.persistentStoreDescriptions.first!
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Set CloudKit container options
        storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.jubileemobilebay.app"
        )
        
        // Configure merge policy
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // Log the error for debugging
                print("❌ Failed to load Core Data store: \(error), \(error.userInfo)")
                
                // In production, we should attempt recovery or use in-memory store
                // For now, we'll create an in-memory store as fallback
                let inMemoryDescription = NSPersistentStoreDescription()
                inMemoryDescription.type = NSInMemoryStoreType
                container.persistentStoreDescriptions = [inMemoryDescription]
                
                // Try loading in-memory store
                container.loadPersistentStores { (_, inMemoryError) in
                    if let inMemoryError = inMemoryError {
                        print("❌ Critical: Failed to load in-memory store: \(inMemoryError)")
                        // Post notification for UI to handle
                        NotificationCenter.default.post(
                            name: NSNotification.Name("CoreDataFailedToLoad"),
                            object: nil,
                            userInfo: ["error": error]
                        )
                    } else {
                        print("⚠️ Using in-memory Core Data store as fallback")
                    }
                }
            }
        }
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Core Data Saving support
    
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Background Context
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Batch Operations
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
}

// MARK: - Sync Status Enum

enum SyncStatus: String, CaseIterable {
    case synced = "synced"
    case pendingUpload = "pendingUpload"
    case pendingDownload = "pendingDownload"
    case conflict = "conflict"
    case error = "error"
}