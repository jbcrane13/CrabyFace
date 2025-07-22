//
//  SyncManager.swift
//  JubileeMobileBay
//
//  Manages synchronization operations and coordinates between services
//

import Foundation
import CoreData
import Combine
import Network

@MainActor
class SyncManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = SyncManager()
    
    // MARK: - Published Properties
    
    @Published var syncState: SyncState = .idle
    @Published var lastSyncResult: SyncResult?
    @Published var networkStatus: NetworkStatus = .unknown
    @Published var pendingChangesCount: Int = 0
    
    // MARK: - Properties
    
    private var syncService: SyncService!
    private let coreDataStack: CoreDataStack
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.jubileemobilebay.network")
    
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Auto-sync settings
    var isAutoSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "AutoSyncEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "AutoSyncEnabled") }
    }
    
    var autoSyncInterval: TimeInterval {
        get { UserDefaults.standard.double(forKey: "AutoSyncInterval") }
        set { UserDefaults.standard.set(newValue, forKey: "AutoSyncInterval") }
    }
    
    // MARK: - Initialization
    
    private init(syncService: SyncService? = nil,
                 coreDataStack: CoreDataStack = .shared) {
        // Initialize sync service if not provided
        if let syncService = syncService {
            self.syncService = syncService
        } else {
            self.syncService = CloudKitSyncService()
        }
        self.coreDataStack = coreDataStack
        
        // Set default auto-sync interval if not set
        if autoSyncInterval == 0 {
            autoSyncInterval = 300 // 5 minutes
        }
        
        setupNetworkMonitoring()
        setupNotifications()
        updatePendingChangesCount()
        
        // Start auto-sync if enabled
        if isAutoSyncEnabled {
            startAutoSync()
        }
    }
    
    // MARK: - Public Methods
    
    func syncNow() async {
        guard networkStatus == .connected else {
            syncState = .failed(SyncError.networkUnavailable)
            return
        }
        
        guard syncState != .syncing else { return }
        
        syncState = .syncing
        
        do {
            let result = try await syncService.syncPendingChanges()
            lastSyncResult = result
            
            if result.hasErrors {
                syncState = .partialSuccess(result)
            } else {
                syncState = .success(result)
            }
            
            await updatePendingChangesCount()
            
        } catch {
            syncState = .failed(error)
        }
    }
    
    func startAutoSync() {
        stopAutoSync()
        
        guard isAutoSyncEnabled else { return }
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: autoSyncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.syncIfNeeded()
            }
        }
    }
    
    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    func resolveConflicts() async throws -> Int {
        let conflicts = try await syncService.getPendingConflicts()
        var resolved = 0
        
        for conflict in conflicts {
            // For now, use automatic resolution
            // In subtask 3.4, we'll implement UI for manual resolution
            let resolution = try await syncService.resolveConflict(
                for: conflict,
                localVersion: conflict,
                remoteVersion: conflict
            )
            
            switch resolution {
            case .useLocal, .useRemote:
                conflict.resolveConflict()
                resolved += 1
            case .merge, .manual:
                // Will be implemented in subtask 3.4
                break
            }
        }
        
        return resolved
    }
    
    func cancelPendingSync() {
        // Cancel any pending sync operations
        syncState = .idle
        // If there's a current sync operation, it will need to handle cancellation
        // For now, we just reset the state
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.updateNetworkStatus(path)
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    private func updateNetworkStatus(_ path: NWPath) {
        switch path.status {
        case .satisfied:
            networkStatus = path.isExpensive ? .cellular : .wifi
        case .unsatisfied:
            networkStatus = .disconnected
        case .requiresConnection:
            networkStatus = .disconnected
        @unknown default:
            networkStatus = .unknown
        }
        
        // Trigger sync when network becomes available
        if networkStatus == .wifi || (networkStatus == .cellular && allowsCellularSync) {
            Task {
                await syncIfNeeded()
            }
        }
    }
    
    private func setupNotifications() {
        // Listen for Core Data changes
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.updatePendingChangesCount()
                }
            }
            .store(in: &cancellables)
        
        // Listen for sync events
        NotificationCenter.default.publisher(for: .syncDidComplete)
            .sink { [weak self] notification in
                if let result = notification.userInfo?["result"] as? SyncResult {
                    Task { @MainActor [weak self] in
                        self?.lastSyncResult = result
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func updatePendingChangesCount() {
        let context = coreDataStack.viewContext
        let fetchRequest = JubileeReport.fetchRequestForSync()
        
        do {
            pendingChangesCount = try context.count(for: fetchRequest)
        } catch {
            print("Error counting pending changes: \(error)")
            pendingChangesCount = 0
        }
    }
    
    private func syncIfNeeded() async {
        guard pendingChangesCount > 0 else { return }
        guard networkStatus == .connected || networkStatus == .wifi || networkStatus == .cellular else { return }
        guard syncState != .syncing else { return }
        
        await syncNow()
    }
    
    private var allowsCellularSync: Bool {
        UserDefaults.standard.bool(forKey: "AllowCellularSync")
    }
}

// MARK: - Sync State

enum SyncState: Equatable {
    case idle
    case syncing
    case success(SyncResult)
    case partialSuccess(SyncResult)
    case failed(Error)
    
    static func == (lhs: SyncState, rhs: SyncState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.syncing, .syncing):
            return true
        case (.success(let lhsResult), .success(let rhsResult)),
             (.partialSuccess(let lhsResult), .partialSuccess(let rhsResult)):
            return lhsResult.uploaded == rhsResult.uploaded &&
                   lhsResult.downloaded == rhsResult.downloaded
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
    
    var isActive: Bool {
        if case .syncing = self {
            return true
        }
        return false
    }
    
    var hasError: Bool {
        if case .failed = self {
            return true
        }
        return false
    }
}

// MARK: - Network Status

enum NetworkStatus {
    case unknown
    case disconnected
    case connected
    case wifi
    case cellular
}