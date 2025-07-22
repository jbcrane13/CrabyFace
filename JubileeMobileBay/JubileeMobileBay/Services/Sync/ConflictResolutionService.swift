//
//  ConflictResolutionService.swift
//  JubileeMobileBay
//
//  Handles conflict detection and resolution for sync operations
//

import Foundation
import CoreData
import CloudKit
import Combine

@MainActor
class ConflictResolutionService: ObservableObject {
    
    // MARK: - Properties
    
    @Published var resolutionStrategy: ConflictResolutionStrategy = .mostRecent
    private let coreDataStack: CoreDataStack
    
    // MARK: - Initialization
    
    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - Public Methods
    
    func setResolutionStrategy(_ strategy: ConflictResolutionStrategy) {
        resolutionStrategy = strategy
    }
    
    func detectConflict(local: JubileeReport, remote: JubileeReport) -> Bool {
        // Check if UUIDs match (they should for conflict detection)
        guard local.uuid == remote.uuid else { return false }
        
        // Check for differences in key fields
        if hasSpeciesConflict(local: local, remote: remote) { return true }
        if hasLocationConflict(local: local, remote: remote) { return true }
        if hasIntensityConflict(local: local, remote: remote) { return true }
        if hasEnvironmentalDataConflict(local: local, remote: remote) { return true }
        if hasNotesConflict(local: local, remote: remote) { return true }
        if hasTimestampConflict(local: local, remote: remote) { return true }
        
        return false
    }
    
    func resolveConflict(
        entity: SyncableEntity,
        localVersion: Any,
        remoteVersion: Any
    ) async throws -> ConflictResolution {
        guard let localReport = localVersion as? JubileeReport,
              let remoteReport = remoteVersion as? JubileeReport else {
            throw ConflictResolutionError.invalidEntityType
        }
        
        let resolution = try await performResolution(
            local: localReport,
            remote: remoteReport,
            strategy: resolutionStrategy
        )
        
        // Record conflict in history
        try await recordConflictHistory(
            entityUUID: localReport.uuid ?? UUID().uuidString,
            resolution: resolution,
            strategy: resolutionStrategy
        )
        
        return resolution
    }
    
    func resolveConflictWithBase(
        entity: SyncableEntity,
        localVersion: Any,
        remoteVersion: Any,
        baseVersion: Any
    ) async throws -> ConflictResolution {
        guard let localReport = localVersion as? JubileeReport,
              let remoteReport = remoteVersion as? JubileeReport,
              let baseReport = baseVersion as? JubileeReport else {
            throw ConflictResolutionError.invalidEntityType
        }
        
        return try await performThreeWayMerge(
            local: localReport,
            remote: remoteReport,
            base: baseReport
        )
    }
    
    func getConflictHistory(for entityUUID: String) async throws -> [ConflictHistoryEntry] {
        let context = coreDataStack.newBackgroundContext()
        
        return try await context.perform {
            let fetchRequest = ConflictHistoryEntry.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "entityUUID == %@", entityUUID)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "occurredAt", ascending: false)]
            
            return try context.fetch(fetchRequest)
        }
    }
    
    func getPendingManualResolutions() async throws -> [JubileeReport] {
        let context = coreDataStack.viewContext
        let fetchRequest = JubileeReport.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "conflictResolutionNeeded == YES")
        
        return try await context.perform {
            try context.fetch(fetchRequest)
        }
    }
    
    // MARK: - Private Resolution Methods
    
    private func performResolution(
        local: JubileeReport,
        remote: JubileeReport,
        strategy: ConflictResolutionStrategy
    ) async throws -> ConflictResolution {
        switch strategy {
        case .serverWins:
            return .useRemote
            
        case .clientWins:
            return .useLocal
            
        case .mostRecent:
            let localDate = local.lastModified ?? Date.distantPast
            let remoteDate = remote.lastModified ?? Date.distantPast
            return localDate > remoteDate ? .useLocal : .useRemote
            
        case .fieldLevelMerge:
            return try await performFieldLevelMerge(local: local, remote: remote)
            
        case .threeWayMerge:
            // For two-way merge, treat local as base
            return try await performThreeWayMerge(local: local, remote: remote, base: local)
            
        case .manual:
            local.markAsConflict()
            return .manual
        }
    }
    
    private func performFieldLevelMerge(
        local: JubileeReport,
        remote: JubileeReport
    ) async throws -> ConflictResolution {
        let context = coreDataStack.newBackgroundContext()
        
        return try await context.perform {
            let mergedReport = JubileeReport(context: context)
            mergedReport.uuid = local.uuid
            
            // Merge fields based on most recent modification for each field
            let localDate = local.lastModified ?? Date.distantPast
            let remoteDate = remote.lastModified ?? Date.distantPast
            
            // Use newer timestamp for each field's decision
            if localDate >= remoteDate {
                mergedReport.speciesArray = local.speciesArray
                mergedReport.intensity = local.intensity
                mergedReport.notes = local.notes
                mergedReport.locationCoordinate = local.locationCoordinate
                mergedReport.environmentalConditionsDict = local.environmentalConditionsDict
            } else {
                mergedReport.speciesArray = remote.speciesArray
                mergedReport.intensity = remote.intensity
                mergedReport.notes = remote.notes
                mergedReport.locationCoordinate = remote.locationCoordinate
                mergedReport.environmentalConditionsDict = remote.environmentalConditionsDict
            }
            
            // Always use the most recent timestamp and metadata
            mergedReport.timestamp = max(local.timestamp ?? Date.distantPast,
                                       remote.timestamp ?? Date.distantPast)
            mergedReport.lastModified = max(localDate, remoteDate)
            
            // Sync metadata
            mergedReport.recordID = local.recordID ?? remote.recordID
            mergedReport.changeTag = remote.changeTag
            mergedReport.syncStatusEnum = .synced
            mergedReport.conflictResolutionNeeded = false
            
            return .merge(merged: mergedReport)
        }
    }
    
    private func performThreeWayMerge(
        local: JubileeReport,
        remote: JubileeReport,
        base: JubileeReport
    ) async throws -> ConflictResolution {
        let context = coreDataStack.newBackgroundContext()
        
        return try await context.perform {
            let mergedReport = JubileeReport(context: context)
            mergedReport.uuid = local.uuid
            
            // Species merge: combine unique species from both versions
            let baseSpecies = Set(base.speciesArray)
            let localSpecies = Set(local.speciesArray)
            let remoteSpecies = Set(remote.speciesArray)
            
            let localChanges = localSpecies.subtracting(baseSpecies)
            let remoteChanges = remoteSpecies.subtracting(baseSpecies)
            let combinedSpecies = baseSpecies.union(localChanges).union(remoteChanges)
            mergedReport.speciesArray = Array(combinedSpecies)
            
            // For other fields, use the changed version if only one side changed
            mergedReport.intensity = self.resolveFieldValue(
                base: base.intensity,
                local: local.intensity,
                remote: remote.intensity
            ) ?? base.intensity
            
            mergedReport.notes = self.resolveFieldValue(
                base: base.notes,
                local: local.notes,
                remote: remote.notes
            ) ?? base.notes
            
            // Location: if both changed, use most recent
            if !self.locationsEqual(base.locationCoordinate, local.locationCoordinate) &&
               !self.locationsEqual(base.locationCoordinate, remote.locationCoordinate) {
                let localDate = local.lastModified ?? Date.distantPast
                let remoteDate = remote.lastModified ?? Date.distantPast
                mergedReport.locationCoordinate = localDate > remoteDate ? local.locationCoordinate : remote.locationCoordinate
            } else if !self.locationsEqual(base.locationCoordinate, local.locationCoordinate) {
                mergedReport.locationCoordinate = local.locationCoordinate
            } else if !self.locationsEqual(base.locationCoordinate, remote.locationCoordinate) {
                mergedReport.locationCoordinate = remote.locationCoordinate
            } else {
                mergedReport.locationCoordinate = base.locationCoordinate
            }
            
            // Environmental data: merge non-conflicting changes
            let mergedConditions = self.mergeEnvironmentalConditions(
                base: base.environmentalConditionsDict,
                local: local.environmentalConditionsDict,
                remote: remote.environmentalConditionsDict
            )
            mergedReport.environmentalConditionsDict = mergedConditions
            
            // Timestamps: use most recent
            mergedReport.timestamp = max(local.timestamp ?? Date.distantPast,
                                       remote.timestamp ?? Date.distantPast,
                                       base.timestamp ?? Date.distantPast)
            mergedReport.lastModified = Date()
            
            // Sync metadata
            mergedReport.recordID = local.recordID ?? remote.recordID
            mergedReport.changeTag = remote.changeTag
            mergedReport.syncStatusEnum = .synced
            mergedReport.conflictResolutionNeeded = false
            
            return .merge(merged: mergedReport)
        }
    }
    
    // MARK: - Conflict Detection Helpers
    
    private func hasSpeciesConflict(local: JubileeReport, remote: JubileeReport) -> Bool {
        return Set(local.speciesArray) != Set(remote.speciesArray)
    }
    
    private func hasLocationConflict(local: JubileeReport, remote: JubileeReport) -> Bool {
        return !locationsEqual(local.locationCoordinate, remote.locationCoordinate)
    }
    
    private func hasIntensityConflict(local: JubileeReport, remote: JubileeReport) -> Bool {
        return local.intensity != remote.intensity
    }
    
    private func hasEnvironmentalDataConflict(local: JubileeReport, remote: JubileeReport) -> Bool {
        return local.environmentalConditionsDict != remote.environmentalConditionsDict
    }
    
    private func hasNotesConflict(local: JubileeReport, remote: JubileeReport) -> Bool {
        return local.notes != remote.notes
    }
    
    private func hasTimestampConflict(local: JubileeReport, remote: JubileeReport) -> Bool {
        let threshold: TimeInterval = 60.0 // 1 minute tolerance
        guard let localTime = local.timestamp,
              let remoteTime = remote.timestamp else { return false }
        
        return abs(localTime.timeIntervalSince(remoteTime)) > threshold
    }
    
    // MARK: - Helper Methods
    
    private func locationsEqual(_ coord1: CLLocationCoordinate2D?, _ coord2: CLLocationCoordinate2D?) -> Bool {
        guard let coord1 = coord1, let coord2 = coord2 else {
            return coord1 == nil && coord2 == nil
        }
        
        let tolerance = 0.0001 // ~10 meters
        return abs(coord1.latitude - coord2.latitude) < tolerance &&
               abs(coord1.longitude - coord2.longitude) < tolerance
    }
    
    private func resolveFieldValue<T: Equatable>(base: T?, local: T?, remote: T?) -> T? {
        if local != base && remote == base {
            return local // Only local changed
        } else if remote != base && local == base {
            return remote // Only remote changed
        } else if local == remote {
            return local // Both changed to same value
        } else {
            return nil // Conflict - both changed to different values
        }
    }
    
    private func mergeEnvironmentalConditions(
        base: [String: Double],
        local: [String: Double],
        remote: [String: Double]
    ) -> [String: Double] {
        var merged = base
        
        for (key, value) in local {
            let baseValue = base[key]
            let remoteValue = remote[key]
            
            if baseValue != value && remoteValue == baseValue {
                merged[key] = value // Only local changed
            }
        }
        
        for (key, value) in remote {
            let baseValue = base[key]
            let localValue = local[key]
            
            if baseValue != value && localValue == baseValue {
                merged[key] = value // Only remote changed
            }
        }
        
        return merged
    }
    
    private func recordConflictHistory(
        entityUUID: String,
        resolution: ConflictResolution,
        strategy: ConflictResolutionStrategy
    ) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            let historyEntry = ConflictHistoryEntry(context: context)
            historyEntry.entityUUID = entityUUID
            historyEntry.occurredAt = Date()
            historyEntry.resolvedAt = Date()
            historyEntry.resolutionStrategy = strategy.rawValue
            historyEntry.resolutionType = resolution.description
            
            if context.hasChanges {
                try context.save()
            }
        }
    }
}


// MARK: - Extensions

extension ConflictResolution: Equatable {
    public static func == (lhs: ConflictResolution, rhs: ConflictResolution) -> Bool {
        switch (lhs, rhs) {
        case (.useLocal, .useLocal), (.useRemote, .useRemote), (.manual, .manual):
            return true
        case (.merge(let merged1), .merge(let merged2)):
            return merged1.isEqual(merged2)
        default:
            return false
        }
    }
}

extension ConflictResolution {
    var description: String {
        switch self {
        case .useLocal: return "use_local"
        case .useRemote: return "use_remote"
        case .merge: return "merge"
        case .manual: return "manual"
        }
    }
}

// MARK: - Conflict Resolution Error

enum ConflictResolutionError: LocalizedError {
    case invalidEntityType
    case resolutionFailed
    case manualResolutionRequired
    
    var errorDescription: String? {
        switch self {
        case .invalidEntityType:
            return "Invalid entity type for conflict resolution"
        case .resolutionFailed:
            return "Conflict resolution failed"
        case .manualResolutionRequired:
            return "Manual resolution required for this conflict"
        }
    }
}