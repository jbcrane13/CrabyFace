//
//  StreamingVideoView.swift
//  JubileeMobileBay
//
//  Created by Xcode User on 1/23/25.
//

import SwiftUI
import AVKit

/// SwiftUI view for displaying a streaming video feed with playback controls
struct StreamingVideoView: View {
    @ObservedObject var player: StreamingVideoPlayer
    let cameraFeed: CameraFeed
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Video player background
            VideoPlayerView(player: player)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showControls.toggle()
                        resetControlsTimer()
                    }
                }
            
            // Loading indicator
            if player.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            
            // Buffering indicator
            if player.isBuffering && !player.isLoading {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Buffering...")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
            }
            
            // Error display
            if let error = player.error {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)
                    
                    Text("Stream Error")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Retry") {
                        player.loadStream(url: cameraFeed.streamURL)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(15)
            }
            
            // Playback controls overlay
            if showControls && player.error == nil {
                VideoControlsOverlay(
                    player: player,
                    cameraFeed: cameraFeed,
                    onDismiss: { dismiss() }
                )
                .transition(.opacity)
                .onAppear {
                    resetControlsTimer()
                }
            }
        }
        .background(Color.black)
        .onAppear {
            if player.error == nil && !player.isPlaying {
                player.play()
            }
        }
        .onDisappear {
            controlsTimer?.invalidate()
        }
    }
    
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation {
                showControls = false
            }
        }
    }
}

/// Video player wrapper using AVPlayerViewController
struct VideoPlayerView: UIViewControllerRepresentable {
    let player: StreamingVideoPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false // We're using custom controls
        controller.videoGravity = .resizeAspect
        controller.allowsPictureInPicturePlayback = true
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Update player when it changes
        if let avPlayer = player.player {
            uiViewController.player = avPlayer
        }
    }
}

/// Custom video controls overlay
struct VideoControlsOverlay: View {
    @ObservedObject var player: StreamingVideoPlayer
    let cameraFeed: CameraFeed
    let onDismiss: () -> Void
    
    @State private var isDraggingSlider = false
    
    var body: some View {
        VStack {
            // Top bar
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(cameraFeed.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(cameraFeed.location)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.black.opacity(0.5)))
                
                // Connection quality indicator
                ConnectionQualityView(player: player)
            }
            .padding()
            
            Spacer()
            
            // Bottom controls
            VStack(spacing: 20) {
                // Time slider
                if player.duration > 0 && player.duration.isFinite {
                    VStack(spacing: 8) {
                        Slider(
                            value: Binding(
                                get: { player.currentTime },
                                set: { newValue in
                                    if !isDraggingSlider {
                                        Task {
                                            await player.seek(to: newValue)
                                        }
                                    }
                                }
                            ),
                            in: 0...player.duration,
                            onEditingChanged: { editing in
                                isDraggingSlider = editing
                            }
                        )
                        .accentColor(.white)
                        
                        HStack {
                            Text(formatTime(player.currentTime))
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("LIVE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.white))
                            
                            Spacer()
                            
                            Text(formatTime(player.duration))
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Playback controls
                HStack(spacing: 30) {
                    // Rewind 10s
                    Button(action: {
                        Task {
                            await player.seek(to: max(0, player.currentTime - 10))
                        }
                    }) {
                        Image(systemName: "gobackward.10")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    // Play/Pause
                    Button(action: {
                        if player.isPlaying {
                            player.pause()
                        } else {
                            player.play()
                        }
                    }) {
                        Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }
                    
                    // Forward 10s
                    Button(action: {
                        Task {
                            await player.seek(to: min(player.duration, player.currentTime + 10))
                        }
                    }) {
                        Image(systemName: "goforward.10")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                
                // Additional controls
                HStack(spacing: 20) {
                    // Picture in Picture
                    Button(action: {
                        // PiP functionality would go here
                    }) {
                        Image(systemName: "pip.enter")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Bitrate info
                    if player.currentBitrate > 0 {
                        BitrateInfoView(player: player)
                    }
                    
                    Spacer()
                    
                    // Fullscreen (already fullscreen in this view)
                    Button(action: {
                        // Could implement landscape rotation here
                    }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        guard time.isFinite else { return "--:--" }
        
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Connection Quality View

struct ConnectionQualityView: View {
    @ObservedObject var player: StreamingVideoPlayer
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: player.connectionQuality.iconName)
                .font(.caption)
                .foregroundColor(player.connectionQuality.color)
            
            Text(player.connectionQuality.rawValue)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.black.opacity(0.5)))
    }
}

// MARK: - Bitrate Info View

struct BitrateInfoView: View {
    @ObservedObject var player: StreamingVideoPlayer
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(formatBitrate(player.currentBitrate))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if player.isAdaptiveBitrateEnabled {
                Text("AUTO")
                    .font(.system(size: 9))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.black.opacity(0.5)))
        .onTapGesture {
            // Toggle adaptive bitrate
            player.toggleAdaptiveBitrate()
        }
    }
    
    private func formatBitrate(_ bitrate: Double) -> String {
        if bitrate < 1_000_000 {
            return String(format: "%.0f Kbps", bitrate / 1_000)
        } else {
            return String(format: "%.1f Mbps", bitrate / 1_000_000)
        }
    }
}

// MARK: - Preview

struct StreamingVideoView_Previews: PreviewProvider {
    static var previews: some View {
        StreamingVideoView(
            player: StreamingVideoPlayer(),
            cameraFeed: CameraFeed.mockCameras[0]
        )
    }
}