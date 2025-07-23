//
//  UserProfileEntity+CoreDataProperties.swift
//  JubileeMobileBay
//
//  Created by Assistant on 1/23/25.
//

import Foundation
import CoreData

extension UserProfileEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfileEntity> {
        return NSFetchRequest<UserProfileEntity>(entityName: "UserProfileEntity")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var displayName: String?
    @NSManaged public var points: Int32
    @NSManaged public var joinedAt: Date?
    @NSManaged public var badges: NSObject?
    @NSManaged public var syncStatus: Int16
    @NSManaged public var cloudKitRecordID: String?
}