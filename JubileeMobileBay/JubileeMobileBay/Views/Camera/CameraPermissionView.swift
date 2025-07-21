//
//  CameraPermissionView.swift
//  JubileeMobileBay
//
//  Camera permission request view
//

import SwiftUI
import AVFoundation

struct CameraPermissionView: View {
    
    // MARK: - Properties
    
    let onPermissionGranted: () -> Void
    @State private var permissionStatus: AVAuthorizationStatus = .notDetermined
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.bottom, 20)
            
            // Title
            Text("Camera Access Required")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Message
            Text(permissionMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Button
            if permissionStatus == .notDetermined {
                Button(action: requestPermission) {
                    Label("Allow Camera Access", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            } else if permissionStatus == .denied || permissionStatus == .restricted {
                Button(action: openSettings) {
                    Label("Open Settings", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .onAppear {
            checkPermissionStatus()
        }
    }
    
    // MARK: - Computed Properties
    
    private var permissionMessage: String {
        switch permissionStatus {
        case .notDetermined:
            return "JubileeMobileBay needs access to your camera to capture and stream live marine life observations during jubilee events."
        case .denied, .restricted:
            return "Camera access has been denied. Please enable camera access in Settings to use live streaming features."
        case .authorized:
            return "Camera access granted!"
        @unknown default:
            return "Please grant camera access to continue."
        }
    }
    
    // MARK: - Methods
    
    private func checkPermissionStatus() {
        permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        if permissionStatus == .authorized {
            onPermissionGranted()
        }
    }
    
    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.permissionStatus = granted ? .authorized : .denied
                
                if granted {
                    self.onPermissionGranted()
                }
            }
        }
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}