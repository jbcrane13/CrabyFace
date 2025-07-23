//
//  MapView.swift
//  JubileeMobileBay
//
//  Map view with home location setting capability
//

import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var viewModel: MapViewModel
    @State private var showEventDetail = false
    @State private var showHomeLocationConfirmation = false
    @State private var pendingHomeCoordinate: CLLocationCoordinate2D?
    @State private var mapCameraPosition: MapCameraPosition
    
    init(locationService: LocationServiceProtocol,
         eventService: MockEventService = MockEventService(),
         homeLocationManager: HomeLocationManagerProtocol) {
        
        let initialRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        
        _mapCameraPosition = State(initialValue: .region(initialRegion))
        
        _viewModel = StateObject(wrappedValue: MapViewModel(
            locationService: locationService,
            eventService: eventService,
            homeLocationManager: homeLocationManager ?? HomeLocationManager(
                cloudKitService: CloudKitService()
            )
        ))
    }
    
    var body: some View {
        ZStack {
            mapContent
                .overlay(alignment: .topTrailing) {
                    mapControls
                        .padding()
                }
                .overlay(alignment: .bottom) {
                    if viewModel.isSettingHomeLocation {
                        homeLocationInstructions
                    }
                }
        }
        .confirmationDialog(
            "Set Home Location",
            isPresented: $showHomeLocationConfirmation,
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
            }
        } message: {
            Text("Set this location as your home? You'll receive personalized jubilee alerts for this area.")
        }
        .task {
            viewModel.loadEvents()
        }
    }
    
    // MARK: - Map Content
    
    private var mapContent: some View {
        Map(position: $mapCameraPosition, interactionModes: .all) {
            // User location
            if viewModel.showUserLocation {
                UserAnnotation()
            }
            
            // Home location
            if let homeAnnotation = viewModel.homeLocationAnnotation {
                Annotation("Home", coordinate: homeAnnotation.coordinate) {
                    Image(systemName: "house.fill")
                        .foregroundColor(.blue)
                        .background(Circle().fill(.white).frame(width: 30, height: 30))
                        .shadow(radius: 2)
                }
                .annotationTitles(.hidden)
            }
            
            // Jubilee event annotations
            ForEach(viewModel.filteredAnnotations) { annotation in
                Annotation(
                    annotation.event.intensity.displayName,
                    coordinate: annotation.event.location
                ) {
                    jubileeAnnotationView(for: annotation.event)
                }
            }
        }
        .onMapCameraChange { context in
            viewModel.mapRegionDidChange(context.region)
        }
        .onTapGesture { location in
            if viewModel.isSettingHomeLocation {
                // Convert tap location to coordinate
                // Note: In production, you'd use proper coordinate conversion
                handleMapTap(at: location)
            }
        }
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if !viewModel.isSettingHomeLocation {
                        viewModel.startSettingHomeLocation()
                    }
                }
        )
    }
    
    // MARK: - Map Controls
    
    private var mapControls: some View {
        VStack(spacing: 12) {
            // Location button
            Button {
                viewModel.showUserLocation.toggle()
                if viewModel.showUserLocation {
                    viewModel.centerOnUserLocation()
                }
            } label: {
                Image(systemName: viewModel.showUserLocation ? "location.fill" : "location")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.white))
                    .shadow(radius: 2)
            }
            
            // Home location button
            Button {
                if viewModel.homeLocationAnnotation != nil {
                    viewModel.centerOnHomeLocation()
                } else {
                    viewModel.startSettingHomeLocation()
                }
            } label: {
                Image(systemName: viewModel.homeLocationAnnotation != nil ? "house.fill" : "house")
                    .font(.title2)
                    .foregroundColor(viewModel.homeLocationAnnotation != nil ? .blue : .gray)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.white))
                    .shadow(radius: 2)
            }
            
            // Filter button
            Menu {
                ForEach(JubileeIntensity.allCases, id: \.self) { intensity in
                    Button {
                        if viewModel.filterIntensities.contains(intensity) {
                            viewModel.filterIntensities.remove(intensity)
                        } else {
                            viewModel.filterIntensities.insert(intensity)
                        }
                    } label: {
                        HStack {
                            if viewModel.filterIntensities.contains(intensity) {
                                Image(systemName: "checkmark")
                            }
                            Text(intensity.displayName)
                            Circle()
                                .fill(intensity.color)
                                .frame(width: 12, height: 12)
                        }
                    }
                }
            } label: {
                Image(systemName: "line.horizontal.3.decrease.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.white))
                    .shadow(radius: 2)
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
    
    // MARK: - Helper Views
    
    private func jubileeAnnotationView(for event: JubileeEvent) -> some View {
        ZStack {
            Circle()
                .fill(event.intensity.color)
                .frame(width: 30, height: 30)
            
            Image(systemName: "fish")
                .foregroundColor(.white)
                .font(.system(size: 16))
        }
        .onTapGesture {
            viewModel.selectEvent(EventAnnotation(event: event))
            showEventDetail = true
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleMapTap(at location: CGPoint) {
        // In a real implementation, you'd convert the tap location to map coordinates
        // For now, we'll use a placeholder
        let coordinate = viewModel.region.center
        pendingHomeCoordinate = coordinate
        showHomeLocationConfirmation = true
    }
}

// MARK: - Event Detail Sheet

struct EventDetailSheet: View {
    let event: JubileeEvent
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Intensity badge
                    HStack {
                        Circle()
                            .fill(event.intensity.color)
                            .frame(width: 12, height: 12)
                        Text(event.intensity.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(event.intensity.color.opacity(0.2))
                    .cornerRadius(20)
                    
                    // Event details
                    VStack(alignment: .leading, spacing: 8) {
                        Label(event.startTime.formatted(date: .abbreviated, time: .shortened),
                              systemImage: "clock")
                        
                        if let duration = event.duration {
                            Label("\(Int(duration / 3600)) hours",
                                  systemImage: "timer")
                        }
                        
                        Label("\(event.reportedBy)",
                              systemImage: "person")
                    }
                    .font(.subheadline)
                    
                    if let notes = event.notes {
                        Text("Notes")
                            .font(.headline)
                        Text(notes)
                            .font(.body)
                    }
                    
                    // Navigation button
                    Button {
                        // Navigate to location
                    } label: {
                        Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Jubilee Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct MapView_Previews: PreviewProvider {
    @MainActor
    static var previews: some View {
        MapView(
            locationService: LocationService(),
            homeLocationManager: HomeLocationManager(
                cloudKitService: CloudKitService()
            )
        )
    }
}