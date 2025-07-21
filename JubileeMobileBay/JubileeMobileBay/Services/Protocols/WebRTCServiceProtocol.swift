//
//  WebRTCServiceProtocol.swift
//  JubileeMobileBay
//
//  Protocol for WebRTC streaming service
//

import Foundation
import Combine

// MARK: - WebRTC Connection State

enum WebRTCConnectionState {
    case disconnected
    case connecting
    case connected
    case failed(Error)
}

// MARK: - WebRTC Stream Type

enum WebRTCStreamType {
    case local
    case remote(peerId: String)
}

// MARK: - WebRTC Configuration

struct WebRTCConfiguration {
    let stunServers: [String]
    let turnServers: [TURNServer]
    let signalingServerURL: URL
    let videoCodec: VideoCodec
    let audioBitrate: Int
    let videoBitrate: Int
    
    struct TURNServer {
        let url: String
        let username: String
        let credential: String
    }
    
    enum VideoCodec: String {
        case h264 = "H264"
        case vp8 = "VP8"
        case vp9 = "VP9"
    }
    
    static let `default` = WebRTCConfiguration(
        stunServers: ["stun:stun.l.google.com:19302"],
        turnServers: [],
        signalingServerURL: URL(string: "wss://jubilee-signaling.example.com")!,
        videoCodec: .h264,
        audioBitrate: 32000,
        videoBitrate: 1000000
    )
}

// MARK: - WebRTC Stream Info

struct WebRTCStreamInfo {
    let streamId: String
    let peerId: String
    let type: WebRTCStreamType
    let isVideo: Bool
    let isAudio: Bool
    let createdAt: Date
}

// MARK: - WebRTC Service Protocol

protocol WebRTCServiceProtocol: AnyObject {
    
    // Publishers
    var connectionStatePublisher: AnyPublisher<WebRTCConnectionState, Never> { get }
    var localStreamPublisher: AnyPublisher<WebRTCStreamInfo?, Never> { get }
    var remoteStreamsPublisher: AnyPublisher<[WebRTCStreamInfo], Never> { get }
    var errorPublisher: AnyPublisher<Error, Never> { get }
    
    // Properties
    var connectionState: WebRTCConnectionState { get }
    var isConnected: Bool { get }
    var localStream: WebRTCStreamInfo? { get }
    var remoteStreams: [WebRTCStreamInfo] { get }
    
    // Connection Methods
    func connect(to roomId: String) async throws
    func disconnect()
    
    // Stream Methods
    func startLocalStream(video: Bool, audio: Bool) async throws
    func stopLocalStream()
    func muteAudio(_ mute: Bool)
    func muteVideo(_ mute: Bool)
    
    // Peer Methods
    func connectToPeer(_ peerId: String) async throws
    func disconnectFromPeer(_ peerId: String)
    
    // Configuration
    func updateConfiguration(_ configuration: WebRTCConfiguration)
    func setVideoQuality(_ quality: VideoQuality)
    
    // Statistics
    func getConnectionStats() async -> WebRTCStats?
}

// MARK: - Video Quality

enum VideoQuality {
    case low      // 360p
    case medium   // 720p
    case high     // 1080p
    case auto     // Adaptive
    
    var resolution: (width: Int, height: Int) {
        switch self {
        case .low:
            return (640, 360)
        case .medium:
            return (1280, 720)
        case .high:
            return (1920, 1080)
        case .auto:
            return (1280, 720) // Default to medium
        }
    }
    
    var bitrate: Int {
        switch self {
        case .low:
            return 500_000
        case .medium:
            return 1_000_000
        case .high:
            return 2_500_000
        case .auto:
            return 1_000_000
        }
    }
}

// MARK: - WebRTC Statistics

struct WebRTCStats {
    let timestamp: Date
    let bytesReceived: Int64
    let bytesSent: Int64
    let packetsLost: Int
    let jitter: Double
    let roundTripTime: Double
    let availableOutgoingBitrate: Double
    let availableIncomingBitrate: Double
    let currentBitrate: Double
    let frameRate: Double
    let resolution: (width: Int, height: Int)
}