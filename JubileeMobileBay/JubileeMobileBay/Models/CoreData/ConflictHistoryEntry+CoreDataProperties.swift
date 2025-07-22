//
//  ConflictHistoryEntry+CoreDataProperties.swift
//  JubileeMobileBay
//
//  Properties extension for ConflictHistoryEntry
//

import Foundation
import CoreData

extension ConflictHistoryEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConflictHistoryEntry> {
        return NSFetchRequest<ConflictHistoryEntry>(entityName: "ConflictHistoryEntry")
    }

    @NSManaged public var uuid: String?
    @NSManaged public var entityUUID: String?
    @NSManaged public var occurredAt: Date?
    @NSManaged public var resolvedAt: Date?
    @NSManaged public var resolutionStrategy: String?
    @NSManaged public var resolutionType: String?
    @NSManaged public var localVersion: Data?
    @NSManaged public var remoteVersion: Data?
    @NSManaged public var mergedVersion: Data?
    @NSManaged public var notes: String?
    
    // MARK: - Computed Properties
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        uuid = UUID().uuidString
        occurredAt = Date()
    }
    
    // MARK: - Fetch Requests
    
    @nonobjc public class func fetchRequestForEntity(_ entityUUID: String) -> NSFetchRequest<ConflictHistoryEntry> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "entityUUID == %@", entityUUID)
        request.sortDescriptors = [NSSortDescriptor(key: "occurredAt", ascending: false)]
        return request
    }
    
    @nonobjc public class func fetchRequestForUnresolved() -> NSFetchRequest<ConflictHistoryEntry> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "resolvedAt == NULL")
        request.sortDescriptors = [NSSortDescriptor(key: "occurredAt", ascending: false)]
        return request
    }
    
    @nonobjc public class func fetchRequestForStrategy(_ strategy: ConflictResolutionStrategy) -> NSFetchRequest<ConflictHistoryEntry> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "resolutionStrategy == %@", strategy.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "occurredAt", ascending: false)]
        return request
    }
}