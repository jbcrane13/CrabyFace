//
//  MessageEntity+SyncableEntity.swift
//  JubileeMobileBay
//
//  Created by Assistant on 1/23/25.
//

import Foundation
import CoreData
import CloudKit

extension MessageEntity: SyncableEntity {
    
    var uuid: String? {
        get { id?.uuidString }
        set { 
            if let uuidString = newValue {
                id = UUID(uuidString: uuidString)
            }
        }
    }
    
    var syncStatus: String? {
        get { SyncStatus(rawValue: syncStatus)?.rawValue }
        set {
            if let status = newValue,
               let syncStatusEnum = SyncStatus(rawValue: Int16(status) ?? 0) {
                self.syncStatus = syncStatusEnum.rawValue
            }
        }
    }
    
    var recordID: String? {
        get { cloudKitRecordID }
        set { cloudKitRecordID = newValue }
    }
    
    var changeTag: String? {
        get { nil } // Messages don't track change tags
        set { } // No-op
    }
    
    var conflictResolutionNeeded: Bool {
        get { false } // Messages use last-write-wins
        set { } // No-op
    }
    
    func toCKRecord() -> CKRecord {
        toCloudKitRecord()
    }
    
    func updateFromCKRecord(_ record: CKRecord) {
        cloudKitRecordID = record.recordID.recordName
        id = (record["id"] as? String).flatMap { UUID(uuidString: $0) } ?? id
        text = record["text"] as? String ?? text
        timestamp = record["timestamp"] as? Date ?? timestamp
        roomId = record["roomId"] as? String ?? roomId
        userId = record["userId"] as? String ?? userId
        userName = record["userName"] as? String
        isDeleted = record["isDeleted"] as? Bool ?? isDeleted
        lastModified = record["lastModified"] as? Date ?? lastModified
        syncStatusEnum = .synced
    }
    
    func markForSync() {
        syncStatusEnum = .pending
        lastModified = Date()
    }
    
    func markAsConflict() {
        // Messages don't have conflicts - last write wins
    }
    
    func resolveConflict() {
        // Messages don't have conflicts - last write wins
    }
}

// MARK: - Fetch Requests
extension MessageEntity {
    
    static func fetchRequestForSync() -> NSFetchRequest<MessageEntity> {
        let request = NSFetchRequest<MessageEntity>(entityName: "MessageEntity")
        request.predicate = NSPredicate(format: "syncStatus == %d", SyncStatus.pending.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return request
    }
    
    static func fetchRequestForRoom(_ roomId: String) -> NSFetchRequest<MessageEntity> {
        let request = NSFetchRequest<MessageEntity>(entityName: "MessageEntity")
        request.predicate = NSPredicate(format: "roomId == %@ AND isDeleted == NO", roomId)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return request
    }
}

// MARK: - SyncStatus Extension
private extension MessageEntity {
    enum SyncStatus: Int16 {
        case pending = 0
        case synced = 1
        case failed = 2
        
        var rawValue: String {
            switch self {
            case .pending: return "pending"
            case .synced: return "synced"
            case .failed: return "failed"
            }
        }
        
        init?(rawValue: String) {
            switch rawValue {
            case "pending": self = .pending
            case "synced": self = .synced
            case "failed": self = .failed
            default: return nil
            }
        }
    }
}