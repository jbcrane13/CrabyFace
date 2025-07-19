//
//  ReportViewModelTests.swift
//  JubileeMobileBayTests
//
//  Test-Driven Development for Report submission
//

import XCTest
import CoreLocation
import PhotosUI
import SwiftUI
@testable import JubileeMobileBay

@MainActor
class ReportViewModelTests: XCTestCase {
    
    var viewModel: ReportViewModel!
    var mockCloudKitService: MockCloudKitService!
    var mockLocationService: MockLocationService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockCloudKitService = MockCloudKitService()
        mockLocationService = MockLocationService()
        viewModel = ReportViewModel(
            cloudKitService: mockCloudKitService,
            locationService: mockLocationService
        )
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockCloudKitService = nil
        mockLocationService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_shouldSetDefaultValues() {
        XCTAssertEqual(viewModel.description, "")
        XCTAssertEqual(viewModel.intensity, .moderate)
        XCTAssertTrue(viewModel.photos.isEmpty)
        XCTAssertTrue(viewModel.marineLifeObservations.isEmpty)
        XCTAssertNil(viewModel.location)
        XCTAssertNil(viewModel.jubileeEventId)
        XCTAssertFalse(viewModel.isSubmitting)
        XCTAssertNil(viewModel.error)
    }
    
    func test_init_withEvent_shouldPreFillEventData() {
        let eventLocation = CLLocationCoordinate2D(latitude: 30.4672, longitude: -87.9833)
        let event = JubileeEvent(
            startTime: Date(),
            location: eventLocation,
            intensity: .heavy,
            verificationStatus: .verified,
            reportCount: 5,
            metadata: JubileeMetadata.mock
        )
        
        viewModel = ReportViewModel(
            cloudKitService: mockCloudKitService,
            locationService: mockLocationService,
            event: event
        )
        
        XCTAssertEqual(viewModel.jubileeEventId, event.id)
        XCTAssertEqual(viewModel.location?.latitude, eventLocation.latitude, accuracy: 0.0001)
        XCTAssertEqual(viewModel.location?.longitude, eventLocation.longitude, accuracy: 0.0001)
        XCTAssertEqual(viewModel.intensity, event.intensity)
    }
    
    // MARK: - Location Tests
    
    func test_useCurrentLocation_shouldRequestLocationAndUpdate() {
        let mockLocation = CLLocation(latitude: 30.5, longitude: -88.0)
        mockLocationService.currentLocation = mockLocation
        
        viewModel.useCurrentLocation()
        
        XCTAssertEqual(viewModel.location?.latitude, 30.5, accuracy: 0.0001)
        XCTAssertEqual(viewModel.location?.longitude, -88.0, accuracy: 0.0001)
    }
    
    func test_useCurrentLocation_whenNoLocation_shouldSetError() {
        mockLocationService.currentLocation = nil
        
        viewModel.useCurrentLocation()
        
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error, "Location not available")
    }
    
    // MARK: - Photo Selection Tests
    
    func test_addPhotos_shouldAppendToPhotosArray() {
        let photo1 = PhotoItem(id: UUID())
        let photo2 = PhotoItem(id: UUID())
        
        viewModel.addPhotos([photo1, photo2])
        
        XCTAssertEqual(viewModel.photos.count, 2)
        XCTAssertTrue(viewModel.photos.contains { $0.id == photo1.id })
        XCTAssertTrue(viewModel.photos.contains { $0.id == photo2.id })
    }
    
    func test_removePhoto_shouldRemoveFromPhotosArray() {
        let photo1 = PhotoItem(id: UUID())
        let photo2 = PhotoItem(id: UUID())
        viewModel.photos = [photo1, photo2]
        
        viewModel.removePhoto(photo1)
        
        XCTAssertEqual(viewModel.photos.count, 1)
        XCTAssertFalse(viewModel.photos.contains { $0.id == photo1.id })
        XCTAssertTrue(viewModel.photos.contains { $0.id == photo2.id })
    }
    
    // MARK: - Marine Life Tests
    
    func test_addMarineLifeObservation_shouldAddToList() {
        viewModel.addMarineLifeObservation("Mullet")
        viewModel.addMarineLifeObservation("Flounder")
        
        XCTAssertEqual(viewModel.marineLifeObservations.count, 2)
        XCTAssertTrue(viewModel.marineLifeObservations.contains("Mullet"))
        XCTAssertTrue(viewModel.marineLifeObservations.contains("Flounder"))
    }
    
    func test_removeMarineLifeObservation_shouldRemoveFromList() {
        viewModel.marineLifeObservations = ["Mullet", "Flounder", "Crab"]
        
        viewModel.removeMarineLifeObservation("Flounder")
        
        XCTAssertEqual(viewModel.marineLifeObservations.count, 2)
        XCTAssertFalse(viewModel.marineLifeObservations.contains("Flounder"))
    }
    
    // MARK: - Validation Tests
    
    func test_canSubmit_whenAllFieldsValid_shouldReturnTrue() {
        viewModel.description = "Fish kill observed"
        viewModel.location = CLLocationCoordinate2D(latitude: 30.4672, longitude: -87.9833)
        viewModel.intensity = .moderate
        
        XCTAssertTrue(viewModel.canSubmit)
    }
    
    func test_canSubmit_whenDescriptionEmpty_shouldReturnFalse() {
        viewModel.description = ""
        viewModel.location = CLLocationCoordinate2D(latitude: 30.4672, longitude: -87.9833)
        
        XCTAssertFalse(viewModel.canSubmit)
    }
    
    func test_canSubmit_whenLocationNil_shouldReturnFalse() {
        viewModel.description = "Fish kill observed"
        viewModel.location = nil
        
        XCTAssertFalse(viewModel.canSubmit)
    }
    
    func test_canSubmit_whenSubmitting_shouldReturnFalse() {
        viewModel.description = "Fish kill observed"
        viewModel.location = CLLocationCoordinate2D(latitude: 30.4672, longitude: -87.9833)
        viewModel.isSubmitting = true
        
        XCTAssertFalse(viewModel.canSubmit)
    }
    
    // MARK: - Submit Tests
    
    func test_submitReport_shouldCreateAndSaveUserReport() async throws {
        // Given
        viewModel.description = "Major fish kill observed"
        viewModel.location = CLLocationCoordinate2D(latitude: 30.4672, longitude: -87.9833)
        viewModel.intensity = .heavy
        viewModel.marineLifeObservations = ["Mullet", "Flounder"]
        
        let photo = PhotoItem(id: UUID())
        viewModel.photos = [photo]
        
        mockCloudKitService.saveUserReportResult = .success(())
        
        // When
        let result = await viewModel.submitReport()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockCloudKitService.savedUserReports.count, 1)
        
        let savedReport = mockCloudKitService.savedUserReports.first
        XCTAssertEqual(savedReport?.description, "Major fish kill observed")
        XCTAssertEqual(savedReport?.intensity, .heavy)
        XCTAssertEqual(savedReport?.location.latitude, 30.4672, accuracy: 0.0001)
        XCTAssertEqual(savedReport?.marineLife.count, 2)
        XCTAssertTrue(savedReport?.marineLife.contains("Mullet") ?? false)
        XCTAssertFalse(viewModel.isSubmitting)
    }
    
    func test_submitReport_whenSaveFails_shouldSetError() async throws {
        // Given
        viewModel.description = "Test report"
        viewModel.location = CLLocationCoordinate2D(latitude: 30.4672, longitude: -87.9833)
        
        mockCloudKitService.saveUserReportResult = .failure(CloudKitError.unknown)
        
        // When
        let result = await viewModel.submitReport()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isSubmitting)
    }
    
    func test_submitReport_withEventId_shouldLinkToEvent() async throws {
        // Given
        let eventId = UUID()
        viewModel.jubileeEventId = eventId
        viewModel.description = "Additional observation"
        viewModel.location = CLLocationCoordinate2D(latitude: 30.4672, longitude: -87.9833)
        
        mockCloudKitService.saveUserReportResult = .success(())
        
        // When
        let _ = await viewModel.submitReport()
        
        // Then
        let savedReport = mockCloudKitService.savedUserReports.first
        XCTAssertEqual(savedReport?.jubileeEventId, eventId)
    }
}

// MARK: - Mock CloudKit Service

class MockCloudKitService: CloudKitServiceProtocol {
    var savedUserReports: [UserReport] = []
    var saveUserReportResult: Result<Void, Error> = .success(())
    
    func saveUserReport(_ report: UserReport) async throws {
        switch saveUserReportResult {
        case .success:
            savedUserReports.append(report)
        case .failure(let error):
            throw error
        }
    }
    
    func saveJubileeEvent(_ event: JubileeEvent) async throws {
        // Not used in these tests
    }
    
    func fetchRecentJubileeEvents(limit: Int) async throws -> [JubileeEvent] {
        return []
    }
    
    func fetchUserReports(for eventId: UUID) async throws -> [UserReport] {
        return []
    }
    
    func subscribeToJubileeEvents() async throws -> CKQuerySubscription {
        fatalError("Not implemented for tests")
    }
}

// MARK: - Photo Item

struct PhotoItem: Identifiable {
    let id: UUID
    var image: UIImage?
    var photoReference: PhotoReference?
}

// MARK: - Mock Extensions

extension JubileeMetadata {
    static var mock: JubileeMetadata {
        JubileeMetadata(
            windSpeed: 5.0,
            windDirection: 180,
            temperature: 75.0,
            humidity: 85.0,
            waterTemperature: 72.0,
            dissolvedOxygen: 2.5,
            salinity: 28.0,
            tide: .rising,
            moonPhase: .full
        )
    }
}