//
//  ReportView.swift
//  JubileeMobileBay
//
//  View for reporting jubilee events with photo upload
//

import SwiftUI
import PhotosUI
import MapKit
import CoreLocation

struct ReportView: View {
    @StateObject var viewModel: ReportViewModel
    @State private var showingMarineLifePicker = false
    @State private var newMarineLife = ""
    @State private var showingSuccessAlert = false
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: ReportViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? ReportViewModel())
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Description Section
                Section(header: Text("Description")) {
                    TextEditor(text: $viewModel.description)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if viewModel.description.isEmpty {
                                    Text("Describe what you're observing...")
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }
                
                // Intensity Section
                Section(header: Text("Intensity")) {
                    Picker("Intensity", selection: $viewModel.intensity) {
                        ForEach(JubileeIntensity.allCases, id: \.self) { intensity in
                            Label(intensity.displayName, systemImage: intensityIcon(for: intensity))
                                .tag(intensity)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Location Section
                Section(header: Text("Location")) {
                    if let location = viewModel.location {
                        LocationMapView(coordinate: location)
                            .frame(height: 200)
                            .cornerRadius(8)
                        
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            Text(String(format: "%.4f, %.4f", location.latitude, location.longitude))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        viewModel.useCurrentLocation()
                    }) {
                        Label("Use Current Location", systemImage: "location.circle.fill")
                    }
                    .disabled(viewModel.location != nil)
                }
                
                // Photos Section
                Section(header: Text("Photos")) {
                    PhotoPickerView(viewModel: viewModel)
                }
                
                // Marine Life Section
                Section(header: Text("Marine Life Observed")) {
                    ForEach(viewModel.marineLifeObservations, id: \.self) { species in
                        HStack {
                            Label(species, systemImage: "fish.fill")
                            Spacer()
                            Button(action: {
                                viewModel.removeMarineLifeObservation(species)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Add species", text: $newMarineLife)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Add") {
                            if !newMarineLife.isEmpty {
                                viewModel.addMarineLifeObservation(newMarineLife)
                                newMarineLife = ""
                            }
                        }
                        .disabled(newMarineLife.isEmpty)
                    }
                }
            }
            .navigationTitle("Report Jubilee")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit Report") {
                        Task {
                            await submitReport()
                        }
                    }
                    .disabled(!viewModel.canSubmit)
                    .overlay(
                        Group {
                            if viewModel.isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            }
                        }
                    )
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error ?? "")
            }
            .alert("Success", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your report has been submitted successfully!")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func intensityIcon(for intensity: JubileeIntensity) -> String {
        switch intensity {
        case .light:
            return "circle"
        case .moderate:
            return "circle.lefthalf.filled"
        case .heavy:
            return "circle.fill"
        }
    }
    
    private func submitReport() async {
        let success = await viewModel.submitReport()
        if success {
            showingSuccessAlert = true
        }
    }
}

// MARK: - Location Map View

struct LocationMapView: View {
    let coordinate: CLLocationCoordinate2D
    
    var body: some View {
        Map(coordinateRegion: .constant(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )), annotationItems: [LocationAnnotation(coordinate: coordinate)]) { location in
            MapMarker(coordinate: location.coordinate, tint: .red)
        }
        .disabled(true)
    }
}

struct LocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}


// MARK: - Preview

struct ReportView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // iPhone Preview
            ReportView()
                .previewDevice("iPhone 16 Pro")
                .previewDisplayName("iPhone")
            
            // iPad Preview
            ReportView()
                .previewDevice("iPad Pro (13-inch) (M4)")
                .previewDisplayName("iPad")
        }
    }
}