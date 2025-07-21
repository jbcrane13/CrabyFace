//
//  CameraService.swift
//  JubileeMobileBay
//
//  Camera capture and streaming service implementation
//

import Foundation
import AVFoundation
import Combine
import UIKit

@MainActor
final class CameraService: NSObject, CameraServiceProtocol {
    
    // MARK: - Publishers
    
    private let stateSubject = CurrentValueSubject<CameraState, Never>(.idle)
    private let frameSubject = PassthroughSubject<CameraFrame, Never>()
    private let permissionSubject = CurrentValueSubject<AVAuthorizationStatus, Never>(.notDetermined)
    
    var statePublisher: AnyPublisher<CameraState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    var framePublisher: AnyPublisher<CameraFrame, Never> {
        frameSubject.eraseToAnyPublisher()
    }
    
    var permissionStatusPublisher: AnyPublisher<AVAuthorizationStatus, Never> {
        permissionSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Properties
    
    var currentState: CameraState {
        stateSubject.value
    }
    
    var isStreaming: Bool {
        currentState == .streaming
    }
    
    private(set) var currentPosition: CameraPosition = .back
    
    // MARK: - Private Properties
    
    private var captureSession: AVCaptureSession?
    private var videoInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var photoOutput: AVCapturePhotoOutput?
    private var movieOutput: AVCaptureMovieFileOutput?
    
    private let sessionQueue = DispatchQueue(label: "com.jubileemobilebay.camera.session")
    private let videoQueue = DispatchQueue(label: "com.jubileemobilebay.camera.video", qos: .userInitiated)
    
    private var configuration = CameraConfiguration()
    private var recordingURL: URL?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        checkInitialPermissionStatus()
    }
    
    // MARK: - Permission Methods
    
    func checkCameraPermission() -> AVAuthorizationStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        permissionSubject.send(status)
        return status
    }
    
    func requestCameraPermission() async -> Bool {
        let status = checkCameraPermission()
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    Task { @MainActor in
                        let newStatus: AVAuthorizationStatus = granted ? .authorized : .denied
                        self?.permissionSubject.send(newStatus)
                        continuation.resume(returning: granted)
                    }
                }
            }
        default:
            return false
        }
    }
    
    // MARK: - Camera Control Methods
    
    func startCamera() async throws {
        guard checkCameraPermission() == .authorized else {
            throw CameraError.permissionDenied
        }
        
        stateSubject.send(.preparing)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                do {
                    try self?.setupCaptureSession()
                    self?.captureSession?.startRunning()
                    
                    Task { @MainActor in
                        self?.stateSubject.send(.ready)
                        continuation.resume()
                    }
                } catch {
                    Task { @MainActor in
                        self?.stateSubject.send(.error(error.localizedDescription))
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    func stopCamera() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
            
            Task { @MainActor in
                self?.stateSubject.send(.idle)
            }
        }
    }
    
    func pauseCamera() {
        guard isStreaming else { return }
        stateSubject.send(.paused)
    }
    
    func resumeCamera() {
        guard currentState == .paused else { return }
        stateSubject.send(.streaming)
    }
    
    // MARK: - Configuration Methods
    
    func switchCamera() async throws {
        let newPosition: CameraPosition = currentPosition == .back ? .front : .back
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                
                do {
                    self.captureSession?.beginConfiguration()
                    
                    // Remove current input
                    if let currentInput = self.videoInput {
                        self.captureSession?.removeInput(currentInput)
                    }
                    
                    // Add new input
                    let device = try self.getCameraDevice(position: newPosition)
                    let newInput = try AVCaptureDeviceInput(device: device)
                    
                    if self.captureSession?.canAddInput(newInput) == true {
                        self.captureSession?.addInput(newInput)
                        self.videoInput = newInput
                        self.currentPosition = newPosition
                    } else {
                        throw CameraError.configurationFailed
                    }
                    
                    self.captureSession?.commitConfiguration()
                    
                    Task { @MainActor in
                        continuation.resume()
                    }
                } catch {
                    self.captureSession?.commitConfiguration()
                    
                    Task { @MainActor in
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    func setVideoQuality(_ quality: AVCaptureSession.Preset) {
        sessionQueue.async { [weak self] in
            guard let session = self?.captureSession,
                  session.canSetSessionPreset(quality) else { return }
            
            session.beginConfiguration()
            session.sessionPreset = quality
            session.commitConfiguration()
            
            self?.configuration.videoQuality = quality
        }
    }
    
    func setFrameRate(_ frameRate: Int) {
        sessionQueue.async { [weak self] in
            guard let device = self?.videoInput?.device else { return }
            
            do {
                try device.lockForConfiguration()
                
                let desiredFrameRate = CMTimeMake(value: 1, timescale: Int32(frameRate))
                device.activeVideoMinFrameDuration = desiredFrameRate
                device.activeVideoMaxFrameDuration = desiredFrameRate
                
                device.unlockForConfiguration()
                
                self?.configuration.frameRate = frameRate
            } catch {
                print("Failed to set frame rate: \(error)")
            }
        }
    }
    
    // MARK: - Capture Methods
    
    func capturePhoto() async throws -> Data {
        guard let photoOutput = photoOutput else {
            throw CameraError.captureSessionFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let photoDelegate = PhotoCaptureDelegate { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            sessionQueue.async {
                let settings = AVCapturePhotoSettings()
                settings.flashMode = .auto
                
                photoOutput.capturePhoto(with: settings, delegate: photoDelegate)
            }
        }
    }
    
    func startRecording(to url: URL) throws {
        guard let movieOutput = movieOutput else {
            throw CameraError.captureSessionFailed
        }
        
        guard !movieOutput.isRecording else {
            return
        }
        
        recordingURL = url
        
        sessionQueue.async {
            movieOutput.startRecording(to: url, recordingDelegate: self)
        }
    }
    
    func stopRecording() async throws -> URL {
        guard let movieOutput = movieOutput,
              movieOutput.isRecording,
              let url = recordingURL else {
            throw CameraError.captureSessionFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.recordingURL = nil
            
            sessionQueue.async {
                movieOutput.stopRecording()
            }
            
            // Wait for delegate callback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume(returning: url)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func checkInitialPermissionStatus() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        permissionSubject.send(status)
    }
    
    private func setupCaptureSession() throws {
        // Create session
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        // Set quality
        if session.canSetSessionPreset(configuration.videoQuality) {
            session.sessionPreset = configuration.videoQuality
        }
        
        // Add video input
        let device = try getCameraDevice(position: configuration.position)
        let input = try AVCaptureDeviceInput(device: device)
        
        guard session.canAddInput(input) else {
            throw CameraError.configurationFailed
        }
        
        session.addInput(input)
        self.videoInput = input
        
        // Add video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        guard session.canAddOutput(videoOutput) else {
            throw CameraError.configurationFailed
        }
        
        session.addOutput(videoOutput)
        self.videoOutput = videoOutput
        
        // Add photo output
        let photoOutput = AVCapturePhotoOutput()
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            self.photoOutput = photoOutput
        }
        
        // Add movie output
        let movieOutput = AVCaptureMovieFileOutput()
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
            self.movieOutput = movieOutput
        }
        
        // Configure device
        try configureDevice(device)
        
        session.commitConfiguration()
        self.captureSession = session
    }
    
    private func getCameraDevice(position: CameraPosition) throws -> AVCaptureDevice {
        let devicePosition: AVCaptureDevice.Position = position == .back ? .back : .front
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTripleCamera],
            mediaType: .video,
            position: devicePosition
        )
        
        guard let device = discoverySession.devices.first else {
            throw CameraError.deviceNotFound
        }
        
        return device
    }
    
    private func configureDevice(_ device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        
        // Set focus mode
        if device.isFocusModeSupported(configuration.focusMode) {
            device.focusMode = configuration.focusMode
        }
        
        // Set exposure mode
        if device.isExposureModeSupported(configuration.exposureMode) {
            device.exposureMode = configuration.exposureMode
        }
        
        // Set video stabilization
        if configuration.videoStabilization {
            if let connection = videoOutput?.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
        }
        
        device.unlockForConfiguration()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard currentState == .streaming || currentState == .ready else { return }
        
        if currentState == .ready {
            Task { @MainActor in
                stateSubject.send(.streaming)
            }
        }
        
        let frame = CameraFrame(
            sampleBuffer: sampleBuffer,
            timestamp: Date(),
            orientation: UIDevice.current.orientation
        )
        
        frameSubject.send(frame)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Handle dropped frames if needed
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Recording started
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Recording error: \(error)")
        }
    }
}

// MARK: - Photo Capture Delegate

private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    
    private let completion: (Result<Data, Error>) -> Void
    
    init(completion: @escaping (Result<Data, Error>) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let data = photo.fileDataRepresentation() else {
            completion(.failure(CameraError.captureSessionFailed))
            return
        }
        
        completion(.success(data))
    }
}