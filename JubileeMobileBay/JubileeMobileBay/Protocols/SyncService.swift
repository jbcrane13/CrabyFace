//
//  SyncService.swift
//  JubileeMobileBay
//
//  Protocol defining synchronization service capabilities
//

import Foundation
import CoreData
import CloudKit

@MainActor
protocol SyncService {
    // Core sync operations
    func syncPendingChanges() async throws -> SyncResult
    func scheduleBackgroundSync()
    func cancelPendingSync()
    
    // Conflict resolution
    func resolveConflict(for entity: SyncableEntity, localVersion: Any, remoteVersion: Any) async throws -> ConflictResolution
    func getPendingConflicts() async throws -> [SyncableEntity]
    
    // Sync status
    var isSyncing: Bool { get }
    var lastSyncDate: Date? { get }
    var syncProgress: Progress { get }
    
    // Sync configuration
    var syncBatchSize: Int { get set }
    var syncPriority: SyncPriority { get set }
}

// MARK: - Sync Priority

enum SyncPriority {
    case low
    case normal
    case high
    case userInitiated
    
    var qualityOfService: QualityOfService {
        switch self {
        case .low:
            return .background
        case .normal:
            return .utility
        case .high:
            return .userInitiated
        case .userInitiated:
            return .userInteractive
        }
    }
}

// MARK: - Sync Direction

enum SyncDirection {
    case upload
    case download
    case bidirectional
}

// MARK: - Sync Options

struct SyncOptions {
    var direction: SyncDirection = .bidirectional
    var batchSize: Int = 50
    var includeDeleted: Bool = false
    var conflictResolution: ConflictResolutionStrategy = .serverWins
    var retryAttempts: Int = 3
    var timeout: TimeInterval = 30.0
}

// MARK: - Conflict Resolution Strategy

public enum ConflictResolutionStrategy: String, CaseIterable {
    case serverWins = "server_wins"
    case clientWins = "client_wins"
    case mostRecent = "most_recent"
    case fieldLevelMerge = "field_level_merge"
    case threeWayMerge = "three_way_merge"
    case manual = "manual"
    
    public var displayName: String {
        switch self {
        case .serverWins: return "Server Wins"
        case .clientWins: return "Client Wins"
        case .mostRecent: return "Most Recent Wins"
        case .fieldLevelMerge: return "Field-Level Merge"
        case .threeWayMerge: return "Three-Way Merge"
        case .manual: return "Manual Resolution"
        }
    }
    
    public var description: String {
        switch self {
        case .serverWins: return "Always use the server version"
        case .clientWins: return "Always use the local version"
        case .mostRecent: return "Use the version with the most recent timestamp"
        case .fieldLevelMerge: return "Merge individual fields based on recency"
        case .threeWayMerge: return "Intelligent merge using common ancestor"
        case .manual: return "Require manual user intervention"
        }
    }
}

// MARK: - Sync Notification Names

extension Notification.Name {
    static let syncDidStart = Notification.Name("syncDidStart")
    static let syncDidComplete = Notification.Name("syncDidComplete")
    static let syncDidFail = Notification.Name("syncDidFail")
    static let syncProgressDidUpdate = Notification.Name("syncProgressDidUpdate")
    static let syncConflictDetected = Notification.Name("syncConflictDetected")
}