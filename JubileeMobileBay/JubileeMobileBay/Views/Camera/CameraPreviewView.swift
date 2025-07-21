//
//  CameraPreviewView.swift
//  JubileeMobileBay
//
//  SwiftUI view for camera preview display
//

import SwiftUI
import AVFoundation
import Combine

struct CameraPreviewView: UIViewRepresentable {
    
    // MARK: - Properties
    
    let cameraService: CameraServiceProtocol
    let gravity: AVLayerVideoGravity
    
    // MARK: - Initialization
    
    init(cameraService: CameraServiceProtocol, gravity: AVLayerVideoGravity = .resizeAspectFill) {
        self.cameraService = cameraService
        self.gravity = gravity
    }
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.videoGravity = gravity
        
        // Set up frame publisher subscription
        context.coordinator.setupFrameSubscription(cameraService: cameraService, previewView: view)
        
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.videoGravity = gravity
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // MARK: - Coordinator
    
    class Coordinator {
        private var cancellable: AnyCancellable?
        
        func setupFrameSubscription(cameraService: CameraServiceProtocol, previewView: CameraPreviewUIView) {
            cancellable = cameraService.framePublisher
                .receive(on: DispatchQueue.main)
                .sink { frame in
                    previewView.display(frame: frame)
                }
        }
    }
}

// MARK: - Camera Preview UIView

class CameraPreviewUIView: UIView {
    
    // MARK: - Properties
    
    override class var layerClass: AnyClass {
        AVSampleBufferDisplayLayer.self
    }
    
    private var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer {
        layer as! AVSampleBufferDisplayLayer
    }
    
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill {
        didSet {
            sampleBufferDisplayLayer.videoGravity = videoGravity
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    // MARK: - Setup
    
    private func setupLayer() {
        sampleBufferDisplayLayer.videoGravity = videoGravity
        backgroundColor = .black
    }
    
    // MARK: - Display
    
    func display(frame: CameraFrame) {
        sampleBufferDisplayLayer.enqueue(frame.sampleBuffer)
        
        // Update orientation if needed
        updateOrientation(frame.orientation)
    }
    
    private func updateOrientation(_ orientation: UIDeviceOrientation) {
        guard let connection = sampleBufferDisplayLayer.connection else { return }
        
        switch orientation {
        case .portrait:
            connection.videoOrientation = .portrait
        case .portraitUpsideDown:
            connection.videoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            connection.videoOrientation = .landscapeRight
        case .landscapeRight:
            connection.videoOrientation = .landscapeLeft
        default:
            break
        }
    }
}

// MARK: - Camera View Container

struct CameraView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel: CameraViewModel
    @State private var showPermissionView = false
    @State private var isFullscreen = false
    
    // MARK: - Initialization
    
    init(cameraService: CameraServiceProtocol? = nil) {
        let service = cameraService ?? CameraService()
        _viewModel = StateObject(wrappedValue: CameraViewModel(cameraService: service))
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Camera Preview
            if viewModel.hasPermission {
                CameraPreviewView(cameraService: viewModel.cameraService)
                    .ignoresSafeArea()
                    .overlay(alignment: .bottom) {
                        if !isFullscreen {
                            cameraControls
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        cameraStateIndicator
                    }
            } else {
                // Permission View
                CameraPermissionView {
                    Task {
                        await viewModel.handlePermissionGranted()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.checkPermissions()
            }
        }
    }
    
    // MARK: - Camera Controls
    
    private var cameraControls: some View {
        HStack(spacing: 30) {
            // Switch Camera
            Button(action: switchCamera) {
                Image(systemName: "camera.rotate")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .disabled(!viewModel.canSwitchCamera)
            
            // Play/Pause
            Button(action: togglePlayPause) {
                Image(systemName: viewModel.isStreaming ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            
            // Fullscreen
            Button(action: toggleFullscreen) {
                Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - State Indicator
    
    private var cameraStateIndicator: some View {
        Group {
            switch viewModel.cameraState {
            case .streaming:
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .fill(Color.red.opacity(0.3))
                                .frame(width: 20, height: 20)
                                .scaleEffect(viewModel.isStreaming ? 1.5 : 1.0)
                                .animation(
                                    Animation.easeInOut(duration: 1.0)
                                        .repeatForever(autoreverses: true),
                                    value: viewModel.isStreaming
                                )
                        )
                    
                    Text("LIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(20)
                
            case .preparing:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                
            case .error(let message):
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(20)
                
            default:
                EmptyView()
            }
        }
        .padding(.top, 50)
        .padding(.trailing, 20)
    }
    
    // MARK: - Actions
    
    private func switchCamera() {
        Task {
            await viewModel.switchCamera()
        }
    }
    
    private func togglePlayPause() {
        Task {
            await viewModel.togglePlayPause()
        }
    }
    
    private func toggleFullscreen() {
        withAnimation {
            isFullscreen.toggle()
        }
    }
}

// MARK: - Preview Provider

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}