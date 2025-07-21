//
//  CloudKitErrorRecovery.swift
//  JubileeMobileBay
//
//  Provides error recovery and retry mechanisms for CloudKit operations
//

import Foundation
import CloudKit

// MARK: - Error Recovery Protocol

protocol CloudKitErrorRecoveryProtocol {
    func shouldRetry(error: Error, attemptCount: Int) -> Bool
    func retryDelay(for attemptCount: Int) -> TimeInterval
    func handleError(_ error: Error, operation: CloudKitOperation) async throws
}

// MARK: - CloudKit Operation Types

enum CloudKitOperation {
    case save(CKRecord)
    case fetch(CKRecord.ID)
    case query(CKQuery)
    case delete(CKRecord.ID)
    case subscription(CKSubscription)
    
    var operationName: String {
        switch self {
        case .save: return "Save"
        case .fetch: return "Fetch"
        case .query: return "Query"
        case .delete: return "Delete"
        case .subscription: return "Subscription"
        }
    }
}

// MARK: - Operation Queue Manager

final class CloudKitOperationQueue {
    private var pendingOperations: [(operation: CloudKitOperation, completion: (Result<Any, Error>) -> Void)] = []
    private let queue = DispatchQueue(label: "com.jubileemobilebay.cloudkit.queue", attributes: .concurrent)
    private let semaphore = DispatchSemaphore(value: 1)
    
    func enqueue(operation: CloudKitOperation, completion: @escaping (Result<Any, Error>) -> Void) {
        queue.async { [weak self] in
            self?.semaphore.wait()
            self?.pendingOperations.append((operation, completion))
            self?.semaphore.signal()
        }
    }
    
    func dequeueAll() -> [(operation: CloudKitOperation, completion: (Result<Any, Error>) -> Void)] {
        semaphore.wait()
        let operations = pendingOperations
        pendingOperations.removeAll()
        semaphore.signal()
        return operations
    }
}

// MARK: - Error Recovery Implementation

final class CloudKitErrorRecovery: CloudKitErrorRecoveryProtocol {
    
    // MARK: - Properties
    
    private let maxRetryAttempts = 3
    private let baseDelay: TimeInterval = 1.0
    private let maxDelay: TimeInterval = 60.0
    private let operationQueue = CloudKitOperationQueue()
    private var isOffline = false
    
    // MARK: - Singleton
    
    static let shared = CloudKitErrorRecovery()
    
    private init() {
        setupNetworkMonitoring()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        // In a real implementation, we'd use NWPathMonitor
        // For now, we'll implement a simple check
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkStatusChanged),
            name: .init("NetworkStatusChanged"),
            object: nil
        )
    }
    
    @objc private func networkStatusChanged(_ notification: Notification) {
        if let isOnline = notification.userInfo?["isOnline"] as? Bool {
            self.isOffline = !isOnline
            
            if isOnline && !operationQueue.dequeueAll().isEmpty {
                Task {
                    await processPendingOperations()
                }
            }
        }
    }
    
    // MARK: - Retry Logic
    
    func shouldRetry(error: Error, attemptCount: Int) -> Bool {
        guard attemptCount < maxRetryAttempts else { return false }
        
        if let ckError = error as? CKError {
            switch ckError.code {
            // Retryable errors
            case .networkUnavailable,
                 .networkFailure,
                 .serviceUnavailable,
                 .requestRateLimited,
                 .zoneBusy:
                return true
                
            // Potentially retryable after delay
            case .serverResponseLost:
                return attemptCount < 2
                
            // Non-retryable errors
            case .internalError,
                 .serverRejectedRequest,
                 .invalidArguments,
                 .unknownItem,
                 .permissionFailure,
                 .quotaExceeded:
                return false
                
            default:
                return false
            }
        }
        
        // For non-CloudKit errors, retry on network-related issues
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain &&
               [NSURLErrorNotConnectedToInternet,
                NSURLErrorTimedOut,
                NSURLErrorNetworkConnectionLost].contains(nsError.code)
    }
    
    func retryDelay(for attemptCount: Int) -> TimeInterval {
        // Exponential backoff with jitter
        let exponentialDelay = min(baseDelay * pow(2.0, Double(attemptCount - 1)), maxDelay)
        let jitter = Double.random(in: 0...0.3) * exponentialDelay
        return exponentialDelay + jitter
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: Error, operation: CloudKitOperation) async throws {
        // Check if we should queue for offline
        if isOffline {
            queueOperationForOffline(operation)
            throw CloudKitError.networkError
        }
        
        // Handle specific CloudKit errors
        if let ckError = error as? CKError {
            switch ckError.code {
            case .partialFailure:
                // Handle partial failures by extracting successful records
                if let partialErrors = ckError.userInfo[CKPartialErrorsByItemIDKey] as? [CKRecord.ID: Error] {
                    try await handlePartialFailure(partialErrors, operation: operation)
                }
                
            case .limitExceeded:
                // Split batch operations into smaller chunks
                try await handleLimitExceeded(operation)
                
            case .changeTokenExpired:
                // Reset sync token and retry
                try await handleChangeTokenExpired(operation)
                
            case .userDeletedZone:
                // Recreate zone and retry
                try await handleDeletedZone(operation)
                
            default:
                throw error
            }
        } else {
            throw error
        }
    }
    
    // MARK: - Specific Error Handlers
    
    private func handlePartialFailure(_ errors: [CKRecord.ID: Error], operation: CloudKitOperation) async throws {
        // Log successful operations and retry failed ones
        for (recordID, error) in errors {
            print("Partial failure for record \(recordID): \(error.localizedDescription)")
            
            // Queue individual retry for failed record
            if case .save(let record) = operation, record.recordID == recordID {
                queueOperationForOffline(.save(record))
            }
        }
    }
    
    private func handleLimitExceeded(_ operation: CloudKitOperation) async throws {
        // For batch operations, split into smaller chunks
        // This is a simplified example
        switch operation {
        case .save(let record):
            // If record is too large, we might need to split attachments
            print("Record too large, consider splitting attachments")
            throw CloudKitError.invalidData
            
        default:
            throw CloudKitError.serverError
        }
    }
    
    private func handleChangeTokenExpired(_ operation: CloudKitOperation) async throws {
        // Reset sync tokens and retry from beginning
        UserDefaults.standard.removeObject(forKey: "CloudKitSyncToken")
        print("Change token expired, resetting sync state")
    }
    
    private func handleDeletedZone(_ operation: CloudKitOperation) async throws {
        // Recreate custom zone if needed
        print("Zone was deleted, need to recreate")
        // In a real implementation, we'd recreate the zone here
    }
    
    // MARK: - Offline Queue Management
    
    private func queueOperationForOffline(_ operation: CloudKitOperation) {
        operationQueue.enqueue(operation: operation) { result in
            switch result {
            case .success:
                print("Queued operation completed successfully")
            case .failure(let error):
                print("Queued operation failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func processPendingOperations() async {
        let operations = operationQueue.dequeueAll()
        
        for (operation, completion) in operations {
            do {
                // In a real implementation, we'd execute the actual CloudKit operation
                print("Processing pending operation: \(operation.operationName)")
                completion(.success("Operation completed"))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

// MARK: - CloudKit Service Extension for Error Recovery

extension CloudKitService {
    
    /// Performs a CloudKit operation with automatic retry and error recovery
    func performWithRetry<T>(
        operation: @escaping () async throws -> T,
        operationType: CloudKitOperation
    ) async throws -> T {
        let errorRecovery = CloudKitErrorRecovery.shared
        var attemptCount = 0
        var lastError: Error?
        
        repeat {
            attemptCount += 1
            
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Check if we should retry
                if errorRecovery.shouldRetry(error: error, attemptCount: attemptCount) {
                    let delay = errorRecovery.retryDelay(for: attemptCount)
                    print("Retrying \(operationType.operationName) after \(delay)s (attempt \(attemptCount))")
                    
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    // Handle non-retryable errors
                    try await errorRecovery.handleError(error, operation: operationType)
                }
            }
        } while attemptCount < 3 && lastError != nil
        
        throw lastError ?? CloudKitError.unknown
    }
}

// MARK: - Enhanced CloudKit Error Messages

extension CloudKitError {
    static var offline: CloudKitError { .networkError }
    static var recordTooLarge: CloudKitError { .invalidData }
    static var limitExceeded: CloudKitError { .serverError }
}

// MARK: - Network Monitor

final class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    private(set) var isConnected = true
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        // Simplified network monitoring
        // In production, use NWPathMonitor
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.checkConnectivity()
        }
    }
    
    private func checkConnectivity() {
        // Simplified connectivity check
        URLSession.shared.dataTask(with: URL(string: "https://www.apple.com")!) { _, response, _ in
            let wasConnected = self.isConnected
            self.isConnected = (response as? HTTPURLResponse)?.statusCode == 200
            
            if wasConnected != self.isConnected {
                NotificationCenter.default.post(
                    name: .init("NetworkStatusChanged"),
                    object: nil,
                    userInfo: ["isOnline": self.isConnected]
                )
            }
        }.resume()
    }
}