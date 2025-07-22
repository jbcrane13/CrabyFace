//
//  CoreDataMigrationManager.swift
//  JubileeMobileBay
//
//  Manages Core Data migrations and schema updates
//

import Foundation
import CoreData

class CoreDataMigrationManager {
    
    static func performMigrationsIfNeeded(for container: NSPersistentCloudKitContainer) {
        // Check if this is the first launch with Core Data
        let userDefaults = UserDefaults.standard
        let hasPerformedInitialSetup = userDefaults.bool(forKey: "HasPerformedCoreDataInitialSetup")
        
        if !hasPerformedInitialSetup {
            performInitialSetup(for: container)
            userDefaults.set(true, forKey: "HasPerformedCoreDataInitialSetup")
        }
    }
    
    private static func performInitialSetup(for container: NSPersistentCloudKitContainer) {
        let context = container.viewContext
        
        // Set initial sync status for any existing data
        let fetchRequest = JubileeReport.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "syncStatus == nil")
        
        do {
            let reports = try context.fetch(fetchRequest)
            for report in reports {
                report.syncStatusEnum = .synced
                report.lastModified = Date()
                
                // Generate UUID if missing
                if report.uuid == nil {
                    report.uuid = UUID().uuidString
                }
            }
            
            if context.hasChanges {
                try context.save()
            }
        } catch {
            print("Error performing initial setup: \(error)")
        }
    }
    
    // MARK: - Lightweight Migration Support
    
    static func configureLightweightMigration(for storeDescription: NSPersistentStoreDescription) {
        storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
    }
}