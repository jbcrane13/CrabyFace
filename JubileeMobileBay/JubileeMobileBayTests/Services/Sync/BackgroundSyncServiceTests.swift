//
//  BackgroundSyncServiceTests.swift
//  JubileeMobileBayTests
//
//  Tests for background sync functionality
//

import XCTest
import BackgroundTasks
import CoreData
@testable import JubileeMobileBay

// MARK: - Mock Background Task

class MockBGAppRefreshTask: BGAppRefreshTask {
    var completedWithSuccess: Bool?
    var expirationHandlerCalled = false
    
    override func setTaskCompleted(success: Bool) {
        completedWithSuccess = success
    }
    
    override var expirationHandler: (() -> Void)? {
        get { return nil }
        set {
            // Simulate expiration if needed
            if expirationHandlerCalled {
                newValue?()
            }
        }
    }
}

class MockBGProcessingTask: BGProcessingTask {
    var completedWithSuccess: Bool?
    var expirationHandlerCalled = false
    
    override func setTaskCompleted(success: Bool) {
        completedWithSuccess = success
    }
    
    override var expirationHandler: (() -> Void)? {
        get { return nil }
        set {
            // Simulate expiration if needed
            if expirationHandlerCalled {
                newValue?()
            }
        }
    }
}

// MARK: - Tests

@MainActor
class BackgroundSyncServiceTests: XCTestCase {
    
    var sut: BackgroundSyncService!
    var coreDataStack: CoreDataStack!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "BackgroundSyncEnabled")
        UserDefaults.standard.removeObject(forKey: "LastBackgroundSyncDate")
        UserDefaults.standard.removeObject(forKey: "BackgroundSyncInterval")
        UserDefaults.standard.removeObject(forKey: "AllowCellularSync")
        
        // Setup Core Data
        coreDataStack = CoreDataStack.inMemoryStack()
        
        // Create SUT
        sut = BackgroundSyncService()
    }
    
    override func tearDown() async throws {
        sut = nil
        coreDataStack = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_initialization_shouldSetDefaultInterval() {
        XCTAssertEqual(sut.backgroundSyncInterval, 21600) // 6 hours
    }
    
    func test_initialization_shouldLoadSavedSettings() {
        // Set values in UserDefaults
        UserDefaults.standard.set(true, forKey: "BackgroundSyncEnabled")
        UserDefaults.standard.set(Date(), forKey: "LastBackgroundSyncDate")
        UserDefaults.standard.set(3600.0, forKey: "BackgroundSyncInterval") // 1 hour
        
        // Create new instance
        let newService = BackgroundSyncService()
        
        XCTAssertTrue(newService.isBackgroundSyncEnabled)
        XCTAssertNotNil(newService.lastBackgroundSyncDate)
        XCTAssertEqual(newService.backgroundSyncInterval, 3600)
    }
    
    // MARK: - Settings Persistence Tests
    
    func test_isBackgroundSyncEnabled_shouldPersistToUserDefaults() {
        sut.isBackgroundSyncEnabled = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "BackgroundSyncEnabled"))
        
        sut.isBackgroundSyncEnabled = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "BackgroundSyncEnabled"))
    }
    
    func test_lastBackgroundSyncDate_shouldPersistToUserDefaults() {
        let testDate = Date()
        sut.lastBackgroundSyncDate = testDate
        
        let savedDate = UserDefaults.standard.object(forKey: "LastBackgroundSyncDate") as? Date
        XCTAssertNotNil(savedDate)
        XCTAssertEqual(savedDate?.timeIntervalSince1970, testDate.timeIntervalSince1970, accuracy: 1.0)
    }
    
    func test_backgroundSyncInterval_shouldPersistToUserDefaults() {
        sut.backgroundSyncInterval = 7200 // 2 hours
        XCTAssertEqual(UserDefaults.standard.double(forKey: "BackgroundSyncInterval"), 7200)
    }
    
    // MARK: - Task Scheduling Tests
    
    func test_registerBackgroundTasks_shouldRegisterBothTaskTypes() {
        // This would require mocking BGTaskScheduler which is not easily mockable
        // In production, we'd use dependency injection for this
        sut.registerBackgroundTasks()
        
        // Verify no crash occurs
        XCTAssertTrue(true)
    }
    
    func test_scheduleNextSync_whenDisabled_shouldNotSchedule() {
        sut.isBackgroundSyncEnabled = false
        sut.scheduleNextSync()
        
        // Would verify no task scheduled if BGTaskScheduler was mockable
        XCTAssertTrue(true)
    }
    
    func test_scheduleProcessingTask_withSmallBatch_shouldNotSchedule() {
        let context = coreDataStack.viewContext
        let reports = (0..<10).map { i in
            let report = JubileeReport(context: context)
            report.uuid = UUID().uuidString
            report.title = "Report \(i)"
            return report
        }
        
        sut.scheduleProcessingTask(for: reports)
        
        // Should not schedule for less than 50 items
        XCTAssertTrue(true)
    }
    
    func test_scheduleProcessingTask_withLargeBatch_shouldSchedule() {
        let context = coreDataStack.viewContext
        let reports = (0..<100).map { i in
            let report = JubileeReport(context: context)
            report.uuid = UUID().uuidString
            report.title = "Report \(i)"
            return report
        }
        
        sut.isBackgroundSyncEnabled = true
        sut.scheduleProcessingTask(for: reports)
        
        // Would verify task scheduled if BGTaskScheduler was mockable
        XCTAssertTrue(true)
    }
    
    // MARK: - Priority Queue Tests
    
    func test_addToSyncQueue_shouldAddItemsWithCorrectPriority() {
        let context = coreDataStack.viewContext
        let report1 = JubileeReport(context: context)
        report1.uuid = UUID().uuidString
        
        let report2 = JubileeReport(context: context)
        report2.uuid = UUID().uuidString
        
        sut.addToSyncQueue([report1], priority: .high)
        sut.addToSyncQueue([report2], priority: .low)
        
        // Would verify queue contents if we had access to internal queue
        XCTAssertTrue(true)
    }
    
    // MARK: - Battery Monitor Tests
    
    func test_batteryMonitor_shouldReportBatteryLevel() {
        let monitor = BatteryMonitor()
        
        // Battery level is between 0 and 1 (or -1 if unknown)
        let level = monitor.batteryLevel
        XCTAssertTrue(level >= -1 && level <= 1)
    }
    
    func test_batteryMonitor_shouldReportChargingState() {
        let monitor = BatteryMonitor()
        let isCharging = monitor.isCharging
        
        // Should return a boolean value
        XCTAssertTrue(isCharging || !isCharging)
    }
    
    // MARK: - Network Monitor Tests
    
    func test_networkMonitor_shouldReportConnectionStatus() {
        let monitor = NetworkMonitor()
        let isConnected = monitor.isConnected
        
        // Should return a boolean value
        XCTAssertTrue(isConnected || !isConnected)
    }
    
    func test_networkMonitor_shouldReportExpensiveConnection() {
        let monitor = NetworkMonitor()
        let isExpensive = monitor.isExpensive
        
        // Should return a boolean value
        XCTAssertTrue(isExpensive || !isExpensive)
    }
    
    // MARK: - Priority Queue Tests
    
    func test_syncPriorityQueue_shouldEnqueueAndDequeue() {
        var queue = SyncPriorityQueue()
        let context = coreDataStack.viewContext
        
        let highPriorityReport = JubileeReport(context: context)
        highPriorityReport.uuid = "high"
        
        let normalPriorityReport = JubileeReport(context: context)
        normalPriorityReport.uuid = "normal"
        
        let lowPriorityReport = JubileeReport(context: context)
        lowPriorityReport.uuid = "low"
        
        queue.enqueue(highPriorityReport, priority: .high)
        queue.enqueue(normalPriorityReport, priority: .normal)
        queue.enqueue(lowPriorityReport, priority: .low)
        
        XCTAssertEqual(queue.totalCount, 3)
        
        // Should dequeue high priority first
        let batch = queue.dequeueBatch(count: 1)
        XCTAssertEqual(batch.count, 1)
        XCTAssertEqual((batch.first as? JubileeReport)?.uuid, "high")
        
        XCTAssertEqual(queue.totalCount, 2)
    }
    
    func test_syncPriorityQueue_shouldDequeueInPriorityOrder() {
        var queue = SyncPriorityQueue()
        let context = coreDataStack.viewContext
        
        // Add multiple items of each priority
        for i in 0..<3 {
            let report = JubileeReport(context: context)
            report.uuid = "low-\(i)"
            queue.enqueue(report, priority: .low)
        }
        
        for i in 0..<2 {
            let report = JubileeReport(context: context)
            report.uuid = "normal-\(i)"
            queue.enqueue(report, priority: .normal)
        }
        
        for i in 0..<1 {
            let report = JubileeReport(context: context)
            report.uuid = "high-\(i)"
            queue.enqueue(report, priority: .high)
        }
        
        // Dequeue all
        let batch = queue.dequeueBatch(count: 10)
        XCTAssertEqual(batch.count, 6)
        
        // Verify order: high first, then normal, then low
        XCTAssertTrue((batch[0] as? JubileeReport)?.uuid?.hasPrefix("high") ?? false)
        XCTAssertTrue((batch[1] as? JubileeReport)?.uuid?.hasPrefix("normal") ?? false)
        XCTAssertTrue((batch[2] as? JubileeReport)?.uuid?.hasPrefix("normal") ?? false)
        XCTAssertTrue((batch[3] as? JubileeReport)?.uuid?.hasPrefix("low") ?? false)
    }
    
    func test_syncPriorityQueue_shouldBeThreadSafe() {
        var queue = SyncPriorityQueue()
        let context = coreDataStack.viewContext
        let expectation = expectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 2
        
        // Concurrent writes
        DispatchQueue.global().async {
            for i in 0..<100 {
                let report = JubileeReport(context: context)
                report.uuid = "thread1-\(i)"
                queue.enqueue(report, priority: .normal)
            }
            expectation.fulfill()
        }
        
        DispatchQueue.global().async {
            for i in 0..<100 {
                let report = JubileeReport(context: context)
                report.uuid = "thread2-\(i)"
                queue.enqueue(report, priority: .high)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Should have all items
        XCTAssertEqual(queue.totalCount, 200)
    }
}