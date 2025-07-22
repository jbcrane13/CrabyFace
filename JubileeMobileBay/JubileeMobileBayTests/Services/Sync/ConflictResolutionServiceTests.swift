//
//  ConflictResolutionServiceTests.swift
//  JubileeMobileBayTests
//
//  Tests for conflict detection and resolution in sync operations
//

import XCTest
import CoreData
@testable import JubileeMobileBay

class ConflictResolutionServiceTests: XCTestCase {
    
    var sut: ConflictResolutionService!
    var mockCoreDataStack: MockCoreDataStack!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        mockCoreDataStack = MockCoreDataStack()
        context = mockCoreDataStack.viewContext
        sut = ConflictResolutionService(coreDataStack: mockCoreDataStack)
    }
    
    override func tearDown() {
        sut = nil
        mockCoreDataStack = nil
        context = nil
        super.tearDown()
    }
    
    // MARK: - Conflict Detection Tests
    
    func test_detectConflicts_withIdenticalRecords_shouldReturnNoConflicts() throws {
        // Given
        let localReport = createJubileeReport(
            uuid: "test-uuid",
            timestamp: Date(),
            species: ["Aurelia aurita"],
            lastModified: Date()
        )
        
        let remoteReport = createJubileeReport(
            uuid: "test-uuid",
            timestamp: localReport.timestamp!,
            species: ["Aurelia aurita"],
            lastModified: localReport.lastModified!
        )
        
        // When
        let hasConflict = sut.detectConflict(local: localReport, remote: remoteReport)
        
        // Then
        XCTAssertFalse(hasConflict)
    }
    
    func test_detectConflicts_withDifferentSpecies_shouldReturnConflict() throws {
        // Given
        let baseDate = Date()
        let localReport = createJubileeReport(
            uuid: "test-uuid",
            timestamp: baseDate,
            species: ["Aurelia aurita"],
            lastModified: baseDate
        )
        
        let remoteReport = createJubileeReport(
            uuid: "test-uuid",
            timestamp: baseDate,
            species: ["Chrysaora quinquecirrha"],
            lastModified: baseDate
        )
        
        // When
        let hasConflict = sut.detectConflict(local: localReport, remote: remoteReport)
        
        // Then
        XCTAssertTrue(hasConflict)
    }
    
    func test_detectConflicts_withDifferentEnvironmentalData_shouldReturnConflict() throws {
        // Given
        let baseDate = Date()
        let localReport = createJubileeReport(
            uuid: "test-uuid",
            timestamp: baseDate,
            species: ["Aurelia aurita"],
            lastModified: baseDate
        )
        localReport.environmentalConditionsDict = ["temperature": 22.5, "salinity": 35.0]
        
        let remoteReport = createJubileeReport(
            uuid: "test-uuid",
            timestamp: baseDate,
            species: ["Aurelia aurita"],
            lastModified: baseDate
        )
        remoteReport.environmentalConditionsDict = ["temperature": 23.0, "salinity": 34.5]
        
        // When
        let hasConflict = sut.detectConflict(local: localReport, remote: remoteReport)
        
        // Then
        XCTAssertTrue(hasConflict)
    }
    
    // MARK: - Resolution Strategy Tests
    
    func test_resolveConflict_withServerWinsStrategy_shouldUseRemoteData() async throws {
        // Given
        sut.resolutionStrategy = .serverWins
        let localReport = createJubileeReport(
            uuid: "test-uuid",
            species: ["Local Species"],
            lastModified: Date()
        )
        let remoteReport = createJubileeReport(
            uuid: "test-uuid",
            species: ["Remote Species"],
            lastModified: Date()
        )
        
        // When
        let resolution = try await sut.resolveConflict(
            entity: localReport,
            localVersion: localReport,
            remoteVersion: remoteReport
        )
        
        // Then
        XCTAssertEqual(resolution, .useRemote)
    }
    
    func test_resolveConflict_withClientWinsStrategy_shouldUseLocalData() async throws {
        // Given
        sut.resolutionStrategy = .clientWins
        let localReport = createJubileeReport(
            uuid: "test-uuid",
            species: ["Local Species"],
            lastModified: Date()
        )
        let remoteReport = createJubileeReport(
            uuid: "test-uuid",
            species: ["Remote Species"],
            lastModified: Date()
        )
        
        // When
        let resolution = try await sut.resolveConflict(
            entity: localReport,
            localVersion: localReport,
            remoteVersion: remoteReport
        )
        
        // Then
        XCTAssertEqual(resolution, .useLocal)
    }
    
    func test_resolveConflict_withMostRecentWinsStrategy_shouldUseNewerData() async throws {
        // Given
        sut.resolutionStrategy = .mostRecentWins
        let olderDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let newerDate = Date()
        
        let localReport = createJubileeReport(
            uuid: "test-uuid",
            species: ["Local Species"],
            lastModified: olderDate
        )
        let remoteReport = createJubileeReport(
            uuid: "test-uuid",
            species: ["Remote Species"],
            lastModified: newerDate
        )
        
        // When
        let resolution = try await sut.resolveConflict(
            entity: localReport,
            localVersion: localReport,
            remoteVersion: remoteReport
        )
        
        // Then
        XCTAssertEqual(resolution, .useRemote)
    }
    
    func test_resolveConflict_withFieldLevelMergeStrategy_shouldMergeFields() async throws {
        // Given
        sut.resolutionStrategy = .fieldLevelMerge
        let olderDate = Date().addingTimeInterval(-3600)
        let newerDate = Date()
        
        let localReport = createJubileeReport(
            uuid: "test-uuid",
            species: ["Local Species"],
            intensity: "High",
            notes: "Local notes",
            lastModified: newerDate
        )
        localReport.temperature = 22.5
        
        let remoteReport = createJubileeReport(
            uuid: "test-uuid",
            species: ["Remote Species"],
            intensity: "Medium",
            notes: "Remote notes",
            lastModified: olderDate
        )
        remoteReport.temperature = 23.0
        
        // When
        let resolution = try await sut.resolveConflict(
            entity: localReport,
            localVersion: localReport,
            remoteVersion: remoteReport
        )
        
        // Then
        switch resolution {
        case .merge(let merged):
            let mergedReport = merged as! JubileeReport
            // Should take newer field values
            XCTAssertEqual(mergedReport.speciesArray, ["Local Species"])
            XCTAssertEqual(mergedReport.intensity, "High")
            XCTAssertEqual(mergedReport.notes, "Local notes")
            XCTAssertEqual(mergedReport.temperature, 22.5)
        default:
            XCTFail("Expected merge resolution")
        }
    }
    
    // MARK: - Conflict History Tests
    
    func test_conflictHistory_shouldBeTracked() async throws {
        // Given
        let localReport = createJubileeReport(
            uuid: "test-uuid",
            species: ["Local Species"],
            lastModified: Date()
        )
        let remoteReport = createJubileeReport(
            uuid: "test-uuid",
            species: ["Remote Species"],
            lastModified: Date()
        )
        
        // When
        _ = try await sut.resolveConflict(
            entity: localReport,
            localVersion: localReport,
            remoteVersion: remoteReport
        )
        
        let history = try await sut.getConflictHistory(for: "test-uuid")
        
        // Then
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.entityUUID, "test-uuid")
        XCTAssertNotNil(history.first?.resolvedAt)
    }
    
    // MARK: - Three-Way Merge Tests
    
    func test_threeWayMerge_shouldResolveComplexConflicts() async throws {
        // Given
        sut.resolutionStrategy = .threeWayMerge
        
        // Base version (common ancestor)
        let baseReport = createJubileeReport(
            uuid: "test-uuid",
            species: ["Original Species"],
            intensity: "Medium",
            notes: "Original notes"
        )
        baseReport.temperature = 20.0
        
        // Local changes: updated species and temperature
        let localReport = createJubileeReport(
            uuid: "test-uuid",
            species: ["Original Species", "New Local Species"],
            intensity: "Medium",
            notes: "Original notes"
        )
        localReport.temperature = 22.0
        
        // Remote changes: updated intensity and notes
        let remoteReport = createJubileeReport(
            uuid: "test-uuid",
            species: ["Original Species"],
            intensity: "High",
            notes: "Updated remote notes"
        )
        remoteReport.temperature = 20.0
        
        // When
        let resolution = try await sut.resolveConflictWithBase(
            entity: localReport,
            localVersion: localReport,
            remoteVersion: remoteReport,
            baseVersion: baseReport
        )
        
        // Then
        switch resolution {
        case .merge(let merged):
            let mergedReport = merged as! JubileeReport
            // Should combine non-conflicting changes
            XCTAssertEqual(mergedReport.speciesArray, ["Original Species", "New Local Species"])
            XCTAssertEqual(mergedReport.intensity, "High")
            XCTAssertEqual(mergedReport.notes, "Updated remote notes")
            XCTAssertEqual(mergedReport.temperature, 22.0)
        default:
            XCTFail("Expected merge resolution")
        }
    }
    
    // MARK: - Manual Resolution Tests
    
    func test_manualResolution_shouldRequireUserIntervention() async throws {
        // Given
        sut.resolutionStrategy = .manual
        let localReport = createJubileeReport(uuid: "test-uuid")
        let remoteReport = createJubileeReport(uuid: "test-uuid")
        
        // When
        let resolution = try await sut.resolveConflict(
            entity: localReport,
            localVersion: localReport,
            remoteVersion: remoteReport
        )
        
        // Then
        XCTAssertEqual(resolution, .manual)
        XCTAssertTrue(localReport.conflictResolutionNeeded)
    }
    
    // MARK: - Helper Methods
    
    private func createJubileeReport(
        uuid: String = UUID().uuidString,
        timestamp: Date = Date(),
        species: [String] = [],
        intensity: String = "Medium",
        notes: String? = nil,
        lastModified: Date = Date()
    ) -> JubileeReport {
        let report = JubileeReport(context: context)
        report.uuid = uuid
        report.timestamp = timestamp
        report.speciesArray = species
        report.intensity = intensity
        report.notes = notes
        report.lastModified = lastModified
        report.syncStatusEnum = .synced
        return report
    }
}

// MARK: - Mock Core Data Stack

class MockCoreDataStack: CoreDataStack {
    override init() {
        super.init()
        // Use in-memory store for testing
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
    }
}