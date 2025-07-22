//
//  CloudKitSyncService.swift
//  JubileeMobileBay
//
//  CloudKit implementation of the SyncService protocol
//

import Foundation
import CoreData
import CloudKit
import Combine

@MainActor
class CloudKitSyncService: ObservableObject, SyncService {
    
    // MARK: - Properties
    
    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var syncProgress = Progress()
    
    var syncBatchSize: Int = 50
    var syncPriority: SyncPriority = .normal
    
    private let coreDataStack: CoreDataStack
    private let cloudKitContainer: CKContainer
    private let privateDatabase: CKDatabase
    private let conflictResolutionService: ConflictResolutionService
    
    private var syncQueue = DispatchQueue(label: "com.jubileemobilebay.sync", qos: .utility)
    private var activeSyncTask: Task<Void, Error>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(coreDataStack: CoreDataStack = .shared,
         containerIdentifier: String = "iCloud.com.jubileemobilebay.app",
         conflictResolutionService: ConflictResolutionService? = nil) {
        self.coreDataStack = coreDataStack
        self.cloudKitContainer = CKContainer(identifier: containerIdentifier)
        self.privateDatabase = cloudKitContainer.privateCloudDatabase
        self.conflictResolutionService = conflictResolutionService ?? ConflictResolutionService(coreDataStack: coreDataStack)
        
        loadLastSyncDate()
        setupNotifications()
    }
    
    // MARK: - SyncService Implementation
    
    func syncPendingChanges() async throws -> SyncResult {
        guard !isSyncing else {
            throw SyncError.alreadySyncing
        }
        
        await MainActor.run {
            isSyncing = true
        }
        
        NotificationCenter.default.post(name: .syncDidStart, object: nil)
        
        do {
            // Check CloudKit availability
            try await verifyCloudKitAvailability()
            
            // Perform sync operations
            let uploadResult = try await uploadPendingChanges()
            let downloadResult = try await downloadRemoteChanges()
            let conflicts = try await detectAndResolveConflicts()
            
            let syncResult = SyncResult(
                uploaded: uploadResult.uploaded,
                downloaded: downloadResult.downloaded,
                conflicts: conflicts.count,
                errors: uploadResult.errors + downloadResult.errors
            )
            
            // Update last sync date
            await MainActor.run {
                lastSyncDate = Date()
                saveLastSyncDate()
            }
            
            NotificationCenter.default.post(
                name: .syncDidComplete,
                object: nil,
                userInfo: ["result": syncResult]
            )
            
            return syncResult
            
        } catch {
            await MainActor.run {
                isSyncing = false
            }
            NotificationCenter.default.post(
                name: .syncDidFail,
                object: nil,
                userInfo: ["error": error]
            )
            throw error
        }
    }
    
    func scheduleBackgroundSync() {
        // This will be implemented in subtask 3.3
        print("Background sync scheduling will be implemented in subtask 3.3")
    }
    
    func cancelPendingSync() {
        activeSyncTask?.cancel()
        activeSyncTask = nil
    }
    
    func resolveConflict(for entity: SyncableEntity, localVersion: Any, remoteVersion: Any) async throws -> ConflictResolution {
        return try await conflictResolutionService.resolveConflict(
            entity: entity,
            localVersion: localVersion,
            remoteVersion: remoteVersion
        )
    }
    
    func getPendingConflicts() async throws -> [SyncableEntity] {
        let context = coreDataStack.viewContext
        let fetchRequest = JubileeReport.fetchRequestForConflicts()
        
        return try await context.perform {
            try context.fetch(fetchRequest)
        }
    }
    
    // MARK: - Private Methods
    
    private func verifyCloudKitAvailability() async throws {
        let accountStatus = try await cloudKitContainer.accountStatus()
        
        switch accountStatus {
        case .available:
            break
        case .noAccount:
            throw SyncError.authenticationRequired
        case .restricted, .couldNotDetermine:
            throw SyncError.networkUnavailable
        @unknown default:
            throw SyncError.unknown(NSError(domain: "CloudKit", code: -1))
        }
    }
    
    private func uploadPendingChanges() async throws -> (uploaded: Int, errors: [Error]) {
        let context = coreDataStack.newBackgroundContext()
        var uploaded = 0
        var errors: [Error] = []
        
        // Fetch reports that need uploading
        let reports = try await context.perform {
            let fetchRequest = JubileeReport.fetchRequestForSync()
            fetchRequest.predicate = NSPredicate(format: "syncStatus == %@", SyncStatus.pendingUpload.rawValue)
            fetchRequest.fetchBatchSize = self.syncBatchSize
            return try context.fetch(fetchRequest)
        }
        
        let totalCount = reports.count
        self.syncProgress.totalUnitCount = Int64(totalCount)
        self.syncProgress.completedUnitCount = 0
        
        // Process in batches
        for batch in reports.chunked(into: self.syncBatchSize) {
            do {
                let records = batch.map { $0.toCKRecord() }
                
                // Upload to CloudKit
                try await self.privateDatabase.modifyRecords(
                    saving: records,
                    deleting: [],
                    savePolicy: .changedKeys
                )
                
                // Update sync status in Core Data
                try await context.perform {
                    for (index, report) in batch.enumerated() {
                        report.syncStatusEnum = .synced
                        if index < records.count {
                            report.changeTag = records[index].recordChangeTag
                        }
                    }
                }
                
                uploaded += batch.count
                self.syncProgress.completedUnitCount = Int64(uploaded)
                
                // Post progress notification
                NotificationCenter.default.post(
                    name: .syncProgressDidUpdate,
                    object: nil,
                    userInfo: ["progress": self.syncProgress]
                )
                
            } catch {
                errors.append(error)
                // Mark records as having sync errors
                try? await context.perform {
                    for report in batch {
                        report.syncStatusEnum = .error
                    }
                }
            }
        }
        
        // Save context
        try await context.perform {
            if context.hasChanges {
                try context.save()
            }
        }
        
        return (uploaded, errors)
    }
    
    private func downloadRemoteChanges() async throws -> (downloaded: Int, errors: [Error]) {
        let context = coreDataStack.newBackgroundContext()
        var downloaded = 0
        var errors: [Error] = []
        
        // Create query for recent changes
        let predicate = NSPredicate(format: "lastModified > %@", (lastSyncDate ?? Date.distantPast) as NSDate)
        let query = CKQuery(recordType: "JubileeReport", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false)]
        
        // Perform query
        do {
            let queryOperation = CKQueryOperation(query: query)
            queryOperation.resultsLimit = syncBatchSize
            queryOperation.qualityOfService = syncPriority.qualityOfService
            
            var fetchedRecords: [CKRecord] = []
            
            let (matchResults, queryCursor) = try await privateDatabase.records(
                matching: query,
                resultsLimit: syncBatchSize
            )
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    fetchedRecords.append(record)
                case .failure(let error):
                    errors.append(error)
                }
            }
            
            // Process fetched records
            downloaded = try await processDownloadedRecords(fetchedRecords, in: context)
            
            // Handle pagination if needed
            if let cursor = queryCursor {
                // Continue fetching in next sync cycle
                print("More records available, will fetch in next sync")
            }
            
        } catch {
            errors.append(error)
        }
        
        return (downloaded, errors)
    }
    
    private func processDownloadedRecords(_ records: [CKRecord], in context: NSManagedObjectContext) async throws -> Int {
        var processed = 0
        
        return try await context.perform {
            for record in records {
                guard let uuid = record["uuid"] as? String else { continue }
                
                // Check if record exists locally
                let fetchRequest = JubileeReport.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "uuid == %@", uuid)
                fetchRequest.fetchLimit = 1
                
                let existingReports = try context.fetch(fetchRequest)
                
                if let existingReport = existingReports.first {
                    // Update existing record
                    existingReport.updateFromCKRecord(record)
                } else {
                    // Create new record
                    let newReport = JubileeReport(context: context)
                    newReport.updateFromCKRecord(record)
                }
                
                processed += 1
            }
            
            // Save context
            if context.hasChanges {
                try context.save()
            }
            
            return processed
        }
    }
    
    private func detectAndResolveConflicts() async throws -> [SyncableEntity] {
        let context = coreDataStack.newBackgroundContext()
        var resolvedConflicts: [SyncableEntity] = []
        
        // First, fetch conflicted reports
        let conflictedReports = try await context.perform {
            let fetchRequest = JubileeReport.fetchRequestForConflicts()
            return try context.fetch(fetchRequest)
        }
        
        // Then process each conflict outside the perform block
        for localReport in conflictedReports {
            // Fetch the remote version from CloudKit
            if let recordID = localReport.recordID {
                do {
                    let ckRecordID = CKRecord.ID(recordName: recordID)
                    let remoteRecord = try await self.privateDatabase.record(for: ckRecordID)
                    
                    // Create a temporary report from the remote record
                    let remoteReport = try await context.perform {
                        let report = JubileeReport(context: context)
                        report.updateFromCKRecord(remoteRecord)
                        return report
                    }
                    
                    // Detect if there's actually a conflict
                    let hasConflict = await self.conflictResolutionService.detectConflict(
                        local: localReport,
                        remote: remoteReport
                    )
                    
                    if hasConflict {
                        // Resolve the conflict
                        let resolution = try await self.conflictResolutionService.resolveConflict(
                            entity: localReport,
                            localVersion: localReport,
                            remoteVersion: remoteReport
                        )
                        
                        // Apply the resolution
                        try await self.applyResolution(resolution, to: localReport, from: remoteReport, in: context)
                        resolvedConflicts.append(localReport)
                    } else {
                        // No conflict, just mark as resolved
                        try await context.perform {
                            localReport.resolveConflict()
                        }
                    }
                    
                    // Clean up temporary report
                    try await context.perform {
                        context.delete(remoteReport)
                    }
                    
                } catch {
                    print("Failed to resolve conflict for record \(recordID): \(error)")
                    // Keep the conflict flag for manual resolution
                    try? await context.perform {
                        localReport.conflictResolutionNeeded = true
                    }
                }
            }
        }
        
        // Save changes
        try await context.perform {
            if context.hasChanges {
                try context.save()
            }
        }
        
        return resolvedConflicts
    }
    
    private func applyResolution(_ resolution: ConflictResolution, to localReport: JubileeReport, from remoteReport: JubileeReport, in context: NSManagedObjectContext) async throws {
        switch resolution {
        case .useLocal:
            // Keep local version, mark as resolved
            localReport.resolveConflict()
            localReport.markForSync() // Sync local changes back to server
            
        case .useRemote:
            // Update local with remote data
            localReport.updateFromCKRecord(remoteReport.toCKRecord())
            localReport.resolveConflict()
            
        case .merge(let merged):
            // Apply merged data to local report
            if let mergedReport = merged as? JubileeReport {
                localReport.speciesArray = mergedReport.speciesArray
                localReport.intensity = mergedReport.intensity
                localReport.notes = mergedReport.notes
                localReport.locationCoordinate = mergedReport.locationCoordinate
                localReport.environmentalConditionsDict = mergedReport.environmentalConditionsDict
                localReport.timestamp = mergedReport.timestamp
                localReport.lastModified = Date()
                localReport.resolveConflict()
                localReport.markForSync() // Sync merged changes back to server
            }
            
        case .manual:
            // Leave for manual resolution - don't change conflict flag
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupNotifications() {
        // Listen for Core Data save notifications to trigger sync
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] notification in
                guard let self = self else { return }
                
                // Check if there are changes that need syncing
                if let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>,
                   insertedObjects.contains(where: { $0 is JubileeReport }) {
                    // Schedule sync for new data
                    Task {
                        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 second delay
                        try? await self.syncPendingChanges()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "LastSyncDate") as? Date
    }
    
    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: "LastSyncDate")
    }
}

// MARK: - Array Extension for Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Additional Sync Errors

extension SyncError {
    static let alreadySyncing = SyncError.unknown(NSError(
        domain: "SyncService",
        code: 1001,
        userInfo: [NSLocalizedDescriptionKey: "Sync is already in progress"]
    ))
}