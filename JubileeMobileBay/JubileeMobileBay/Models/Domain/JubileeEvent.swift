import Foundation
import CoreLocation

struct JubileeEvent: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date?
    let location: CLLocationCoordinate2D
    let intensity: JubileeIntensity
    let verificationStatus: VerificationStatus
    let reportCount: Int
    let reportedBy: String
    let notes: String?
    let metadata: JubileeMetadata
    
    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date? = nil,
        location: CLLocationCoordinate2D,
        intensity: JubileeIntensity,
        verificationStatus: VerificationStatus,
        reportCount: Int = 0,
        reportedBy: String,
        notes: String? = nil,
        metadata: JubileeMetadata
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.intensity = intensity
        self.verificationStatus = verificationStatus
        self.reportCount = reportCount
        self.reportedBy = reportedBy
        self.notes = notes
        self.metadata = metadata
    }
    
    // MARK: - Calculated Properties
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    var isActive: Bool {
        if endTime == nil {
            return true
        }
        if let endTime = endTime {
            return endTime > Date()
        }
        return false
    }
    
    var isValid: Bool {
        // Validate coordinates
        guard CLLocationCoordinate2DIsValid(location) else { return false }
        
        // Validate time relationship
        if let endTime = endTime {
            guard endTime >= startTime else { return false }
        }
        
        return true
    }
    
    // MARK: - Equatable
    
    static func == (lhs: JubileeEvent, rhs: JubileeEvent) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case startTime
        case endTime
        case latitude
        case longitude
        case intensity
        case verificationStatus
        case reportCount
        case reportedBy
        case notes
        case metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        intensity = try container.decode(JubileeIntensity.self, forKey: .intensity)
        verificationStatus = try container.decode(VerificationStatus.self, forKey: .verificationStatus)
        reportCount = try container.decode(Int.self, forKey: .reportCount)
        reportedBy = try container.decode(String.self, forKey: .reportedBy)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        metadata = try container.decode(JubileeMetadata.self, forKey: .metadata)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(location.latitude, forKey: .latitude)
        try container.encode(location.longitude, forKey: .longitude)
        try container.encode(intensity, forKey: .intensity)
        try container.encode(verificationStatus, forKey: .verificationStatus)
        try container.encode(reportCount, forKey: .reportCount)
        try container.encode(reportedBy, forKey: .reportedBy)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(metadata, forKey: .metadata)
    }
}