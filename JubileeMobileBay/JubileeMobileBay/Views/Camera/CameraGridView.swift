//
//  CameraGridView.swift
//  JubileeMobileBay
//
//  Grid layout for displaying multiple camera feeds
//

import SwiftUI
import AVKit

// Note: CameraFeed model moved to CameraFeedViewModel.swift

// MARK: - Streaming Video Preview

struct StreamingVideoPreview: UIViewControllerRepresentable {
    let player: StreamingVideoPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if let avPlayer = player.player {
            uiViewController.player = avPlayer
        }
    }
}

// MARK: - Camera Grid View

struct CameraGridView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel: CameraFeedViewModel
    @State private var selectedFeed: CameraFeed?
    @State private var showFullscreenCamera = false
    @Namespace private var animationNamespace
    
    init(cameraService: CameraFeedServiceProtocol = MockCameraService()) {
        _viewModel = StateObject(wrappedValue: CameraFeedViewModel(cameraService: cameraService))
    }
    
    // Grid layout
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Live indicator header
                    liveHeader
                    
                    // Camera grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        // Remote camera feeds
                        ForEach(viewModel.availableCameras) { feed in
                            CameraFeedTile(
                                feed: feed,
                                viewModel: viewModel,
                                namespace: animationNamespace,
                                onTap: {
                                    selectFeed(feed)
                                }
                            )
                            .onAppear {
                                // Start stream when tile appears if auto-play enabled
                                if feed.isOnline && viewModel.activePlayers.count < 2 {
                                    viewModel.startStream(for: feed.id, url: feed.streamURL)
                                }
                            }
                            .onDisappear {
                                // Stop stream when tile disappears to save memory
                                viewModel.stopStream(for: feed.id)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Live Cameras")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { viewModel.stopAllStreams() }) {
                            Label("Stop All Streams", systemImage: "stop.circle")
                        }
                        
                        Button(action: refreshFeeds) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .fullScreenCover(item: $selectedFeed) { feed in
                FullscreenCameraView(
                    feed: feed,
                    viewModel: viewModel,
                    namespace: animationNamespace,
                    onDismiss: {
                        selectedFeed = nil
                    }
                )
            }
            .task {
                await viewModel.loadCameraFeeds()
            }
        }
    }
    
    // MARK: - Live Header
    
    private var liveHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                
                Text("\(viewModel.totalViewers) watching")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(viewModel.activeCameras) active cameras")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    // MARK: - User Camera Feed
    
    private var userCameraFeedView: some View {
        ZStack {
            // Camera preview
            CameraView()
                .aspectRatio(16/9, contentMode: .fill)
                .clipped()
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red, lineWidth: 2)
                )
            
            // Overlay
            VStack {
                HStack {
                    // Live indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        
                        Text("LIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    // Viewer count
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                        
                        Text("\(viewModel.userStreamViewers)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                }
                .padding(8)
                
                Spacer()
                
                // Location
                HStack {
                    Text("Your Stream")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
        }
        .frame(height: 200)
    }
    
    // MARK: - Actions
    
    private func selectFeed(_ feed: CameraFeed) {
        selectedFeed = feed
    }
    
    private func toggleUserStream() {
        Task {
            await viewModel.toggleUserStream()
        }
    }
    
    private func refreshFeeds() {
        Task {
            await viewModel.loadCameraFeeds()
        }
    }
}

// MARK: - Camera Feed Tile

struct CameraFeedTile: View {
    
    let feed: CameraFeed
    @ObservedObject var viewModel: CameraFeedViewModel
    let namespace: Namespace.ID
    let onTap: () -> Void
    
    private var placeholderView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .aspectRatio(16/9, contentMode: .fill)
            .overlay(
                Image(systemName: feed.isOnline ? "video.fill" : "video.slash.fill")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            )
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Show streaming video or placeholder
                if let player = viewModel.player(for: feed.id) {
                    // Active stream preview
                    StreamingVideoPreview(player: player)
                        .aspectRatio(16/9, contentMode: .fill)
                        .clipped()
                } else if let thumbnailURL = feed.thumbnailURL {
                    // Thumbnail from URL
                    AsyncImage(url: thumbnailURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                                .clipped()
                        case .failure(_), .empty:
                            placeholderView
                        @unknown default:
                            placeholderView
                        }
                    }
                } else {
                    placeholderView
                }
                
                // Overlay
                VStack {
                    HStack {
                        if feed.isOnline {
                            // Live indicator
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                
                                Text("LIVE")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                        }
                        
                        Spacer()
                        
                        if feed.isOnline {
                            if let player = viewModel.player(for: feed.id) {
                                // Connection quality for active streams
                                HStack(spacing: 4) {
                                    Image(systemName: player.connectionQuality.iconName)
                                        .font(.caption2)
                                        .foregroundColor(player.connectionQuality.color)
                                    
                                    if player.currentBitrate > 0 {
                                        Text(formatBitrate(player.currentBitrate))
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    } else {
                                        Text("Connecting")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(8)
                    
                    Spacer()
                    
                    // Feed info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feed.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(feed.location)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                }
            }
            .cornerRadius(12)
            .shadow(radius: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .matchedGeometryEffect(id: feed.id, in: namespace)
    }
    
    private func formatBitrate(_ bitrate: Double) -> String {
        if bitrate < 1_000_000 {
            return String(format: "%.0f Kbps", bitrate / 1_000)
        } else {
            return String(format: "%.1f Mbps", bitrate / 1_000_000)
        }
    }
}

// MARK: - Fullscreen Camera View

struct FullscreenCameraView: View {
    
    let feed: CameraFeed
    @ObservedObject var viewModel: CameraFeedViewModel
    let namespace: Namespace.ID
    let onDismiss: () -> Void
    
    @StateObject private var player = StreamingVideoPlayer()
    
    var body: some View {
        ZStack {
            // Camera view background
            Color.black
                .ignoresSafeArea()
            
            // Camera content
            if feed.isOnline {
                // For online feeds, show streaming video
                StreamingVideoView(
                    player: player,
                    cameraFeed: feed
                )
                .ignoresSafeArea()
            } else {
                // Offline message
                VStack(spacing: 20) {
                    Image(systemName: "video.slash.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    
                    Text("Camera Offline")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Text("This camera is not currently streaming")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            // Load stream if online
            if feed.isOnline {
                player.loadStream(url: feed.streamURL)
            }
        }
        .onDisappear {
            player.stop()
        }
        .matchedGeometryEffect(id: feed.id, in: namespace)
    }
}


// MARK: - Preview

struct CameraGridView_Previews: PreviewProvider {
    static var previews: some View {
        CameraGridView()
    }
}