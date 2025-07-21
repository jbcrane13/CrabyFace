import Foundation

// MARK: - Prediction Models

struct HourlyPrediction: Identifiable, Equatable {
    let id = UUID()
    let hour: Int
    let probability: Double
    let confidence: Double
    let conditions: PredictedConditions
    
    static func == (lhs: HourlyPrediction, rhs: HourlyPrediction) -> Bool {
        lhs.hour == rhs.hour &&
        lhs.probability == rhs.probability &&
        lhs.confidence == rhs.confidence &&
        lhs.conditions == rhs.conditions
    }
}

struct PredictedConditions: Equatable {
    let temperature: Double
    let dissolvedOxygen: Double
    let windSpeed: Double
    let humidity: Double
}

// MARK: - Trend Analysis

enum TrendDirection: String {
    case increasing = "increasing"
    case decreasing = "decreasing"
    case stable = "stable"
}

struct JubileeTrend: Equatable {
    let direction: TrendDirection
    let changeRate: Double // Percentage change per day
    let summary: String
    let keyFactors: [String]
}

// MARK: - Risk Factors

struct RiskFactor: Equatable {
    let name: String
    let weight: Double
    let currentValue: Double
    let threshold: Double
    let contribution: Double // How much this factor contributes to probability
}

// MARK: - Prediction Configuration

struct PredictionConfiguration {
    // Thresholds for critical conditions
    static let criticalOxygenLevel = 2.0
    static let lowOxygenLevel = 4.0
    static let highTemperatureThreshold = 80.0
    static let lowWindSpeedThreshold = 5.0
    static let highHumidityThreshold = 80.0
    
    // Weights for different factors
    static let oxygenWeight = 0.4
    static let temperatureWeight = 0.2
    static let windWeight = 0.2
    static let humidityWeight = 0.1
    static let trendWeight = 0.1
}

// MARK: - Confidence Interval
struct ConfidenceInterval {
    let lower: Double
    let upper: Double
    let confidence: Double
    
    init(lower: Double, upper: Double, confidence: Double = 0.95) {
        self.lower = lower
        self.upper = upper
        self.confidence = confidence
    }
}