//
//  CameraViewModel.swift
//  JubileeMobileBay
//
//  View model for camera functionality
//

import Foundation
import AVFoundation
import Combine

@MainActor
class CameraViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var cameraState: CameraState = .idle
    @Published var hasPermission = false
    @Published var isStreaming = false
    @Published var canSwitchCamera = true
    @Published var errorMessage: String?
    
    // MARK: - Properties
    
    let cameraService: CameraServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(cameraService: CameraServiceProtocol) {
        self.cameraService = cameraService
        setupSubscriptions()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Camera state subscription
        cameraService.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.cameraState = state
                self?.isStreaming = (state == .streaming)
                
                if case .error(let message) = state {
                    self?.errorMessage = message
                } else {
                    self?.errorMessage = nil
                }
            }
            .store(in: &cancellables)
        
        // Permission status subscription
        cameraService.permissionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.hasPermission = (status == .authorized)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func checkPermissions() async {
        let status = cameraService.checkCameraPermission()
        hasPermission = (status == .authorized)
        
        if hasPermission {
            await startCamera()
        }
    }
    
    func handlePermissionGranted() async {
        hasPermission = true
        await startCamera()
    }
    
    func startCamera() async {
        do {
            try await cameraService.startCamera()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func stopCamera() {
        cameraService.stopCamera()
    }
    
    func togglePlayPause() async {
        if isStreaming {
            cameraService.pauseCamera()
        } else if cameraState == .paused {
            cameraService.resumeCamera()
        } else {
            await startCamera()
        }
    }
    
    func switchCamera() async {
        canSwitchCamera = false
        
        do {
            try await cameraService.switchCamera()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        canSwitchCamera = true
    }
    
    func capturePhoto() async -> Data? {
        do {
            return try await cameraService.capturePhoto()
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    func startRecording(to url: URL) {
        do {
            try cameraService.startRecording(to: url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func stopRecording() async -> URL? {
        do {
            return try await cameraService.stopRecording()
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}