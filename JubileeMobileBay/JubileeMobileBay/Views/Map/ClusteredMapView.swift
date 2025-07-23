//
//  ClusteredMapView.swift
//  JubileeMobileBay
//
//  UIKit-based map view with proper clustering support
//

import SwiftUI
import MapKit
import Combine

struct ClusteredMapView: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel
    let onAnnotationTapped: (MKAnnotation) -> Void
    let onLongPress: (CLLocationCoordinate2D) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Register annotation views
        mapView.registerAnnotationViews()
        
        // Set initial region
        mapView.setRegion(viewModel.region, animated: false)
        
        // Configure map
        mapView.showsUserLocation = viewModel.showUserLocation
        mapView.showsCompass = true
        mapView.showsScale = true
        
        // Add long press gesture
        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPress.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPress)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update user location
        mapView.showsUserLocation = viewModel.showUserLocation
        
        // Update annotations
        updateAnnotations(on: mapView)
        
        // Update region if needed
        if shouldUpdateRegion(mapView: mapView) {
            mapView.setRegion(viewModel.region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel,
                   onAnnotationTapped: onAnnotationTapped,
                   onLongPress: onLongPress)
    }
    
    private func updateAnnotations(on mapView: MKMapView) {
        // Remove existing annotations (except user location)
        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existingAnnotations)
        
        // Add new annotations
        let annotations = viewModel.allAnnotations
        mapView.addAnnotations(annotations)
    }
    
    private func shouldUpdateRegion(mapView: MKMapView) -> Bool {
        let threshold: Double = 0.01
        let currentCenter = mapView.region.center
        let viewModelCenter = viewModel.region.center
        
        let latDiff = abs(currentCenter.latitude - viewModelCenter.latitude)
        let lonDiff = abs(currentCenter.longitude - viewModelCenter.longitude)
        
        return latDiff > threshold || lonDiff > threshold
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let viewModel: MapViewModel
        let onAnnotationTapped: (MKAnnotation) -> Void
        let onLongPress: (CLLocationCoordinate2D) -> Void
        
        init(viewModel: MapViewModel,
             onAnnotationTapped: @escaping (MKAnnotation) -> Void,
             onLongPress: @escaping (CLLocationCoordinate2D) -> Void) {
            self.viewModel = viewModel
            self.onAnnotationTapped = onAnnotationTapped
            self.onLongPress = onLongPress
        }
        
        // MARK: - Gesture Handling
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began,
                  let mapView = gesture.view as? MKMapView else { return }
            
            let location = gesture.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            onLongPress(coordinate)
        }
        
        // MARK: - MKMapViewDelegate
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            viewModel.mapRegionDidChange(mapView.region)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't provide custom view for user location
            if annotation is MKUserLocation {
                return nil
            }
            
            // Home location gets special treatment
            if annotation is HomeLocationAnnotation {
                let identifier = "home"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                    annotationView?.image = UIImage(systemName: "house.fill")
                    annotationView?.tintColor = .systemBlue
                } else {
                    annotationView?.annotation = annotation
                }
                return annotationView
            }
            
            // Handle different annotation types
            switch annotation {
            case is CameraAnnotation:
                return mapView.dequeueReusableAnnotationView(
                    withIdentifier: MKMapView.AnnotationIdentifier.camera,
                    for: annotation
                )
            case is WeatherStationAnnotation:
                return mapView.dequeueReusableAnnotationView(
                    withIdentifier: MKMapView.AnnotationIdentifier.weatherStation,
                    for: annotation
                )
            case is JubileeReportAnnotation:
                return mapView.dequeueReusableAnnotationView(
                    withIdentifier: MKMapView.AnnotationIdentifier.jubileeReport,
                    for: annotation
                )
            case is MKClusterAnnotation:
                return mapView.dequeueReusableAnnotationView(
                    withIdentifier: MKMapView.AnnotationIdentifier.cluster,
                    for: annotation
                )
            default:
                return nil
            }
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation else { return }
            
            // Don't handle user location or cluster selections here
            if annotation is MKUserLocation || annotation is MKClusterAnnotation {
                return
            }
            
            onAnnotationTapped(annotation)
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                     calloutAccessoryControlTapped control: UIControl) {
            guard let annotation = view.annotation else { return }
            onAnnotationTapped(annotation)
        }
        
        // Clustering support
        func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
            return MapClusterAnnotation(memberAnnotations: memberAnnotations)
        }
    }
}

// MARK: - SwiftUI Map View Wrapper

struct ClusteredMapContainerView: View {
    static func make() -> ClusteredMapContainerView {
        ClusteredMapContainerView(
            locationService: LocationService(),
            homeLocationManager: HomeLocationManager(
                cloudKitService: CloudKitService()
            )
        )
    }
    @StateObject private var viewModel: MapViewModel
    @State private var showingAnnotationDetail = false
    @State private var showingHomeLocationConfirmation = false
    @State private var pendingHomeCoordinate: CLLocationCoordinate2D?
    @State private var showingFilterMenu = false
    
    init(locationService: LocationServiceProtocol,
         eventService: MockEventService = MockEventService(),
         homeLocationManager: HomeLocationManagerProtocol) {
        
        _viewModel = StateObject(wrappedValue: MapViewModel(
            locationService: locationService,
            eventService: eventService,
            homeLocationManager: homeLocationManager
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ClusteredMapView(
                    viewModel: viewModel,
                    onAnnotationTapped: { annotation in
                        viewModel.selectAnnotation(annotation)
                        showingAnnotationDetail = true
                    },
                    onLongPress: { coordinate in
                        if viewModel.isSettingHomeLocation {
                            pendingHomeCoordinate = coordinate
                            showingHomeLocationConfirmation = true
                        }
                    }
                )
                .ignoresSafeArea(edges: .top)
                
                VStack {
                    Spacer()
                    
                    if viewModel.isSettingHomeLocation {
                        homeLocationInstructions
                    }
                }
                
                VStack {
                    HStack {
                        Spacer()
                        mapControls
                            .padding()
                    }
                    Spacer()
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilterMenu = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .confirmationDialog(
                "Set Home Location",
                isPresented: $showingHomeLocationConfirmation,
                titleVisibility: .visible
            ) {
                Button("Set as Home") {
                    if let coordinate = pendingHomeCoordinate {
                        Task {
                            await viewModel.setHomeLocation(at: coordinate)
                        }
                    }
                }
                
                Button("Cancel", role: .cancel) {
                    pendingHomeCoordinate = nil
                    viewModel.cancelSettingHomeLocation()
                }
            } message: {
                Text("Set this location as your home? You'll receive personalized jubilee alerts for this area.")
            }
            .sheet(isPresented: $showingAnnotationDetail) {
                if let annotation = viewModel.selectedAnnotation {
                    AnnotationDetailView(annotation: annotation, viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingFilterMenu) {
                MapFilterView(viewModel: viewModel)
            }
            .task {
                viewModel.loadEvents()
                viewModel.loadAllAnnotations()
            }
        }
    }
    
    // MARK: - Map Controls
    
    private var mapControls: some View {
        VStack(spacing: 12) {
            // Location button
            MapControlButton(
                systemName: viewModel.showUserLocation ? "location.fill" : "location",
                isActive: viewModel.showUserLocation
            ) {
                viewModel.showUserLocation.toggle()
                if viewModel.showUserLocation {
                    viewModel.centerOnUserLocation()
                }
            }
            
            // Home location button
            MapControlButton(
                systemName: viewModel.homeLocationAnnotation != nil ? "house.fill" : "house",
                isActive: viewModel.homeLocationAnnotation != nil
            ) {
                if viewModel.homeLocationAnnotation != nil {
                    viewModel.centerOnHomeLocation()
                } else {
                    viewModel.startSettingHomeLocation()
                }
            }
            
            Divider()
                .frame(width: 30)
            
            // Camera toggle
            MapControlButton(
                systemName: "video.fill",
                isActive: viewModel.showCameras,
                color: .blue
            ) {
                viewModel.showCameras.toggle()
            }
            
            // Weather station toggle
            MapControlButton(
                systemName: "cloud.sun.fill",
                isActive: viewModel.showWeatherStations,
                color: .orange
            ) {
                viewModel.showWeatherStations.toggle()
            }
            
            // Jubilee reports toggle
            MapControlButton(
                systemName: "fish.fill",
                isActive: viewModel.showJubileeReports,
                color: .purple
            ) {
                viewModel.showJubileeReports.toggle()
            }
        }
    }
    
    // MARK: - Home Location Instructions
    
    private var homeLocationInstructions: some View {
        VStack(spacing: 8) {
            Text("Setting Home Location")
                .font(.headline)
            Text("Long press on the map to set your home location")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Cancel") {
                viewModel.cancelSettingHomeLocation()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
        .padding()
    }
}

// MARK: - Preview

struct ClusteredMapView_Previews: PreviewProvider {
    @MainActor
    static var previews: some View {
        ClusteredMapContainerView.make()
    }
}