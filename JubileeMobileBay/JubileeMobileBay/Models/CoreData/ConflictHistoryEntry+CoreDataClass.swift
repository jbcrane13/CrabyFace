//
//  ConflictHistoryEntry+CoreDataClass.swift
//  JubileeMobileBay
//
//  NSManagedObject subclass for ConflictHistoryEntry entity
//

import Foundation
import CoreData

@objc(ConflictHistoryEntry)
public class ConflictHistoryEntry: NSManagedObject {
    
    // MARK: - Computed Properties
    
    var resolutionStrategyEnum: ConflictResolutionStrategy {
        get {
            return ConflictResolutionStrategy(rawValue: resolutionStrategy ?? "") ?? .mostRecent
        }
        set {
            resolutionStrategy = newValue.rawValue
        }
    }
    
    var isResolved: Bool {
        return resolvedAt != nil
    }
    
    var resolutionDuration: TimeInterval? {
        guard let occurred = occurredAt,
              let resolved = resolvedAt else { return nil }
        return resolved.timeIntervalSince(occurred)
    }
    
    // MARK: - Helper Methods
    
    func markAsResolved(with strategy: ConflictResolutionStrategy, type: String) {
        resolvedAt = Date()
        resolutionStrategyEnum = strategy
        resolutionType = type
    }
}