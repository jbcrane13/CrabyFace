//
//  CloudKitService.swift
//  JubileeMobileBay
//
//  CloudKit service for managing container and data operations
//

import Foundation
import CloudKit
import CoreLocation

@MainActor
class CloudKitService: ObservableObject {
    
    // MARK: - Properties
    
    let container: CKContainer
    
    var publicDatabase: CKDatabase {
        container.database(with: .public)
    }
    
    var privateDatabase: CKDatabase {
        container.database(with: .private)
    }
    
    // MARK: - Record Types
    
    enum RecordType: String {
        case jubileeEvent = "JubileeEvent"
        case userReport = "UserReport"
        case environmentalData = "EnvironmentalData"
        case userProfile = "UserProfile"
    }
    
    // MARK: - Field Keys
    
    private enum JubileeEventField: String {
        case location
        case intensity
        case startTime
        case endTime
        case verificationStatus
        case environmentalData
        case photoURLs
    }
    
    private enum UserReportField: String {
        case jubileeEventId
        case userId
        case timestamp
        case description
        case intensity
        case photoURLs
        case location
    }
    
    // MARK: - Initialization
    
    init(container: CKContainer? = nil) {
        self.container = container ?? CKContainer(identifier: "iCloud.com.jubileemobilebay.app")
    }
    
    // MARK: - Save Operations
    
    func saveUserReport(_ report: UserReport) async throws {
        let record = CKRecord(recordType: RecordType.userReport.rawValue)
        
        if let jubileeEventId = report.jubileeEventId {
            record[UserReportField.jubileeEventId.rawValue] = jubileeEventId.uuidString as CKRecordValue
        }
        record[UserReportField.userId.rawValue] = report.userId.uuidString as CKRecordValue
        record[UserReportField.timestamp.rawValue] = report.timestamp as CKRecordValue
        record[UserReportField.description.rawValue] = report.description as CKRecordValue
        record[UserReportField.intensity.rawValue] = report.intensity.rawValue as CKRecordValue
        
        // Save location
        let location = CLLocation(
            latitude: report.location.latitude,
            longitude: report.location.longitude
        )
        record[UserReportField.location.rawValue] = location as CKRecordValue
        
        if !report.photos.isEmpty {
            let photoURLs = report.photos.map { $0.url.absoluteString }
            record[UserReportField.photoURLs.rawValue] = photoURLs as CKRecordValue
        }
        
        let _ = try await publicDatabase.save(record)
    }
    
    func saveJubileeEvent(_ event: JubileeEvent) async throws {
        let record = CKRecord(recordType: RecordType.jubileeEvent.rawValue)
        
        let location = CLLocation(
            latitude: event.location.latitude,
            longitude: event.location.longitude
        )
        record[JubileeEventField.location.rawValue] = location as CKRecordValue
        record[JubileeEventField.intensity.rawValue] = event.intensity.rawValue as CKRecordValue
        record[JubileeEventField.startTime.rawValue] = event.startTime as CKRecordValue
        
        if let endTime = event.endTime {
            record[JubileeEventField.endTime.rawValue] = endTime as CKRecordValue
        }
        
        record[JubileeEventField.verificationStatus.rawValue] = event.verificationStatus.rawValue as CKRecordValue
        
        // Save metadata as embedded fields
        saveJubileeMetadata(event.metadata, to: record)
        
        record["reportCount"] = event.reportCount as CKRecordValue
        
        let _ = try await publicDatabase.save(record)
    }
    
    private func saveJubileeMetadata(_ metadata: JubileeMetadata, to record: CKRecord) {
        record["temperature"] = metadata.temperature as CKRecordValue
        record["humidity"] = metadata.humidity as CKRecordValue
        record["windSpeed"] = metadata.windSpeed as CKRecordValue
        record["windDirection"] = metadata.windDirection as CKRecordValue
        record["waterTemperature"] = metadata.waterTemperature as CKRecordValue
        record["dissolvedOxygen"] = metadata.dissolvedOxygen as CKRecordValue
        record["salinity"] = metadata.salinity as CKRecordValue
        record["tide"] = metadata.tide.rawValue as CKRecordValue
        record["moonPhase"] = metadata.moonPhase.rawValue as CKRecordValue
    }
    
    func saveEnvironmentalData(_ data: EnvironmentalData) async throws {
        let record = CKRecord(recordType: RecordType.environmentalData.rawValue)
        
        let location = CLLocation(
            latitude: data.location.latitude,
            longitude: data.location.longitude
        )
        record["location"] = location as CKRecordValue
        record["timestamp"] = data.timestamp as CKRecordValue
        record["temperature"] = data.temperature as CKRecordValue
        record["humidity"] = data.humidity as CKRecordValue
        record["windSpeed"] = data.windSpeed as CKRecordValue
        record["windDirection"] = data.windDirection as CKRecordValue
        
        if let pressure = data.pressure {
            record["pressure"] = pressure as CKRecordValue
        }
        if let waterTemp = data.waterTemperature {
            record["waterTemperature"] = waterTemp as CKRecordValue
        }
        if let dissolved = data.dissolvedOxygen {
            record["dissolvedOxygen"] = dissolved as CKRecordValue
        }
        if let salinity = data.salinity {
            record["salinity"] = salinity as CKRecordValue
        }
        if let ph = data.ph {
            record["ph"] = ph as CKRecordValue
        }
        if let turbidity = data.turbidity {
            record["turbidity"] = turbidity as CKRecordValue
        }
        
        record["dataSource"] = data.dataSource.rawValue as CKRecordValue
        
        let _ = try await publicDatabase.save(record)
    }
    
    // MARK: - Fetch Operations
    
    func fetchRecentJubileeEvents(limit: Int = 50) async throws -> [JubileeEvent] {
        let query = CKQuery(
            recordType: RecordType.jubileeEvent.rawValue,
            predicate: NSPredicate(value: true)
        )
        
        query.sortDescriptors = [
            NSSortDescriptor(key: JubileeEventField.startTime.rawValue, ascending: false)
        ]
        
        let records = try await publicDatabase.perform(query, resultsLimit: limit)
        return records.compactMap { record in
            jubileeEventFromRecord(record)
        }
    }
    
    func fetchUserReports(for eventId: UUID) async throws -> [UserReport] {
        let predicate = NSPredicate(
            format: "%K == %@",
            UserReportField.jubileeEventId.rawValue,
            eventId.uuidString
        )
        
        let query = CKQuery(
            recordType: RecordType.userReport.rawValue,
            predicate: predicate
        )
        
        query.sortDescriptors = [
            NSSortDescriptor(key: UserReportField.timestamp.rawValue, ascending: false)
        ]
        
        let records = try await publicDatabase.perform(query)
        return records.compactMap { record in
            userReportFromRecord(record)
        }
    }
    
    // MARK: - Subscriptions
    
    func subscribeToJubileeEvents() async throws -> CKQuerySubscription {
        let predicate = NSPredicate(value: true)
        
        let subscription = CKQuerySubscription(
            recordType: RecordType.jubileeEvent.rawValue,
            predicate: predicate,
            subscriptionID: "jubilee-event-subscription",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "New jubilee event reported nearby!"
        notificationInfo.shouldBadge = true
        notificationInfo.soundName = "default"
        
        subscription.notificationInfo = notificationInfo
        
        return try await publicDatabase.save(subscription) as! CKQuerySubscription
    }
    
    // MARK: - Record Conversion
    
    private func jubileeEventFromRecord(_ record: CKRecord) -> JubileeEvent? {
        guard let location = record[JubileeEventField.location.rawValue] as? CLLocation,
              let intensityString = record[JubileeEventField.intensity.rawValue] as? String,
              let intensity = JubileeIntensity(rawValue: intensityString),
              let startTime = record[JubileeEventField.startTime.rawValue] as? Date,
              let verificationStatusString = record[JubileeEventField.verificationStatus.rawValue] as? String,
              let verificationStatus = VerificationStatus(rawValue: verificationStatusString) else {
            return nil
        }
        
        let endTime = record[JubileeEventField.endTime.rawValue] as? Date
        let reportCount = record["reportCount"] as? Int ?? 0
        
        // Extract metadata
        guard let temperature = record["temperature"] as? Double,
              let humidity = record["humidity"] as? Double,
              let windSpeed = record["windSpeed"] as? Double,
              let windDirection = record["windDirection"] as? Int,
              let waterTemperature = record["waterTemperature"] as? Double,
              let dissolvedOxygen = record["dissolvedOxygen"] as? Double,
              let salinity = record["salinity"] as? Double,
              let tideString = record["tide"] as? String,
              let tide = TideState(rawValue: tideString),
              let moonPhaseString = record["moonPhase"] as? String,
              let moonPhase = MoonPhase(rawValue: moonPhaseString) else {
            return nil
        }
        
        let metadata = JubileeMetadata(
            windSpeed: windSpeed,
            windDirection: windDirection,
            temperature: temperature,
            humidity: humidity,
            waterTemperature: waterTemperature,
            dissolvedOxygen: dissolvedOxygen,
            salinity: salinity,
            tide: tide,
            moonPhase: moonPhase
        )
        
        return JubileeEvent(
            id: UUID(),
            startTime: startTime,
            endTime: endTime,
            location: location.coordinate,
            intensity: intensity,
            verificationStatus: verificationStatus,
            reportCount: reportCount,
            metadata: metadata
        )
    }
    
    private func userReportFromRecord(_ record: CKRecord) -> UserReport? {
        guard let userIdString = record[UserReportField.userId.rawValue] as? String,
              let userId = UUID(uuidString: userIdString),
              let timestamp = record[UserReportField.timestamp.rawValue] as? Date,
              let description = record[UserReportField.description.rawValue] as? String,
              let intensityString = record[UserReportField.intensity.rawValue] as? String,
              let intensity = JubileeIntensity(rawValue: intensityString),
              let location = record[UserReportField.location.rawValue] as? CLLocation else {
            return nil
        }
        
        let eventIdString = record[UserReportField.jubileeEventId.rawValue] as? String
        let eventId = eventIdString.flatMap { UUID(uuidString: $0) }
        
        let photoURLStrings = record[UserReportField.photoURLs.rawValue] as? [String] ?? []
        let photoReferences = photoURLStrings.compactMap { urlString in
            URL(string: urlString).map { PhotoReference(id: UUID(), url: $0, thumbnailUrl: $0) }
        }
        
        return UserReport(
            id: UUID(),
            userId: userId,
            timestamp: timestamp,
            location: location.coordinate,
            jubileeEventId: eventId,
            description: description,
            photos: photoReferences,
            intensity: intensity
        )
    }
}

// MARK: - CKDatabase Extension for Async/Await

extension CKDatabase {
    func save(_ record: CKRecord) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            save(record) { savedRecord, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let savedRecord = savedRecord {
                    continuation.resume(returning: savedRecord)
                } else {
                    continuation.resume(throwing: CloudKitError.unknown)
                }
            }
        }
    }
    
    func save(_ subscription: CKSubscription) async throws -> CKSubscription {
        try await withCheckedThrowingContinuation { continuation in
            save(subscription) { savedSubscription, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let savedSubscription = savedSubscription {
                    continuation.resume(returning: savedSubscription)
                } else {
                    continuation.resume(throwing: CloudKitError.unknown)
                }
            }
        }
    }
    
    func perform(_ query: CKQuery, resultsLimit: Int = CKQueryOperation.maximumResults) async throws -> [CKRecord] {
        try await withCheckedThrowingContinuation { continuation in
            var records: [CKRecord] = []
            
            let operation = CKQueryOperation(query: query)
            operation.resultsLimit = resultsLimit
            
            operation.recordMatchedBlock = { _, result in
                switch result {
                case .success(let record):
                    records.append(record)
                case .failure:
                    break
                }
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: records)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            self.add(operation)
        }
    }
}

// MARK: - CloudKit Error

enum CloudKitError: LocalizedError {
    case unknown
    case recordNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "An unknown CloudKit error occurred"
        case .recordNotFound:
            return "The requested record was not found"
        case .invalidData:
            return "The CloudKit data is invalid"
        }
    }
}