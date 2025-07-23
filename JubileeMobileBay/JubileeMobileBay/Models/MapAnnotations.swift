//
//  MapAnnotations.swift
//  JubileeMobileBay
//
//  Custom annotation types for map features
//

import Foundation
import MapKit
import CoreLocation

// MARK: - Camera Annotation

class CameraAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let cameraId: String
    let cameraName: String
    let streamURL: URL?
    let isOnline: Bool
    let lastUpdated: Date
    
    var title: String? {
        cameraName
    }
    
    var subtitle: String? {
        isOnline ? "Live" : "Offline"
    }
    
    init(cameraId: String,
         cameraName: String,
         coordinate: CLLocationCoordinate2D,
         streamURL: URL? = nil,
         isOnline: Bool = true,
         lastUpdated: Date = Date()) {
        self.cameraId = cameraId
        self.cameraName = cameraName
        self.coordinate = coordinate
        self.streamURL = streamURL
        self.isOnline = isOnline
        self.lastUpdated = lastUpdated
        super.init()
    }
}

// MARK: - Weather Station Annotation

class WeatherStationAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let stationId: String
    let stationName: String
    let currentTemperature: Double?
    let currentWindSpeed: Double?
    let currentHumidity: Double?
    let lastReading: Date
    
    var title: String? {
        stationName
    }
    
    var subtitle: String? {
        if let temp = currentTemperature {
            return "\(Int(temp))°F"
        }
        return "No data"
    }
    
    init(stationId: String,
         stationName: String,
         coordinate: CLLocationCoordinate2D,
         currentTemperature: Double? = nil,
         currentWindSpeed: Double? = nil,
         currentHumidity: Double? = nil,
         lastReading: Date = Date()) {
        self.stationId = stationId
        self.stationName = stationName
        self.coordinate = coordinate
        self.currentTemperature = currentTemperature
        self.currentWindSpeed = currentWindSpeed
        self.currentHumidity = currentHumidity
        self.lastReading = lastReading
        super.init()
    }
}

// MARK: - Jubilee Report Annotation

class JubileeReportAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let reportId: String
    let intensity: JubileeIntensity
    let reportedAt: Date
    let reportedBy: String
    let verificationStatus: VerificationStatus
    let imageURL: URL?
    let notes: String?
    
    var title: String? {
        "\(intensity.displayName) Jubilee"
    }
    
    var subtitle: String? {
        let timeAgo = reportedAt.timeAgoDisplay()
        return verificationStatus == .verified ? "Verified • \(timeAgo)" : timeAgo
    }
    
    init(reportId: String,
         intensity: JubileeIntensity,
         coordinate: CLLocationCoordinate2D,
         reportedAt: Date,
         reportedBy: String,
         verificationStatus: VerificationStatus = .userReported,
         imageURL: URL? = nil,
         notes: String? = nil) {
        self.reportId = reportId
        self.intensity = intensity
        self.coordinate = coordinate
        self.reportedAt = reportedAt
        self.reportedBy = reportedBy
        self.verificationStatus = verificationStatus
        self.imageURL = imageURL
        self.notes = notes
        super.init()
    }
}

// MARK: - Annotation View Identifiers

extension MKMapView {
    enum AnnotationIdentifier {
        static let camera = "CameraAnnotation"
        static let weatherStation = "WeatherStationAnnotation"
        static let jubileeReport = "JubileeReportAnnotation"
        static let cluster = "ClusterAnnotation"
        static let home = "HomeAnnotation"
    }
}

// MARK: - Date Extension for Time Ago

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Cluster Annotation

class MapClusterAnnotation: MKClusterAnnotation {
    override init(memberAnnotations: [MKAnnotation]) {
        super.init(memberAnnotations: memberAnnotations)
        updateTitleAndSubtitle()
    }
    
    private func updateTitleAndSubtitle() {
        let count = memberAnnotations.count
        
        // Count annotations by type
        let cameraCount = memberAnnotations.filter { $0 is CameraAnnotation }.count
        let stationCount = memberAnnotations.filter { $0 is WeatherStationAnnotation }.count
        let reportCount = memberAnnotations.filter { $0 is JubileeReportAnnotation }.count
        
        if count == cameraCount {
            title = "\(count) Cameras"
        } else if count == stationCount {
            title = "\(count) Stations"
        } else if count == reportCount {
            title = "\(count) Reports"
        } else {
            title = "\(count) Items"
        }
        
        let types = annotationTypes()
        if types.count > 1 {
            subtitle = types.joined(separator: ", ")
        } else {
            subtitle = nil
        }
    }
    
    private func annotationTypes() -> [String] {
        var types: [String] = []
        
        let cameraCount = memberAnnotations.filter { $0 is CameraAnnotation }.count
        let stationCount = memberAnnotations.filter { $0 is WeatherStationAnnotation }.count
        let reportCount = memberAnnotations.filter { $0 is JubileeReportAnnotation }.count
        
        if cameraCount > 0 {
            types.append("\(cameraCount) camera\(cameraCount > 1 ? "s" : "")")
        }
        if stationCount > 0 {
            types.append("\(stationCount) station\(stationCount > 1 ? "s" : "")")
        }
        if reportCount > 0 {
            types.append("\(reportCount) report\(reportCount > 1 ? "s" : "")")
        }
        
        return types
    }
}

// MARK: - Mock Data Generation

extension CameraAnnotation {
    static func mockAnnotations() -> [CameraAnnotation] {
        return [
            CameraAnnotation(
                cameraId: "cam_001",
                cameraName: "Fairhope Pier",
                coordinate: CLLocationCoordinate2D(latitude: 30.5228, longitude: -87.9031),
                streamURL: URL(string: "https://example.com/stream/cam_001"),
                isOnline: true
            ),
            CameraAnnotation(
                cameraId: "cam_002",
                cameraName: "Daphne Bayfront",
                coordinate: CLLocationCoordinate2D(latitude: 30.6032, longitude: -87.8848),
                streamURL: URL(string: "https://example.com/stream/cam_002"),
                isOnline: true
            ),
            CameraAnnotation(
                cameraId: "cam_003",
                cameraName: "Mobile Bay Bridge",
                coordinate: CLLocationCoordinate2D(latitude: 30.6569, longitude: -87.9856),
                streamURL: URL(string: "https://example.com/stream/cam_003"),
                isOnline: false
            )
        ]
    }
}

extension WeatherStationAnnotation {
    static func mockAnnotations() -> [WeatherStationAnnotation] {
        return [
            WeatherStationAnnotation(
                stationId: "ws_001",
                stationName: "Fairhope Station",
                coordinate: CLLocationCoordinate2D(latitude: 30.5228, longitude: -87.9031),
                currentTemperature: 72.5,
                currentWindSpeed: 12.3,
                currentHumidity: 65
            ),
            WeatherStationAnnotation(
                stationId: "ws_002",
                stationName: "Spanish Fort Marina",
                coordinate: CLLocationCoordinate2D(latitude: 30.6744, longitude: -87.9156),
                currentTemperature: 71.8,
                currentWindSpeed: 15.2,
                currentHumidity: 68
            ),
            WeatherStationAnnotation(
                stationId: "ws_003",
                stationName: "Point Clear",
                coordinate: CLLocationCoordinate2D(latitude: 30.4944, longitude: -87.9211),
                currentTemperature: 73.2,
                currentWindSpeed: 10.5,
                currentHumidity: 62
            )
        ]
    }
}

extension JubileeReportAnnotation {
    static func mockAnnotations() -> [JubileeReportAnnotation] {
        return [
            JubileeReportAnnotation(
                reportId: "rpt_001",
                intensity: .moderate,
                coordinate: CLLocationCoordinate2D(latitude: 30.5328, longitude: -87.9131),
                reportedAt: Date().addingTimeInterval(-3600), // 1 hour ago
                reportedBy: "User123",
                verificationStatus: .verified
            ),
            JubileeReportAnnotation(
                reportId: "rpt_002",
                intensity: .light,
                coordinate: CLLocationCoordinate2D(latitude: 30.6132, longitude: -87.8948),
                reportedAt: Date().addingTimeInterval(-7200), // 2 hours ago
                reportedBy: "User456",
                verificationStatus: .userReported
            ),
            JubileeReportAnnotation(
                reportId: "rpt_003",
                intensity: .heavy,
                coordinate: CLLocationCoordinate2D(latitude: 30.4844, longitude: -87.9111),
                reportedAt: Date().addingTimeInterval(-1800), // 30 minutes ago
                reportedBy: "User789",
                verificationStatus: .verified,
                notes: "Large amounts of fish near shore"
            )
        ]
    }
}