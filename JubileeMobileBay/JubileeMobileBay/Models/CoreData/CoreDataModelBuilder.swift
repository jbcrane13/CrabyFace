//
//  CoreDataModelBuilder.swift
//  JubileeMobileBay
//
//  Programmatic Core Data model creation for CloudKit sync
//

import Foundation
import CoreData

class CoreDataModelBuilder {
    
    static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // Create JubileeReport entity
        let jubileeReportEntity = NSEntityDescription()
        jubileeReportEntity.name = "JubileeReport"
        jubileeReportEntity.managedObjectClassName = "JubileeReport"
        
        // Core Attributes
        var properties: [NSPropertyDescription] = []
        
        // UUID
        let uuidAttribute = NSAttributeDescription()
        uuidAttribute.name = "uuid"
        uuidAttribute.attributeType = .stringAttributeType
        uuidAttribute.isOptional = true
        properties.append(uuidAttribute)
        
        // Timestamp
        let timestampAttribute = NSAttributeDescription()
        timestampAttribute.name = "timestamp"
        timestampAttribute.attributeType = .dateAttributeType
        timestampAttribute.isOptional = true
        properties.append(timestampAttribute)
        
        // Location attributes
        let latitudeAttribute = NSAttributeDescription()
        latitudeAttribute.name = "latitude"
        latitudeAttribute.attributeType = .doubleAttributeType
        latitudeAttribute.isOptional = true
        properties.append(latitudeAttribute)
        
        let longitudeAttribute = NSAttributeDescription()
        longitudeAttribute.name = "longitude"
        longitudeAttribute.attributeType = .doubleAttributeType
        longitudeAttribute.isOptional = true
        properties.append(longitudeAttribute)
        
        // Species (JSON encoded)
        let speciesAttribute = NSAttributeDescription()
        speciesAttribute.name = "species"
        speciesAttribute.attributeType = .binaryDataAttributeType
        speciesAttribute.isOptional = true
        properties.append(speciesAttribute)
        
        // Intensity
        let intensityAttribute = NSAttributeDescription()
        intensityAttribute.name = "intensity"
        intensityAttribute.attributeType = .stringAttributeType
        intensityAttribute.isOptional = true
        properties.append(intensityAttribute)
        
        // Environmental Conditions (JSON encoded)
        let environmentalConditionsAttribute = NSAttributeDescription()
        environmentalConditionsAttribute.name = "environmentalConditions"
        environmentalConditionsAttribute.attributeType = .binaryDataAttributeType
        environmentalConditionsAttribute.isOptional = true
        properties.append(environmentalConditionsAttribute)
        
        // Sync-related Attributes
        let syncStatusAttribute = NSAttributeDescription()
        syncStatusAttribute.name = "syncStatus"
        syncStatusAttribute.attributeType = .stringAttributeType
        syncStatusAttribute.defaultValue = "synced"
        syncStatusAttribute.isOptional = true
        properties.append(syncStatusAttribute)
        
        let lastModifiedAttribute = NSAttributeDescription()
        lastModifiedAttribute.name = "lastModified"
        lastModifiedAttribute.attributeType = .dateAttributeType
        lastModifiedAttribute.isOptional = true
        properties.append(lastModifiedAttribute)
        
        let conflictResolutionNeededAttribute = NSAttributeDescription()
        conflictResolutionNeededAttribute.name = "conflictResolutionNeeded"
        conflictResolutionNeededAttribute.attributeType = .booleanAttributeType
        conflictResolutionNeededAttribute.defaultValue = false
        conflictResolutionNeededAttribute.isOptional = true  // CloudKit requires optional
        properties.append(conflictResolutionNeededAttribute)
        
        let recordIDAttribute = NSAttributeDescription()
        recordIDAttribute.name = "recordID"
        recordIDAttribute.attributeType = .stringAttributeType
        recordIDAttribute.isOptional = true
        properties.append(recordIDAttribute)
        
        let changeTagAttribute = NSAttributeDescription()
        changeTagAttribute.name = "changeTag"
        changeTagAttribute.attributeType = .stringAttributeType
        changeTagAttribute.isOptional = true
        properties.append(changeTagAttribute)
        
        // User and metadata
        let userIDAttribute = NSAttributeDescription()
        userIDAttribute.name = "userID"
        userIDAttribute.attributeType = .stringAttributeType
        userIDAttribute.isOptional = true
        properties.append(userIDAttribute)
        
        let notesAttribute = NSAttributeDescription()
        notesAttribute.name = "notes"
        notesAttribute.attributeType = .stringAttributeType
        notesAttribute.isOptional = true
        properties.append(notesAttribute)
        
        let imageURLsAttribute = NSAttributeDescription()
        imageURLsAttribute.name = "imageURLs"
        imageURLsAttribute.attributeType = .binaryDataAttributeType
        imageURLsAttribute.isOptional = true
        properties.append(imageURLsAttribute)
        
        let verificationStatusAttribute = NSAttributeDescription()
        verificationStatusAttribute.name = "verificationStatus"
        verificationStatusAttribute.attributeType = .stringAttributeType
        verificationStatusAttribute.isOptional = true
        properties.append(verificationStatusAttribute)
        
        // Environmental measurements
        let temperatureAttribute = NSAttributeDescription()
        temperatureAttribute.name = "temperature"
        temperatureAttribute.attributeType = .doubleAttributeType
        temperatureAttribute.isOptional = true
        properties.append(temperatureAttribute)
        
        let salinityAttribute = NSAttributeDescription()
        salinityAttribute.name = "salinity"
        salinityAttribute.attributeType = .doubleAttributeType
        salinityAttribute.isOptional = true
        properties.append(salinityAttribute)
        
        let dissolvedOxygenAttribute = NSAttributeDescription()
        dissolvedOxygenAttribute.name = "dissolvedOxygen"
        dissolvedOxygenAttribute.attributeType = .doubleAttributeType
        dissolvedOxygenAttribute.isOptional = true
        properties.append(dissolvedOxygenAttribute)
        
        let windSpeedAttribute = NSAttributeDescription()
        windSpeedAttribute.name = "windSpeed"
        windSpeedAttribute.attributeType = .doubleAttributeType
        windSpeedAttribute.isOptional = true
        properties.append(windSpeedAttribute)
        
        let windDirectionAttribute = NSAttributeDescription()
        windDirectionAttribute.name = "windDirection"
        windDirectionAttribute.attributeType = .doubleAttributeType
        windDirectionAttribute.isOptional = true
        properties.append(windDirectionAttribute)
        
        let barometricPressureAttribute = NSAttributeDescription()
        barometricPressureAttribute.name = "barometricPressure"
        barometricPressureAttribute.attributeType = .doubleAttributeType
        barometricPressureAttribute.isOptional = true
        properties.append(barometricPressureAttribute)
        
        let tideLevelAttribute = NSAttributeDescription()
        tideLevelAttribute.name = "tideLevel"
        tideLevelAttribute.attributeType = .doubleAttributeType
        tideLevelAttribute.isOptional = true
        properties.append(tideLevelAttribute)
        
        // Set properties and add indexes
        jubileeReportEntity.properties = properties
        
        // Add indexes for efficient querying
        let syncStatusIndex = NSFetchIndexDescription(name: "syncStatusIndex", elements: [
            NSFetchIndexElementDescription(property: syncStatusAttribute, collationType: .binary)
        ])
        
        let timestampIndex = NSFetchIndexDescription(name: "timestampIndex", elements: [
            NSFetchIndexElementDescription(property: timestampAttribute, collationType: .binary)
        ])
        
        let lastModifiedIndex = NSFetchIndexDescription(name: "lastModifiedIndex", elements: [
            NSFetchIndexElementDescription(property: lastModifiedAttribute, collationType: .binary)
        ])
        
        jubileeReportEntity.indexes = [syncStatusIndex, timestampIndex, lastModifiedIndex]
        
        // CloudKit does not support uniqueness constraints - removed
        
        // Create ConflictHistoryEntry entity
        let conflictHistoryEntity = createConflictHistoryEntity()
        
        // Create community entities
        let messageEntity = createMessageEntity()
        let chatRoomEntity = createChatRoomEntity()
        let userProfileEntity = createUserProfileEntity()
        let achievementProgressEntity = createAchievementProgressEntity()
        
        // Add entities to model
        model.entities = [
            jubileeReportEntity, 
            conflictHistoryEntity,
            messageEntity,
            chatRoomEntity,
            userProfileEntity,
            achievementProgressEntity
        ]
        
        return model
    }
    
    // MARK: - ConflictHistoryEntry Entity
    
    private static func createConflictHistoryEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "ConflictHistoryEntry"
        entity.managedObjectClassName = NSStringFromClass(ConflictHistoryEntry.self)
        
        var properties: [NSPropertyDescription] = []
        
        // UUID (Primary Key)
        let uuidAttribute = NSAttributeDescription()
        uuidAttribute.name = "uuid"
        uuidAttribute.attributeType = .stringAttributeType
        uuidAttribute.isOptional = true  // CloudKit requires optional
        properties.append(uuidAttribute)
        
        // Entity UUID (Foreign Key)
        let entityUUIDAttribute = NSAttributeDescription()
        entityUUIDAttribute.name = "entityUUID"
        entityUUIDAttribute.attributeType = .stringAttributeType
        entityUUIDAttribute.isOptional = true  // CloudKit requires optional
        properties.append(entityUUIDAttribute)
        
        // Timestamps
        let occurredAtAttribute = NSAttributeDescription()
        occurredAtAttribute.name = "occurredAt"
        occurredAtAttribute.attributeType = .dateAttributeType
        occurredAtAttribute.isOptional = true  // CloudKit requires optional
        properties.append(occurredAtAttribute)
        
        let resolvedAtAttribute = NSAttributeDescription()
        resolvedAtAttribute.name = "resolvedAt"
        resolvedAtAttribute.attributeType = .dateAttributeType
        resolvedAtAttribute.isOptional = true
        properties.append(resolvedAtAttribute)
        
        // Resolution metadata
        let resolutionStrategyAttribute = NSAttributeDescription()
        resolutionStrategyAttribute.name = "resolutionStrategy"
        resolutionStrategyAttribute.attributeType = .stringAttributeType
        resolutionStrategyAttribute.isOptional = true
        properties.append(resolutionStrategyAttribute)
        
        let resolutionTypeAttribute = NSAttributeDescription()
        resolutionTypeAttribute.name = "resolutionType"
        resolutionTypeAttribute.attributeType = .stringAttributeType
        resolutionTypeAttribute.isOptional = true
        properties.append(resolutionTypeAttribute)
        
        // Version data (serialized)
        let localVersionAttribute = NSAttributeDescription()
        localVersionAttribute.name = "localVersion"
        localVersionAttribute.attributeType = .binaryDataAttributeType
        localVersionAttribute.isOptional = true
        localVersionAttribute.allowsExternalBinaryDataStorage = true
        properties.append(localVersionAttribute)
        
        let remoteVersionAttribute = NSAttributeDescription()
        remoteVersionAttribute.name = "remoteVersion"
        remoteVersionAttribute.attributeType = .binaryDataAttributeType
        remoteVersionAttribute.isOptional = true
        remoteVersionAttribute.allowsExternalBinaryDataStorage = true
        properties.append(remoteVersionAttribute)
        
        let mergedVersionAttribute = NSAttributeDescription()
        mergedVersionAttribute.name = "mergedVersion"
        mergedVersionAttribute.attributeType = .binaryDataAttributeType
        mergedVersionAttribute.isOptional = true
        mergedVersionAttribute.allowsExternalBinaryDataStorage = true
        properties.append(mergedVersionAttribute)
        
        // Notes
        let notesAttribute = NSAttributeDescription()
        notesAttribute.name = "notes"
        notesAttribute.attributeType = .stringAttributeType
        notesAttribute.isOptional = true
        properties.append(notesAttribute)
        
        entity.properties = properties
        
        // Add indexes for better query performance
        let entityUUIDIndex = NSFetchIndexDescription(name: "byEntityUUID", elements: [
            NSFetchIndexElementDescription(property: entityUUIDAttribute, collationType: .binary)
        ])
        
        let occurredAtIndex = NSFetchIndexDescription(name: "byOccurredAt", elements: [
            NSFetchIndexElementDescription(property: occurredAtAttribute, collationType: .binary)
        ])
        
        entity.indexes = [entityUUIDIndex, occurredAtIndex]
        
        // CloudKit does not support uniqueness constraints - removed
        
        return entity
    }
    
    // MARK: - MessageEntity
    
    private static func createMessageEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "MessageEntity"
        entity.managedObjectClassName = "MessageEntity"
        
        var properties: [NSPropertyDescription] = []
        
        // id: UUID
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = true  // CloudKit requires optional
        properties.append(idAttribute)
        
        // text: String
        let textAttribute = NSAttributeDescription()
        textAttribute.name = "text"
        textAttribute.attributeType = .stringAttributeType
        textAttribute.isOptional = true  // CloudKit requires optional
        properties.append(textAttribute)
        
        // timestamp: Date
        let timestampAttribute = NSAttributeDescription()
        timestampAttribute.name = "timestamp"
        timestampAttribute.attributeType = .dateAttributeType
        timestampAttribute.isOptional = true  // CloudKit requires optional
        properties.append(timestampAttribute)
        
        // roomId: String
        let roomIdAttribute = NSAttributeDescription()
        roomIdAttribute.name = "roomId"
        roomIdAttribute.attributeType = .stringAttributeType
        roomIdAttribute.isOptional = true  // CloudKit requires optional
        properties.append(roomIdAttribute)
        
        // userId: String
        let userIdAttribute = NSAttributeDescription()
        userIdAttribute.name = "userId"
        userIdAttribute.attributeType = .stringAttributeType
        userIdAttribute.isOptional = true  // CloudKit requires optional
        properties.append(userIdAttribute)
        
        // userName: String
        let userNameAttribute = NSAttributeDescription()
        userNameAttribute.name = "userName"
        userNameAttribute.attributeType = .stringAttributeType
        userNameAttribute.isOptional = true
        properties.append(userNameAttribute)
        
        // syncStatusValue: Int16
        let syncStatusAttribute = NSAttributeDescription()
        syncStatusAttribute.name = "syncStatusValue"
        syncStatusAttribute.attributeType = .integer16AttributeType
        syncStatusAttribute.defaultValue = 0
        properties.append(syncStatusAttribute)
        
        // cloudKitRecordID: String
        let cloudKitRecordIDAttribute = NSAttributeDescription()
        cloudKitRecordIDAttribute.name = "cloudKitRecordID"
        cloudKitRecordIDAttribute.attributeType = .stringAttributeType
        cloudKitRecordIDAttribute.isOptional = true
        properties.append(cloudKitRecordIDAttribute)
        
        // lastModified: Date
        let lastModifiedAttribute = NSAttributeDescription()
        lastModifiedAttribute.name = "lastModified"
        lastModifiedAttribute.attributeType = .dateAttributeType
        lastModifiedAttribute.isOptional = true  // CloudKit requires optional
        properties.append(lastModifiedAttribute)
        
        // deletedFlag: Bool
        let deletedFlagAttribute = NSAttributeDescription()
        deletedFlagAttribute.name = "deletedFlag"
        deletedFlagAttribute.attributeType = .booleanAttributeType
        deletedFlagAttribute.defaultValue = false
        properties.append(deletedFlagAttribute)
        
        // Threading support
        let parentMessageIdAttribute = NSAttributeDescription()
        parentMessageIdAttribute.name = "parentMessageId"
        parentMessageIdAttribute.attributeType = .UUIDAttributeType
        parentMessageIdAttribute.isOptional = true
        properties.append(parentMessageIdAttribute)
        
        let threadDepthAttribute = NSAttributeDescription()
        threadDepthAttribute.name = "threadDepth"
        threadDepthAttribute.attributeType = .integer16AttributeType
        threadDepthAttribute.defaultValue = 0
        properties.append(threadDepthAttribute)
        
        let replyCountAttribute = NSAttributeDescription()
        replyCountAttribute.name = "replyCount"
        replyCountAttribute.attributeType = .integer32AttributeType
        replyCountAttribute.defaultValue = 0
        properties.append(replyCountAttribute)
        
        entity.properties = properties
        
        // Add indexes
        let roomIdIndex = NSFetchIndexDescription(name: "roomIdIndex", elements: [
            NSFetchIndexElementDescription(property: roomIdAttribute, collationType: .binary)
        ])
        
        let timestampIndex = NSFetchIndexDescription(name: "timestampIndex", elements: [
            NSFetchIndexElementDescription(property: timestampAttribute, collationType: .binary)
        ])
        
        let parentMessageIdIndex = NSFetchIndexDescription(name: "parentMessageIdIndex", elements: [
            NSFetchIndexElementDescription(property: parentMessageIdAttribute, collationType: .binary)
        ])
        
        entity.indexes = [roomIdIndex, timestampIndex, parentMessageIdIndex]
        
        return entity
    }
    
    // MARK: - ChatRoomEntity
    
    private static func createChatRoomEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "ChatRoomEntity"
        entity.managedObjectClassName = "ChatRoomEntity"
        
        var properties: [NSPropertyDescription] = []
        
        // id: String
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .stringAttributeType
        idAttribute.isOptional = true  // CloudKit requires optional
        properties.append(idAttribute)
        
        // name: String
        let nameAttribute = NSAttributeDescription()
        nameAttribute.name = "name"
        nameAttribute.attributeType = .stringAttributeType
        nameAttribute.isOptional = true  // CloudKit requires optional
        properties.append(nameAttribute)
        
        // createdAt: Date
        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = true  // CloudKit requires optional
        properties.append(createdAtAttribute)
        
        // lastMessageAt: Date
        let lastMessageAtAttribute = NSAttributeDescription()
        lastMessageAtAttribute.name = "lastMessageAt"
        lastMessageAtAttribute.attributeType = .dateAttributeType
        lastMessageAtAttribute.isOptional = true
        properties.append(lastMessageAtAttribute)
        
        // unreadCount: Int64
        let unreadCountAttribute = NSAttributeDescription()
        unreadCountAttribute.name = "unreadCount"
        unreadCountAttribute.attributeType = .integer64AttributeType
        unreadCountAttribute.defaultValue = 0
        properties.append(unreadCountAttribute)
        
        // syncStatusValue: Int16
        let syncStatusAttribute = NSAttributeDescription()
        syncStatusAttribute.name = "syncStatusValue"
        syncStatusAttribute.attributeType = .integer16AttributeType
        syncStatusAttribute.defaultValue = 0
        properties.append(syncStatusAttribute)
        
        entity.properties = properties
        
        // CloudKit does not support uniqueness constraints - removed
        
        return entity
    }
    
    // MARK: - UserProfileEntity
    
    private static func createUserProfileEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "UserProfileEntity"
        entity.managedObjectClassName = "UserProfileEntity"
        
        var properties: [NSPropertyDescription] = []
        
        // id: String
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .stringAttributeType
        idAttribute.isOptional = true
        properties.append(idAttribute)
        
        // displayName: String
        let displayNameAttribute = NSAttributeDescription()
        displayNameAttribute.name = "displayName"
        displayNameAttribute.attributeType = .stringAttributeType
        displayNameAttribute.isOptional = true
        properties.append(displayNameAttribute)
        
        // points: Int32
        let pointsAttribute = NSAttributeDescription()
        pointsAttribute.name = "points"
        pointsAttribute.attributeType = .integer32AttributeType
        pointsAttribute.defaultValue = 0
        properties.append(pointsAttribute)
        
        // badgesData: String (JSON encoded array)
        let badgesDataAttribute = NSAttributeDescription()
        badgesDataAttribute.name = "badgesData"
        badgesDataAttribute.attributeType = .stringAttributeType
        badgesDataAttribute.isOptional = true
        properties.append(badgesDataAttribute)
        
        // rank: String
        let rankAttribute = NSAttributeDescription()
        rankAttribute.name = "rank"
        rankAttribute.attributeType = .stringAttributeType
        rankAttribute.isOptional = true
        properties.append(rankAttribute)
        
        // joinedAt: Date
        let joinedAtAttribute = NSAttributeDescription()
        joinedAtAttribute.name = "joinedAt"
        joinedAtAttribute.attributeType = .dateAttributeType
        joinedAtAttribute.isOptional = true
        properties.append(joinedAtAttribute)
        
        // syncStatusValue: Int16
        let syncStatusAttribute = NSAttributeDescription()
        syncStatusAttribute.name = "syncStatusValue"
        syncStatusAttribute.attributeType = .integer16AttributeType
        syncStatusAttribute.defaultValue = 0
        properties.append(syncStatusAttribute)
        
        entity.properties = properties
        
        // CloudKit does not support uniqueness constraints - removed
        
        return entity
    }
    
    // MARK: - AchievementProgressEntity
    
    private static func createAchievementProgressEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "AchievementProgressEntity"
        entity.managedObjectClassName = "AchievementProgressEntity"
        
        var properties: [NSPropertyDescription] = []
        
        // userId: String
        let userIdAttribute = NSAttributeDescription()
        userIdAttribute.name = "userId"
        userIdAttribute.attributeType = .stringAttributeType
        userIdAttribute.isOptional = true
        properties.append(userIdAttribute)
        
        // achievementId: String
        let achievementIdAttribute = NSAttributeDescription()
        achievementIdAttribute.name = "achievementId"
        achievementIdAttribute.attributeType = .stringAttributeType
        achievementIdAttribute.isOptional = true
        properties.append(achievementIdAttribute)
        
        // currentValue: Int32
        let currentValueAttribute = NSAttributeDescription()
        currentValueAttribute.name = "currentValue"
        currentValueAttribute.attributeType = .integer32AttributeType
        currentValueAttribute.defaultValue = 0
        properties.append(currentValueAttribute)
        
        // targetValue: Int32
        let targetValueAttribute = NSAttributeDescription()
        targetValueAttribute.name = "targetValue"
        targetValueAttribute.attributeType = .integer32AttributeType
        targetValueAttribute.defaultValue = 0
        properties.append(targetValueAttribute)
        
        // isCompleted: Bool
        let isCompletedAttribute = NSAttributeDescription()
        isCompletedAttribute.name = "isCompleted"
        isCompletedAttribute.attributeType = .booleanAttributeType
        isCompletedAttribute.defaultValue = false
        properties.append(isCompletedAttribute)
        
        // completedDate: Date?
        let completedDateAttribute = NSAttributeDescription()
        completedDateAttribute.name = "completedDate"
        completedDateAttribute.attributeType = .dateAttributeType
        completedDateAttribute.isOptional = true
        properties.append(completedDateAttribute)
        
        // lastUpdated: Date
        let lastUpdatedAttribute = NSAttributeDescription()
        lastUpdatedAttribute.name = "lastUpdated"
        lastUpdatedAttribute.attributeType = .dateAttributeType
        lastUpdatedAttribute.isOptional = true
        properties.append(lastUpdatedAttribute)
        
        // syncStatusValue: Int16
        let syncStatusAttribute = NSAttributeDescription()
        syncStatusAttribute.name = "syncStatusValue"
        syncStatusAttribute.attributeType = .integer16AttributeType
        syncStatusAttribute.defaultValue = 0
        properties.append(syncStatusAttribute)
        
        // cloudKitRecordID: String
        let cloudKitRecordIDAttribute = NSAttributeDescription()
        cloudKitRecordIDAttribute.name = "cloudKitRecordID"
        cloudKitRecordIDAttribute.attributeType = .stringAttributeType
        cloudKitRecordIDAttribute.isOptional = true
        properties.append(cloudKitRecordIDAttribute)
        
        entity.properties = properties
        
        // Add indexes
        let userIdIndex = NSFetchIndexDescription(name: "userIdIndex", elements: [
            NSFetchIndexElementDescription(property: userIdAttribute, collationType: .binary)
        ])
        
        let achievementIdIndex = NSFetchIndexDescription(name: "achievementIdIndex", elements: [
            NSFetchIndexElementDescription(property: achievementIdAttribute, collationType: .binary)
        ])
        
        entity.indexes = [userIdIndex, achievementIdIndex]
        
        // CloudKit does not support uniqueness constraints - removed
        
        return entity
    }
}