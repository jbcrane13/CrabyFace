import XCTest
import CoreLocation
@testable import JubileeMobileBay

final class JubileeEventTests: XCTestCase {
    
    // MARK: - Model Tests
    
    func test_jubileeEvent_initialization_shouldSetAllProperties() {
        // Given
        let id = UUID()
        let startTime = Date()
        let endTime = Date().addingTimeInterval(3600)
        let location = CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399)
        let intensity = JubileeIntensity.moderate
        let verificationStatus = VerificationStatus.userReported
        let reportCount = 5
        let metadata = JubileeMetadata(
            windSpeed: 15.5,
            windDirection: 180,
            temperature: 75.0,
            humidity: 85.0,
            waterTemperature: 78.0,
            dissolvedOxygen: 2.5,
            salinity: 25.0,
            tide: .low,
            moonPhase: .full
        )
        
        // When
        let event = JubileeEvent(
            id: id,
            startTime: startTime,
            endTime: endTime,
            location: location,
            intensity: intensity,
            verificationStatus: verificationStatus,
            reportCount: reportCount,
            metadata: metadata
        )
        
        // Then
        XCTAssertEqual(event.id, id)
        XCTAssertEqual(event.startTime, startTime)
        XCTAssertEqual(event.endTime, endTime)
        XCTAssertEqual(event.location.latitude, location.latitude)
        XCTAssertEqual(event.location.longitude, location.longitude)
        XCTAssertEqual(event.intensity, intensity)
        XCTAssertEqual(event.verificationStatus, verificationStatus)
        XCTAssertEqual(event.reportCount, reportCount)
        XCTAssertEqual(event.metadata.windSpeed, 15.5)
        XCTAssertEqual(event.metadata.temperature, 75.0)
    }
    
    func test_jubileeEvent_duration_shouldCalculateCorrectly() {
        // Given
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(7200) // 2 hours
        let event = JubileeEvent(
            id: UUID(),
            startTime: startTime,
            endTime: endTime,
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            intensity: .heavy,
            verificationStatus: .verified,
            reportCount: 10,
            metadata: JubileeMetadata.mock
        )
        
        // When
        let duration = event.duration
        
        // Then
        XCTAssertEqual(duration, 7200, accuracy: 0.1)
    }
    
    func test_jubileeEvent_isActive_shouldReturnTrueWhenEndTimeIsNil() {
        // Given
        let event = JubileeEvent(
            id: UUID(),
            startTime: Date(),
            endTime: nil,
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            intensity: .light,
            verificationStatus: .predicted,
            reportCount: 0,
            metadata: JubileeMetadata.mock
        )
        
        // When & Then
        XCTAssertTrue(event.isActive)
    }
    
    func test_jubileeEvent_isActive_shouldReturnFalseWhenEndTimeIsPast() {
        // Given
        let event = JubileeEvent(
            id: UUID(),
            startTime: Date().addingTimeInterval(-7200),
            endTime: Date().addingTimeInterval(-3600),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            intensity: .moderate,
            verificationStatus: .verified,
            reportCount: 15,
            metadata: JubileeMetadata.mock
        )
        
        // When & Then
        XCTAssertFalse(event.isActive)
    }
    
    // MARK: - Validation Tests
    
    func test_jubileeEvent_validation_shouldFailForInvalidCoordinates() {
        // Given
        let event = JubileeEvent(
            id: UUID(),
            startTime: Date(),
            endTime: nil,
            location: CLLocationCoordinate2D(latitude: 91.0, longitude: -88.0399), // Invalid latitude
            intensity: .moderate,
            verificationStatus: .userReported,
            reportCount: 1,
            metadata: JubileeMetadata.mock
        )
        
        // When & Then
        XCTAssertFalse(event.isValid)
    }
    
    func test_jubileeEvent_validation_shouldFailForEndTimeBeforeStartTime() {
        // Given
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(-3600) // 1 hour before start
        let event = JubileeEvent(
            id: UUID(),
            startTime: startTime,
            endTime: endTime,
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            intensity: .heavy,
            verificationStatus: .verified,
            reportCount: 20,
            metadata: JubileeMetadata.mock
        )
        
        // When & Then
        XCTAssertFalse(event.isValid)
    }
    
    func test_jubileeEvent_validation_shouldPassForValidEvent() {
        // Given
        let event = JubileeEvent(
            id: UUID(),
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            intensity: .moderate,
            verificationStatus: .verified,
            reportCount: 10,
            metadata: JubileeMetadata.mock
        )
        
        // When & Then
        XCTAssertTrue(event.isValid)
    }
    
    // MARK: - Equatable Tests
    
    func test_jubileeEvent_equatable_shouldBeEqualWhenIDsMatch() {
        // Given
        let id = UUID()
        let event1 = JubileeEvent(
            id: id,
            startTime: Date(),
            endTime: nil,
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            intensity: .light,
            verificationStatus: .predicted,
            reportCount: 0,
            metadata: JubileeMetadata.mock
        )
        
        let event2 = JubileeEvent(
            id: id,
            startTime: Date().addingTimeInterval(100),
            endTime: Date().addingTimeInterval(200),
            location: CLLocationCoordinate2D(latitude: 31.0, longitude: -89.0),
            intensity: .heavy,
            verificationStatus: .verified,
            reportCount: 50,
            metadata: JubileeMetadata.mock
        )
        
        // When & Then
        XCTAssertEqual(event1, event2)
    }
    
    func test_jubileeEvent_equatable_shouldNotBeEqualWhenIDsDiffer() {
        // Given
        let event1 = JubileeEvent.mock
        let event2 = JubileeEvent.mock
        
        // When & Then
        XCTAssertNotEqual(event1, event2)
    }
}

// MARK: - Mock Extensions

extension JubileeMetadata {
    static var mock: JubileeMetadata {
        JubileeMetadata(
            windSpeed: 10.0,
            windDirection: 90,
            temperature: 72.0,
            humidity: 80.0,
            waterTemperature: 76.0,
            dissolvedOxygen: 3.0,
            salinity: 30.0,
            tide: .high,
            moonPhase: .new
        )
    }
}

extension JubileeEvent {
    static var mock: JubileeEvent {
        JubileeEvent(
            id: UUID(),
            startTime: Date(),
            endTime: nil,
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            intensity: .moderate,
            verificationStatus: .userReported,
            reportCount: 5,
            metadata: JubileeMetadata.mock
        )
    }
}