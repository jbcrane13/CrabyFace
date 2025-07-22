//
//  BackgroundSyncService.swift
//  JubileeMobileBay
//
//  Handles background sync operations using iOS Background Tasks
//

import Foundation
import BackgroundTasks
import CoreData
import Combine
import UIKit

@MainActor
class BackgroundSyncService: ObservableObject {
    
    // MARK: - Constants
    
    static let appRefreshTaskIdentifier = "com.jubileemobilebay.sync.refresh"
    static let processingTaskIdentifier = "com.jubileemobilebay.sync.processing"
    
    // MARK: - Properties
    
    @Published var isBackgroundSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBackgroundSyncEnabled, forKey: "BackgroundSyncEnabled")
            if isBackgroundSyncEnabled {
                scheduleNextSync()
            }
        }
    }
    
    @Published var lastBackgroundSyncDate: Date? {
        didSet {
            if let date = lastBackgroundSyncDate {
                UserDefaults.standard.set(date, forKey: "LastBackgroundSyncDate")
            }
        }
    }
    
    @Published var backgroundSyncInterval: TimeInterval {
        didSet {
            UserDefaults.standard.set(backgroundSyncInterval, forKey: "BackgroundSyncInterval")
        }
    }
    
    private let syncManager = SyncManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Priority queue for sync operations
    private var syncPriorityQueue = SyncPriorityQueue()
    
    // Battery and network monitoring
    private let batteryMonitor = BatteryMonitor()
    private let networkMonitor = BackgroundSyncNetworkMonitor()
    
    // MARK: - Initialization
    
    init() {
        // Load settings from UserDefaults
        self.isBackgroundSyncEnabled = UserDefaults.standard.bool(forKey: "BackgroundSyncEnabled")
        self.lastBackgroundSyncDate = UserDefaults.standard.object(forKey: "LastBackgroundSyncDate") as? Date
        
        // Default to 6 hours if not set
        let savedInterval = UserDefaults.standard.double(forKey: "BackgroundSyncInterval")
        self.backgroundSyncInterval = savedInterval > 0 ? savedInterval : 21600 // 6 hours
        
        setupNotifications()
    }
    
    // MARK: - Public Methods
    
    func registerBackgroundTasks() {
        // Register app refresh task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.appRefreshTaskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleAppRefreshTask(task as! BGAppRefreshTask)
        }
        
        // Register processing task for longer operations
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.processingTaskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleProcessingTask(task as! BGProcessingTask)
        }
    }
    
    func scheduleNextSync() {
        guard isBackgroundSyncEnabled else { return }
        
        // Schedule app refresh task
        let request = BGAppRefreshTaskRequest(identifier: Self.appRefreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: backgroundSyncInterval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background sync scheduled for \(request.earliestBeginDate!)")
        } catch {
            print("Failed to schedule background sync: \(error)")
        }
    }
    
    func scheduleProcessingTask(for items: [SyncableEntity]) {
        guard isBackgroundSyncEnabled else { return }
        guard items.count > 50 else { return } // Only use processing task for large batches
        
        let request = BGProcessingTaskRequest(identifier: Self.processingTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = items.count > 200 // Require power for very large syncs
        
        // Schedule for low-usage time (e.g., overnight)
        let calendar = Calendar.current
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()),
           let tomorrowAt2AM = calendar.date(bySettingHour: 2, minute: 0, second: 0, of: tomorrow) {
            request.earliestBeginDate = tomorrowAt2AM
        }
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Processing task scheduled for large sync")
        } catch {
            print("Failed to schedule processing task: \(error)")
        }
    }
    
    func addToSyncQueue(_ items: [SyncableEntity], priority: SyncPriority = .normal) {
        for item in items {
            syncPriorityQueue.enqueue(item, priority: priority)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleAppRefreshTask(_ task: BGAppRefreshTask) {
        // Schedule next sync immediately
        scheduleNextSync()
        
        // Create a task to track sync completion
        let syncTask = Task { @MainActor in
            do {
                // Check battery and network conditions
                guard shouldPerformBackgroundSync() else {
                    task.setTaskCompleted(success: true)
                    return
                }
                
                // Perform quick sync of high-priority items
                let highPriorityItems = syncPriorityQueue.dequeue(count: 20, priority: .high)
                if !highPriorityItems.isEmpty {
                    try await performBackgroundSync(for: highPriorityItems)
                }
                
                lastBackgroundSyncDate = Date()
                task.setTaskCompleted(success: true)
                
            } catch {
                print("Background sync failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
        
        // Handle task expiration
        task.expirationHandler = {
            syncTask.cancel()
            // Clean up any ongoing operations
            self.syncManager.cancelPendingSync()
        }
    }
    
    private func handleProcessingTask(_ task: BGProcessingTask) {
        // Create a longer-running task for bulk sync
        let processingTask = Task { @MainActor in
            do {
                // Check conditions
                guard shouldPerformBackgroundSync() else {
                    task.setTaskCompleted(success: true)
                    return
                }
                
                // Sync all pending items in priority order
                var syncedCount = 0
                let maxItems = 500 // Limit to prevent excessive processing
                
                while syncedCount < maxItems && !Task.isCancelled {
                    let batch = syncPriorityQueue.dequeueBatch(count: 50)
                    if batch.isEmpty { break }
                    
                    try await performBackgroundSync(for: batch)
                    syncedCount += batch.count
                    
                    // Update progress
                    task.setTaskCompleted(success: false) // Keep task alive
                }
                
                lastBackgroundSyncDate = Date()
                task.setTaskCompleted(success: true)
                
            } catch {
                print("Processing task failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
        
        // Handle task expiration
        task.expirationHandler = {
            processingTask.cancel()
            self.syncManager.cancelPendingSync()
        }
    }
    
    private func performBackgroundSync(for items: [SyncableEntity]) async throws {
        // Update sync status for items
        let context = CoreDataStack.shared.newBackgroundContext()
        
        try await context.perform {
            for item in items {
                let objectID = item.objectID
                if let object = try? context.existingObject(with: objectID) as? JubileeReport {
                    object.syncStatusEnum = .pendingUpload
                }
            }
            
            if context.hasChanges {
                try context.save()
            }
        }
        
        // Trigger sync through SyncManager
        await syncManager.syncNow()
    }
    
    private func shouldPerformBackgroundSync() -> Bool {
        // Check battery level
        if batteryMonitor.batteryLevel < 0.2 && !batteryMonitor.isCharging {
            print("Skipping background sync: Low battery")
            return false
        }
        
        // Check network conditions
        guard networkMonitor.isConnected else {
            print("Skipping background sync: No network")
            return false
        }
        
        // Skip if on cellular and user hasn't allowed it
        if networkMonitor.isExpensive && !UserDefaults.standard.bool(forKey: "AllowCellularSync") {
            print("Skipping background sync: Cellular data disabled")
            return false
        }
        
        return true
    }
    
    private func setupNotifications() {
        // Listen for app lifecycle events
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.scheduleNextSync()
            }
            .store(in: &cancellables)
        
        // Listen for significant time changes
        NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)
            .sink { [weak self] _ in
                self?.evaluateSyncNeed()
            }
            .store(in: &cancellables)
    }
    
    private func evaluateSyncNeed() {
        guard let lastSync = lastBackgroundSyncDate else {
            scheduleNextSync()
            return
        }
        
        let timeSinceLastSync = Date().timeIntervalSince(lastSync)
        if timeSinceLastSync > backgroundSyncInterval {
            // Overdue for sync, schedule immediately
            let request = BGAppRefreshTaskRequest(identifier: Self.appRefreshTaskIdentifier)
            request.earliestBeginDate = Date(timeIntervalSinceNow: 60) // 1 minute
            
            try? BGTaskScheduler.shared.submit(request)
        }
    }
}

// MARK: - Sync Priority Queue

struct SyncPriorityQueue {
    private var highPriorityQueue: [SyncableEntity] = []
    private var normalPriorityQueue: [SyncableEntity] = []
    private var lowPriorityQueue: [SyncableEntity] = []
    private let lock = NSLock()
    
    mutating func enqueue(_ entity: SyncableEntity, priority: SyncPriority) {
        lock.lock()
        defer { lock.unlock() }
        
        switch priority {
        case .high, .userInitiated:
            highPriorityQueue.append(entity)
        case .normal:
            normalPriorityQueue.append(entity)
        case .low:
            lowPriorityQueue.append(entity)
        }
    }
    
    mutating func dequeue(count: Int, priority: SyncPriority) -> [SyncableEntity] {
        lock.lock()
        defer { lock.unlock() }
        
        switch priority {
        case .high, .userInitiated:
            return Array(highPriorityQueue.prefix(count))
        case .normal:
            return Array(normalPriorityQueue.prefix(count))
        case .low:
            return Array(lowPriorityQueue.prefix(count))
        }
    }
    
    mutating func dequeueBatch(count: Int) -> [SyncableEntity] {
        lock.lock()
        defer { lock.unlock() }
        
        var batch: [SyncableEntity] = []
        var remaining = count
        
        // Take from high priority first
        let highCount = min(remaining, highPriorityQueue.count)
        if highCount > 0 {
            batch.append(contentsOf: highPriorityQueue.prefix(highCount))
            highPriorityQueue.removeFirst(highCount)
            remaining -= highCount
        }
        
        // Then normal priority
        let normalCount = min(remaining, normalPriorityQueue.count)
        if normalCount > 0 {
            batch.append(contentsOf: normalPriorityQueue.prefix(normalCount))
            normalPriorityQueue.removeFirst(normalCount)
            remaining -= normalCount
        }
        
        // Finally low priority
        let lowCount = min(remaining, lowPriorityQueue.count)
        if lowCount > 0 {
            batch.append(contentsOf: lowPriorityQueue.prefix(lowCount))
            lowPriorityQueue.removeFirst(lowCount)
        }
        
        return batch
    }
    
    var totalCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return highPriorityQueue.count + normalPriorityQueue.count + lowPriorityQueue.count
    }
}

// MARK: - Battery Monitor

class BatteryMonitor {
    var batteryLevel: Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryLevel
    }
    
    var isCharging: Bool {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
    }
    
    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
}

// MARK: - Background Sync Network Monitor

@MainActor
class BackgroundSyncNetworkMonitor {
    var isConnected: Bool {
        // This would use the Network framework's NWPathMonitor
        // For now, we'll use the SyncManager's network status
        return SyncManager.shared.networkStatus != .disconnected
    }
    
    var isExpensive: Bool {
        return SyncManager.shared.networkStatus == .cellular
    }
}