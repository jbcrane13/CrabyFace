import XCTest
import CoreLocation
@testable import JubileeMobileBay

final class UserReportTests: XCTestCase {
    
    // MARK: - Model Tests
    
    func test_userReport_initialization_shouldSetAllProperties() {
        // Given
        let id = UUID()
        let userId = UUID()
        let timestamp = Date()
        let location = CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399)
        let jubileeEventId = UUID()
        let description = "Large jubilee event with many flounder and crabs"
        let photos = [
            PhotoReference(id: UUID(), url: URL(string: "https://example.com/photo1.jpg")!, thumbnailUrl: URL(string: "https://example.com/photo1_thumb.jpg")!),
            PhotoReference(id: UUID(), url: URL(string: "https://example.com/photo2.jpg")!, thumbnailUrl: URL(string: "https://example.com/photo2_thumb.jpg")!)
        ]
        let intensity = JubileeIntensity.heavy
        let marineLife = ["flounder", "blue crab", "shrimp", "stingray"]
        let upvotes = 15
        let downvotes = 2
        let verificationStatus = VerificationStatus.verified
        
        // When
        let report = UserReport(
            id: id,
            userId: userId,
            timestamp: timestamp,
            location: location,
            jubileeEventId: jubileeEventId,
            description: description,
            photos: photos,
            intensity: intensity,
            marineLife: marineLife,
            upvotes: upvotes,
            downvotes: downvotes,
            verificationStatus: verificationStatus
        )
        
        // Then
        XCTAssertEqual(report.id, id)
        XCTAssertEqual(report.userId, userId)
        XCTAssertEqual(report.timestamp, timestamp)
        XCTAssertEqual(report.location.latitude, location.latitude)
        XCTAssertEqual(report.location.longitude, location.longitude)
        XCTAssertEqual(report.jubileeEventId, jubileeEventId)
        XCTAssertEqual(report.description, description)
        XCTAssertEqual(report.photos.count, 2)
        XCTAssertEqual(report.intensity, intensity)
        XCTAssertEqual(report.marineLife, marineLife)
        XCTAssertEqual(report.upvotes, upvotes)
        XCTAssertEqual(report.downvotes, downvotes)
        XCTAssertEqual(report.verificationStatus, verificationStatus)
    }
    
    func test_userReport_optionalProperties_shouldHandleNilValues() {
        // Given
        let report = UserReport(
            id: UUID(),
            userId: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            jubileeEventId: nil,
            description: "Possible jubilee starting",
            photos: [],
            intensity: .light,
            marineLife: [],
            upvotes: 0,
            downvotes: 0,
            verificationStatus: .userReported
        )
        
        // When & Then
        XCTAssertNil(report.jubileeEventId)
        XCTAssertTrue(report.photos.isEmpty)
        XCTAssertTrue(report.marineLife.isEmpty)
    }
    
    // MARK: - Calculated Properties Tests
    
    func test_userReport_credibilityScore_shouldCalculateCorrectly() {
        // Given
        let report1 = UserReport(
            id: UUID(),
            userId: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            jubileeEventId: UUID(),
            description: "Jubilee event",
            photos: [],
            intensity: .moderate,
            marineLife: [],
            upvotes: 20,
            downvotes: 5,
            verificationStatus: .userReported
        )
        
        // When
        let score = report1.credibilityScore
        
        // Then
        XCTAssertEqual(score, 0.8, accuracy: 0.01) // 20 / (20 + 5) = 0.8
    }
    
    func test_userReport_credibilityScore_shouldHandleZeroVotes() {
        // Given
        let report = UserReport(
            id: UUID(),
            userId: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            jubileeEventId: nil,
            description: "New report",
            photos: [],
            intensity: .light,
            marineLife: [],
            upvotes: 0,
            downvotes: 0,
            verificationStatus: .userReported
        )
        
        // When
        let score = report.credibilityScore
        
        // Then
        XCTAssertEqual(score, 0.5) // Default score for no votes
    }
    
    func test_userReport_isVerified_shouldReturnTrueForVerifiedStatus() {
        // Given
        let report = UserReport(
            id: UUID(),
            userId: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            jubileeEventId: UUID(),
            description: "Confirmed jubilee",
            photos: [],
            intensity: .heavy,
            marineLife: ["flounder", "crab"],
            upvotes: 50,
            downvotes: 2,
            verificationStatus: .verified
        )
        
        // When & Then
        XCTAssertTrue(report.isVerified)
    }
    
    func test_userReport_isVerified_shouldReturnFalseForUnverifiedStatus() {
        // Given
        let report = UserReport(
            id: UUID(),
            userId: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            jubileeEventId: nil,
            description: "Possible jubilee",
            photos: [],
            intensity: .light,
            marineLife: [],
            upvotes: 3,
            downvotes: 1,
            verificationStatus: .userReported
        )
        
        // When & Then
        XCTAssertFalse(report.isVerified)
    }
    
    // MARK: - Validation Tests
    
    func test_userReport_validation_shouldFailForEmptyDescription() {
        // Given
        let report = UserReport(
            id: UUID(),
            userId: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            jubileeEventId: nil,
            description: "", // Empty description
            photos: [],
            intensity: .moderate,
            marineLife: [],
            upvotes: 0,
            downvotes: 0,
            verificationStatus: .userReported
        )
        
        // When & Then
        XCTAssertFalse(report.isValid)
    }
    
    func test_userReport_validation_shouldFailForTooManyPhotos() {
        // Given
        var photos: [PhotoReference] = []
        for i in 0..<6 { // More than 5 photos
            photos.append(PhotoReference(
                id: UUID(),
                url: URL(string: "https://example.com/photo\(i).jpg")!,
                thumbnailUrl: URL(string: "https://example.com/photo\(i)_thumb.jpg")!
            ))
        }
        
        let report = UserReport(
            id: UUID(),
            userId: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            jubileeEventId: nil,
            description: "Jubilee with too many photos",
            photos: photos,
            intensity: .moderate,
            marineLife: [],
            upvotes: 0,
            downvotes: 0,
            verificationStatus: .userReported
        )
        
        // When & Then
        XCTAssertFalse(report.isValid)
    }
    
    func test_userReport_validation_shouldFailForFutureTimestamp() {
        // Given
        let report = UserReport(
            id: UUID(),
            userId: UUID(),
            timestamp: Date().addingTimeInterval(3600), // 1 hour in the future
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            jubileeEventId: nil,
            description: "Future jubilee report",
            photos: [],
            intensity: .moderate,
            marineLife: [],
            upvotes: 0,
            downvotes: 0,
            verificationStatus: .userReported
        )
        
        // When & Then
        XCTAssertFalse(report.isValid)
    }
    
    func test_userReport_validation_shouldPassForValidReport() {
        // Given
        let report = UserReport(
            id: UUID(),
            userId: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            jubileeEventId: UUID(),
            description: "Active jubilee with many flounder",
            photos: [
                PhotoReference(id: UUID(), url: URL(string: "https://example.com/photo1.jpg")!, thumbnailUrl: URL(string: "https://example.com/photo1_thumb.jpg")!)
            ],
            intensity: .moderate,
            marineLife: ["flounder", "blue crab"],
            upvotes: 10,
            downvotes: 1,
            verificationStatus: .userReported
        )
        
        // When & Then
        XCTAssertTrue(report.isValid)
    }
    
    // MARK: - Equatable Tests
    
    func test_userReport_equatable_shouldBeEqualWhenIDsMatch() {
        // Given
        let id = UUID()
        let report1 = UserReport(
            id: id,
            userId: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            jubileeEventId: nil,
            description: "Report 1",
            photos: [],
            intensity: .light,
            marineLife: [],
            upvotes: 0,
            downvotes: 0,
            verificationStatus: .userReported
        )
        
        let report2 = UserReport(
            id: id,
            userId: UUID(),
            timestamp: Date().addingTimeInterval(100),
            location: CLLocationCoordinate2D(latitude: 31.0, longitude: -89.0),
            jubileeEventId: UUID(),
            description: "Report 2",
            photos: [PhotoReference.mock],
            intensity: .heavy,
            marineLife: ["flounder"],
            upvotes: 100,
            downvotes: 5,
            verificationStatus: .verified
        )
        
        // When & Then
        XCTAssertEqual(report1, report2)
    }
}

// MARK: - Mock Extensions

extension PhotoReference {
    static var mock: PhotoReference {
        PhotoReference(
            id: UUID(),
            url: URL(string: "https://example.com/photo.jpg")!,
            thumbnailUrl: URL(string: "https://example.com/photo_thumb.jpg")!
        )
    }
}

extension UserReport {
    static var mock: UserReport {
        UserReport(
            id: UUID(),
            userId: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            jubileeEventId: UUID(),
            description: "Active jubilee event with flounder and crabs",
            photos: [PhotoReference.mock],
            intensity: .moderate,
            marineLife: ["flounder", "blue crab"],
            upvotes: 10,
            downvotes: 2,
            verificationStatus: .userReported
        )
    }
}