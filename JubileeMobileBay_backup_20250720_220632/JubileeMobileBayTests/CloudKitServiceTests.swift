//
//  CloudKitServiceTests.swift
//  JubileeMobileBayTests
//
//  Test-Driven Development for CloudKit Service
//

import XCTest
import CloudKit
@testable import JubileeMobileBay

@MainActor
class CloudKitServiceTests: XCTestCase {
    
    var service: CloudKitService!
    var mockContainer: MockCKContainer!
    var mockPublicDatabase: MockCKDatabase!
    var mockPrivateDatabase: MockCKDatabase!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockPublicDatabase = MockCKDatabase()
        mockPrivateDatabase = MockCKDatabase()
        mockContainer = MockCKContainer(
            publicDatabase: mockPublicDatabase,
            privateDatabase: mockPrivateDatabase
        )
        service = CloudKitService(container: mockContainer)
    }
    
    override func tearDownWithError() throws {
        service = nil
        mockContainer = nil
        mockPublicDatabase = nil
        mockPrivateDatabase = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Container Tests
    
    func test_init_shouldConfigureContainer() {
        XCTAssertNotNil(service.container)
        XCTAssertEqual(service.container.containerIdentifier, mockContainer.containerIdentifier)
    }
    
    func test_publicDatabase_shouldReturnContainerPublicDatabase() {
        let database = service.publicDatabase
        XCTAssertTrue(database === mockPublicDatabase)
    }
    
    func test_privateDatabase_shouldReturnContainerPrivateDatabase() {
        let database = service.privateDatabase
        XCTAssertTrue(database === mockPrivateDatabase)
    }
    
    // MARK: - Record Type Tests
    
    func test_recordTypes_shouldDefineAllExpectedTypes() {
        XCTAssertEqual(CloudKitService.RecordType.jubileeEvent.rawValue, "JubileeEvent")
        XCTAssertEqual(CloudKitService.RecordType.userReport.rawValue, "UserReport")
        XCTAssertEqual(CloudKitService.RecordType.environmentalData.rawValue, "EnvironmentalData")
        XCTAssertEqual(CloudKitService.RecordType.userProfile.rawValue, "UserProfile")
    }
    
    // MARK: - User Report Tests
    
    func test_saveUserReport_shouldCreateRecordInPublicDatabase() async throws {
        // Given
        let location = CLLocationCoordinate2D(latitude: 30.4672, longitude: -87.9833)
        let report = UserReport(
            id: UUID(),
            userId: UUID(),
            timestamp: Date(),
            location: location,
            jubileeEventId: UUID(),
            description: "Test report",
            photos: [],
            intensity: .moderate
        )
        
        mockPublicDatabase.saveResult = .success(CKRecord(recordType: CloudKitService.RecordType.userReport.rawValue))
        
        // When
        try await service.saveUserReport(report)
        
        // Then
        XCTAssertEqual(mockPublicDatabase.savedRecords.count, 1)
        let savedRecord = mockPublicDatabase.savedRecords.first
        XCTAssertEqual(savedRecord?.recordType, CloudKitService.RecordType.userReport.rawValue)
        XCTAssertEqual(savedRecord?["jubileeEventId"] as? String, report.jubileeEventId?.uuidString)
        XCTAssertEqual(savedRecord?["userId"] as? String, report.userId.uuidString)
        XCTAssertEqual(savedRecord?["description"] as? String, report.description)
        XCTAssertEqual(savedRecord?["intensity"] as? String, report.intensity.rawValue)
        
        let savedLocation = savedRecord?["location"] as? CLLocation
        XCTAssertEqual(savedLocation?.coordinate.latitude, location.latitude, accuracy: 0.0001)
        XCTAssertEqual(savedLocation?.coordinate.longitude, location.longitude, accuracy: 0.0001)
    }
    
    func test_saveUserReport_withPhotos_shouldIncludePhotoReferences() async throws {
        // Given
        let photoRefs = [
            PhotoReference(id: UUID(), url: URL(string: "https://example.com/photo1.jpg")!, thumbnailUrl: URL(string: "https://example.com/thumb1.jpg")!),
            PhotoReference(id: UUID(), url: URL(string: "https://example.com/photo2.jpg")!, thumbnailUrl: URL(string: "https://example.com/thumb2.jpg")!)
        ]
        let location = CLLocationCoordinate2D(latitude: 30.4672, longitude: -87.9833)
        let report = UserReport(
            id: UUID(),
            userId: UUID(),
            timestamp: Date(),
            location: location,
            jubileeEventId: UUID(),
            description: "Test report with photos",
            photos: photoRefs,
            intensity: .heavy
        )
        
        mockPublicDatabase.saveResult = .success(CKRecord(recordType: CloudKitService.RecordType.userReport.rawValue))
        
        // When
        try await service.saveUserReport(report)
        
        // Then
        let savedRecord = mockPublicDatabase.savedRecords.first
        let photoURLs = savedRecord?["photoURLs"] as? [String]
        XCTAssertEqual(photoURLs?.count, 2)
        XCTAssertEqual(photoURLs?[0], photoRefs[0].url.absoluteString)
        XCTAssertEqual(photoURLs?[1], photoRefs[1].url.absoluteString)
    }
    
    // MARK: - Jubilee Event Tests
    
    func test_saveJubileeEvent_shouldCreateRecordInPublicDatabase() async throws {
        // Given
        let location = CLLocationCoordinate2D(latitude: 30.4672, longitude: -87.9833)
        let metadata = JubileeMetadata(
            windSpeed: 5.0,
            windDirection: 180,
            temperature: 75.5,
            humidity: 85.0,
            waterTemperature: 72.0,
            dissolvedOxygen: 2.5,
            salinity: 28.0,
            tide: .rising,
            moonPhase: .full
        )
        
        let event = JubileeEvent(
            id: UUID(),
            startTime: Date(),
            endTime: nil,
            location: location,
            intensity: .moderate,
            verificationStatus: .unverified,
            reportCount: 0,
            metadata: metadata
        )
        
        mockPublicDatabase.saveResult = .success(CKRecord(recordType: CloudKitService.RecordType.jubileeEvent.rawValue))
        
        // When
        try await service.saveJubileeEvent(event)
        
        // Then
        XCTAssertEqual(mockPublicDatabase.savedRecords.count, 1)
        let savedRecord = mockPublicDatabase.savedRecords.first
        XCTAssertEqual(savedRecord?.recordType, CloudKitService.RecordType.jubileeEvent.rawValue)
        
        let savedLocation = savedRecord?["location"] as? CLLocation
        XCTAssertEqual(savedLocation?.coordinate.latitude, location.latitude, accuracy: 0.0001)
        XCTAssertEqual(savedLocation?.coordinate.longitude, location.longitude, accuracy: 0.0001)
        
        XCTAssertEqual(savedRecord?["intensity"] as? String, event.intensity.rawValue)
        XCTAssertEqual(savedRecord?["verificationStatus"] as? String, event.verificationStatus.rawValue)
        XCTAssertEqual(savedRecord?["temperature"] as? Double, metadata.temperature)
        XCTAssertEqual(savedRecord?["humidity"] as? Double, metadata.humidity)
        XCTAssertEqual(savedRecord?["tide"] as? String, metadata.tide.rawValue)
        XCTAssertEqual(savedRecord?["moonPhase"] as? String, metadata.moonPhase.rawValue)
    }
    
    // MARK: - Fetch Tests
    
    func test_fetchRecentJubileeEvents_shouldQueryPublicDatabase() async throws {
        // Given
        let recordsToReturn = [
            createMockJubileeEventRecord(intensity: .light),
            createMockJubileeEventRecord(intensity: .moderate),
            createMockJubileeEventRecord(intensity: .heavy)
        ]
        
        mockPublicDatabase.queryResult = .success(recordsToReturn)
        
        // When
        let events = try await service.fetchRecentJubileeEvents(limit: 10)
        
        // Then
        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(mockPublicDatabase.performedQueries.count, 1)
        
        let query = mockPublicDatabase.performedQueries.first
        XCTAssertEqual(query?.recordType, CloudKitService.RecordType.jubileeEvent.rawValue)
        XCTAssertEqual(query?.sortDescriptors?.first?.key, "startTime")
        XCTAssertEqual(query?.sortDescriptors?.first?.ascending, false)
    }
    
    func test_fetchUserReports_forEvent_shouldQueryByEventId() async throws {
        // Given
        let eventId = UUID()
        let recordsToReturn = [
            createMockUserReportRecord(eventId: eventId),
            createMockUserReportRecord(eventId: eventId)
        ]
        
        mockPublicDatabase.queryResult = .success(recordsToReturn)
        
        // When
        let reports = try await service.fetchUserReports(for: eventId)
        
        // Then
        XCTAssertEqual(reports.count, 2)
        XCTAssertEqual(mockPublicDatabase.performedQueries.count, 1)
        
        let query = mockPublicDatabase.performedQueries.first
        XCTAssertEqual(query?.recordType, CloudKitService.RecordType.userReport.rawValue)
        XCTAssertTrue(query?.predicate?.predicateFormat.contains("jubileeEventId") ?? false)
    }
    
    // MARK: - Subscription Tests
    
    func test_subscribeToJubileeEvents_shouldCreateSubscription() async throws {
        // Given
        let mockSubscription = CKQuerySubscription(
            recordType: CloudKitService.RecordType.jubileeEvent.rawValue,
            predicate: NSPredicate(value: true),
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        
        mockPublicDatabase.saveSubscriptionResult = .success(mockSubscription)
        
        // When
        let subscription = try await service.subscribeToJubileeEvents()
        
        // Then
        XCTAssertNotNil(subscription)
        XCTAssertEqual(mockPublicDatabase.savedSubscriptions.count, 1)
        XCTAssertEqual(subscription.recordType, CloudKitService.RecordType.jubileeEvent.rawValue)
    }
    
    // MARK: - Helper Methods
    
    private func createMockJubileeEventRecord(intensity: JubileeIntensity) -> CKRecord {
        let record = CKRecord(recordType: CloudKitService.RecordType.jubileeEvent.rawValue)
        record["intensity"] = intensity.rawValue as CKRecordValue
        record["location"] = CLLocation(latitude: 30.4672, longitude: -87.9833)
        record["startTime"] = Date() as CKRecordValue
        record["verificationStatus"] = VerificationStatus.unverified.rawValue as CKRecordValue
        record["reportCount"] = 0 as CKRecordValue
        
        // Add metadata fields
        record["temperature"] = 75.0 as CKRecordValue
        record["humidity"] = 85.0 as CKRecordValue
        record["windSpeed"] = 5.0 as CKRecordValue
        record["windDirection"] = 180 as CKRecordValue
        record["waterTemperature"] = 72.0 as CKRecordValue
        record["dissolvedOxygen"] = 2.5 as CKRecordValue
        record["salinity"] = 28.0 as CKRecordValue
        record["tide"] = TideState.rising.rawValue as CKRecordValue
        record["moonPhase"] = MoonPhase.full.rawValue as CKRecordValue
        
        return record
    }
    
    private func createMockUserReportRecord(eventId: UUID) -> CKRecord {
        let record = CKRecord(recordType: CloudKitService.RecordType.userReport.rawValue)
        record["jubileeEventId"] = eventId.uuidString as CKRecordValue
        record["userId"] = UUID().uuidString as CKRecordValue
        record["timestamp"] = Date() as CKRecordValue
        record["description"] = "Test report" as CKRecordValue
        record["intensity"] = JubileeIntensity.moderate.rawValue as CKRecordValue
        record["location"] = CLLocation(latitude: 30.4672, longitude: -87.9833)
        return record
    }
}

// MARK: - Mock Classes

class MockCKContainer: CKContainer {
    let publicDatabase: CKDatabase
    let privateDatabase: CKDatabase
    
    init(publicDatabase: CKDatabase, privateDatabase: CKDatabase) {
        self.publicDatabase = publicDatabase
        self.privateDatabase = privateDatabase
        super.init(identifier: "iCloud.com.jubileemobilebay.app")
    }
    
    override func database(with databaseScope: CKDatabase.Scope) -> CKDatabase {
        switch databaseScope {
        case .public:
            return publicDatabase
        case .private:
            return privateDatabase
        case .shared:
            fatalError("Shared database not implemented in mock")
        @unknown default:
            fatalError("Unknown database scope")
        }
    }
}

class MockCKDatabase: CKDatabase {
    var savedRecords: [CKRecord] = []
    var performedQueries: [CKQuery] = []
    var savedSubscriptions: [CKSubscription] = []
    
    var saveResult: Result<CKRecord, Error> = .success(CKRecord(recordType: "Mock"))
    var queryResult: Result<[CKRecord], Error> = .success([])
    var saveSubscriptionResult: Result<CKSubscription, Error> = .success(CKQuerySubscription(recordType: "Mock", predicate: NSPredicate(value: true)))
    
    override func save(_ record: CKRecord, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
        savedRecords.append(record)
        switch saveResult {
        case .success(let mockRecord):
            completionHandler(mockRecord, nil)
        case .failure(let error):
            completionHandler(nil, error)
        }
    }
    
    override func perform(_ query: CKQuery, inZoneWith zoneID: CKRecordZone.ID?, completionHandler: @escaping ([CKRecord]?, Error?) -> Void) {
        performedQueries.append(query)
        switch queryResult {
        case .success(let records):
            completionHandler(records, nil)
        case .failure(let error):
            completionHandler(nil, error)
        }
    }
    
    override func save(_ subscription: CKSubscription, completionHandler: @escaping (CKSubscription?, Error?) -> Void) {
        savedSubscriptions.append(subscription)
        switch saveSubscriptionResult {
        case .success(let mockSubscription):
            completionHandler(mockSubscription, nil)
        case .failure(let error):
            completionHandler(nil, error)
        }
    }
}