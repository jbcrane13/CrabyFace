//
//  EnhancedMapView.swift
//  JubileeMobileBay
//
//  Enhanced map view with clustering support and multiple annotation types
//

import SwiftUI
import MapKit

struct EnhancedMapView: View {
    @StateObject private var viewModel: MapViewModel
    @State private var mapCameraPosition: MapCameraPosition
    @State private var showingAnnotationDetail = false
    @State private var showingHomeLocationConfirmation = false
    @State private var pendingHomeCoordinate: CLLocationCoordinate2D?
    @State private var showingFilterMenu = false
    
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
            homeLocationManager: homeLocationManager
        ))
    }
    
    var body: some View {
        NavigationStack {
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
                EnhancedMapFilterView(viewModel: viewModel)
            }
            .task {
                viewModel.loadEvents()
                viewModel.loadAllAnnotations()
            }
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
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 36, height: 36)
                        Image(systemName: "house.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 20))
                    }
                    .shadow(radius: 2)
                }
                .annotationTitles(.hidden)
            }
            
            // Camera annotations
            if viewModel.showCameras {
                ForEach(viewModel.cameraAnnotations, id: \.cameraId) { camera in
                    Annotation(camera.title ?? "", coordinate: camera.coordinate) {
                        CameraAnnotationDetailView(camera: camera)
                            .onTapGesture {
                                viewModel.selectAnnotation(camera)
                                showingAnnotationDetail = true
                            }
                    }
                }
            }
            
            // Weather station annotations
            if viewModel.showWeatherStations {
                ForEach(viewModel.weatherStationAnnotations, id: \.stationId) { station in
                    Annotation(station.title ?? "", coordinate: station.coordinate) {
                        WeatherStationAnnotationDetailView(station: station)
                            .onTapGesture {
                                viewModel.selectAnnotation(station)
                                showingAnnotationDetail = true
                            }
                    }
                }
            }
            
            // Jubilee report annotations
            if viewModel.showJubileeReports {
                ForEach(viewModel.jubileeReportAnnotations.filter { report in
                    viewModel.filterIntensities.contains(report.intensity)
                }, id: \.reportId) { report in
                    Annotation(report.title ?? "", coordinate: report.coordinate) {
                        JubileeReportAnnotationDetailView(report: report)
                            .onTapGesture {
                                viewModel.selectAnnotation(report)
                                showingAnnotationDetail = true
                            }
                    }
                }
            }
        }
        .onMapCameraChange { context in
            viewModel.mapRegionDidChange(context.region)
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

// MARK: - Map Control Button

struct MapControlButton: View {
    let systemName: String
    let isActive: Bool
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundColor(isActive ? color : .gray)
                .frame(width: 44, height: 44)
                .background(Circle().fill(.white))
                .shadow(radius: 2)
        }
    }
}

// MARK: - Annotation Detail Views

struct CameraAnnotationDetailView: View {
    let camera: CameraAnnotation
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 36, height: 36)
            
            Image(systemName: "video.fill")
                .foregroundColor(camera.isOnline ? .blue : .gray)
                .font(.system(size: 18))
            
            if camera.isOnline {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                    .offset(x: 12, y: -12)
            }
        }
        .shadow(radius: 2)
    }
}

struct WeatherStationAnnotationDetailView: View {
    let station: WeatherStationAnnotation
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.white)
                .frame(width: 50, height: 36)
            
            VStack(spacing: 2) {
                Image(systemName: "cloud.sun.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                
                if let temp = station.currentTemperature {
                    Text("\(Int(temp))°")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
            }
        }
        .shadow(radius: 2)
    }
}

struct JubileeReportAnnotationDetailView: View {
    let report: JubileeReportAnnotation
    
    var body: some View {
        ZStack {
            Circle()
                .fill(report.intensity.color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
            
            Image(systemName: "fish.fill")
                .foregroundColor(.white)
                .font(.system(size: 18))
            
            if report.verificationStatus == .verified {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 12))
                    .background(Circle().fill(.white).frame(width: 16, height: 16))
                    .offset(x: 14, y: -14)
            }
        }
        .shadow(radius: 2)
    }
}

// MARK: - Filter View

struct EnhancedMapFilterView: View {
    @ObservedObject var viewModel: MapViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Annotation Types") {
                    Toggle("Cameras", isOn: $viewModel.showCameras)
                    Toggle("Weather Stations", isOn: $viewModel.showWeatherStations)
                    Toggle("Jubilee Reports", isOn: $viewModel.showJubileeReports)
                }
                
                Section("Jubilee Intensity Filter") {
                    ForEach(JubileeIntensity.allCases, id: \.self) { intensity in
                        HStack {
                            Circle()
                                .fill(intensity.color)
                                .frame(width: 12, height: 12)
                            
                            Text(intensity.displayName)
                            
                            Spacer()
                            
                            if viewModel.filterIntensities.contains(intensity) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if viewModel.filterIntensities.contains(intensity) {
                                viewModel.filterIntensities.remove(intensity)
                            } else {
                                viewModel.filterIntensities.insert(intensity)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Map Filters")
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

// MARK: - Annotation Detail View

struct AnnotationDetailView: View {
    let annotation: MKAnnotation
    @ObservedObject var viewModel: MapViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    detailContent
                }
                .padding()
            }
            .navigationTitle((annotation.title ?? "") ?? "Details")
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
    
    @ViewBuilder
    private var detailContent: some View {
        switch annotation {
        case let camera as CameraAnnotation:
            CameraDetailView(camera: camera)
        case let station as WeatherStationAnnotation:
            WeatherStationDetailView(station: station)
        case let report as JubileeReportAnnotation:
            JubileeReportDetailView(report: report)
        default:
            Text("No details available")
        }
    }
}

// MARK: - Detail Views

struct CameraDetailView: View {
    let camera: CameraAnnotation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "video.fill")
                    .foregroundColor(.blue)
                Text(camera.cameraName)
                    .font(.headline)
                Spacer()
                StatusBadge(isOnline: camera.isOnline)
            }
            
            if let streamURL = camera.streamURL {
                Button {
                    // Navigate to stream view
                } label: {
                    Label("View Live Stream", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!camera.isOnline)
            }
            
            InfoRow(label: "Camera ID", value: camera.cameraId)
            InfoRow(label: "Last Updated", value: camera.lastUpdated.formatted())
        }
    }
}

struct WeatherStationDetailView: View {
    let station: WeatherStationAnnotation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .foregroundColor(.orange)
                Text(station.stationName)
                    .font(.headline)
            }
            
            if let temp = station.currentTemperature {
                WeatherDataRow(label: "Temperature", value: "\(Int(temp))°F", icon: "thermometer")
            }
            
            if let wind = station.currentWindSpeed {
                WeatherDataRow(label: "Wind Speed", value: "\(Int(wind)) mph", icon: "wind")
            }
            
            if let humidity = station.currentHumidity {
                WeatherDataRow(label: "Humidity", value: "\(Int(humidity))%", icon: "humidity")
            }
            
            InfoRow(label: "Station ID", value: station.stationId)
            InfoRow(label: "Last Reading", value: station.lastReading.formatted())
        }
    }
}

struct JubileeReportDetailView: View {
    let report: JubileeReportAnnotation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(report.intensity.color)
                    .frame(width: 12, height: 12)
                Text(report.intensity.displayName)
                    .font(.headline)
                
                if report.verificationStatus == .verified {
                    Label("Verified", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            if let notes = report.notes {
                Text(notes)
                    .font(.body)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            InfoRow(label: "Reported By", value: report.reportedBy)
            InfoRow(label: "Reported At", value: report.reportedAt.formatted())
            InfoRow(label: "Report ID", value: report.reportId)
            
            Button {
                // Navigate to location
            } label: {
                Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Helper Views

struct StatusBadge: View {
    let isOnline: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isOnline ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            Text(isOnline ? "Live" : "Offline")
                .font(.caption)
                .foregroundColor(isOnline ? .green : .gray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }
}

struct WeatherDataRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct EnhancedMapView_Previews: PreviewProvider {
    @MainActor
    static var previews: some View {
        EnhancedMapView(
            locationService: LocationService(),
            homeLocationManager: HomeLocationManager(
                cloudKitService: CloudKitService()
            )
        )
    }
}