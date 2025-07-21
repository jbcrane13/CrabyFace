import Foundation
import CoreLocation

struct UserReport: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    let userId: UUID
    let timestamp: Date
    let location: CLLocationCoordinate2D
    let jubileeEventId: UUID?
    let description: String
    let photos: [PhotoReference]
    let intensity: JubileeIntensity
    let marineLife: [String]
    let upvotes: Int
    let downvotes: Int
    let verificationStatus: VerificationStatus
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        timestamp: Date = Date(),
        location: CLLocationCoordinate2D,
        jubileeEventId: UUID? = nil,
        description: String,
        photos: [PhotoReference] = [],
        intensity: JubileeIntensity,
        marineLife: [String] = [],
        upvotes: Int = 0,
        downvotes: Int = 0,
        verificationStatus: VerificationStatus = .userReported
    ) {
        self.id = id
        self.userId = userId
        self.timestamp = timestamp
        self.location = location
        self.jubileeEventId = jubileeEventId
        self.description = description
        self.photos = photos
        self.intensity = intensity
        self.marineLife = marineLife
        self.upvotes = upvotes
        self.downvotes = downvotes
        self.verificationStatus = verificationStatus
    }
    
    // MARK: - Calculated Properties
    
    var credibilityScore: Double {
        let totalVotes = upvotes + downvotes
        guard totalVotes > 0 else { return 0.5 } // Default score for no votes
        return Double(upvotes) / Double(totalVotes)
    }
    
    var isVerified: Bool {
        verificationStatus == .verified
    }
    
    var isValid: Bool {
        // Validate description is not empty
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        
        // Validate maximum 5 photos
        guard photos.count <= 5 else { return false }
        
        // Validate timestamp is not in the future
        guard timestamp <= Date() else { return false }
        
        // Validate coordinates
        guard CLLocationCoordinate2DIsValid(location) else { return false }
        
        // Validate votes are non-negative
        guard upvotes >= 0 && downvotes >= 0 else { return false }
        
        return true
    }
    
    // MARK: - Equatable
    
    static func == (lhs: UserReport, rhs: UserReport) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case timestamp
        case latitude
        case longitude
        case jubileeEventId
        case description
        case photos
        case intensity
        case marineLife
        case upvotes
        case downvotes
        case verificationStatus
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        jubileeEventId = try container.decodeIfPresent(UUID.self, forKey: .jubileeEventId)
        description = try container.decode(String.self, forKey: .description)
        photos = try container.decode([PhotoReference].self, forKey: .photos)
        intensity = try container.decode(JubileeIntensity.self, forKey: .intensity)
        marineLife = try container.decode([String].self, forKey: .marineLife)
        upvotes = try container.decode(Int.self, forKey: .upvotes)
        downvotes = try container.decode(Int.self, forKey: .downvotes)
        verificationStatus = try container.decode(VerificationStatus.self, forKey: .verificationStatus)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(location.latitude, forKey: .latitude)
        try container.encode(location.longitude, forKey: .longitude)
        try container.encodeIfPresent(jubileeEventId, forKey: .jubileeEventId)
        try container.encode(description, forKey: .description)
        try container.encode(photos, forKey: .photos)
        try container.encode(intensity, forKey: .intensity)
        try container.encode(marineLife, forKey: .marineLife)
        try container.encode(upvotes, forKey: .upvotes)
        try container.encode(downvotes, forKey: .downvotes)
        try container.encode(verificationStatus, forKey: .verificationStatus)
    }
}