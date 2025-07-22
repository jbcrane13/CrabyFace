//
//  SyncableEntity.swift
//  JubileeMobileBay
//
//  Protocol for entities that support synchronization
//

import Foundation
import CoreData
import CloudKit

protocol SyncableEntity: NSManagedObject {
    var uuid: String? { get set }
    var syncStatus: String? { get set }
    var lastModified: Date? { get set }
    var conflictResolutionNeeded: Bool { get set }
    var recordID: String? { get set }
    var changeTag: String? { get set }
    
    func toCKRecord() -> CKRecord
    func updateFromCKRecord(_ record: CKRecord)
    func markForSync()
    func markAsConflict()
    func resolveConflict()
}

// MARK: - Sync Result

struct SyncResult {
    let uploaded: Int
    let downloaded: Int
    let conflicts: Int
    let errors: [Error]
    
    var hasErrors: Bool {
        return !errors.isEmpty
    }
    
    var hasConflicts: Bool {
        return conflicts > 0
    }
}

// MARK: - Conflict Resolution

enum ConflictResolution {
    case useLocal
    case useRemote
    case merge(merged: NSManagedObject)
    case manual
}

// MARK: - Sync Error

enum SyncError: LocalizedError {
    case networkUnavailable
    case authenticationRequired
    case quotaExceeded
    case serverError(String)
    case dataCorruption
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network connection is unavailable"
        case .authenticationRequired:
            return "iCloud authentication is required"
        case .quotaExceeded:
            return "iCloud storage quota exceeded"
        case .serverError(let message):
            return "Server error: \(message)"
        case .dataCorruption:
            return "Data corruption detected during sync"
        case .unknown(let error):
            return "Unknown sync error: \(error.localizedDescription)"
        }
    }
}