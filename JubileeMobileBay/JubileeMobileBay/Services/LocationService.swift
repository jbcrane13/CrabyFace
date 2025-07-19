//
//  LocationService.swift
//  JubileeMobileBay
//
//  Created on 1/19/25.
//

import Foundation
import CoreLocation
import Combine

@MainActor
class LocationService: NSObject, ObservableObject, LocationServiceProtocol {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var currentLocation: CLLocation?
    
    private let locationManager: CLLocationManager
    private let regionEventSubject = PassthroughSubject<RegionEvent, Never>()
    private let errorSubject = PassthroughSubject<LocationError, Never>()
    
    var regionEventPublisher: AnyPublisher<RegionEvent, Never> {
        regionEventSubject.eraseToAnyPublisher()
    }
    
    var errorPublisher: AnyPublisher<LocationError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    init(locationManager: CLLocationManager = CLLocationManager()) {
        self.locationManager = locationManager
        super.init()
        
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0
        // Don't enable background updates by default - requires UIBackgroundModes in Info.plist
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = true
        
        // Update initial authorization status
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard isAuthorized else {
            errorSubject.send(.authorizationDenied)
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func startMonitoring(region: CLCircularRegion) {
        guard isAuthorized else {
            errorSubject.send(.authorizationDenied)
            return
        }
        
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            errorSubject.send(.regionMonitoringUnavailable)
            return
        }
        
        region.notifyOnEntry = true
        region.notifyOnExit = true
        locationManager.startMonitoring(for: region)
    }
    
    func stopMonitoring(region: CLCircularRegion) {
        locationManager.stopMonitoring(for: region)
    }
    
    func setDesiredAccuracy(_ accuracy: LocationAccuracy) {
        locationManager.desiredAccuracy = accuracy.clAccuracy
    }
    
    func setDistanceFilter(_ distance: CLLocationDistance) {
        locationManager.distanceFilter = distance
    }
    
    func enableBackgroundLocationUpdates() {
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
    }
    
    func disableBackgroundLocationUpdates() {
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.showsBackgroundLocationIndicator = false
    }
    
    private var isAuthorized: Bool {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            currentLocation = location
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    errorSubject.send(.authorizationDenied)
                case .locationUnknown:
                    errorSubject.send(.locationUnknown)
                case .network:
                    errorSubject.send(.networkError)
                default:
                    errorSubject.send(.locationUnknown)
                }
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        
        Task { @MainActor in
            regionEventSubject.send(RegionEvent(type: .entered, region: circularRegion))
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        
        Task { @MainActor in
            regionEventSubject.send(RegionEvent(type: .exited, region: circularRegion))
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Task { @MainActor in
            errorSubject.send(.regionMonitoringFailed)
        }
    }
}