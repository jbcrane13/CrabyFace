//
//  JubileeReport+CoreDataProperties.swift
//  JubileeMobileBay
//
//  NSManagedObject properties for JubileeReport entity
//

import Foundation
import CoreData

extension JubileeReport {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<JubileeReport> {
        return NSFetchRequest<JubileeReport>(entityName: "JubileeReport")
    }
    
    // Core Attributes
    @NSManaged public var uuid: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var latitude: NSNumber?
    @NSManaged public var longitude: NSNumber?
    @NSManaged public var species: Data? // JSON encoded array
    @NSManaged public var intensity: String?
    @NSManaged public var environmentalConditions: Data? // JSON encoded dictionary
    
    // Sync-related Attributes
    @NSManaged public var syncStatus: String?
    @NSManaged public var lastModified: Date?
    @NSManaged public var conflictResolutionNeeded: Bool
    @NSManaged public var recordID: String? // CloudKit record ID
    @NSManaged public var changeTag: String? // For optimistic concurrency
    
    // User and metadata
    @NSManaged public var userID: String?
    @NSManaged public var notes: String?
    @NSManaged public var imageURLs: Data? // JSON encoded array of URLs
    @NSManaged public var verificationStatus: String?
    
    // Analytics metadata
    @NSManaged public var temperature: NSNumber?
    @NSManaged public var salinity: NSNumber?
    @NSManaged public var dissolvedOxygen: NSNumber?
    @NSManaged public var windSpeed: NSNumber?
    @NSManaged public var windDirection: NSNumber?
    @NSManaged public var barometricPressure: NSNumber?
    @NSManaged public var tideLevel: NSNumber?
}

// MARK: - Fetch Request Helpers

extension JubileeReport {
    
    static func fetchRequestForSync() -> NSFetchRequest<JubileeReport> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus != %@", SyncStatus.synced.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: true)]
        return request
    }
    
    static func fetchRequestForConflicts() -> NSFetchRequest<JubileeReport> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "conflictResolutionNeeded == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return request
    }
    
    static func fetchRequestForDateRange(from startDate: Date, to endDate: Date) -> NSFetchRequest<JubileeReport> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return request
    }
}

// MARK: - Core Data Generated Accessors for Relationships (if needed in future)

extension JubileeReport {
    // Add relationship accessors here when relationships are added to the model
}