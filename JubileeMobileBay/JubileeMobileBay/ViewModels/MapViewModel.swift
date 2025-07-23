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
    @Published var cameraAnnotations: [CameraAnnotation] = []
    @Published var weatherStationAnnotations: [WeatherStationAnnotation] = []
    @Published var jubileeReportAnnotations: [JubileeReportAnnotation] = []
    @Published var selectedEvent: JubileeEvent?
    @Published var selectedAnnotation: MKAnnotation?
    @Published var showUserLocation: Bool = false {
        didSet {
            if showUserLocation && !userLocationAuthorized {
                locationService.requestAuthorization()
            }
        }
    }
    @Published var filterIntensities: Set<JubileeIntensity> = Set(JubileeIntensity.allCases)
    @Published var filterTimeRange: TimeRange = .all
    @Published var isSettingHomeLocation: Bool = false
    @Published var homeLocationAnnotation: HomeLocationAnnotation?
    @Published var showCameras: Bool = true
    @Published var showWeatherStations: Bool = true
    @Published var showJubileeReports: Bool = true
    
    // MARK: - Services
    
    private let locationService: LocationServiceProtocol
    private let eventService: MockEventService
    private let homeLocationManager: HomeLocationManagerProtocol
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
    
    var allAnnotations: [MKAnnotation] {
        var annotations: [MKAnnotation] = []
        
        // Add camera annotations if enabled
        if showCameras {
            annotations.append(contentsOf: cameraAnnotations)
        }
        
        // Add weather station annotations if enabled
        if showWeatherStations {
            annotations.append(contentsOf: weatherStationAnnotations)
        }
        
        // Add jubilee report annotations if enabled and filtered
        if showJubileeReports {
            let filteredReports = jubileeReportAnnotations.filter { annotation in
                // Filter by intensity
                guard filterIntensities.contains(annotation.intensity) else {
                    return false
                }
                
                // Filter by time range
                if let timeInterval = filterTimeRange.timeInterval {
                    let cutoffDate = Date().addingTimeInterval(-timeInterval)
                    return annotation.reportedAt >= cutoffDate
                }
                
                return true
            }
            annotations.append(contentsOf: filteredReports)
        }
        
        // Always include home location if set
        if let homeAnnotation = homeLocationAnnotation {
            annotations.append(homeAnnotation)
        }
        
        return annotations
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
        eventService: MockEventService,
        homeLocationManager: HomeLocationManagerProtocol
    ) {
        self.locationService = locationService
        self.eventService = eventService
        self.homeLocationManager = homeLocationManager
        
        // Initialize with Mobile Bay centered region
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        
        setupBindings()
        loadHomeLocation()
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
    
    func loadAllAnnotations() {
        // Load mock data for now
        Task {
            await MainActor.run {
                // Load cameras
                cameraAnnotations = CameraAnnotation.mockAnnotations()
                
                // Load weather stations
                weatherStationAnnotations = WeatherStationAnnotation.mockAnnotations()
                
                // Load jubilee reports
                jubileeReportAnnotations = JubileeReportAnnotation.mockAnnotations()
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
    
    func selectAnnotation(_ annotation: MKAnnotation) {
        selectedAnnotation = annotation
    }
    
    func deselectAnnotation() {
        selectedAnnotation = nil
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
    
    // MARK: - Home Location Methods
    
    func startSettingHomeLocation() {
        isSettingHomeLocation = true
    }
    
    func setHomeLocation(at coordinate: CLLocationCoordinate2D) async {
        isSettingHomeLocation = false
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        do {
            try await homeLocationManager.setHomeLocation(location)
            updateHomeLocationAnnotation()
        } catch {
            print("Failed to set home location: \(error)")
        }
    }
    
    func cancelSettingHomeLocation() {
        isSettingHomeLocation = false
    }
    
    func centerOnHomeLocation() {
        guard let homeLocation = homeLocationManager.homeLocation else { return }
        
        region = MKCoordinateRegion(
            center: homeLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
    
    private func loadHomeLocation() {
        updateHomeLocationAnnotation()
    }
    
    private func updateHomeLocationAnnotation() {
        if let location = homeLocationManager.homeLocation {
            homeLocationAnnotation = HomeLocationAnnotation(
                coordinate: location.coordinate,
                title: "Home",
                subtitle: homeLocationManager.homeLocationName
            )
        } else {
            homeLocationAnnotation = nil
        }
    }
}

// MARK: - Home Location Annotation

class HomeLocationAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        super.init()
    }
}

