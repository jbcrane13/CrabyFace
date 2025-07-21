//
//  LocationServiceTests.swift
//  JubileeMobileBayTests
//
//  Created on 1/19/25.
//

import XCTest
import CoreLocation
import Combine
@testable import JubileeMobileBay

@MainActor
class LocationServiceTests: XCTestCase {
    var sut: LocationService!
    var mockLocationManager: MockCLLocationManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = []
        mockLocationManager = MockCLLocationManager()
    }
    
    override func tearDown() {
        sut = nil
        mockLocationManager = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_shouldSetupLocationManagerProperties() {
        // When
        sut = LocationService(locationManager: mockLocationManager)
        
        // Then
        XCTAssertEqual(mockLocationManager.desiredAccuracy, kCLLocationAccuracyBest)
        XCTAssertEqual(mockLocationManager.distanceFilter, 10.0)
        XCTAssertTrue(mockLocationManager.allowsBackgroundLocationUpdates)
        XCTAssertTrue(mockLocationManager.pausesLocationUpdatesAutomatically)
    }
    
    // MARK: - Authorization Tests
    
    func test_requestAuthorization_whenNotDetermined_shouldRequestWhenInUseAuthorization() {
        // Given
        sut = LocationService(locationManager: mockLocationManager)
        mockLocationManager.mockAuthorizationStatus = .notDetermined
        
        // When
        sut.requestAuthorization()
        
        // Then
        XCTAssertTrue(mockLocationManager.requestWhenInUseAuthorizationCalled)
    }
    
    func test_requestAuthorization_whenAuthorizedWhenInUse_shouldRequestAlwaysAuthorization() {
        // Given
        sut = LocationService(locationManager: mockLocationManager)
        mockLocationManager.mockAuthorizationStatus = .authorizedWhenInUse
        
        // When
        sut.requestAuthorization()
        
        // Then
        XCTAssertTrue(mockLocationManager.requestAlwaysAuthorizationCalled)
    }
    
    func test_authorizationStatus_shouldPublishCurrentStatus() {
        // Given
        sut = LocationService(locationManager: mockLocationManager)
        let expectation = expectation(description: "Authorization status published")
        var receivedStatus: CLAuthorizationStatus?
        
        sut.$authorizationStatus
            .dropFirst()
            .sink { status in
                receivedStatus = status
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        mockLocationManager.mockAuthorizationStatus = .authorizedAlways
        mockLocationManager.delegate?.locationManagerDidChangeAuthorization?(mockLocationManager)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedStatus, .authorizedAlways)
    }
    
    // MARK: - Location Updates Tests
    
    func test_startLocationUpdates_whenAuthorized_shouldStartUpdatingLocation() {
        // Given
        sut = LocationService(locationManager: mockLocationManager)
        mockLocationManager.mockAuthorizationStatus = .authorizedAlways
        
        // When
        sut.startLocationUpdates()
        
        // Then
        XCTAssertTrue(mockLocationManager.startUpdatingLocationCalled)
    }
    
    func test_startLocationUpdates_whenNotAuthorized_shouldNotStartUpdating() {
        // Given
        sut = LocationService(locationManager: mockLocationManager)
        mockLocationManager.mockAuthorizationStatus = .denied
        
        // When
        sut.startLocationUpdates()
        
        // Then
        XCTAssertFalse(mockLocationManager.startUpdatingLocationCalled)
    }
    
    func test_stopLocationUpdates_shouldStopUpdatingLocation() {
        // Given
        sut = LocationService(locationManager: mockLocationManager)
        
        // When
        sut.stopLocationUpdates()
        
        // Then
        XCTAssertTrue(mockLocationManager.stopUpdatingLocationCalled)
    }
    
    func test_currentLocation_shouldPublishLocationUpdates() {
        // Given
        sut = LocationService(locationManager: mockLocationManager)
        let expectation = expectation(description: "Location published")
        var receivedLocation: CLLocation?
        
        sut.$currentLocation
            .compactMap { $0 }
            .sink { location in
                receivedLocation = location
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let testLocation = CLLocation(latitude: 30.6954, longitude: -88.0399)
        
        // When
        mockLocationManager.delegate?.locationManager?(
            mockLocationManager,
            didUpdateLocations: [testLocation]
        )
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedLocation?.coordinate.latitude, 30.6954, accuracy: 0.0001)
        XCTAssertEqual(receivedLocation?.coordinate.longitude, -88.0399, accuracy: 0.0001)
    }
    
    // MARK: - Geofencing Tests
    
    func test_startMonitoringRegion_whenAuthorized_shouldStartMonitoring() {
        // Given
        sut = LocationService(locationManager: mockLocationManager)
        mockLocationManager.mockAuthorizationStatus = .authorizedAlways
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            radius: 1000,
            identifier: "test-region"
        )
        
        // When
        sut.startMonitoring(region: region)
        
        // Then
        XCTAssertTrue(mockLocationManager.startMonitoringCalled)
        XCTAssertEqual(mockLocationManager.monitoredRegions.count, 1)
        XCTAssertEqual(mockLocationManager.monitoredRegions.first?.identifier, "test-region")
    }
    
    func test_stopMonitoringRegion_shouldStopMonitoring() {
        // Given
        sut = LocationService(locationManager: mockLocationManager)
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            radius: 1000,
            identifier: "test-region"
        )
        mockLocationManager.monitoredRegions.insert(region)
        
        // When
        sut.stopMonitoring(region: region)
        
        // Then
        XCTAssertTrue(mockLocationManager.stopMonitoringCalled)
        XCTAssertEqual(mockLocationManager.monitoredRegions.count, 0)
    }
    
    func test_regionEvents_shouldPublishEnterEvents() {
        // Given
        sut = LocationService(locationManager: mockLocationManager)
        let expectation = expectation(description: "Region event published")
        var receivedEvent: RegionEvent?
        
        sut.regionEventPublisher
            .sink { event in
                receivedEvent = event
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            radius: 1000,
            identifier: "test-region"
        )
        
        // When
        mockLocationManager.delegate?.locationManager?(
            mockLocationManager,
            didEnterRegion: region
        )
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedEvent?.type, .entered)
        XCTAssertEqual(receivedEvent?.region.identifier, "test-region")
    }
    
    func test_regionEvents_shouldPublishExitEvents() {
        // Given
        sut = LocationService(locationManager: mockLocationManager)
        let expectation = expectation(description: "Region event published")
        var receivedEvent: RegionEvent?
        
        sut.regionEventPublisher
            .sink { event in
                receivedEvent = event
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            radius: 1000,
            identifier: "test-region"
        )
        
        // When
        mockLocationManager.delegate?.locationManager?(
            mockLocationManager,
            didExitRegion: region
        )
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedEvent?.type, .exited)
        XCTAssertEqual(receivedEvent?.region.identifier, "test-region")
    }
    
    // MARK: - Location Accuracy Tests
    
    func test_setDesiredAccuracy_shouldUpdateLocationManager() {
        // Given
        sut = LocationService(locationManager: mockLocationManager)
        
        // When
        sut.setDesiredAccuracy(LocationAccuracy.navigation)
        
        // Then
        XCTAssertEqual(mockLocationManager.desiredAccuracy, kCLLocationAccuracyBestForNavigation)
    }
    
    func test_setDistanceFilter_shouldUpdateLocationManager() {
        // Given
        sut = LocationService(locationManager: mockLocationManager)
        
        // When
        sut.setDistanceFilter(50.0)
        
        // Then
        XCTAssertEqual(mockLocationManager.distanceFilter, 50.0)
    }
    
    // MARK: - Error Handling Tests
    
    func test_locationError_shouldPublishError() {
        // Given
        sut = LocationService(locationManager: mockLocationManager)
        let expectation = expectation(description: "Error published")
        var receivedError: LocationError?
        
        sut.errorPublisher
            .sink { error in
                receivedError = error
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let nsError = NSError(
            domain: kCLErrorDomain,
            code: CLError.denied.rawValue,
            userInfo: nil
        )
        
        // When
        mockLocationManager.delegate?.locationManager?(
            mockLocationManager,
            didFailWithError: nsError
        )
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError, .authorizationDenied)
    }
    
    // MARK: - Background Location Tests
    
    func test_enableBackgroundLocationUpdates_shouldConfigureForBackground() {
        // Given
        sut = LocationService(locationManager: mockLocationManager)
        
        // When
        sut.enableBackgroundLocationUpdates()
        
        // Then
        XCTAssertTrue(mockLocationManager.allowsBackgroundLocationUpdates)
        XCTAssertTrue(mockLocationManager.showsBackgroundLocationIndicator)
    }
    
    func test_disableBackgroundLocationUpdates_shouldDisableBackground() {
        // Given
        sut = LocationService(locationManager: mockLocationManager)
        
        // When
        sut.disableBackgroundLocationUpdates()
        
        // Then
        XCTAssertFalse(mockLocationManager.allowsBackgroundLocationUpdates)
        XCTAssertFalse(mockLocationManager.showsBackgroundLocationIndicator)
    }
}

// MARK: - Mock CLLocationManager

class MockCLLocationManager: CLLocationManager {
    var mockAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    var requestWhenInUseAuthorizationCalled = false
    var requestAlwaysAuthorizationCalled = false
    var startUpdatingLocationCalled = false
    var stopUpdatingLocationCalled = false
    var startMonitoringCalled = false
    var stopMonitoringCalled = false
    
    private var _monitoredRegions = Set<CLRegion>()
    override var monitoredRegions: Set<CLRegion> {
        get { _monitoredRegions }
        set { _monitoredRegions = newValue }
    }
    
    override var authorizationStatus: CLAuthorizationStatus {
        return mockAuthorizationStatus
    }
    
    override func requestWhenInUseAuthorization() {
        requestWhenInUseAuthorizationCalled = true
    }
    
    override func requestAlwaysAuthorization() {
        requestAlwaysAuthorizationCalled = true
    }
    
    override func startUpdatingLocation() {
        startUpdatingLocationCalled = true
    }
    
    override func stopUpdatingLocation() {
        stopUpdatingLocationCalled = true
    }
    
    override func startMonitoring(for region: CLRegion) {
        startMonitoringCalled = true
        _monitoredRegions.insert(region)
    }
    
    override func stopMonitoring(for region: CLRegion) {
        stopMonitoringCalled = true
        _monitoredRegions.remove(region)
    }
}

