//
//  ChatRoomEntity+CoreDataClass.swift
//  JubileeMobileBay
//
//  Created by Assistant on 1/23/25.
//

import Foundation
import CoreData
import CloudKit

@objc(ChatRoomEntity)
public class ChatRoomEntity: NSManagedObject {
    
    // MARK: - Sync Status
    enum SyncStatus: Int16 {
        case pending = 0
        case synced = 1
        case failed = 2
    }
    
    var syncStatusEnum: SyncStatus {
        get { SyncStatus(rawValue: syncStatus) ?? .pending }
        set { syncStatus = newValue.rawValue }
    }
    
    // MARK: - CloudKit Conversion
    func toCloudKitRecord() -> CKRecord {
        let recordID = cloudKitRecordID.flatMap { CKRecord.ID(recordName: $0) } ?? CKRecord.ID()
        let record = CKRecord(recordType: "ChatRoom", recordID: recordID)
        
        record["id"] = id
        record["name"] = name
        record["createdAt"] = createdAt
        record["lastMessageAt"] = lastMessageAt
        record["unreadCount"] = unreadCount
        
        return record
    }
    
    static func fromCloudKitRecord(_ record: CKRecord, context: NSManagedObjectContext) -> ChatRoomEntity {
        let entity = ChatRoomEntity(context: context)
        
        entity.cloudKitRecordID = record.recordID.recordName
        entity.id = record["id"] as? String ?? ""
        entity.name = record["name"] as? String ?? ""
        entity.createdAt = record["createdAt"] as? Date ?? Date()
        entity.lastMessageAt = record["lastMessageAt"] as? Date
        entity.unreadCount = record["unreadCount"] as? Int32 ?? 0
        entity.syncStatusEnum = .synced
        
        return entity
    }
}