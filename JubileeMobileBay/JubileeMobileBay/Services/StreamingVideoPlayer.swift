//
//  StreamingVideoPlayer.swift
//  JubileeMobileBay
//
//  Created by Xcode User on 1/23/25.
//

import Foundation
import AVFoundation
import AVKit
import Combine
import SwiftUI

/// Manages streaming video playback with memory management and lifecycle handling
@MainActor
class StreamingVideoPlayer: ObservableObject {
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var error: Error?
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isBuffering = false
    @Published var currentBitrate: Double = 0
    @Published var availableBitrates: [Double] = []
    @Published var connectionQuality: ConnectionQuality = .unknown
    @Published var isAdaptiveBitrateEnabled = true
    
    // MARK: - Public Properties (for UI integration)
    var player: AVPlayer? {
        return avPlayer
    }
    
    // MARK: - Private Properties
    private var avPlayer: AVPlayer?
    private var playerViewController: AVPlayerViewController?
    private var timeObserver: Any?
    private var playerItemObservation: NSKeyValueObservation?
    private var playerTimeObservation: NSKeyValueObservation?
    private var notificationObservers: [Any] = []
    private var bitrateObservation: NSKeyValueObservation?
    private var eventObservation: NSKeyValueObservation?
    private var preferredPeakBitRate: Double = 0
    private var bufferCheckTimer: Timer?
    private var bitrateHistory: [BitrateEntry] = []
    private let maxBitrateHistorySize = 10
    private let networkReachability = NetworkReachability.shared
    private var networkCancellable: AnyCancellable?
    
    // MARK: - Initialization
    init() {
        setupNotificationObservers()
        setupNetworkMonitoring()
    }
    
    deinit {
        // Cleanup is handled elsewhere since we can't call async methods from deinit
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
        notificationObservers.removeAll()
    }
    
    // MARK: - Public Methods
    
    /// Load and prepare a stream for playback
    func loadStream(url: URL) {
        cleanup()
        isLoading = true
        error = nil
        
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        // Observe player item status
        playerItemObservation = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                self?.handlePlayerItemStatusChange(item)
            }
        }
        
        // Create and configure player
        avPlayer = AVPlayer(playerItem: playerItem)
        avPlayer?.automaticallyWaitsToMinimizeStalling = true
        
        // Configure adaptive bitrate settings
        configureAdaptiveBitrate(for: playerItem)
        
        // Setup audio session for background playback
        setupBackgroundAudioSession()
        
        // Setup time observer
        setupTimeObserver()
        
        // Observe buffer status
        observeBufferStatus(for: playerItem)
        
        // Start monitoring bitrate
        startBitrateMonitoring(for: playerItem)
        
        // Start connection quality monitoring
        startConnectionQualityMonitoring()
    }
    
    /// Start or resume playback
    func play() {
        avPlayer?.play()
        isPlaying = true
    }
    
    /// Pause playback
    func pause() {
        avPlayer?.pause()
        isPlaying = false
    }
    
    /// Stop playback and cleanup resources
    func stop() {
        cleanup()
    }
    
    /// Seek to specific time
    func seek(to time: Double) async {
        guard let player = avPlayer else { return }
        await player.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }
    
    /// Set maximum bitrate manually (0 for auto)
    func setMaxBitrate(_ bitrate: Double) {
        preferredPeakBitRate = bitrate
        avPlayer?.currentItem?.preferredPeakBitRate = bitrate
    }
    
    /// Toggle adaptive bitrate streaming
    func toggleAdaptiveBitrate() {
        isAdaptiveBitrateEnabled.toggle()
        if isAdaptiveBitrateEnabled {
            avPlayer?.currentItem?.preferredPeakBitRate = 0 // Auto
        } else {
            // Use current bitrate as fixed rate
            avPlayer?.currentItem?.preferredPeakBitRate = currentBitrate
        }
    }
    
    // MARK: - Private Methods
    
    private func cleanup() {
        // Remove observers
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
        notificationObservers.removeAll()
        
        if let timeObserver = timeObserver {
            avPlayer?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        playerItemObservation?.invalidate()
        playerItemObservation = nil
        
        playerTimeObservation?.invalidate()
        playerTimeObservation = nil
        
        bitrateObservation?.invalidate()
        bitrateObservation = nil
        
        eventObservation?.invalidate()
        eventObservation = nil
        
        bufferCheckTimer?.invalidate()
        bufferCheckTimer = nil
        
        networkCancellable?.cancel()
        networkCancellable = nil
        
        // Clean up player
        avPlayer?.pause()
        avPlayer?.replaceCurrentItem(with: nil)
        avPlayer = nil
        
        // Reset state
        isPlaying = false
        isLoading = false
        isBuffering = false
        currentTime = 0
        duration = 0
        error = nil
        currentBitrate = 0
        availableBitrates = []
        connectionQuality = .unknown
        bitrateHistory.removeAll()
    }
    
    private func setupBackgroundAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = avPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = time.seconds
                
                if let duration = self?.avPlayer?.currentItem?.duration {
                    self?.duration = duration.seconds
                }
            }
        }
    }
    
    private func observeBufferStatus(for playerItem: AVPlayerItem) {
        playerTimeObservation = playerItem.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                self?.isBuffering = item.isPlaybackBufferEmpty
            }
        }
    }
    
    private func handlePlayerItemStatusChange(_ item: AVPlayerItem) {
        switch item.status {
        case .readyToPlay:
            isLoading = false
            duration = item.duration.seconds
        case .failed:
            isLoading = false
            error = item.error ?? StreamingError.unknownError
        case .unknown:
            break
        @unknown default:
            break
        }
    }
    
    private func setupNotificationObservers() {
        // App lifecycle
        let enterBackground = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleEnterBackground()
            }
        }
        
        let enterForeground = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleEnterForeground()
            }
        }
        
        // Audio session interruption
        let audioInterruption = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleAudioSessionInterruption(notification)
            }
        }
        
        notificationObservers = [enterBackground, enterForeground, audioInterruption]
    }
    
    private func handleEnterBackground() {
        // Continue playing audio in background if video has audio track
        if isPlaying {
            avPlayer?.rate = 1.0
        }
    }
    
    private func handleEnterForeground() {
        // Resume video playback if it was playing
        if isPlaying {
            avPlayer?.play()
        }
    }
    
    private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            pause()
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    play()
                }
            }
        @unknown default:
            break
        }
    }

    // MARK: - Adaptive Bitrate Methods
    
    private func configureAdaptiveBitrate(for playerItem: AVPlayerItem) {
        // Enable automatic bitrate adaptation
        playerItem.preferredPeakBitRate = 0 // 0 means automatic
        
        // Configure buffer preferences for smoother streaming
        playerItem.preferredForwardBufferDuration = 5.0
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
    }
    
    private func startBitrateMonitoring(for playerItem: AVPlayerItem) {
        // Observe access log events for bitrate information
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemNewAccessLogEntry,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.processAccessLog(playerItem.accessLog())
            }
        }
        
        // Observe current bitrate
        bitrateObservation = playerItem.observe(\.presentationSize, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                self?.updateBitrateInfo(from: item)
            }
        }
    }
    
    private func processAccessLog(_ accessLog: AVPlayerItemAccessLog?) {
        guard let events = accessLog?.events, !events.isEmpty else { return }
        
        // Get the most recent event
        if let lastEvent = events.last {
            // Update current bitrate
            let bitrate = lastEvent.indicatedBitrate
            if bitrate > 0 {
                currentBitrate = bitrate
                
                // Add to history
                let entry = BitrateEntry(timestamp: Date(), bitrate: bitrate)
                bitrateHistory.append(entry)
                
                // Keep history size limited
                if bitrateHistory.count > maxBitrateHistorySize {
                    bitrateHistory.removeFirst()
                }
                
                // Update connection quality based on bitrate stability
                updateConnectionQuality()
            }
            
            // Extract available bitrates from variant information
            if lastEvent.indicatedAverageBitrate > 0 {
                updateAvailableBitrates(from: lastEvent)
            }
        }
    }
    
    private func updateBitrateInfo(from playerItem: AVPlayerItem) {
        // Additional bitrate monitoring if needed
        guard let tracks = playerItem.tracks.first?.assetTrack else { return }
        
        // Log current track information for debugging
        if #available(iOS 16.0, *) {
            Task {
                do {
                    let dataRate = try await tracks.load(.estimatedDataRate)
                    if dataRate > 0 {
                        print("Estimated data rate: \(dataRate) bps")
                    }
                } catch {
                    print("Failed to load estimated data rate: \(error)")
                }
            }
        }
    }
    
    private func updateAvailableBitrates(from event: AVPlayerItemAccessLogEvent) {
        // Extract available bitrates from switch events
        var bitrates: Set<Double> = []
        
        if event.indicatedBitrate > 0 {
            bitrates.insert(event.indicatedBitrate)
        }
        
        if event.observedBitrate > 0 {
            bitrates.insert(event.observedBitrate)
        }
        
        // Update available bitrates if we found new ones
        if !bitrates.isEmpty {
            availableBitrates = Array(bitrates).sorted()
        }
    }
    
    private func startConnectionQualityMonitoring() {
        // Monitor buffer health every 2 seconds
        bufferCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.evaluateConnectionQuality()
            }
        }
    }
    
    private func updateConnectionQuality() {
        guard !bitrateHistory.isEmpty else {
            connectionQuality = .unknown
            return
        }
        
        // Calculate bitrate stability
        let recentBitrates = bitrateHistory.suffix(5).map { $0.bitrate }
        let averageBitrate = recentBitrates.reduce(0, +) / Double(recentBitrates.count)
        let variance = recentBitrates.reduce(0) { $0 + pow($1 - averageBitrate, 2) } / Double(recentBitrates.count)
        let standardDeviation = sqrt(variance)
        let coefficientOfVariation = standardDeviation / averageBitrate
        
        // Determine quality based on stability and bitrate
        if coefficientOfVariation < 0.1 {
            // Stable connection
            if averageBitrate > 5_000_000 {
                connectionQuality = .excellent
            } else if averageBitrate > 2_000_000 {
                connectionQuality = .good
            } else if averageBitrate > 1_000_000 {
                connectionQuality = .fair
            } else {
                connectionQuality = .poor
            }
        } else if coefficientOfVariation < 0.3 {
            // Somewhat stable
            connectionQuality = averageBitrate > 2_000_000 ? .fair : .poor
        } else {
            // Unstable connection
            connectionQuality = .poor
        }
    }
    
    private func evaluateConnectionQuality() {
        guard let playerItem = avPlayer?.currentItem else { return }
        
        // Check buffer status
        let bufferEmpty = playerItem.isPlaybackBufferEmpty
        let bufferFull = playerItem.isPlaybackBufferFull
        let likelyToKeepUp = playerItem.isPlaybackLikelyToKeepUp
        
        // Adjust quality assessment based on buffer health
        if bufferEmpty && !likelyToKeepUp {
            // Degraded performance
            if connectionQuality != .poor {
                connectionQuality = .poor
                
                // Consider reducing bitrate if adaptive is enabled
                if isAdaptiveBitrateEnabled && preferredPeakBitRate == 0 {
                    adjustBitrateForPoorConnection()
                }
            }
        } else if bufferFull && likelyToKeepUp {
            // Good performance - re-evaluate based on bitrate
            updateConnectionQuality()
        }
    }
    
    private func adjustBitrateForPoorConnection() {
        guard let playerItem = avPlayer?.currentItem,
              !availableBitrates.isEmpty else { return }
        
        // Find a lower bitrate
        let currentRate = currentBitrate
        let lowerBitrates = availableBitrates.filter { $0 < currentRate }
        
        if let targetBitrate = lowerBitrates.last {
            // Temporarily set a maximum to force lower quality
            playerItem.preferredPeakBitRate = targetBitrate * 1.1
            
            // Reset to auto after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                if self?.isAdaptiveBitrateEnabled == true {
                    playerItem.preferredPeakBitRate = 0
                }
            }
        }
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        // Start network monitoring
        networkReachability.startMonitoring()
        
        // Observe network changes
        networkCancellable = Publishers.CombineLatest(
            networkReachability.$connectionSpeed,
            networkReachability.$isConnected
        )
        .sink { [weak self] speed, isConnected in
            self?.handleNetworkChange(speed: speed, isConnected: isConnected)
        }
    }
    
    private func handleNetworkChange(speed: ConnectionSpeed, isConnected: Bool) {
        guard isConnected else {
            connectionQuality = .unknown
            return
        }
        
        // Update connection quality based on network speed
        switch speed {
        case .none:
            connectionQuality = .unknown
        case .poor:
            connectionQuality = .poor
        case .fair:
            connectionQuality = .fair
        case .good:
            connectionQuality = .good
        case .excellent:
            connectionQuality = .excellent
        case .unknown:
            // Keep existing quality assessment
            break
        }
        
        // Adjust bitrate if adaptive is enabled
        if isAdaptiveBitrateEnabled && preferredPeakBitRate == 0 {
            adjustBitrateForNetworkConditions(speed: speed)
        }
    }
    
    private func adjustBitrateForNetworkConditions(speed: ConnectionSpeed) {
        guard let playerItem = avPlayer?.currentItem else { return }
        
        let recommendedBitrate = speed.recommendedBitrate
        
        // Temporarily set max bitrate based on network conditions
        if recommendedBitrate > 0 {
            playerItem.preferredPeakBitRate = recommendedBitrate
            
            // Reset to auto after network stabilizes
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
                if self?.isAdaptiveBitrateEnabled == true {
                    playerItem.preferredPeakBitRate = 0
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum ConnectionQuality: String, CaseIterable {
    case unknown = "Unknown"
    case poor = "Poor"
    case fair = "Fair"
    case good = "Good"
    case excellent = "Excellent"
    
    var color: Color {
        switch self {
        case .unknown: return .gray
        case .poor: return .red
        case .fair: return .orange
        case .good: return .yellow
        case .excellent: return .green
        }
    }
    
    var iconName: String {
        switch self {
        case .unknown: return "wifi.slash"
        case .poor: return "wifi.exclamationmark"
        case .fair: return "wifi"
        case .good: return "wifi"
        case .excellent: return "wifi"
        }
    }
}

private struct BitrateEntry {
    let timestamp: Date
    let bitrate: Double
}

// MARK: - Errors
enum StreamingError: LocalizedError {
    case unknownError
    case networkError
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .unknownError:
            return "An unknown error occurred"
        case .networkError:
            return "Network connection error"
        case .invalidURL:
            return "Invalid stream URL"
        }
    }
}