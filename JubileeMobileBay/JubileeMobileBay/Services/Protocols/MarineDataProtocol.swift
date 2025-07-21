import Foundation

protocol MarineDataProtocol {
    func fetchCurrentConditions() async throws -> MarineConditions
    func fetchHistoricalData(from startDate: Date, to endDate: Date) async throws -> [MarineConditions]
    func fetchNearbyStations(latitude: Double, longitude: Double, radius: Double) async throws -> [MonitoringStation]
}

enum MarineDataError: Error, Equatable {
    case networkError
    case invalidResponse
    case decodingError
    case stationNotFound
    case dataNotAvailable
}

// MARK: - Monitoring Station Models

enum StationType: String, Codable {
    case buoy = "buoy"
    case shore = "shore"
    case platform = "platform"
}

enum StationStatus: String, Codable {
    case active = "active"
    case maintenance = "maintenance"
    case offline = "offline"
}

struct MonitoringStation: Codable, Equatable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let type: StationType
    let status: StationStatus
}