//
//  LegacyPredictionTypes.swift
//  JubileeMobileBay
//
//  Legacy types for backward compatibility with Phase 1-3
//  These will be replaced with ML-based predictions in Phase 4
//

import Foundation

// MARK: - Legacy Types (To be deprecated)

struct HourlyPrediction: Codable, Identifiable {
    let id = UUID()
    let hour: Date
    let probability: Double
    let conditions: String
}

struct JubileeTrend: Codable {
    let direction: TrendDirection
    let strength: Double
    let confidence: Double
}

enum TrendDirection: String, Codable {
    case increasing = "increasing"
    case decreasing = "decreasing"
    case stable = "stable"
}

struct RiskFactor: Codable, Identifiable {
    let id = UUID()
    let name: String
    let impact: Double
    let description: String
}

struct ConfidenceInterval: Codable {
    let lower: Double
    let upper: Double
    let confidence: Double
}