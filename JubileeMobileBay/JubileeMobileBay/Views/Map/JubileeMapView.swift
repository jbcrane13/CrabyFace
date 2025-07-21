//
//  JubileeMapView.swift
//  JubileeMobileBay
//
//  Created on 1/19/25.
//

import SwiftUI
import MapKit

struct JubileeMapView: View {
    @StateObject private var viewModel: MapViewModel
    @State private var showFilters = false
    @State private var showEventDetail = false
    @State private var showReportForm = false
    
    init(
        locationService: LocationServiceProtocol? = nil,
        eventService: MockEventService? = nil
    ) {
        let vm = MapViewModel(
            locationService: locationService ?? LocationService(),
            eventService: eventService ?? MockEventService()
        )
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack {
            // Map
            Map(coordinateRegion: $viewModel.region,
                showsUserLocation: viewModel.showUserLocation,
                annotationItems: viewModel.filteredAnnotations) { annotation in
                MapAnnotation(coordinate: annotation.event.location) {
                    EventMapMarker(
                        event: annotation.event,
                        isSelected: viewModel.selectedEvent?.id == annotation.event.id
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectEvent(annotation)
                            showEventDetail = true
                        }
                    }
                }
            }
            .ignoresSafeArea()
            
            // Map Controls
            VStack {
                HStack {
                    // Filter Button
                    Button(action: { showFilters.toggle() }) {
                        Label("Filters", systemImage: "line.horizontal.3.decrease.circle.fill")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.regularMaterial)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    // Report Button
                    Button(action: { showReportForm = true }) {
                        Label("Report", systemImage: "plus.circle.fill")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    
                    // Location Button
                    if viewModel.userLocationAuthorized {
                        Button(action: { viewModel.centerOnUserLocation() }) {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .padding(12)
                                .background(.regularMaterial)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // Event Count Badge
                if !viewModel.filteredAnnotations.isEmpty {
                    HStack {
                        Text("\(viewModel.filteredAnnotations.count) Active Events")
                            .font(.caption)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.regularMaterial)
                            .clipShape(Capsule())
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            MapFilterView(viewModel: viewModel)
        }
        .sheet(isPresented: $showEventDetail) {
            if let event = viewModel.selectedEvent {
                EventDetailView(
                    event: event,
                    onNavigate: {
                        viewModel.navigateToEvent(event)
                    },
                    onReport: {
                        showEventDetail = false
                        showReportForm = true
                    }
                )
            }
        }
        .sheet(isPresented: $showReportForm) {
            ReportView(viewModel: ReportViewModel(event: viewModel.selectedEvent))
        }
        .onAppear {
            viewModel.loadEvents()
            if viewModel.showUserLocation {
                viewModel.showUserLocation = true
            }
        }
    }
}

// MARK: - Event Map Marker

struct EventMapMarker: View {
    let event: JubileeEvent
    let isSelected: Bool
    
    var markerColor: Color {
        switch event.intensity {
        case .minimal: return .gray
        case .light: return .green
        case .moderate: return .yellow
        case .heavy: return .red
        case .extreme: return .black
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(markerColor.opacity(0.3))
                .frame(width: isSelected ? 60 : 40, height: isSelected ? 60 : 40)
            
            Circle()
                .fill(markerColor)
                .frame(width: isSelected ? 40 : 30, height: isSelected ? 40 : 30)
            
            Image(systemName: "fish.fill")
                .foregroundColor(.white)
                .font(.system(size: isSelected ? 20 : 16))
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Map Filter View

struct MapFilterView: View {
    @ObservedObject var viewModel: MapViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Event Intensity") {
                    ForEach(JubileeIntensity.allCases, id: \.self) { intensity in
                        Toggle(isOn: Binding(
                            get: { viewModel.filterIntensities.contains(intensity) },
                            set: { isOn in
                                if isOn {
                                    viewModel.filterIntensities.insert(intensity)
                                } else {
                                    viewModel.filterIntensities.remove(intensity)
                                }
                            }
                        )) {
                            HStack {
                                Circle()
                                    .fill(colorForIntensity(intensity))
                                    .frame(width: 20, height: 20)
                                Text(intensity.displayName)
                            }
                        }
                    }
                }
                
                Section("Time Range") {
                    Picker("Show events from", selection: $viewModel.filterTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Map Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func colorForIntensity(_ intensity: JubileeIntensity) -> Color {
        switch intensity {
        case .minimal: return .gray
        case .light: return .green
        case .moderate: return .yellow
        case .heavy: return .red
        case .extreme: return .black
        }
    }
}

// MARK: - Event Detail View

struct EventDetailView: View {
    let event: JubileeEvent
    let onNavigate: () -> Void
    var onReport: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Jubilee Event")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Circle()
                                    .fill(colorForIntensity(event.intensity))
                                    .frame(width: 16, height: 16)
                                Text(event.intensity.displayName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(event.verificationStatus.displayName)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                            
                            if event.reportCount > 0 {
                                Text("\(event.reportCount) reports")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Time Information
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Started", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(event.startTime, style: .date) +
                        Text(" at ") +
                        Text(event.startTime, style: .time)
                        
                        if let endTime = event.endTime {
                            Label("Ended", systemImage: "clock.badge.checkmark")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                            
                            Text(endTime, style: .date) +
                            Text(" at ") +
                            Text(endTime, style: .time)
                        } else if event.isActive {
                            Text("Currently Active")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.top, 4)
                        }
                    }
                    
                    Divider()
                    
                    // Environmental Conditions
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Environmental Conditions", systemImage: "cloud.sun")
                            .font(.headline)
                        
                        EnvironmentalConditionRow(
                            title: "Wind",
                            value: "\(Int(event.metadata.windSpeed)) mph from \(event.metadata.windDirection)°"
                        )
                        
                        EnvironmentalConditionRow(
                            title: "Temperature",
                            value: "\(Int(event.metadata.temperature))°F"
                        )
                        
                        EnvironmentalConditionRow(
                            title: "Water Temperature",
                            value: "\(Int(event.metadata.waterTemperature))°F"
                        )
                        
                        EnvironmentalConditionRow(
                            title: "Dissolved Oxygen",
                            value: String(format: "%.1f mg/L", event.metadata.dissolvedOxygen)
                        )
                        
                        EnvironmentalConditionRow(
                            title: "Tide",
                            value: event.metadata.tide.displayName
                        )
                        
                        EnvironmentalConditionRow(
                            title: "Moon Phase",
                            value: event.metadata.moonPhase.displayName
                        )
                    }
                    
                    Divider()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            dismiss()
                            onNavigate()
                        }) {
                            Label("Navigate to Location", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        if let onReport = onReport {
                            Button(action: {
                                dismiss()
                                onReport()
                            }) {
                                Label("Add Report", systemImage: "square.and.pencil")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func colorForIntensity(_ intensity: JubileeIntensity) -> Color {
        switch intensity {
        case .minimal: return .gray
        case .light: return .green
        case .moderate: return .yellow
        case .heavy: return .red
        case .extreme: return .black
        }
    }
}

// MARK: - Environmental Condition Row

struct EnvironmentalConditionRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.callout)
    }
}

// MARK: - Preview

struct JubileeMapView_Previews: PreviewProvider {
    static var previews: some View {
        JubileeMapView()
    }
}