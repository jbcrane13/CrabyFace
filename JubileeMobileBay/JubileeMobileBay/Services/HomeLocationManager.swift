//
//  HomeLocationManager.swift
//  JubileeMobileBay
//
//  Manages user's home location with offline-first persistence
//

import Foundation
import CoreLocation
import CloudKit

protocol HomeLocationManagerProtocol {
    var homeLocation: CLLocation? { get }
    var homeLocationName: String? { get }
    func setHomeLocation(_ location: CLLocation) async throws
    func syncWithCloudKit() async throws
    func clearHomeLocation()
}

@MainActor
class HomeLocationManager: ObservableObject, HomeLocationManagerProtocol {
    
    // MARK: - Published Properties
    
    @Published private(set) var homeLocation: CLLocation?
    @Published private(set) var homeLocationName: String?
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    
    // MARK: - Private Properties
    
    private let userDefaults: UserDefaults
    private let cloudKitService: CloudKitServiceProtocol
    private let geocoder = CLGeocoder()
    
    // UserDefaults Keys
    private enum Keys {
        static let homeLatitude = "homeLocationLatitude"
        static let homeLongitude = "homeLocationLongitude"
        static let homeLocationName = "homeLocationName"
        static let lastSyncDate = "homeLocationLastSync"
    }
    
    // MARK: - Initialization
    
    init(userDefaults: UserDefaults = .standard,
         cloudKitService: CloudKitServiceProtocol) {
        self.userDefaults = userDefaults
        self.cloudKitService = cloudKitService
        
        // Load saved location
        loadSavedLocation()
    }
    
    // MARK: - Public Methods
    
    func setHomeLocation(_ location: CLLocation) async throws {
        // 1. Save immediately to UserDefaults (offline-first)
        saveToUserDefaults(location)
        
        // 2. Update published property
        self.homeLocation = location
        
        // 3. Perform reverse geocoding
        await performReverseGeocoding(for: location)
        
        // 4. Queue for CloudKit sync
        Task {
            try? await syncWithCloudKit()
        }
    }
    
    func syncWithCloudKit() async throws {
        guard let location = homeLocation else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            // Create CloudKit record
            let record = CKRecord(recordType: "UserPreferences")
            record["homeLatitude"] = location.coordinate.latitude
            record["homeLongitude"] = location.coordinate.longitude
            record["homeLocationName"] = homeLocationName
            record["lastUpdated"] = Date()
            
            // Save to CloudKit
            // TODO: Phase 2 - Implement CloudKit sync
            // try await cloudKitService.save(record)
            
            // Update sync date
            lastSyncDate = Date()
            userDefaults.set(lastSyncDate, forKey: Keys.lastSyncDate)
            
        } catch {
            print("Failed to sync home location to CloudKit: \(error)")
            throw error
        }
    }
    
    func clearHomeLocation() {
        homeLocation = nil
        homeLocationName = nil
        lastSyncDate = nil
        
        // Clear from UserDefaults
        userDefaults.removeObject(forKey: Keys.homeLatitude)
        userDefaults.removeObject(forKey: Keys.homeLongitude)
        userDefaults.removeObject(forKey: Keys.homeLocationName)
        userDefaults.removeObject(forKey: Keys.lastSyncDate)
        
        // Clear from CloudKit
        Task {
            try? await deleteFromCloudKit()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadSavedLocation() {
        guard userDefaults.object(forKey: Keys.homeLatitude) != nil else { return }
        
        let latitude = userDefaults.double(forKey: Keys.homeLatitude)
        let longitude = userDefaults.double(forKey: Keys.homeLongitude)
        
        homeLocation = CLLocation(latitude: latitude, longitude: longitude)
        homeLocationName = userDefaults.string(forKey: Keys.homeLocationName)
        lastSyncDate = userDefaults.object(forKey: Keys.lastSyncDate) as? Date
    }
    
    private func saveToUserDefaults(_ location: CLLocation) {
        userDefaults.set(location.coordinate.latitude, forKey: Keys.homeLatitude)
        userDefaults.set(location.coordinate.longitude, forKey: Keys.homeLongitude)
    }
    
    private func performReverseGeocoding(for location: CLLocation) async {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            if let placemark = placemarks.first {
                let locationName = buildLocationName(from: placemark)
                self.homeLocationName = locationName
                userDefaults.set(locationName, forKey: Keys.homeLocationName)
            }
        } catch {
            print("Reverse geocoding failed: \(error)")
            // Use coordinate string as fallback
            self.homeLocationName = String(format: "%.4f, %.4f", 
                                          location.coordinate.latitude,
                                          location.coordinate.longitude)
            userDefaults.set(homeLocationName, forKey: Keys.homeLocationName)
        }
    }
    
    private func buildLocationName(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        // Build location name from available components
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let subLocality = placemark.subLocality, subLocality != placemark.locality {
            components.append(subLocality)
        }
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        return components.isEmpty ? "Unknown Location" : components.joined(separator: ", ")
    }
    
    private func deleteFromCloudKit() async throws {
        // TODO: Phase 2 - Implement CloudKit sync
        // Fetch existing record
        // let predicate = NSPredicate(format: "TRUEPREDICATE")
        // let query = CKQuery(recordType: "UserPreferences", predicate: predicate)
        
        // do {
        //     let records = try await cloudKitService.fetch(with: query, in: .private)
        //     if let record = records.first {
        //         try await cloudKitService.delete(recordID: record.recordID)
        //     }
        // } catch {
        //     print("Failed to delete home location from CloudKit: \(error)")
        // }
    }
}

// MARK: - Mock for Testing

class MockHomeLocationManager: HomeLocationManagerProtocol {
    var homeLocation: CLLocation?
    var homeLocationName: String?
    var setLocationCalled = false
    var syncCalled = false
    
    func setHomeLocation(_ location: CLLocation) async throws {
        setLocationCalled = true
        homeLocation = location
        homeLocationName = "Mock Location"
    }
    
    func syncWithCloudKit() async throws {
        syncCalled = true
    }
    
    func clearHomeLocation() {
        homeLocation = nil
        homeLocationName = nil
    }
}