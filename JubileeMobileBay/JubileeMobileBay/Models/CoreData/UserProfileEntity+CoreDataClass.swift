//
//  UserProfileEntity+CoreDataClass.swift
//  JubileeMobileBay
//
//  Created by Assistant on 1/23/25.
//

import Foundation
import CoreData
import CloudKit

@objc(UserProfileEntity)
public class UserProfileEntity: NSManagedObject {
    
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
        let record = CKRecord(recordType: "UserProfile", recordID: recordID)
        
        record["id"] = id
        record["displayName"] = displayName
        record["points"] = points
        record["joinedAt"] = joinedAt
        
        // Convert badges array to JSON string for CloudKit storage
        if let badgesArray = badges as? [String], !badgesArray.isEmpty {
            let badgesData = try? JSONSerialization.data(withJSONObject: badgesArray)
            record["badges"] = badgesData?.base64EncodedString()
        }
        
        return record
    }
    
    static func fromCloudKitRecord(_ record: CKRecord, context: NSManagedObjectContext) -> UserProfileEntity {
        let entity = UserProfileEntity(context: context)
        
        entity.cloudKitRecordID = record.recordID.recordName
        entity.id = record["id"] as? String ?? ""
        entity.displayName = record["displayName"] as? String ?? ""
        entity.points = record["points"] as? Int32 ?? 0
        entity.joinedAt = record["joinedAt"] as? Date ?? Date()
        
        // Convert badges from JSON string back to array
        if let badgesString = record["badges"] as? String,
           let badgesData = Data(base64Encoded: badgesString),
           let badgesArray = try? JSONSerialization.jsonObject(with: badgesData) as? [String] {
            entity.badges = badgesArray as NSObject
        }
        
        entity.syncStatusEnum = .synced
        
        return entity
    }
}