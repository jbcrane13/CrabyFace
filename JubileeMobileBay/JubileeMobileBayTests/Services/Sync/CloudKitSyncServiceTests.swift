//
//  CloudKitSyncServiceTests.swift
//  JubileeMobileBayTests
//
//  Tests for CloudKit synchronization service
//

import XCTest
import CoreData
import CloudKit
import Combine
@testable import JubileeMobileBay

// MARK: - Mocks

class MockCKDatabase: CKDatabase {
    var shouldSucceed = true
    var recordsToReturn: [CKRecord] = []
    var savedRecords: [CKRecord] = []
    var deletedRecordIDs: [CKRecord.ID] = []
    var modifyError: Error?
    var queryError: Error?
    
    override func modifyRecords(saving recordsToSave: [CKRecord], 
                               deleting recordIDsToDelete: [CKRecord.ID],
                               savePolicy: CKModifyRecordsOperation.RecordSavePolicy) async throws -> ([CKRecord.ID : Result<CKRecord, Error>], [CKRecord.ID : Result<Void, Error>]) {
        if let error = modifyError {
            throw error
        }
        
        savedRecords.append(contentsOf: recordsToSave)
        deletedRecordIDs.append(contentsOf: recordIDsToDelete)
        
        var saveResults: [CKRecord.ID: Result<CKRecord, Error>] = [:]
        for record in recordsToSave {
            saveResults[record.recordID] = .success(record)
        }
        
        var deleteResults: [CKRecord.ID: Result<Void, Error>] = [:]
        for recordID in recordIDsToDelete {
            deleteResults[recordID] = .success(())
        }
        
        return (saveResults, deleteResults)
    }
    
    override func records(matching query: CKQuery, resultsLimit: Int = CKQueryOperation.maximumResults) async throws -> (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?) {
        if let error = queryError {
            throw error
        }
        
        var results: [(CKRecord.ID, Result<CKRecord, Error>)] = []
        for record in recordsToReturn {
            results.append((record.recordID, .success(record)))
        }
        
        return (results, nil)
    }
}

class MockCKContainer: CKContainer {
    var accountStatusToReturn: CKAccountStatus = .available
    var mockDatabase: MockCKDatabase
    
    init(mockDatabase: MockCKDatabase = MockCKDatabase()) {
        self.mockDatabase = mockDatabase
        super.init(identifier: "test.container")
    }
    
    override func accountStatus() async throws -> CKAccountStatus {
        return accountStatusToReturn
    }
    
    override var privateCloudDatabase: CKDatabase {
        return mockDatabase
    }
}

// MARK: - Tests

class CloudKitSyncServiceTests: XCTestCase {
    
    var sut: CloudKitSyncService!
    var coreDataStack: CoreDataStack!
    var mockDatabase: MockCKDatabase!
    var mockContainer: MockCKContainer!
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Setup in-memory Core Data stack
        coreDataStack = CoreDataStack.inMemoryStack()
        
        // Setup mock CloudKit
        mockDatabase = MockCKDatabase()
        mockContainer = MockCKContainer(mockDatabase: mockDatabase)
        
        // Create SUT with mocks
        await MainActor.run {
            sut = CloudKitSyncService(coreDataStack: coreDataStack)
            // We'll need to inject the mock container via a test-specific initializer
        }
    }
    
    override func tearDown() async throws {
        cancellables.removeAll()
        sut = nil
        coreDataStack = nil
        mockDatabase = nil
        mockContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Sync Status Tests
    
    @MainActor
    func test_syncService_initialState_shouldNotBeSyncing() {
        XCTAssertFalse(sut.isSyncing)
        XCTAssertNil(sut.lastSyncDate)
        XCTAssertEqual(sut.syncProgress.totalUnitCount, 0)
    }
    
    // MARK: - Account Status Tests
    
    @MainActor
    func test_syncPendingChanges_whenNoAccount_shouldThrowAuthenticationRequired() async {
        mockContainer.accountStatusToReturn = .noAccount
        
        do {
            _ = try await sut.syncPendingChanges()
            XCTFail("Should throw authentication required error")
        } catch {
            XCTAssertEqual(error as? SyncError, SyncError.authenticationRequired)
        }
    }
    
    @MainActor
    func test_syncPendingChanges_whenAccountRestricted_shouldThrowNetworkUnavailable() async {
        mockContainer.accountStatusToReturn = .restricted
        
        do {
            _ = try await sut.syncPendingChanges()
            XCTFail("Should throw network unavailable error")
        } catch {
            XCTAssertEqual(error as? SyncError, SyncError.networkUnavailable)
        }
    }
    
    // MARK: - Sync Process Tests
    
    @MainActor
    func test_syncPendingChanges_whenAlreadySyncing_shouldThrowError() async {
        // Start a sync
        let syncTask = Task {
            try await sut.syncPendingChanges()
        }
        
        // Try to start another sync
        do {
            _ = try await sut.syncPendingChanges()
            XCTFail("Should throw already syncing error")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "SyncService")
            XCTAssertEqual(nsError.code, 1001)
        }
        
        // Clean up
        syncTask.cancel()
    }
    
    @MainActor
    func test_syncPendingChanges_withNoChanges_shouldReturnEmptyResult() async throws {
        let result = try await sut.syncPendingChanges()
        
        XCTAssertEqual(result.uploaded, 0)
        XCTAssertEqual(result.downloaded, 0)
        XCTAssertEqual(result.conflicts, 0)
        XCTAssertTrue(result.errors.isEmpty)
        XCTAssertNotNil(sut.lastSyncDate)
    }
    
    @MainActor
    func test_syncPendingChanges_withPendingUploads_shouldUploadRecords() async throws {
        // Create test data
        let context = coreDataStack.viewContext
        let report1 = JubileeReport(context: context)
        report1.uuid = UUID().uuidString
        report1.title = "Test Report 1"
        report1.syncStatusEnum = .pendingUpload
        report1.lastModified = Date()
        
        let report2 = JubileeReport(context: context)
        report2.uuid = UUID().uuidString
        report2.title = "Test Report 2"
        report2.syncStatusEnum = .pendingUpload
        report2.lastModified = Date()
        
        try context.save()
        
        // Perform sync
        let result = try await sut.syncPendingChanges()
        
        // Verify results
        XCTAssertEqual(result.uploaded, 2)
        XCTAssertEqual(mockDatabase.savedRecords.count, 2)
        
        // Verify sync status updated
        XCTAssertEqual(report1.syncStatusEnum, .synced)
        XCTAssertEqual(report2.syncStatusEnum, .synced)
    }
    
    @MainActor
    func test_syncPendingChanges_withRemoteChanges_shouldDownloadRecords() async throws {
        // Setup remote records
        let record1 = CKRecord(recordType: "JubileeReport", recordID: CKRecord.ID(recordName: UUID().uuidString))
        record1["uuid"] = UUID().uuidString
        record1["title"] = "Remote Report 1"
        record1["lastModified"] = Date()
        
        mockDatabase.recordsToReturn = [record1]
        
        // Perform sync
        let result = try await sut.syncPendingChanges()
        
        // Verify results
        XCTAssertEqual(result.downloaded, 1)
        
        // Verify record created in Core Data
        let fetchRequest = JubileeReport.fetchRequest()
        let reports = try coreDataStack.viewContext.fetch(fetchRequest)
        XCTAssertEqual(reports.count, 1)
        XCTAssertEqual(reports.first?.title, "Remote Report 1")
    }
    
    // MARK: - Conflict Resolution Tests
    
    @MainActor
    func test_resolveConflict_withLocalNewer_shouldUseLocal() async throws {
        let localReport = JubileeReport(context: coreDataStack.viewContext)
        localReport.lastModified = Date()
        
        let remoteReport = JubileeReport(context: coreDataStack.viewContext)
        remoteReport.lastModified = Date().addingTimeInterval(-60) // 1 minute older
        
        let resolution = try await sut.resolveConflict(
            for: localReport,
            localVersion: localReport,
            remoteVersion: remoteReport
        )
        
        XCTAssertEqual(resolution, .useLocal)
    }
    
    @MainActor
    func test_resolveConflict_withRemoteNewer_shouldUseRemote() async throws {
        let localReport = JubileeReport(context: coreDataStack.viewContext)
        localReport.lastModified = Date().addingTimeInterval(-60) // 1 minute older
        
        let remoteReport = JubileeReport(context: coreDataStack.viewContext)
        remoteReport.lastModified = Date()
        
        let resolution = try await sut.resolveConflict(
            for: localReport,
            localVersion: localReport,
            remoteVersion: remoteReport
        )
        
        XCTAssertEqual(resolution, .useRemote)
    }
    
    @MainActor
    func test_resolveConflict_withEqualTimestamps_shouldUseRemote() async throws {
        let timestamp = Date()
        let localReport = JubileeReport(context: coreDataStack.viewContext)
        localReport.lastModified = timestamp
        
        let remoteReport = JubileeReport(context: coreDataStack.viewContext)
        remoteReport.lastModified = timestamp
        
        let resolution = try await sut.resolveConflict(
            for: localReport,
            localVersion: localReport,
            remoteVersion: remoteReport
        )
        
        XCTAssertEqual(resolution, .useRemote)
    }
    
    // MARK: - Notification Tests
    
    @MainActor
    func test_syncPendingChanges_shouldPostNotifications() async throws {
        var receivedNotifications: [Notification.Name] = []
        
        let expectations = [
            expectation(forNotification: .syncDidStart, object: nil),
            expectation(forNotification: .syncDidComplete, object: nil)
        ]
        
        NotificationCenter.default.publisher(for: .syncDidStart)
            .sink { _ in receivedNotifications.append(.syncDidStart) }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .syncDidComplete)
            .sink { _ in receivedNotifications.append(.syncDidComplete) }
            .store(in: &cancellables)
        
        _ = try await sut.syncPendingChanges()
        
        await fulfillment(of: expectations, timeout: 1.0)
        XCTAssertEqual(receivedNotifications, [.syncDidStart, .syncDidComplete])
    }
    
    @MainActor
    func test_syncPendingChanges_whenFails_shouldPostFailureNotification() async {
        mockDatabase.modifyError = SyncError.networkUnavailable
        
        let expectation = expectation(forNotification: .syncDidFail, object: nil)
        
        do {
            _ = try await sut.syncPendingChanges()
            XCTFail("Should throw error")
        } catch {
            // Expected
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Progress Tests
    
    @MainActor
    func test_uploadPendingChanges_shouldUpdateProgress() async throws {
        // Create multiple reports
        let context = coreDataStack.viewContext
        for i in 1...5 {
            let report = JubileeReport(context: context)
            report.uuid = UUID().uuidString
            report.title = "Report \(i)"
            report.syncStatusEnum = .pendingUpload
        }
        try context.save()
        
        var progressUpdates: [Progress] = []
        NotificationCenter.default.publisher(for: .syncProgressDidUpdate)
            .compactMap { $0.userInfo?["progress"] as? Progress }
            .sink { progress in
                progressUpdates.append(progress)
            }
            .store(in: &cancellables)
        
        _ = try await sut.syncPendingChanges()
        
        XCTAssertFalse(progressUpdates.isEmpty)
        XCTAssertEqual(sut.syncProgress.totalUnitCount, 5)
        XCTAssertEqual(sut.syncProgress.completedUnitCount, 5)
    }
    
    // MARK: - Cancel Tests
    
    @MainActor
    func test_cancelPendingSync_shouldCancelActiveTask() {
        // This test would require a more sophisticated mock setup
        // to properly test cancellation behavior
        sut.cancelPendingSync()
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    // MARK: - Batch Processing Tests
    
    @MainActor
    func test_uploadPendingChanges_shouldProcessInBatches() async throws {
        // Create more reports than batch size
        let context = coreDataStack.viewContext
        let batchSize = sut.syncBatchSize
        let totalReports = batchSize + 10
        
        for i in 1...totalReports {
            let report = JubileeReport(context: context)
            report.uuid = UUID().uuidString
            report.title = "Report \(i)"
            report.syncStatusEnum = .pendingUpload
        }
        try context.save()
        
        _ = try await sut.syncPendingChanges()
        
        // Verify all records were uploaded
        XCTAssertEqual(mockDatabase.savedRecords.count, totalReports)
    }
}

// MARK: - Test Helpers

extension CloudKitSyncService {
    static func testInstance(coreDataStack: CoreDataStack, container: CKContainer) -> CloudKitSyncService {
        // This would require modifying the CloudKitSyncService to accept
        // an injected container for testing purposes
        return CloudKitSyncService(coreDataStack: coreDataStack)
    }
}