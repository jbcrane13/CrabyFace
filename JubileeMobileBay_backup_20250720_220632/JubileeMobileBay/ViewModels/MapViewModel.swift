//
//  MapViewModel.swift
//  JubileeMobileBay
//
//  Created on 1/19/25.
//

import Foundation
import MapKit
import Combine
import CoreLocation

@MainActor
class MapViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var region: MKCoordinateRegion
    @Published var eventAnnotations: [EventAnnotation] = []
    @Published var selectedEvent: JubileeEvent?
    @Published var showUserLocation: Bool = false {
        didSet {
            if showUserLocation && !userLocationAuthorized {
                locationService.requestAuthorization()
            }
        }
    }
    @Published var filterIntensities: Set<JubileeIntensity> = Set(JubileeIntensity.allCases)
    @Published var filterTimeRange: TimeRange = .all
    
    // MARK: - Services
    
    private let locationService: LocationServiceProtocol
    private let eventService: MockEventService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Properties
    
    var userLocationAuthorized: Bool {
        switch locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }
    
    var filteredAnnotations: [EventAnnotation] {
        eventAnnotations.filter { annotation in
            // Filter by intensity
            guard filterIntensities.contains(annotation.event.intensity) else {
                return false
            }
            
            // Filter by time range
            if let timeInterval = filterTimeRange.timeInterval {
                let cutoffDate = Date().addingTimeInterval(timeInterval)
                return annotation.event.startTime >= cutoffDate
            }
            
            return true
        }
    }
    
    // For navigation
    var openURLHandler: ((URL) -> Void)?
    
    // MARK: - Initialization
    
    init(
        locationService: LocationServiceProtocol,
        eventService: MockEventService
    ) {
        self.locationService = locationService
        self.eventService = eventService
        
        // Initialize with Mobile Bay centered region
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        
        setupBindings()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Observe location authorization changes
        if let locationService = locationService as? LocationService {
            locationService.$authorizationStatus
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Public Methods
    
    func loadEvents() {
        Task {
            do {
                let events = try await eventService.loadEvents()
                self.eventAnnotations = events.map { EventAnnotation(event: $0) }
            } catch {
                // Handle error
                print("Failed to load events: \(error)")
            }
        }
    }
    
    func centerOnUserLocation() {
        guard let location = locationService.currentLocation else { return }
        
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
    
    func selectEvent(_ annotation: EventAnnotation) {
        selectedEvent = annotation.event
    }
    
    func deselectEvent() {
        selectedEvent = nil
    }
    
    func mapRegionDidChange(_ newRegion: MKCoordinateRegion) {
        region = newRegion
    }
    
    func navigateToEvent(_ event: JubileeEvent) {
        let coordinate = event.location
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = "Jubilee Event"
        
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ]
        
        mapItem.openInMaps(launchOptions: launchOptions)
    }
}

