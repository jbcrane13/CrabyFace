//
//  MessageEntity+CoreDataProperties.swift
//  JubileeMobileBay
//
//  Created by Assistant on 1/23/25.
//

import Foundation
import CoreData

extension MessageEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MessageEntity> {
        return NSFetchRequest<MessageEntity>(entityName: "MessageEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var text: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var roomId: String?
    @NSManaged public var userId: String?
    @NSManaged public var userName: String?
    @NSManaged public var syncStatus: Int16
    @NSManaged public var cloudKitRecordID: String?
    @NSManaged public var lastModified: Date?
    @NSManaged public var isDeleted: Bool
}