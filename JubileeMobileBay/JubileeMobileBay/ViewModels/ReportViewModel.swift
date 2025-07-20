//
//  ReportViewModel.swift
//  JubileeMobileBay
//
//  ViewModel for event reporting with photo upload
//

import Foundation
import SwiftUI
import PhotosUI
import CoreLocation
import CloudKit

@MainActor
class ReportViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published var description = ""
    @Published var intensity: JubileeIntensity = .moderate
    @Published var photos: [PhotoItem] = []
    @Published var marineLifeObservations: [String] = []
    @Published var location: CLLocationCoordinate2D?
    @Published var jubileeEventId: UUID?
    @Published var isSubmitting = false
    @Published var error: String?
    
    private let cloudKitService: CloudKitService
    private let locationService: LocationServiceProtocol
    
    // MARK: - Computed Properties
    
    var canSubmit: Bool {
        !description.isEmpty &&
        location != nil &&
        !isSubmitting
    }
    
    // MARK: - Initialization
    
    init(cloudKitService: CloudKitService? = nil,
         locationService: LocationServiceProtocol? = nil,
         event: JubileeEvent? = nil) {
        self.cloudKitService = cloudKitService ?? CloudKitService()
        self.locationService = locationService ?? LocationService()
        
        // Pre-fill with event data if provided
        if let event = event {
            self.jubileeEventId = event.id
            self.location = event.location
            self.intensity = event.intensity
        }
    }
    
    // MARK: - Location Methods
    
    func useCurrentLocation() {
        if let currentLocation = locationService.currentLocation {
            self.location = currentLocation.coordinate
            self.error = nil
        } else {
            self.error = "Location not available"
        }
    }
    
    // MARK: - Photo Methods
    
    func addPhotos(_ items: [PhotoItem]) {
        photos.append(contentsOf: items)
    }
    
    func removePhoto(_ item: PhotoItem) {
        photos.removeAll { $0.id == item.id }
    }
    
    func loadPhoto(from item: PhotosPickerItem) async -> PhotoItem? {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            return nil
        }
        
        var photoItem = PhotoItem(id: UUID())
        photoItem.image = image
        
        // In a real app, we would upload to CloudKit Assets here
        // For now, we'll create a mock photo reference
        let mockUrl = URL(string: "https://cloudkit.example.com/photo/\(photoItem.id)")!
        photoItem.photoReference = PhotoReference(
            id: photoItem.id,
            url: mockUrl,
            thumbnailUrl: mockUrl
        )
        
        return photoItem
    }
    
    // MARK: - Marine Life Methods
    
    func addMarineLifeObservation(_ species: String) {
        if !species.isEmpty && !marineLifeObservations.contains(species) {
            marineLifeObservations.append(species)
        }
    }
    
    func removeMarineLifeObservation(_ species: String) {
        marineLifeObservations.removeAll { $0 == species }
    }
    
    // MARK: - Submit Method
    
    func submitReport() async -> Bool {
        guard canSubmit, let location = location else {
            error = "Please fill in all required fields"
            return false
        }
        
        isSubmitting = true
        error = nil
        
        do {
            // Create photo references (in real app, would upload to CloudKit)
            let photoReferences = photos.compactMap { $0.photoReference }
            
            // Create user report
            let report = UserReport(
                userId: UUID(), // In real app, would use Sign in with Apple user ID
                timestamp: Date(),
                location: location,
                jubileeEventId: jubileeEventId,
                description: description,
                photos: photoReferences,
                intensity: intensity,
                marineLife: marineLifeObservations
            )
            
            // Save to CloudKit
            try await cloudKitService.saveUserReport(report)
            
            // Clear form on success
            clearForm()
            
            isSubmitting = false
            return true
            
        } catch {
            self.error = error.localizedDescription
            isSubmitting = false
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func clearForm() {
        description = ""
        intensity = .moderate
        photos = []
        marineLifeObservations = []
        // Keep location and eventId if reporting for existing event
        if jubileeEventId == nil {
            location = nil
        }
    }
}

