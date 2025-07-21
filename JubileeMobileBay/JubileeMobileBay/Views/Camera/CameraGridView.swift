//
//  CameraGridView.swift
//  JubileeMobileBay
//
//  Grid layout for displaying multiple camera feeds
//

import SwiftUI

// MARK: - Camera Feed Model

struct CameraFeed: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let streamURL: URL?
    let isLive: Bool
    let viewerCount: Int
    let thumbnailImage: String? // For demo purposes
    
    static let mockFeeds: [CameraFeed] = [
        CameraFeed(
            name: "Main Beach Cam",
            location: "Fairhope Municipal Pier",
            streamURL: URL(string: "https://stream1.example.com"),
            isLive: true,
            viewerCount: 142,
            thumbnailImage: "beach.thumbnail"
        ),
        CameraFeed(
            name: "South Shore View",
            location: "Point Clear",
            streamURL: URL(string: "https://stream2.example.com"),
            isLive: true,
            viewerCount: 89,
            thumbnailImage: "shore.thumbnail"
        ),
        CameraFeed(
            name: "Marina Cam",
            location: "Eastern Shore Marina",
            streamURL: URL(string: "https://stream3.example.com"),
            isLive: false,
            viewerCount: 0,
            thumbnailImage: "marina.thumbnail"
        ),
        CameraFeed(
            name: "Bay Bridge View",
            location: "Battleship Park",
            streamURL: URL(string: "https://stream4.example.com"),
            isLive: true,
            viewerCount: 234,
            thumbnailImage: "bridge.thumbnail"
        )
    ]
}

// MARK: - Camera Grid View

struct CameraGridView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = CameraGridViewModel()
    @State private var selectedFeed: CameraFeed?
    @State private var showFullscreenCamera = false
    @Namespace private var animationNamespace
    
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
                        // User's camera (if streaming)
                        if viewModel.isUserStreaming {
                            userCameraFeedView
                        }
                        
                        // Remote camera feeds
                        ForEach(viewModel.cameraFeeds) { feed in
                            CameraFeedTile(
                                feed: feed,
                                namespace: animationNamespace,
                                onTap: {
                                    selectFeed(feed)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Live Cameras")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: toggleUserStream) {
                        Image(systemName: viewModel.isUserStreaming ? "video.slash.fill" : "video.fill")
                            .foregroundColor(viewModel.isUserStreaming ? .red : .blue)
                    }
                }
            }
            .fullScreenCover(item: $selectedFeed) { feed in
                FullscreenCameraView(
                    feed: feed,
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
}

// MARK: - Camera Feed Tile

struct CameraFeedTile: View {
    
    let feed: CameraFeed
    let namespace: Namespace.ID
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Thumbnail or placeholder
                if let thumbnailImage = feed.thumbnailImage {
                    Image(thumbnailImage)
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(16/9, contentMode: .fill)
                        .overlay(
                            Image(systemName: feed.isLive ? "video.fill" : "video.slash.fill")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
                
                // Overlay
                VStack {
                    HStack {
                        if feed.isLive {
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
                        
                        if feed.isLive {
                            // Viewer count
                            HStack(spacing: 4) {
                                Image(systemName: "eye.fill")
                                    .font(.caption2)
                                
                                Text("\(feed.viewerCount)")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
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
}

// MARK: - Fullscreen Camera View

struct FullscreenCameraView: View {
    
    let feed: CameraFeed
    let namespace: Namespace.ID
    let onDismiss: () -> Void
    
    @State private var showControls = true
    @State private var hideControlsTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            // Camera view background
            Color.black
                .ignoresSafeArea()
            
            // Camera content
            if feed.isLive {
                // For live feeds, show camera view
                // In a real app, this would connect to the stream URL
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        VStack {
                            Image(systemName: "video.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("Connecting to stream...")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                    )
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
            
            // Controls overlay
            if showControls {
                VStack {
                    // Top bar
                    HStack {
                        // Close button
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Feed info
                        VStack(alignment: .trailing) {
                            Text(feed.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(feed.location)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Bottom controls
                    if feed.isLive {
                        HStack(spacing: 30) {
                            // Screenshot
                            Button(action: takeScreenshot) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            
                            // Record
                            Button(action: toggleRecording) {
                                Image(systemName: "record.circle")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.red.opacity(0.8))
                                    .clipShape(Circle())
                            }
                            
                            // Share
                            Button(action: shareStream) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onTapGesture {
            toggleControls()
        }
        .onAppear {
            startHideControlsTimer()
        }
        .matchedGeometryEffect(id: feed.id, in: namespace)
    }
    
    // MARK: - Actions
    
    private func toggleControls() {
        withAnimation {
            showControls.toggle()
        }
        
        if showControls {
            startHideControlsTimer()
        }
    }
    
    private func startHideControlsTimer() {
        hideControlsTask?.cancel()
        
        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            if !Task.isCancelled {
                withAnimation {
                    showControls = false
                }
            }
        }
    }
    
    private func takeScreenshot() {
        // Implement screenshot functionality
        print("Taking screenshot of \(feed.name)")
    }
    
    private func toggleRecording() {
        // Implement recording functionality
        print("Toggling recording for \(feed.name)")
    }
    
    private func shareStream() {
        // Implement share functionality
        print("Sharing stream: \(feed.name)")
    }
}

// MARK: - Camera Grid View Model

@MainActor
class CameraGridViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var cameraFeeds: [CameraFeed] = []
    @Published var isUserStreaming = false
    @Published var userStreamViewers = 0
    
    // MARK: - Computed Properties
    
    var activeCameras: Int {
        cameraFeeds.filter { $0.isLive }.count + (isUserStreaming ? 1 : 0)
    }
    
    var totalViewers: Int {
        let feedViewers = cameraFeeds.filter { $0.isLive }.reduce(0) { $0 + $1.viewerCount }
        return feedViewers + userStreamViewers
    }
    
    // MARK: - Methods
    
    func loadCameraFeeds() async {
        // Simulate loading camera feeds
        // In a real app, this would fetch from a server
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        cameraFeeds = CameraFeed.mockFeeds
    }
    
    func toggleUserStream() async {
        isUserStreaming.toggle()
        
        if isUserStreaming {
            // Simulate viewers joining
            for i in 1...5 {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                userStreamViewers = i * 3
            }
        } else {
            userStreamViewers = 0
        }
    }
}

// MARK: - Preview

struct CameraGridView_Previews: PreviewProvider {
    static var previews: some View {
        CameraGridView()
    }
}