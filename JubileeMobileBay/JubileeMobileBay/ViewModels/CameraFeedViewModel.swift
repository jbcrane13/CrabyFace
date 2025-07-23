//
//  CameraFeedViewModel.swift
//  JubileeMobileBay
//
//  Created by Xcode User on 1/23/25.
//

import Foundation
import Combine
import AVFoundation

/// Manages multiple camera feeds with strict memory limits and lifecycle management
@MainActor
class CameraFeedViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var activePlayers: [String: StreamingVideoPlayer] = [:]
    @Published var availableCameras: [CameraFeed] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var memoryWarning = false
    @Published var isUserStreaming = false
    @Published var userStreamViewers = 0
    
    // MARK: - Configuration
    private let maxConcurrentStreams = 4
    private let memoryThresholdMB: Double = 500
    private var memoryMonitorTimer: Timer?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let cameraService: CameraFeedServiceProtocol
    
    // MARK: - Computed Properties
    var activeCameras: Int {
        activePlayers.count + (isUserStreaming ? 1 : 0)
    }
    
    var totalViewers: Int {
        // In a real app, this would aggregate actual viewer counts
        let baseViewers = activePlayers.count * 10
        return baseViewers + userStreamViewers
    }
    
    // MARK: - Initialization
    init(cameraService: CameraFeedServiceProtocol = MockCameraService()) {
        self.cameraService = cameraService
        setupMemoryMonitoring()
        Task {
            await loadCameraFeeds()
        }
    }
    
    deinit {
        // Clean up timer only - stream cleanup happens elsewhere
        memoryMonitorTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Start streaming from a specific camera
    func startStream(for cameraId: String, url: URL) {
        // Check memory limits
        if activePlayers.count >= maxConcurrentStreams {
            stopOldestStream()
        }
        
        // Create and configure player
        let player = StreamingVideoPlayer()
        player.loadStream(url: url)
        
        // Monitor player state
        player.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.handleStreamError(for: cameraId, error: error)
            }
            .store(in: &cancellables)
        
        // Store player
        activePlayers[cameraId] = player
        
        // Start playback
        player.play()
    }
    
    /// Stop streaming from a specific camera
    func stopStream(for cameraId: String) {
        activePlayers[cameraId]?.stop()
        activePlayers.removeValue(forKey: cameraId)
    }
    
    /// Stop all active streams
    func stopAllStreams() {
        activePlayers.values.forEach { $0.stop() }
        activePlayers.removeAll()
    }
    
    /// Toggle stream for a camera
    func toggleStream(for camera: CameraFeed) {
        if activePlayers[camera.id] != nil {
            stopStream(for: camera.id)
        } else {
            startStream(for: camera.id, url: camera.streamURL)
        }
    }
    
    /// Check if a camera is currently streaming
    func isStreaming(cameraId: String) -> Bool {
        activePlayers[cameraId] != nil
    }
    
    /// Get player for specific camera
    func player(for cameraId: String) -> StreamingVideoPlayer? {
        activePlayers[cameraId]
    }
    
    /// Load available camera feeds
    func loadCameraFeeds() async {
        isLoading = true
        
        // In real implementation, this would fetch from a service
        do {
            availableCameras = try await cameraService.fetchAvailableCameras()
        } catch {
            self.error = error
        }
        isLoading = false
    }
    
    /// Toggle user's own stream
    func toggleUserStream() async {
        isUserStreaming.toggle()
        
        if isUserStreaming {
            // Simulate viewers joining
            for i in 1...5 {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                userStreamViewers = i * 3
            }
        } else {
            userStreamViewers = 0
        }
    }
    
    // MARK: - Private Methods
    
    private func setupMemoryMonitoring() {
        // Monitor memory usage every 5 seconds
        memoryMonitorTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkMemoryUsage()
            }
        }
    }
    
    private func checkMemoryUsage() {
        let memoryUsageMB = getCurrentMemoryUsage()
        memoryWarning = memoryUsageMB > memoryThresholdMB
        
        if memoryWarning && activePlayers.count > 1 {
            // Stop oldest stream if memory pressure is high
            stopOldestStream()
        }
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        }
        
        return 0
    }
    
    private func stopOldestStream() {
        // Find oldest stream (first in dictionary)
        guard let oldestCameraId = activePlayers.keys.first else { return }
        stopStream(for: oldestCameraId)
    }
    
    private func handleStreamError(for cameraId: String, error: Error) {
        // Log error and stop problematic stream
        print("Stream error for camera \(cameraId): \(error)")
        stopStream(for: cameraId)
        
        // Notify user
        self.error = CameraStreamError.streamFailed(cameraId: cameraId, underlying: error)
    }
}

// MARK: - Supporting Types

struct CameraFeed: Identifiable {
    let id: String
    let name: String
    let location: String
    let streamURL: URL
    let thumbnailURL: URL?
    let isOnline: Bool
    
    static let mockCameras: [CameraFeed] = [
        CameraFeed(
            id: "cam1",
            name: "Fairhope Pier",
            location: "Fairhope, AL",
            streamURL: URL(string: "https://example.com/stream1.m3u8")!,
            thumbnailURL: URL(string: "https://example.com/thumb1.jpg"),
            isOnline: true
        ),
        CameraFeed(
            id: "cam2",
            name: "Mobile Bay Bridge",
            location: "Mobile, AL",
            streamURL: URL(string: "https://example.com/stream2.m3u8")!,
            thumbnailURL: URL(string: "https://example.com/thumb2.jpg"),
            isOnline: true
        ),
        CameraFeed(
            id: "cam3",
            name: "Dauphin Island",
            location: "Dauphin Island, AL",
            streamURL: URL(string: "https://example.com/stream3.m3u8")!,
            thumbnailURL: URL(string: "https://example.com/thumb3.jpg"),
            isOnline: false
        ),
        CameraFeed(
            id: "cam4",
            name: "USS Alabama",
            location: "Mobile, AL",
            streamURL: URL(string: "https://example.com/stream4.m3u8")!,
            thumbnailURL: URL(string: "https://example.com/thumb4.jpg"),
            isOnline: true
        )
    ]
}

enum CameraStreamError: LocalizedError {
    case streamFailed(cameraId: String, underlying: Error)
    case memoryLimitExceeded
    case cameraOffline(cameraId: String)
    
    var errorDescription: String? {
        switch self {
        case .streamFailed(let cameraId, _):
            return "Failed to stream from camera \(cameraId)"
        case .memoryLimitExceeded:
            return "Memory limit exceeded. Please close some streams."
        case .cameraOffline(let cameraId):
            return "Camera \(cameraId) is currently offline"
        }
    }
}

// MARK: - Mock Camera Service

protocol CameraFeedServiceProtocol {
    func fetchAvailableCameras() async throws -> [CameraFeed]
}

class MockCameraService: CameraFeedServiceProtocol {
    func fetchAvailableCameras() async throws -> [CameraFeed] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return CameraFeed.mockCameras
    }
}