//
//  MapViewModelTests.swift
//  JubileeMobileBayTests
//
//  Created on 1/19/25.
//

import XCTest
import MapKit
import Combine
import CoreLocation
@testable import JubileeMobileBay

@MainActor
class MapViewModelTests: XCTestCase {
    var sut: MapViewModel!
    var mockLocationService: MockLocationService!
    var mockEventService: MockEventService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = []
        mockLocationService = MockLocationService()
        mockEventService = MockEventService()
        sut = MapViewModel(
            locationService: mockLocationService,
            eventService: mockEventService
        )
    }
    
    override func tearDown() {
        sut = nil
        mockLocationService = nil
        mockEventService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_shouldSetDefaultMapRegion() {
        // Given
        let expectedCenter = CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399)
        let expectedSpan = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        
        // Then
        XCTAssertEqual(sut.region.center.latitude, expectedCenter.latitude, accuracy: 0.0001)
        XCTAssertEqual(sut.region.center.longitude, expectedCenter.longitude, accuracy: 0.0001)
        XCTAssertEqual(sut.region.span.latitudeDelta, expectedSpan.latitudeDelta, accuracy: 0.01)
        XCTAssertEqual(sut.region.span.longitudeDelta, expectedSpan.longitudeDelta, accuracy: 0.01)
    }
    
    // MARK: - Event Loading Tests
    
    func test_loadEvents_shouldUpdateEventAnnotations() {
        // Given
        let expectation = expectation(description: "Events loaded")
        let mockEvents = [
            JubileeEvent.mock(id: UUID(), location: CLLocationCoordinate2D(latitude: 30.7, longitude: -88.0)),
            JubileeEvent.mock(id: UUID(), location: CLLocationCoordinate2D(latitude: 30.65, longitude: -88.05))
        ]
        mockEventService.mockEvents = mockEvents
        
        var receivedAnnotations: [EventAnnotation] = []
        sut.$eventAnnotations
            .dropFirst()
            .sink { annotations in
                receivedAnnotations = annotations
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        sut.loadEvents()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedAnnotations.count, 2)
        XCTAssertEqual(receivedAnnotations[0].event.id, mockEvents[0].id)
        XCTAssertEqual(receivedAnnotations[1].event.id, mockEvents[1].id)
    }
    
    func test_loadEvents_shouldHandleEmptyEvents() {
        // Given
        let expectation = expectation(description: "Empty events handled")
        mockEventService.mockEvents = []
        
        sut.$eventAnnotations
            .dropFirst()
            .sink { annotations in
                XCTAssertTrue(annotations.isEmpty)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        sut.loadEvents()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - User Location Tests
    
    func test_showUserLocation_shouldRequestLocationAuthorization() {
        // When
        sut.showUserLocation = true
        
        // Then
        XCTAssertTrue(mockLocationService.requestAuthorizationCalled)
    }
    
    func test_centerOnUserLocation_whenLocationAvailable_shouldUpdateRegion() {
        // Given
        let userLocation = CLLocation(latitude: 30.75, longitude: -88.1)
        mockLocationService.currentLocation = userLocation
        
        // When
        sut.centerOnUserLocation()
        
        // Then
        XCTAssertEqual(sut.region.center.latitude, 30.75, accuracy: 0.0001)
        XCTAssertEqual(sut.region.center.longitude, -88.1, accuracy: 0.0001)
        XCTAssertEqual(sut.region.span.latitudeDelta, 0.05, accuracy: 0.01)
    }
    
    func test_userLocationAuthorized_shouldReflectAuthorizationStatus() {
        // Given
        mockLocationService.authorizationStatus = .authorizedWhenInUse
        
        // Then
        XCTAssertTrue(sut.userLocationAuthorized)
        
        // When
        mockLocationService.authorizationStatus = .denied
        
        // Then
        XCTAssertFalse(sut.userLocationAuthorized)
    }
    
    // MARK: - Event Selection Tests
    
    func test_selectEvent_shouldUpdateSelectedEvent() {
        // Given
        let event = JubileeEvent.mock()
        let annotation = EventAnnotation(event: event)
        
        // When
        sut.selectEvent(annotation)
        
        // Then
        XCTAssertEqual(sut.selectedEvent?.id, event.id)
    }
    
    func test_deselectEvent_shouldClearSelectedEvent() {
        // Given
        let event = JubileeEvent.mock()
        sut.selectedEvent = event
        
        // When
        sut.deselectEvent()
        
        // Then
        XCTAssertNil(sut.selectedEvent)
    }
    
    // MARK: - Filtering Tests
    
    func test_filterEvents_byIntensity_shouldFilterAnnotations() {
        // Given
        let lightEvent = JubileeEvent.mock(intensity: .light)
        let moderateEvent = JubileeEvent.mock(intensity: .moderate)
        let heavyEvent = JubileeEvent.mock(intensity: .heavy)
        
        sut.eventAnnotations = [
            EventAnnotation(event: lightEvent),
            EventAnnotation(event: moderateEvent),
            EventAnnotation(event: heavyEvent)
        ]
        
        // When
        sut.filterIntensities = [.moderate, .heavy]
        
        // Then
        XCTAssertEqual(sut.filteredAnnotations.count, 2)
        XCTAssertTrue(sut.filteredAnnotations.contains { $0.event.intensity == .moderate })
        XCTAssertTrue(sut.filteredAnnotations.contains { $0.event.intensity == .heavy })
    }
    
    func test_filterEvents_byTimeRange_shouldFilterAnnotations() {
        // Given
        let now = Date()
        let recentEvent = JubileeEvent.mock(startTime: now.addingTimeInterval(-3600)) // 1 hour ago
        let oldEvent = JubileeEvent.mock(startTime: now.addingTimeInterval(-86400)) // 24 hours ago
        
        sut.eventAnnotations = [
            EventAnnotation(event: recentEvent),
            EventAnnotation(event: oldEvent)
        ]
        
        // When
        sut.filterTimeRange = .last6Hours
        
        // Then
        XCTAssertEqual(sut.filteredAnnotations.count, 1)
        XCTAssertEqual(sut.filteredAnnotations.first?.event.id, recentEvent.id)
    }
    
    // MARK: - Map Interaction Tests
    
    func test_mapRegionDidChange_shouldUpdateRegion() {
        // Given
        let newRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 30.8, longitude: -88.2),
            span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
        )
        
        // When
        sut.mapRegionDidChange(newRegion)
        
        // Then
        XCTAssertEqual(sut.region.center.latitude, 30.8, accuracy: 0.0001)
        XCTAssertEqual(sut.region.center.longitude, -88.2, accuracy: 0.0001)
    }
    
    // MARK: - Navigation Tests
    
    func test_navigateToEvent_shouldOpenMapsApp() {
        // Given
        let event = JubileeEvent.mock(
            location: CLLocationCoordinate2D(latitude: 30.7, longitude: -88.0)
        )
        let expectation = expectation(description: "Navigation URL opened")
        
        sut.openURLHandler = { url in
            XCTAssertTrue(url.absoluteString.contains("maps.apple.com"))
            XCTAssertTrue(url.absoluteString.contains("30.7"))
            XCTAssertTrue(url.absoluteString.contains("-88.0"))
            expectation.fulfill()
        }
        
        // When
        sut.navigateToEvent(event)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Mock Services

class MockLocationService: LocationServiceProtocol {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    
    var requestAuthorizationCalled = false
    var startLocationUpdatesCalled = false
    var stopLocationUpdatesCalled = false
    
    private let regionEventSubject = PassthroughSubject<RegionEvent, Never>()
    private let errorSubject = PassthroughSubject<LocationError, Never>()
    
    var regionEventPublisher: AnyPublisher<RegionEvent, Never> {
        regionEventSubject.eraseToAnyPublisher()
    }
    
    var errorPublisher: AnyPublisher<LocationError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    func requestAuthorization() {
        requestAuthorizationCalled = true
    }
    
    func startLocationUpdates() {
        startLocationUpdatesCalled = true
    }
    
    func stopLocationUpdates() {
        stopLocationUpdatesCalled = true
    }
    
    func startMonitoring(region: CLCircularRegion) {}
    func stopMonitoring(region: CLCircularRegion) {}
    func setDesiredAccuracy(_ accuracy: LocationAccuracy) {}
    func setDistanceFilter(_ distance: CLLocationDistance) {}
    func enableBackgroundLocationUpdates() {}
    func disableBackgroundLocationUpdates() {}
}

class MockEventService: ObservableObject {
    var mockEvents: [JubileeEvent] = []
    var loadEventsCalled = false
    
    func loadEvents() async throws -> [JubileeEvent] {
        loadEventsCalled = true
        return mockEvents
    }
}


// MARK: - Mock Extensions

extension JubileeEvent {
    static func mock(
        id: UUID = UUID(),
        location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
        intensity: JubileeIntensity = .moderate,
        startTime: Date = Date(),
        endTime: Date? = nil,
        verificationStatus: VerificationStatus = .predicted,
        reportCount: Int = 0
    ) -> JubileeEvent {
        return JubileeEvent(
            id: id,
            startTime: startTime,
            endTime: endTime,
            location: location,
            intensity: intensity,
            verificationStatus: verificationStatus,
            reportCount: reportCount,
            metadata: JubileeMetadata.mock()
        )
    }
}

extension EnvironmentalData {
    static func mock() -> EnvironmentalData {
        return EnvironmentalData(
            timestamp: Date(),
            temperature: 75.0,
            humidity: 80.0,
            windSpeed: 5.0,
            windDirection: 180.0,
            atmosphericPressure: 30.0,
            oxygenLevel: 7.5,
            dataSource: .noaa,
            reliability: 0.9
        )
    }
}

extension JubileeMetadata {
    static func mock() -> JubileeMetadata {
        return JubileeMetadata(
            windSpeed: 5.0,
            windDirection: 180,
            temperature: 75.0,
            humidity: 80.0,
            waterTemperature: 74.0,
            dissolvedOxygen: 2.5,
            salinity: 25.0,
            tide: .rising,
            moonPhase: .full
        )
    }
}