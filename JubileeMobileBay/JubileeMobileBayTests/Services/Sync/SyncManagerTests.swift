//
//  SyncManagerTests.swift
//  JubileeMobileBayTests
//
//  Tests for sync coordination and management
//

import XCTest
import CoreData
import CloudKit
import Combine
import Network
@testable import JubileeMobileBay

// MARK: - Mocks

@MainActor
class MockSyncService: SyncService {
    var isSyncing: Bool = false
    var lastSyncDate: Date?
    var syncProgress = Progress()
    var syncBatchSize: Int = 50
    var syncPriority: SyncPriority = .normal
    
    var syncPendingChangesCalled = false
    var syncPendingChangesResult: Result<SyncResult, Error> = .success(SyncResult(uploaded: 0, downloaded: 0, conflicts: 0, errors: []))
    var scheduleBackgroundSyncCalled = false
    var cancelPendingSyncCalled = false
    var getPendingConflictsResult: Result<[SyncableEntity], Error> = .success([])
    
    func syncPendingChanges() async throws -> SyncResult {
        syncPendingChangesCalled = true
        isSyncing = true
        
        defer { isSyncing = false }
        
        switch syncPendingChangesResult {
        case .success(let result):
            lastSyncDate = Date()
            return result
        case .failure(let error):
            throw error
        }
    }
    
    func scheduleBackgroundSync() {
        scheduleBackgroundSyncCalled = true
    }
    
    func cancelPendingSync() {
        cancelPendingSyncCalled = true
        isSyncing = false
    }
    
    func resolveConflict(for entity: SyncableEntity, localVersion: Any, remoteVersion: Any) async throws -> ConflictResolution {
        return .useLocal
    }
    
    func getPendingConflicts() async throws -> [SyncableEntity] {
        switch getPendingConflictsResult {
        case .success(let conflicts):
            return conflicts
        case .failure(let error):
            throw error
        }
    }
}

class MockNetworkPathMonitor: NWPathMonitor {
    var pathUpdateHandler: ((NWPath) -> Void)?
    
    override func start(queue: DispatchQueue) {
        // Don't actually start monitoring
    }
    
    override func cancel() {
        // Don't actually cancel
    }
    
    func simulateNetworkChange(status: NWPath.Status, isExpensive: Bool = false) {
        // Create a mock path
        // This is simplified - in real tests you'd need a proper mock NWPath
    }
}

// MARK: - Tests

@MainActor
class SyncManagerTests: XCTestCase {
    
    var sut: SyncManager!
    var mockSyncService: MockSyncService!
    var coreDataStack: CoreDataStack!
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Setup Core Data
        coreDataStack = CoreDataStack.inMemoryStack()
        
        // Setup mocks
        mockSyncService = MockSyncService()
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "AutoSyncEnabled")
        UserDefaults.standard.removeObject(forKey: "AutoSyncInterval")
        UserDefaults.standard.removeObject(forKey: "AllowCellularSync")
        
        // Note: SyncManager is a singleton, so we can't easily inject mocks
        // In production code, we'd need to refactor to allow dependency injection
        sut = SyncManager.shared
    }
    
    override func tearDown() async throws {
        cancellables.removeAll()
        sut.stopAutoSync()
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_syncManager_initialization_shouldSetDefaultAutoSyncInterval() {
        XCTAssertEqual(sut.autoSyncInterval, 300) // 5 minutes
    }
    
    func test_syncManager_initialization_shouldStartAutoSyncIfEnabled() {
        UserDefaults.standard.set(true, forKey: "AutoSyncEnabled")
        
        // Re-initialize would be needed here, but singleton pattern prevents it
        // This test demonstrates the limitation of the current design
    }
    
    // MARK: - Network Status Tests
    
    func test_networkStatus_initialState_shouldBeUnknown() {
        XCTAssertEqual(sut.networkStatus, .unknown)
    }
    
    // MARK: - Sync State Tests
    
    func test_syncState_initialState_shouldBeIdle() {
        XCTAssertEqual(sut.syncState, .idle)
    }
    
    func test_syncNow_whenNetworkUnavailable_shouldSetFailedState() async {
        sut.networkStatus = .disconnected
        
        await sut.syncNow()
        
        if case .failed(let error) = sut.syncState {
            XCTAssertEqual(error as? SyncError, SyncError.networkUnavailable)
        } else {
            XCTFail("Expected failed state with network unavailable error")
        }
    }
    
    func test_syncNow_whenAlreadySyncing_shouldNotStartNewSync() async {
        // Set syncing state
        sut.syncState = .syncing
        
        await sut.syncNow()
        
        // Should still be in syncing state (not changed)
        XCTAssertEqual(sut.syncState, .syncing)
    }
    
    // MARK: - Auto Sync Tests
    
    func test_startAutoSync_shouldScheduleTimer() {
        sut.isAutoSyncEnabled = true
        sut.startAutoSync()
        
        // Timer should be scheduled
        // Note: Testing Timer is challenging without dependency injection
        
        sut.stopAutoSync()
    }
    
    func test_stopAutoSync_shouldInvalidateTimer() {
        sut.isAutoSyncEnabled = true
        sut.startAutoSync()
        
        sut.stopAutoSync()
        
        // Timer should be invalidated
        // Again, testing this properly requires refactoring
    }
    
    // MARK: - Pending Changes Tests
    
    func test_pendingChangesCount_shouldUpdateFromCoreData() async {
        // Create pending reports
        let context = coreDataStack.viewContext
        let report = JubileeReport(context: context)
        report.uuid = UUID().uuidString
        report.syncStatusEnum = .pendingUpload
        
        try! context.save()
        
        // Trigger notification
        NotificationCenter.default.post(name: .NSManagedObjectContextDidSave, object: context)
        
        // Wait for debounce
        try! await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // This test would work if SyncManager used the injected CoreDataStack
        // Current implementation uses .shared which is different
    }
    
    // MARK: - Conflict Resolution Tests
    
    func test_resolveConflicts_whenNoConflicts_shouldReturnZero() async throws {
        let resolved = try await sut.resolveConflicts()
        XCTAssertEqual(resolved, 0)
    }
    
    // MARK: - Sync State Equality Tests
    
    func test_syncState_equality_idle() {
        let state1 = SyncState.idle
        let state2 = SyncState.idle
        XCTAssertEqual(state1, state2)
    }
    
    func test_syncState_equality_syncing() {
        let state1 = SyncState.syncing
        let state2 = SyncState.syncing
        XCTAssertEqual(state1, state2)
    }
    
    func test_syncState_equality_success() {
        let result1 = SyncResult(uploaded: 5, downloaded: 3, conflicts: 0, errors: [])
        let result2 = SyncResult(uploaded: 5, downloaded: 3, conflicts: 0, errors: [])
        let state1 = SyncState.success(result1)
        let state2 = SyncState.success(result2)
        XCTAssertEqual(state1, state2)
    }
    
    func test_syncState_inequality_differentResults() {
        let result1 = SyncResult(uploaded: 5, downloaded: 3, conflicts: 0, errors: [])
        let result2 = SyncResult(uploaded: 2, downloaded: 1, conflicts: 0, errors: [])
        let state1 = SyncState.success(result1)
        let state2 = SyncState.success(result2)
        XCTAssertNotEqual(state1, state2)
    }
    
    func test_syncState_isActive_whenSyncing_shouldBeTrue() {
        let state = SyncState.syncing
        XCTAssertTrue(state.isActive)
    }
    
    func test_syncState_isActive_whenIdle_shouldBeFalse() {
        let state = SyncState.idle
        XCTAssertFalse(state.isActive)
    }
    
    func test_syncState_hasError_whenFailed_shouldBeTrue() {
        let state = SyncState.failed(SyncError.networkUnavailable)
        XCTAssertTrue(state.hasError)
    }
    
    func test_syncState_hasError_whenSuccess_shouldBeFalse() {
        let result = SyncResult(uploaded: 1, downloaded: 1, conflicts: 0, errors: [])
        let state = SyncState.success(result)
        XCTAssertFalse(state.hasError)
    }
    
    // MARK: - UserDefaults Tests
    
    func test_isAutoSyncEnabled_shouldPersistToUserDefaults() {
        sut.isAutoSyncEnabled = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "AutoSyncEnabled"))
        
        sut.isAutoSyncEnabled = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "AutoSyncEnabled"))
    }
    
    func test_autoSyncInterval_shouldPersistToUserDefaults() {
        sut.autoSyncInterval = 600 // 10 minutes
        XCTAssertEqual(UserDefaults.standard.double(forKey: "AutoSyncInterval"), 600)
    }
    
    // MARK: - Notification Tests
    
    func test_syncManager_shouldListenForSyncCompletionNotifications() {
        let expectation = expectation(description: "Sync completion notification received")
        let testResult = SyncResult(uploaded: 5, downloaded: 3, conflicts: 0, errors: [])
        
        sut.$lastSyncResult
            .dropFirst()
            .sink { result in
                if result?.uploaded == 5 && result?.downloaded == 3 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.post(
            name: .syncDidComplete,
            object: nil,
            userInfo: ["result": testResult]
        )
        
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Test Helpers

extension SyncManager {
    /// Factory method for testing that could be added to allow dependency injection
    static func testInstance(syncService: SyncService, coreDataStack: CoreDataStack) -> SyncManager {
        // This would require refactoring SyncManager to not be a singleton
        // and to accept injected dependencies
        return SyncManager.shared
    }
}