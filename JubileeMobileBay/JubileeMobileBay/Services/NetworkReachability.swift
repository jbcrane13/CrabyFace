//
//  NetworkReachability.swift
//  JubileeMobileBay
//
//  Created by Xcode User on 1/23/25.
//

import Foundation
import Network
import Combine

/// Monitors network connectivity and quality
@MainActor
class NetworkReachability: ObservableObject {
    static let shared = NetworkReachability()
    
    // MARK: - Published Properties
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?
    @Published var isExpensive = false
    @Published var isConstrained = false
    @Published var hasInternetConnection = true
    @Published var connectionSpeed: ConnectionSpeed = .unknown
    
    // MARK: - Private Properties
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkReachability")
    private var speedTestTimer: Timer?
    private var lastBandwidthTest: Date?
    private let bandwidthTestInterval: TimeInterval = 30 // Test every 30 seconds
    
    // MARK: - Initialization
    private init() {
        setupMonitor()
    }
    
    deinit {
        monitor.cancel()
        speedTestTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring network changes
    func startMonitoring() {
        monitor.start(queue: queue)
        startSpeedTesting()
    }
    
    /// Stop monitoring
    func stopMonitoring() {
        monitor.cancel()
        speedTestTimer?.invalidate()
    }
    
    /// Force a bandwidth test
    func testBandwidth() async {
        await performBandwidthTest()
    }
    
    // MARK: - Private Methods
    
    private func setupMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updatePath(path)
            }
        }
    }
    
    private func updatePath(_ path: NWPath) {
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else {
            connectionType = nil
        }
        
        // Check for actual internet connectivity
        if isConnected {
            Task {
                await checkInternetConnection()
            }
        } else {
            hasInternetConnection = false
            connectionSpeed = .none
        }
    }
    
    private func checkInternetConnection() async {
        // Simple connectivity check using Apple's captive portal detection
        guard let url = URL(string: "https://captive.apple.com/hotspot-detect.html") else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let responseString = String(data: data, encoding: .utf8),
               responseString.contains("<HTML>") {
                hasInternetConnection = true
            } else {
                hasInternetConnection = false
            }
        } catch {
            hasInternetConnection = false
        }
    }
    
    private func startSpeedTesting() {
        speedTestTimer = Timer.scheduledTimer(withTimeInterval: bandwidthTestInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.performBandwidthTest()
            }
        }
        
        // Perform initial test
        Task {
            await performBandwidthTest()
        }
    }
    
    private func performBandwidthTest() async {
        guard isConnected && hasInternetConnection else {
            connectionSpeed = .none
            return
        }
        
        // Use a small test file to estimate bandwidth
        guard let url = URL(string: "https://www.apple.com/library/test/success.html") else { return }
        
        let startTime = Date()
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let elapsedTime = Date().timeIntervalSince(startTime)
            let bytesReceived = Double(data.count)
            
            // Calculate bandwidth in Mbps
            let bitsReceived = bytesReceived * 8
            let megabitsReceived = bitsReceived / 1_000_000
            let bandwidthMbps = megabitsReceived / elapsedTime
            
            // Categorize connection speed
            connectionSpeed = categorizeSpeed(bandwidthMbps)
            
        } catch {
            // If test fails, base speed on connection type
            connectionSpeed = estimateSpeedByType()
        }
    }
    
    private func categorizeSpeed(_ mbps: Double) -> ConnectionSpeed {
        switch mbps {
        case ..<0.5:
            return .poor
        case 0.5..<2:
            return .fair
        case 2..<10:
            return .good
        case 10...:
            return .excellent
        default:
            return .unknown
        }
    }
    
    private func estimateSpeedByType() -> ConnectionSpeed {
        guard let type = connectionType else { return .unknown }
        
        switch type {
        case .wifi:
            return .good
        case .cellular:
            return isConstrained ? .fair : .good
        case .wiredEthernet:
            return .excellent
        default:
            return .unknown
        }
    }
}

// MARK: - Supporting Types

enum ConnectionSpeed: String, CaseIterable {
    case none = "No Connection"
    case poor = "Poor"
    case fair = "Fair"
    case good = "Good"
    case excellent = "Excellent"
    case unknown = "Unknown"
    
    var recommendedBitrate: Double {
        switch self {
        case .none:
            return 0
        case .poor:
            return 500_000 // 500 Kbps
        case .fair:
            return 1_000_000 // 1 Mbps
        case .good:
            return 3_000_000 // 3 Mbps
        case .excellent:
            return 5_000_000 // 5 Mbps
        case .unknown:
            return 1_000_000 // 1 Mbps default
        }
    }
    
    var color: Color {
        switch self {
        case .none: return .red
        case .poor: return .red
        case .fair: return .orange
        case .good: return .yellow
        case .excellent: return .green
        case .unknown: return .gray
        }
    }
}

// MARK: - SwiftUI Extensions

import SwiftUI

extension ConnectionSpeed {
    var iconName: String {
        switch self {
        case .none:
            return "wifi.slash"
        case .poor:
            return "wifi.exclamationmark"
        case .fair, .good, .excellent:
            return "wifi"
        case .unknown:
            return "questionmark.circle"
        }
    }
}