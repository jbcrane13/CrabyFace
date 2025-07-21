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
    private let userSessionManager: UserSessionManagerProtocol
    private let photoUploadService: PhotoUploadService
    
    // MARK: - Computed Properties
    
    var canSubmit: Bool {
        !description.isEmpty &&
        location != nil &&
        !isSubmitting
    }
    
    // MARK: - Initialization
    
    init(cloudKitService: CloudKitService? = nil,
         locationService: LocationServiceProtocol? = nil,
         userSessionManager: UserSessionManagerProtocol? = nil,
         photoUploadService: PhotoUploadService? = nil,
         event: JubileeEvent? = nil) {
        self.cloudKitService = cloudKitService ?? CloudKitService()
        self.locationService = locationService ?? LocationService()
        self.userSessionManager = userSessionManager ?? UserSessionManager.shared
        self.photoUploadService = photoUploadService ?? PhotoUploadService()
        
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
        do {
            // Check photo library permissions first
            guard await photoUploadService.requestPhotoLibraryAccess() else {
                error = "Photo library access denied"
                return nil
            }
            
            // Load image data
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                return nil
            }
            
            var photoItem = PhotoItem(id: UUID())
            photoItem.image = image
            
            // Upload to CloudKit in background
            Task {
                do {
                    let references = try await photoUploadService.uploadPhotos(from: [item])
                    if let reference = references.first {
                        photoItem.photoReference = reference
                    }
                } catch {
                    print("Photo upload failed: \(error.localizedDescription)")
                    // Continue with local image for now
                }
            }
            
            return photoItem
        } catch {
            self.error = "Failed to load photo: \(error.localizedDescription)"
            return nil
        }
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
            // Upload any photos that don't have references yet
            var photoReferences: [PhotoReference] = []
            
            for photo in photos {
                if let reference = photo.photoReference {
                    photoReferences.append(reference)
                } else if let image = photo.image {
                    // Upload image if not already uploaded
                    do {
                        let references = try await photoUploadService.uploadReportPhotos(
                            for: UserReport(
                                userId: UUID(),
                                timestamp: Date(),
                                location: location,
                                description: description,
                                intensity: intensity
                            ),
                            images: [image]
                        )
                        if let reference = references.first {
                            photoReferences.append(reference)
                        }
                    } catch {
                        print("Failed to upload photo: \(error.localizedDescription)")
                        // Continue without this photo
                    }
                }
            }
            
            // Get authenticated user ID or use anonymous ID
            guard let userUUID = userSessionManager.currentUserUUID else {
                error = "Unable to determine user ID"
                isSubmitting = false
                return false
            }
            
            // Create user report with proper user ID
            let report = UserReport(
                userId: userUUID,
                timestamp: Date(),
                location: location,
                jubileeEventId: jubileeEventId,
                description: description,
                photos: photoReferences,
                intensity: intensity,
                marineLife: marineLifeObservations
            )
            
            // Save to CloudKit
            _ = try await cloudKitService.saveUserReport(report)
            
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

