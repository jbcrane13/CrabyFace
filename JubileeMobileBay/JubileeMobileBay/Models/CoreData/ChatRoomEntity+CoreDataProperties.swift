//
//  ChatRoomEntity+CoreDataProperties.swift
//  JubileeMobileBay
//
//  Created by Assistant on 1/23/25.
//

import Foundation
import CoreData

extension ChatRoomEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatRoomEntity> {
        return NSFetchRequest<ChatRoomEntity>(entityName: "ChatRoomEntity")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastMessageAt: Date?
    @NSManaged public var unreadCount: Int32
    @NSManaged public var syncStatus: Int16
    @NSManaged public var cloudKitRecordID: String?
}