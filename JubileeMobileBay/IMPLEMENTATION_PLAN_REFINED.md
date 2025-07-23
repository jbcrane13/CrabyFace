# JubileeMobileBay Feature Implementation Plan - Refined Version

## Executive Summary

This refined implementation plan incorporates architectural analysis and expert recommendations for adding three major features to the JubileeMobileBay iOS app over 12 weeks. The plan emphasizes incremental delivery, technical feasibility, and user value.

### Key Improvements from Original Plan:
- Proper separation of device camera from streaming video
- CloudKit-first approach before WebSocket complexity
- Comprehensive offline support from Day 1
- Standardized dependency injection patterns
- Performance-first design with clustering

## Phase 1: Enhanced Maps View (Weeks 1-3)

### Overview
Build foundation for location-based features with proper offline support and performance optimization.

### Week 1: Home Location Infrastructure
**Technical Implementation**:
```swift
// HomeLocationManager.swift
protocol HomeLocationManagerProtocol {
    var homeLocation: CLLocation? { get }
    func setHomeLocation(_ location: CLLocation) async throws
    func syncWithCloudKit() async throws
}

class HomeLocationManager: HomeLocationManagerProtocol {
    private let userDefaults: UserDefaults
    private let cloudKitService: CloudKitServiceProtocol
    
    init(userDefaults: UserDefaults = .standard,
         cloudKitService: CloudKitServiceProtocol) {
        self.userDefaults = userDefaults
        self.cloudKitService = cloudKitService
    }
    
    func setHomeLocation(_ location: CLLocation) async throws {
        // 1. Save immediately to UserDefaults
        userDefaults.set(location.coordinate.latitude, forKey: "homeLatitude")
        userDefaults.set(location.coordinate.longitude, forKey: "homeLongitude")
        
        // 2. Queue for CloudKit sync
        try await syncWithCloudKit()
    }
}
```

**Deliverables**:
- Offline-first home location persistence
- Background CloudKit sync
- Privacy controls for location sharing
- Reverse geocoding for location names

### Week 2: Performance-Optimized Map Annotations
**Technical Implementation**:
```swift
// Custom Annotation Types
class CameraAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let cameraId: String
    let title: String?
    let isOnline: Bool
}

// Clustering Support
class MapAnnotationClusterView: MKAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        displayPriority = .defaultHigh
        collisionMode = .circle
    }
}

// MapViewModel Enhancement
extension MapViewModel {
    func configureAnnotationClustering() {
        mapView.register(
            MapAnnotationClusterView.self,
            forAnnotationViewWithReuseIdentifier: "cluster"
        )
    }
}
```

**Performance Optimizations**:
- MKClusterAnnotation for handling 1000+ annotations
- Region-based data loading
- Annotation view reuse
- Off-main-thread data preparation

### Week 3: Interactive Features & Offline Support
**Offline Queue Implementation**:
```swift
// OfflineReportQueue.swift
class OfflineReportQueue {
    private let coreDataStack: CoreDataStack
    
    func queueReport(_ report: JubileeReport) {
        // Save to Core Data with sync pending flag
        let entity = ReportEntity(context: coreDataStack.context)
        entity.populate(from: report)
        entity.syncStatus = .pending
        try? coreDataStack.save()
    }
    
    func syncPendingReports() async {
        // Called when network becomes available
        let pending = fetchPendingReports()
        for report in pending {
            try? await cloudKitService.submit(report)
            report.syncStatus = .completed
        }
    }
}
```

## Phase 2: Live Webcam Feeds (Weeks 4-7)

### Week 4: Streaming Infrastructure (NOT Device Camera)
**Critical Architecture Decision**: Separate streaming from device camera
```swift
// StreamingVideoPlayer.swift
@MainActor
class StreamingVideoPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var error: Error?
    
    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?
    private var timeObserver: Any?
    
    deinit {
        cleanup()
    }
    
    func loadStream(url: URL) {
        cleanup()
        
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        // Monitor playback
        playerItem.addObserver(self, forKeyPath: "status", 
                              options: .new, context: nil)
        
        player = AVPlayer(playerItem: playerItem)
        setupBackgroundAudioSession()
        observeAppLifecycle()
    }
    
    private func cleanup() {
        timeObserver.map { player?.removeTimeObserver($0) }
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        NotificationCenter.default.removeObserver(self)
    }
}
```

### Week 5: HLS Video Player with Controls
**Memory-Efficient Implementation**:
```swift
// CameraFeedViewModel.swift
class CameraFeedViewModel: ObservableObject {
    @Published var activePlayers: [String: StreamingVideoPlayer] = [:]
    private let maxConcurrentStreams = 4
    
    func startStream(for cameraId: String, url: URL) {
        // Enforce memory limits
        if activePlayers.count >= maxConcurrentStreams {
            stopOldestStream()
        }
        
        let player = StreamingVideoPlayer()
        player.loadStream(url: url)
        activePlayers[cameraId] = player
    }
    
    func stopAllStreams() {
        activePlayers.values.forEach { $0.cleanup() }
        activePlayers.removeAll()
    }
}
```

### Week 6: Multi-Camera Grid View
**Optimized Grid Layout**:
```swift
struct CameraGridView: View {
    @StateObject var viewModel: CameraFeedViewModel
    let cameras: [CameraFeed]
    
    var body: some View {
        GeometryReader { geometry in
            LazyVGrid(columns: gridColumns(for: geometry.size)) {
                ForEach(cameras) { camera in
                    CameraStreamTile(camera: camera)
                        .aspectRatio(16/9, contentMode: .fit)
                        .onAppear {
                            viewModel.startStream(for: camera.id, 
                                                url: camera.streamURL)
                        }
                        .onDisappear {
                            viewModel.stopStream(for: camera.id)
                        }
                }
            }
        }
    }
}
```

### Week 7: Integration & Optimization
**Adaptive Bitrate Support**:
```swift
extension StreamingVideoPlayer {
    func enableAdaptiveBitrate() {
        player?.currentItem?.preferredPeakBitRate = 
            Double(Reachability.shared.connectionQuality.maxBitrate)
        
        // Monitor connection changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(connectionChanged),
            name: .reachabilityChanged,
            object: nil
        )
    }
}
```

## Phase 3: Community Features (Weeks 8-12)

### Week 8: Data Models with Offline Support
**Core Data + CloudKit Schema**:
```swift
// MessageEntity.swift (Core Data)
@objc(MessageEntity)
class MessageEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var text: String
    @NSManaged var timestamp: Date
    @NSManaged var roomId: String
    @NSManaged var userId: String
    @NSManaged var syncStatus: Int16 // pending, synced, failed
    
    var cloudKitRecord: CKRecord {
        let record = CKRecord(recordType: "Message")
        record["text"] = text
        record["timestamp"] = timestamp
        record["roomId"] = roomId
        record["userId"] = userId
        return record
    }
}
```

### Week 9-10: CloudKit-First Chat Implementation
**Near Real-Time with CloudKit Subscriptions**:
```swift
// ChatService.swift
class ChatService {
    private let cloudKit: CloudKitServiceProtocol
    private let coreData: CoreDataStack
    
    func setupSubscriptions(for roomId: String) {
        let predicate = NSPredicate(format: "roomId == %@", roomId)
        let subscription = CKQuerySubscription(
            recordType: "Message",
            predicate: predicate,
            options: [.firesOnRecordCreation]
        )
        
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        
        cloudKit.save(subscription) { _, _ in
            print("Chat subscription created")
        }
    }
    
    func sendMessage(_ text: String, roomId: String) async throws {
        // 1. Save to Core Data immediately
        let message = MessageEntity(context: coreData.context)
        message.text = text
        message.roomId = roomId
        message.syncStatus = .pending
        try coreData.save()
        
        // 2. Sync to CloudKit
        let record = message.cloudKitRecord
        try await cloudKit.save(record)
        message.syncStatus = .synced
    }
}
```

### Week 11: Progressive Enhancement to WebSocket
**Only If Scale Demands**:
```swift
// WebSocketService.swift (Week 11 - Optional)
class WebSocketService {
    private var socket: WebSocket?
    private let fallbackToCloudKit: Bool = true
    
    func connect() {
        guard Reachability.shared.isConnected else {
            // Fallback to CloudKit polling
            return
        }
        
        var request = URLRequest(url: websocketURL)
        request.setValue(authToken, forHTTPHeaderField: "Authorization")
        
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }
}
```

### Week 12: Gamification with CloudKit
**Points System**:
```swift
struct UserProfile {
    let id: String
    var points: Int
    var badges: Set<Badge>
    
    mutating func awardPoints(for action: UserAction) {
        points += action.pointValue
        checkForNewBadges()
    }
}

enum UserAction: Int {
    case createPost = 10
    case reportJubilee = 100
    case helpfulPost = 50 // 5+ upvotes
    
    var pointValue: Int { rawValue }
}
```

## Architecture Guidelines

### Dependency Injection Pattern
**Standard Pattern for All ViewModels**:
```swift
// ALWAYS use protocol-based dependencies
protocol ServiceProtocol { }

class ViewModel: ObservableObject {
    private let service: ServiceProtocol
    
    // ALWAYS inject dependencies via init
    init(service: ServiceProtocol = ServiceImplementation()) {
        self.service = service
    }
}
```

### Offline-First Design
1. **Immediate Local Storage**: UserDefaults or Core Data
2. **Background Sync**: CloudKit when network available
3. **Conflict Resolution**: Last-write-wins with user override
4. **Queue Management**: Pending operations in Core Data

### Performance Optimization
1. **Maps**: MKClusterAnnotation for >100 annotations
2. **Video**: Max 4 concurrent streams, adaptive bitrate
3. **Chat**: Pagination with 50 messages per page
4. **Images**: Compressed before upload, cached after download

### Testing Requirements
**Minimum Coverage Targets**:
- ViewModels: 90% coverage
- Services: 85% coverage
- UI Critical Paths: 80% coverage

**Test Structure**:
```swift
class MapViewModelTests: XCTestCase {
    var sut: MapViewModel!
    var mockLocationService: MockLocationService!
    var mockHomeLocationManager: MockHomeLocationManager!
    
    override func setUp() {
        super.setUp()
        mockLocationService = MockLocationService()
        mockHomeLocationManager = MockHomeLocationManager()
        sut = MapViewModel(
            locationService: mockLocationService,
            homeLocationManager: mockHomeLocationManager
        )
    }
    
    func test_setHomeLocation_persistsImmediately() async {
        // Given
        let location = CLLocation(latitude: 30.0, longitude: -88.0)
        
        // When
        await sut.setHomeLocation(location)
        
        // Then
        XCTAssertEqual(mockHomeLocationManager.savedLocation, location)
        XCTAssertTrue(mockHomeLocationManager.saveWasCalledImmediately)
    }
}
```

## Risk Mitigation Updates

### Technical Risks & Mitigations
1. **Camera Feed Sources**
   - Start with 3-5 public feeds
   - Mock feeds for development
   - Partner agreements in parallel

2. **Video Memory Management**
   - Strict concurrent stream limits
   - Automatic resource cleanup
   - Memory monitoring alerts

3. **Real-time Scalability**
   - CloudKit first (proven scale)
   - WebSocket only when needed
   - Automatic fallback mechanisms

4. **Offline Scenarios**
   - All features work offline
   - Transparent sync when online
   - Clear UI indicators for sync status

## Success Metrics (Updated)

### Phase 1 - Maps
- 90% of users set home location (up from 80%)
- <100ms annotation render time
- Zero data loss for offline reports

### Phase 2 - Video
- 95% successful stream starts (up from 90%)
- <3s stream start time (improved from 5s)
- <500MB memory usage with 4 streams

### Phase 3 - Community
- Messages appear <2s with CloudKit
- 100% message delivery guarantee
- Seamless offline/online transitions

## Implementation Checklist

### Before Starting Each Phase
- [ ] Create comprehensive unit tests
- [ ] Set up performance benchmarks
- [ ] Define offline behavior
- [ ] Document API contracts
- [ ] Review memory management

### After Completing Each Phase
- [ ] Run full test suite
- [ ] Performance profile on older devices
- [ ] Beta test with 50+ users
- [ ] Document lessons learned
- [ ] Update architecture docs

## Conclusion

This refined plan addresses the critical gaps identified in architectural analysis while maintaining the original vision. The emphasis on offline-first design, proper separation of concerns, and progressive enhancement ensures a robust, scalable application that delivers value incrementally.