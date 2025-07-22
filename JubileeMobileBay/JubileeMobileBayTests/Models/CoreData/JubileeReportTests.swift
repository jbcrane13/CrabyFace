//
//  JubileeReportTests.swift
//  JubileeMobileBayTests
//
//  Tests for JubileeReport Core Data entity
//

import XCTest
import CoreData
@testable import JubileeMobileBay

class JubileeReportTests: XCTestCase {
    
    var coreDataStack: CoreDataStack!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory Core Data stack for testing
        let model = CoreDataModelBuilder.createModel()
        let container = NSPersistentContainer(name: "TestContainer", managedObjectModel: model)
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }
        
        context = container.viewContext
    }
    
    override func tearDown() {
        context = nil
        coreDataStack = nil
        super.tearDown()
    }
    
    // MARK: - Model Tests
    
    func test_jubileeReport_initialization_shouldSetDefaultValues() {
        // Given
        let report = JubileeReport(context: context)
        
        // When
        report.uuid = UUID().uuidString
        report.timestamp = Date()
        report.syncStatusEnum = .synced
        
        // Then
        XCTAssertNotNil(report.uuid)
        XCTAssertNotNil(report.timestamp)
        XCTAssertEqual(report.syncStatusEnum, .synced)
        XCTAssertFalse(report.conflictResolutionNeeded)
    }
    
    func test_jubileeReport_locationCoordinate_shouldConvertCorrectly() {
        // Given
        let report = JubileeReport(context: context)
        let expectedCoordinate = CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399)
        
        // When
        report.locationCoordinate = expectedCoordinate
        
        // Then
        XCTAssertEqual(report.latitude?.doubleValue, expectedCoordinate.latitude)
        XCTAssertEqual(report.longitude?.doubleValue, expectedCoordinate.longitude)
        XCTAssertEqual(report.locationCoordinate?.latitude, expectedCoordinate.latitude)
        XCTAssertEqual(report.locationCoordinate?.longitude, expectedCoordinate.longitude)
    }
    
    func test_jubileeReport_speciesArray_shouldSerializeCorrectly() {
        // Given
        let report = JubileeReport(context: context)
        let expectedSpecies = ["Blue Crab", "Flounder", "Shrimp"]
        
        // When
        report.speciesArray = expectedSpecies
        
        // Then
        XCTAssertEqual(report.speciesArray, expectedSpecies)
        XCTAssertNotNil(report.species)
    }
    
    func test_jubileeReport_environmentalConditions_shouldSerializeCorrectly() {
        // Given
        let report = JubileeReport(context: context)
        let expectedConditions = [
            "temperature": 75.5,
            "salinity": 15.0,
            "dissolvedOxygen": 5.2
        ]
        
        // When
        report.environmentalConditionsDict = expectedConditions
        
        // Then
        XCTAssertEqual(report.environmentalConditionsDict["temperature"], 75.5)
        XCTAssertEqual(report.environmentalConditionsDict["salinity"], 15.0)
        XCTAssertEqual(report.environmentalConditionsDict["dissolvedOxygen"], 5.2)
    }
    
    // MARK: - Sync Status Tests
    
    func test_markForSync_shouldUpdateSyncStatus() {
        // Given
        let report = JubileeReport(context: context)
        report.syncStatusEnum = .synced
        let beforeDate = Date()
        
        // When
        report.markForSync()
        
        // Then
        XCTAssertEqual(report.syncStatusEnum, .pendingUpload)
        XCTAssertNotNil(report.lastModified)
        XCTAssertTrue(report.lastModified! >= beforeDate)
    }
    
    func test_markAsConflict_shouldSetConflictStatus() {
        // Given
        let report = JubileeReport(context: context)
        
        // When
        report.markAsConflict()
        
        // Then
        XCTAssertEqual(report.syncStatusEnum, .conflict)
        XCTAssertTrue(report.conflictResolutionNeeded)
    }
    
    func test_resolveConflict_shouldClearConflictStatus() {
        // Given
        let report = JubileeReport(context: context)
        report.markAsConflict()
        
        // When
        report.resolveConflict()
        
        // Then
        XCTAssertEqual(report.syncStatusEnum, .synced)
        XCTAssertFalse(report.conflictResolutionNeeded)
    }
    
    // MARK: - Fetch Request Tests
    
    func test_fetchRequestForSync_shouldReturnPendingItems() throws {
        // Given
        createReport(with: .synced)
        createReport(with: .pendingUpload)
        createReport(with: .pendingDownload)
        createReport(with: .conflict)
        
        try context.save()
        
        // When
        let fetchRequest = JubileeReport.fetchRequestForSync()
        let results = try context.fetch(fetchRequest)
        
        // Then
        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { $0.syncStatusEnum != .synced })
    }
    
    func test_fetchRequestForConflicts_shouldReturnConflictedItems() throws {
        // Given
        let normalReport = createReport(with: .synced)
        normalReport.conflictResolutionNeeded = false
        
        let conflictedReport = createReport(with: .conflict)
        conflictedReport.conflictResolutionNeeded = true
        
        try context.save()
        
        // When
        let fetchRequest = JubileeReport.fetchRequestForConflicts()
        let results = try context.fetch(fetchRequest)
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.first!.conflictResolutionNeeded)
    }
    
    // MARK: - Helper Methods
    
    @discardableResult
    private func createReport(with status: SyncStatus) -> JubileeReport {
        let report = JubileeReport(context: context)
        report.uuid = UUID().uuidString
        report.timestamp = Date()
        report.syncStatusEnum = status
        report.lastModified = Date()
        return report
    }
}