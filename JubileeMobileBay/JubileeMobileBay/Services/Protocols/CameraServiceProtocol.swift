//
//  CameraServiceProtocol.swift
//  JubileeMobileBay
//
//  Protocol for camera capture and streaming services
//

import Foundation
import AVFoundation
import Combine

// MARK: - Camera Error

enum CameraError: LocalizedError {
    case permissionDenied
    case cameraUnavailable
    case captureSessionFailed
    case deviceNotFound
    case configurationFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera permission denied. Please enable camera access in Settings."
        case .cameraUnavailable:
            return "Camera is not available on this device."
        case .captureSessionFailed:
            return "Failed to start camera capture session."
        case .deviceNotFound:
            return "Camera device not found."
        case .configurationFailed:
            return "Failed to configure camera."
        }
    }
}

// MARK: - Camera Position

enum CameraPosition {
    case front
    case back
}

// MARK: - Camera State

enum CameraState: Equatable {
    case idle
    case preparing
    case ready
    case streaming
    case paused
    case error(String)
}

// MARK: - Camera Frame

struct CameraFrame {
    let sampleBuffer: CMSampleBuffer
    let timestamp: Date
    let orientation: UIDeviceOrientation
}

// MARK: - Camera Service Protocol

protocol CameraServiceProtocol: AnyObject {
    // Publishers
    var statePublisher: AnyPublisher<CameraState, Never> { get }
    var framePublisher: AnyPublisher<CameraFrame, Never> { get }
    var permissionStatusPublisher: AnyPublisher<AVAuthorizationStatus, Never> { get }
    
    // Properties
    var currentState: CameraState { get }
    var isStreaming: Bool { get }
    var currentPosition: CameraPosition { get }
    
    // Permission Methods
    func checkCameraPermission() -> AVAuthorizationStatus
    func requestCameraPermission() async -> Bool
    
    // Camera Control Methods
    func startCamera() async throws
    func stopCamera()
    func pauseCamera()
    func resumeCamera()
    
    // Configuration Methods
    func switchCamera() async throws
    func setVideoQuality(_ quality: AVCaptureSession.Preset)
    func setFrameRate(_ frameRate: Int)
    
    // Capture Methods
    func capturePhoto() async throws -> Data
    func startRecording(to url: URL) throws
    func stopRecording() async throws -> URL
}

// MARK: - Camera Configuration

struct CameraConfiguration {
    var position: CameraPosition = .back
    var videoQuality: AVCaptureSession.Preset = .high
    var frameRate: Int = 30
    var videoStabilization: Bool = true
    var exposureMode: AVCaptureDevice.ExposureMode = .continuousAutoExposure
    var focusMode: AVCaptureDevice.FocusMode = .continuousAutoFocus
}