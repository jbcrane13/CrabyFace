//
//  LocationServiceProtocol.swift
//  JubileeMobileBay
//
//  Created on 1/19/25.
//

import Foundation
import CoreLocation
import Combine

protocol LocationServiceProtocol {
    var authorizationStatus: CLAuthorizationStatus { get }
    var currentLocation: CLLocation? { get }
    var regionEventPublisher: AnyPublisher<RegionEvent, Never> { get }
    var errorPublisher: AnyPublisher<LocationError, Never> { get }
    
    func requestAuthorization()
    func startLocationUpdates()
    func stopLocationUpdates()
    func startMonitoring(region: CLCircularRegion)
    func stopMonitoring(region: CLCircularRegion)
    func setDesiredAccuracy(_ accuracy: LocationAccuracy)
    func setDistanceFilter(_ distance: CLLocationDistance)
    func enableBackgroundLocationUpdates()
    func disableBackgroundLocationUpdates()
}

enum LocationError: Error, Equatable {
    case authorizationDenied
    case locationServicesDisabled
    case locationUnknown
    case networkError
    case regionMonitoringUnavailable
    case regionMonitoringFailed
    
    var localizedDescription: String {
        switch self {
        case .authorizationDenied:
            return "Location access denied. Please enable in Settings."
        case .locationServicesDisabled:
            return "Location services are disabled."
        case .locationUnknown:
            return "Unable to determine location."
        case .networkError:
            return "Network error occurred."
        case .regionMonitoringUnavailable:
            return "Region monitoring is not available."
        case .regionMonitoringFailed:
            return "Failed to monitor region."
        }
    }
}

struct RegionEvent: Equatable {
    enum EventType: Equatable {
        case entered
        case exited
    }
    
    let type: EventType
    let region: CLCircularRegion
    let timestamp: Date
    
    init(type: EventType, region: CLCircularRegion, timestamp: Date = Date()) {
        self.type = type
        self.region = region
        self.timestamp = timestamp
    }
    
    static func == (lhs: RegionEvent, rhs: RegionEvent) -> Bool {
        lhs.type == rhs.type && 
        lhs.region.identifier == rhs.region.identifier &&
        lhs.region.center.latitude == rhs.region.center.latitude &&
        lhs.region.center.longitude == rhs.region.center.longitude &&
        lhs.region.radius == rhs.region.radius
    }
}