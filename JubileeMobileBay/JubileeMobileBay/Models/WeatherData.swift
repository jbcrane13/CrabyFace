import Foundation

// MARK: - Weather Conditions

struct WeatherConditions: Codable, Equatable {
    let temperature: Double
    let humidity: Double
    let windSpeed: Double
    let windDirection: String
    let pressure: Double
    let visibility: Double
    let uvIndex: Int
    let cloudCover: Int
}

// MARK: - Weather Forecast

struct WeatherForecast: Codable, Equatable {
    let date: Date
    let temperature: Double
    let humidity: Double
    let windSpeed: Double
    let windDirection: String
    let precipitationChance: Int
    let conditions: String
    let icon: String
}

// MARK: - Tide Data

enum TideType: String, Codable {
    case high = "high"
    case low = "low"
}

struct TideData: Codable, Equatable {
    let time: Date
    let height: Double
    let type: TideType
}