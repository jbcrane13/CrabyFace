import Foundation

// MARK: - Water Quality

enum OxygenStatus: String, Codable {
    case critical = "critical"
    case low = "low"
    case normal = "normal"
}

struct WaterQuality: Codable, Equatable {
    let temperature: Double
    let dissolvedOxygen: Double
    let ph: Double
    let salinity: Double
    let turbidity: Double
    let chlorophyll: Double
    
    var dissolvedOxygenStatus: OxygenStatus {
        switch dissolvedOxygen {
        case ..<2.0:
            return .critical
        case 2.0..<4.0:
            return .low
        default:
            return .normal
        }
    }
}

// MARK: - Current Data

struct CurrentData: Codable, Equatable {
    let speed: Double
    let direction: Int
    let temperature: Double
}

// MARK: - Wave Data

struct WaveData: Codable, Equatable {
    let height: Double
    let period: Double
    let direction: Int
}

// MARK: - Marine Conditions

struct MarineConditions: Codable, Equatable {
    let waterQuality: WaterQuality
    let current: CurrentData
    let wave: WaveData
    let timestamp: Date
}