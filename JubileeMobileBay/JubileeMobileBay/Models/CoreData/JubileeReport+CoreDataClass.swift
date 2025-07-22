//
//  JubileeReport+CoreDataClass.swift
//  JubileeMobileBay
//
//  NSManagedObject subclass for JubileeReport entity
//

import Foundation
import CoreData
import CoreLocation
import CloudKit

@objc(JubileeReport)
public class JubileeReport: NSManagedObject {
    
    // MARK: - Computed Properties
    
    var syncStatusEnum: SyncStatus {
        get {
            return SyncStatus(rawValue: syncStatus ?? "") ?? .synced
        }
        set {
            syncStatus = newValue.rawValue
        }
    }
    
    var locationCoordinate: CLLocationCoordinate2D? {
        get {
            guard let latitude = latitude?.doubleValue,
                  let longitude = longitude?.doubleValue else {
                return nil
            }
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            if let coordinate = newValue {
                latitude = NSNumber(value: coordinate.latitude)
                longitude = NSNumber(value: coordinate.longitude)
            } else {
                latitude = nil
                longitude = nil
            }
        }
    }
    
    var speciesArray: [String] {
        get {
            guard let speciesData = species,
                  let array = try? JSONDecoder().decode([String].self, from: speciesData) else {
                return []
            }
            return array
        }
        set {
            species = try? JSONEncoder().encode(newValue)
        }
    }
    
    var environmentalConditionsDict: [String: Double] {
        get {
            guard let data = environmentalConditions,
                  let dict = try? JSONDecoder().decode([String: Double].self, from: data) else {
                return [:]
            }
            return dict
        }
        set {
            environmentalConditions = try? JSONEncoder().encode(newValue)
        }
    }
    
    // MARK: - Helper Methods
    
    func markForSync() {
        syncStatusEnum = .pendingUpload
        lastModified = Date()
    }
    
    func markAsConflict() {
        syncStatusEnum = .conflict
        conflictResolutionNeeded = true
    }
    
    func resolveConflict() {
        conflictResolutionNeeded = false
        if syncStatusEnum == .conflict {
            syncStatusEnum = .synced
        }
    }
}

// MARK: - SyncableEntity Conformance

extension JubileeReport: SyncableEntity {
    
    func toCKRecord() -> CKRecord {
        let recordID = self.recordID ?? UUID().uuidString
        let record = CKRecord(recordType: "JubileeReport", recordID: CKRecord.ID(recordName: recordID))
        
        // Core fields
        record["uuid"] = uuid as CKRecordValue?
        record["timestamp"] = timestamp as CKRecordValue?
        
        // Location
        if let coordinate = locationCoordinate {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            record["location"] = location as CKRecordValue
        }
        
        // Arrays and dictionaries
        record["species"] = speciesArray as CKRecordValue
        record["intensity"] = intensity as CKRecordValue?
        
        // Environmental conditions as separate fields for better querying
        let conditions = environmentalConditionsDict
        record["temperature"] = conditions["temperature"] as CKRecordValue?
        record["salinity"] = conditions["salinity"] as CKRecordValue?
        record["dissolvedOxygen"] = conditions["dissolvedOxygen"] as CKRecordValue?
        record["windSpeed"] = conditions["windSpeed"] as CKRecordValue?
        record["windDirection"] = conditions["windDirection"] as CKRecordValue?
        record["barometricPressure"] = conditions["barometricPressure"] as CKRecordValue?
        record["tideLevel"] = conditions["tideLevel"] as CKRecordValue?
        
        // Metadata
        record["userID"] = userID as CKRecordValue?
        record["notes"] = notes as CKRecordValue?
        record["verificationStatus"] = verificationStatus as CKRecordValue?
        record["lastModified"] = lastModified as CKRecordValue?
        
        // Store the record ID for future reference
        self.recordID = recordID
        
        return record
    }
    
    func updateFromCKRecord(_ record: CKRecord) {
        // Core fields
        uuid = record["uuid"] as? String
        timestamp = record["timestamp"] as? Date
        
        // Location
        if let location = record["location"] as? CLLocation {
            locationCoordinate = location.coordinate
        }
        
        // Arrays and dictionaries
        if let speciesArray = record["species"] as? [String] {
            self.speciesArray = speciesArray
        }
        
        intensity = record["intensity"] as? String
        
        // Environmental conditions
        var conditions: [String: Double] = [:]
        if let temp = record["temperature"] as? Double {
            conditions["temperature"] = temp
            temperature = NSNumber(value: temp)
        }
        if let sal = record["salinity"] as? Double {
            conditions["salinity"] = sal
            salinity = NSNumber(value: sal)
        }
        if let oxygen = record["dissolvedOxygen"] as? Double {
            conditions["dissolvedOxygen"] = oxygen
            dissolvedOxygen = NSNumber(value: oxygen)
        }
        if let wind = record["windSpeed"] as? Double {
            conditions["windSpeed"] = wind
            windSpeed = NSNumber(value: wind)
        }
        if let windDir = record["windDirection"] as? Double {
            conditions["windDirection"] = windDir
            windDirection = NSNumber(value: windDir)
        }
        if let pressure = record["barometricPressure"] as? Double {
            conditions["barometricPressure"] = pressure
            barometricPressure = NSNumber(value: pressure)
        }
        if let tide = record["tideLevel"] as? Double {
            conditions["tideLevel"] = tide
            tideLevel = NSNumber(value: tide)
        }
        environmentalConditionsDict = conditions
        
        // Metadata
        userID = record["userID"] as? String
        notes = record["notes"] as? String
        verificationStatus = record["verificationStatus"] as? String
        lastModified = record["lastModified"] as? Date ?? Date()
        
        // Sync metadata
        recordID = record.recordID.recordName
        changeTag = record.recordChangeTag
        syncStatusEnum = .synced
        conflictResolutionNeeded = false
    }
}