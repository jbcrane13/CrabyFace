import Foundation

// MARK: - Jubilee Intensity

enum JubileeIntensity: String, CaseIterable, Codable {
    case minimal = "minimal"
    case light = "light"
    case moderate = "moderate"
    case heavy = "heavy"
    case extreme = "extreme"
    
    var displayName: String {
        switch self {
        case .minimal: return "Minimal Activity"
        case .light: return "Light Activity"
        case .moderate: return "Moderate Activity"
        case .heavy: return "Heavy Activity"
        case .extreme: return "Extreme Activity"
        }
    }
    
    var colorHex: String {
        switch self {
        case .minimal: return "#808080"    // Gray
        case .light: return "#90EE90"      // Light green
        case .moderate: return "#FFD700"   // Gold
        case .heavy: return "#FF6B6B"      // Light red
        case .extreme: return "#FF0000"    // Red
        }
    }
    
    var colorName: String {
        switch self {
        case .minimal: return "gray"
        case .light: return "blue"
        case .moderate: return "green"
        case .heavy: return "orange"
        case .extreme: return "red"
        }
    }
    
    var score: Double {
        switch self {
        case .minimal: return 0.1
        case .light: return 0.3
        case .moderate: return 0.5
        case .heavy: return 0.7
        case .extreme: return 0.9
        }
    }
}

// MARK: - Verification Status

enum VerificationStatus: String, CaseIterable, Codable {
    case predicted = "predicted"
    case userReported = "user_reported"
    case verified = "verified"
    
    var displayName: String {
        switch self {
        case .predicted: return "Predicted"
        case .userReported: return "User Reported"
        case .verified: return "Verified"
        }
    }
}

// MARK: - Data Source

enum DataSource: String, CaseIterable, Codable {
    case noaa = "noaa"
    case openWeatherMap = "open_weather_map"
    case userSubmitted = "user_submitted"
    case sensor = "sensor"
    
    var displayName: String {
        switch self {
        case .noaa: return "NOAA"
        case .openWeatherMap: return "OpenWeatherMap"
        case .userSubmitted: return "User Submitted"
        case .sensor: return "Sensor"
        }
    }
}

// MARK: - Tide State

enum TideState: String, CaseIterable, Codable {
    case high = "high"
    case low = "low"
    case rising = "rising"
    case falling = "falling"
    
    var displayName: String {
        switch self {
        case .high: return "High Tide"
        case .low: return "Low Tide"
        case .rising: return "Rising Tide"
        case .falling: return "Falling Tide"
        }
    }
}

// MARK: - Moon Phase

enum MoonPhase: String, CaseIterable, Codable {
    case new = "new"
    case waxingCrescent = "waxing_crescent"
    case firstQuarter = "first_quarter"
    case waxingGibbous = "waxing_gibbous"
    case full = "full"
    case waningGibbous = "waning_gibbous"
    case lastQuarter = "last_quarter"
    case waningCrescent = "waning_crescent"
    
    var displayName: String {
        switch self {
        case .new: return "New Moon"
        case .waxingCrescent: return "Waxing Crescent"
        case .firstQuarter: return "First Quarter"
        case .waxingGibbous: return "Waxing Gibbous"
        case .full: return "Full Moon"
        case .waningGibbous: return "Waning Gibbous"
        case .lastQuarter: return "Last Quarter"
        case .waningCrescent: return "Waning Crescent"
        }
    }
    
    var symbolName: String {
        switch self {
        case .new: return "moon.circle"
        case .waxingCrescent: return "moon.circle.righthalf.filled"
        case .firstQuarter: return "moon.circle.righthalf.filled"
        case .waxingGibbous: return "moon.circle.fill"
        case .full: return "moon.circle.fill"
        case .waningGibbous: return "moon.circle.fill"
        case .lastQuarter: return "moon.circle.lefthalf.filled"
        case .waningCrescent: return "moon.circle.lefthalf.filled"
        }
    }
}