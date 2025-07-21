//
//  ReportViewModelTests.swift
//  JubileeMobileBayTests
//
//  TDD tests for ReportViewModel
//

import XCTest
import CoreLocation
@testable import JubileeMobileBay

@MainActor
class ReportViewModelTests: XCTestCase {
    
    var sut: ReportViewModel!
    var mockCloudKitService: MockCloudKitService!
    var mockLocationService: MockLocationService!
    var mockUserSessionManager: MockUserSessionManager!
    var mockPhotoUploadService: MockPhotoUploadService!
    
    override func setUp() {
        super.setUp()
        
        mockCloudKitService = MockCloudKitService()
        mockLocationService = MockLocationService()
        mockUserSessionManager = MockUserSessionManager()
        mockPhotoUploadService = MockPhotoUploadService()
        
        sut = ReportViewModel(
            cloudKitService: mockCloudKitService,
            locationService: mockLocationService,
            userSessionManager: mockUserSessionManager,
            photoUploadService: mockPhotoUploadService
        )
    }
    
    override func tearDown() {
        sut = nil
        mockCloudKitService = nil
        mockLocationService = nil
        mockUserSessionManager = nil
        mockPhotoUploadService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_shouldSetDefaultValues() {
        XCTAssertEqual(sut.description, "")
        XCTAssertEqual(sut.intensity, .moderate)
        XCTAssertTrue(sut.photos.isEmpty)
        XCTAssertTrue(sut.marineLifeObservations.isEmpty)
        XCTAssertNil(sut.location)
        XCTAssertNil(sut.jubileeEventId)
        XCTAssertFalse(sut.isSubmitting)
        XCTAssertNil(sut.error)
    }
    
    func test_init_withEvent_shouldPreFillEventData() {
        // Given
        let event = JubileeEvent(
            id: UUID(),
            location: CLLocationCoordinate2D(latitude: 30.0, longitude: -88.0),
            intensity: .heavy,
            startTime: Date(),
            verificationStatus: .userReported,
            metadata: JubileeMetadata(
                temperature: 25.0,
                humidity: 80.0,
                windSpeed: 10.0,
                windDirection: "NE",
                dissolvedOxygen: 3.5
            )
        )
        
        // When
        sut = ReportViewModel(event: event)
        
        // Then
        XCTAssertEqual(sut.jubileeEventId, event.id)
        XCTAssertEqual(sut.location?.latitude, event.location.latitude)
        XCTAssertEqual(sut.location?.longitude, event.location.longitude)
        XCTAssertEqual(sut.intensity, event.intensity)
    }
    
    // MARK: - Location Tests
    
    func test_useCurrentLocation_withAvailableLocation_shouldSetLocation() {
        // Given
        let expectedLocation = CLLocation(latitude: 30.5, longitude: -88.5)
        mockLocationService.currentLocation = expectedLocation
        
        // When
        sut.useCurrentLocation()
        
        // Then
        XCTAssertEqual(sut.location?.latitude, expectedLocation.coordinate.latitude)
        XCTAssertEqual(sut.location?.longitude, expectedLocation.coordinate.longitude)
        XCTAssertNil(sut.error)
    }
    
    func test_useCurrentLocation_withNoLocation_shouldSetError() {
        // Given
        mockLocationService.currentLocation = nil
        
        // When
        sut.useCurrentLocation()
        
        // Then
        XCTAssertNil(sut.location)
        XCTAssertEqual(sut.error, "Location not available")
    }
    
    // MARK: - Marine Life Tests
    
    func test_addMarineLifeObservation_withValidSpecies_shouldAdd() {
        // When
        sut.addMarineLifeObservation("Blue Crab")
        
        // Then
        XCTAssertEqual(sut.marineLifeObservations.count, 1)
        XCTAssertTrue(sut.marineLifeObservations.contains("Blue Crab"))
    }
    
    func test_addMarineLifeObservation_withEmptyString_shouldNotAdd() {
        // When
        sut.addMarineLifeObservation("")
        
        // Then
        XCTAssertTrue(sut.marineLifeObservations.isEmpty)
    }
    
    func test_addMarineLifeObservation_withDuplicate_shouldNotAddAgain() {
        // Given
        sut.addMarineLifeObservation("Shrimp")
        
        // When
        sut.addMarineLifeObservation("Shrimp")
        
        // Then
        XCTAssertEqual(sut.marineLifeObservations.count, 1)
    }
    
    func test_removeMarineLifeObservation_shouldRemove() {
        // Given
        sut.marineLifeObservations = ["Blue Crab", "Shrimp", "Flounder"]
        
        // When
        sut.removeMarineLifeObservation("Shrimp")
        
        // Then
        XCTAssertEqual(sut.marineLifeObservations.count, 2)
        XCTAssertFalse(sut.marineLifeObservations.contains("Shrimp"))
        XCTAssertTrue(sut.marineLifeObservations.contains("Blue Crab"))
        XCTAssertTrue(sut.marineLifeObservations.contains("Flounder"))
    }
    
    // MARK: - Submit Tests
    
    func test_canSubmit_withValidData_shouldReturnTrue() {
        // Given
        sut.description = "Observed jubilee event"
        sut.location = CLLocationCoordinate2D(latitude: 30.0, longitude: -88.0)
        sut.isSubmitting = false
        
        // Then
        XCTAssertTrue(sut.canSubmit)
    }
    
    func test_canSubmit_withEmptyDescription_shouldReturnFalse() {
        // Given
        sut.description = ""
        sut.location = CLLocationCoordinate2D(latitude: 30.0, longitude: -88.0)
        
        // Then
        XCTAssertFalse(sut.canSubmit)
    }
    
    func test_canSubmit_withNoLocation_shouldReturnFalse() {
        // Given
        sut.description = "Observed jubilee event"
        sut.location = nil
        
        // Then
        XCTAssertFalse(sut.canSubmit)
    }
    
    func test_canSubmit_whileSubmitting_shouldReturnFalse() {
        // Given
        sut.description = "Observed jubilee event"
        sut.location = CLLocationCoordinate2D(latitude: 30.0, longitude: -88.0)
        sut.isSubmitting = true
        
        // Then
        XCTAssertFalse(sut.canSubmit)
    }
    
    func test_submitReport_withValidData_shouldSucceed() async {
        // Given
        let userId = UUID()
        mockUserSessionManager.currentUserUUID = userId
        mockUserSessionManager.currentUserId = userId.uuidString
        
        sut.description = "Observed jubilee event with many fish"
        sut.location = CLLocationCoordinate2D(latitude: 30.0, longitude: -88.0)
        sut.intensity = .heavy
        sut.marineLifeObservations = ["Blue Crab", "Shrimp"]
        
        let expectedReport = UserReport(
            userId: userId,
            timestamp: Date(),
            location: sut.location!,
            description: sut.description,
            intensity: sut.intensity,
            marineLife: sut.marineLifeObservations
        )
        
        mockCloudKitService.saveUserReportResult = .success(expectedReport)
        
        // When
        let success = await sut.submitReport()
        
        // Then
        XCTAssertTrue(success)
        XCTAssertTrue(mockCloudKitService.saveUserReportCalled)
        XCTAssertFalse(sut.isSubmitting)
        XCTAssertNil(sut.error)
        
        // Verify form was cleared
        XCTAssertEqual(sut.description, "")
        XCTAssertEqual(sut.intensity, .moderate)
        XCTAssertTrue(sut.photos.isEmpty)
        XCTAssertTrue(sut.marineLifeObservations.isEmpty)
    }
    
    func test_submitReport_withNoUserId_shouldFail() async {
        // Given
        mockUserSessionManager.currentUserUUID = nil
        mockUserSessionManager.currentUserId = nil
        
        sut.description = "Observed jubilee event"
        sut.location = CLLocationCoordinate2D(latitude: 30.0, longitude: -88.0)
        
        // When
        let success = await sut.submitReport()
        
        // Then
        XCTAssertFalse(success)
        XCTAssertEqual(sut.error, "Unable to determine user ID")
        XCTAssertFalse(sut.isSubmitting)
    }
    
    func test_submitReport_withCloudKitError_shouldFail() async {
        // Given
        let userId = UUID()
        mockUserSessionManager.currentUserUUID = userId
        
        sut.description = "Observed jubilee event"
        sut.location = CLLocationCoordinate2D(latitude: 30.0, longitude: -88.0)
        
        mockCloudKitService.saveUserReportResult = .failure(CloudKitError.networkError)
        
        // When
        let success = await sut.submitReport()
        
        // Then
        XCTAssertFalse(success)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isSubmitting)
    }
    
    // MARK: - Photo Tests
    
    func test_addPhotos_shouldAddToCollection() {
        // Given
        let photo1 = PhotoItem(id: UUID())
        let photo2 = PhotoItem(id: UUID())
        
        // When
        sut.addPhotos([photo1, photo2])
        
        // Then
        XCTAssertEqual(sut.photos.count, 2)
        XCTAssertTrue(sut.photos.contains(where: { $0.id == photo1.id }))
        XCTAssertTrue(sut.photos.contains(where: { $0.id == photo2.id }))
    }
    
    func test_removePhoto_shouldRemoveFromCollection() {
        // Given
        let photo1 = PhotoItem(id: UUID())
        let photo2 = PhotoItem(id: UUID())
        sut.photos = [photo1, photo2]
        
        // When
        sut.removePhoto(photo1)
        
        // Then
        XCTAssertEqual(sut.photos.count, 1)
        XCTAssertFalse(sut.photos.contains(where: { $0.id == photo1.id }))
        XCTAssertTrue(sut.photos.contains(where: { $0.id == photo2.id }))
    }
}