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
        uuidAttribute.isOptional = false
        properties.append(uuidAttribute)
        
        // Timestamp
        let timestampAttribute = NSAttributeDescription()
        timestampAttribute.name = "timestamp"
        timestampAttribute.attributeType = .dateAttributeType
        timestampAttribute.isOptional = false
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
        syncStatusAttribute.defaultValue = SyncStatus.synced.rawValue
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
        conflictResolutionNeededAttribute.isOptional = false
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
        
        // Add uniqueness constraint on UUID
        jubileeReportEntity.uniquenessConstraints = [
            [uuidAttribute.name]
        ]
        
        // Create ConflictHistoryEntry entity
        let conflictHistoryEntity = createConflictHistoryEntity()
        
        // Add entities to model
        model.entities = [jubileeReportEntity, conflictHistoryEntity]
        
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
        uuidAttribute.isOptional = false
        properties.append(uuidAttribute)
        
        // Entity UUID (Foreign Key)
        let entityUUIDAttribute = NSAttributeDescription()
        entityUUIDAttribute.name = "entityUUID"
        entityUUIDAttribute.attributeType = .stringAttributeType
        entityUUIDAttribute.isOptional = false
        properties.append(entityUUIDAttribute)
        
        // Timestamps
        let occurredAtAttribute = NSAttributeDescription()
        occurredAtAttribute.name = "occurredAt"
        occurredAtAttribute.attributeType = .dateAttributeType
        occurredAtAttribute.isOptional = false
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
        
        // Uniqueness constraint
        entity.uniquenessConstraints = [
            [uuidAttribute.name]
        ]
        
        return entity
    }
}