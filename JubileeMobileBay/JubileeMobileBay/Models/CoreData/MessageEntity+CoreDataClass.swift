//
//  MessageEntity+CoreDataClass.swift
//  JubileeMobileBay
//
//  Created by Assistant on 1/23/25.
//

import Foundation
import CoreData
import CloudKit

@objc(MessageEntity)
public class MessageEntity: NSManagedObject {
    
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
        let record = CKRecord(recordType: "Message", recordID: recordID)
        
        record["id"] = id?.uuidString ?? UUID().uuidString
        record["text"] = text
        record["timestamp"] = timestamp
        record["roomId"] = roomId
        record["userId"] = userId
        record["userName"] = userName
        record["isDeleted"] = isDeleted
        record["lastModified"] = lastModified
        
        return record
    }
    
    static func fromCloudKitRecord(_ record: CKRecord, context: NSManagedObjectContext) -> MessageEntity {
        let entity = MessageEntity(context: context)
        
        entity.cloudKitRecordID = record.recordID.recordName
        entity.id = (record["id"] as? String).flatMap { UUID(uuidString: $0) } ?? UUID()
        entity.text = record["text"] as? String ?? ""
        entity.timestamp = record["timestamp"] as? Date ?? Date()
        entity.roomId = record["roomId"] as? String ?? ""
        entity.userId = record["userId"] as? String ?? ""
        entity.userName = record["userName"] as? String
        entity.isDeleted = record["isDeleted"] as? Bool ?? false
        entity.lastModified = record["lastModified"] as? Date ?? Date()
        entity.syncStatusEnum = .synced
        
        return entity
    }
}