//
//  JubileePrediction.swift
//  JubileeMobileBay
//
//  Advanced ML-based jubilee prediction data models for Phase 4
//

import Foundation
import CoreLocation

// MARK: - Main Prediction Result

struct JubileePrediction: Codable, Identifiable, Equatable {
    let id = UUID()
    let probability: Double // 0.0 to 1.0
    let confidenceScore: Double // 0.0 to 1.0
    let environmentalFactors: [String: Double]
    let predictedIntensity: JubileeIntensity
    let predictedSpecies: [MarineSpecies]
    let timestamp: Date
    let location: LocationData
    let modelVersion: String
    
    // Computed properties
    var probabilityPercentage: Int {
        Int(probability * 100)
    }
    
    var isHighConfidence: Bool {
        confidenceScore >= 0.7
    }
    
    var recommendationLevel: RecommendationLevel {
        switch probability {
        case 0.8...1.0:
            return .excellent
        case 0.6..<0.8:
            return .good
        case 0.4..<0.6:
            return .moderate
        case 0.2..<0.4:
            return .poor
        default:
            return .unlikely
        }
    }
    
    // CodingKeys to exclude computed properties and UUID from encoding
    enum CodingKeys: String, CodingKey {
        case probability, confidenceScore, environmentalFactors
        case predictedIntensity, predictedSpecies, timestamp
        case location, modelVersion
    }
}

// MARK: - Supporting Enums

enum RecommendationLevel: String, Codable {
    case excellent = "excellent"
    case good = "good"
    case moderate = "moderate"
    case poor = "poor"
    case unlikely = "unlikely"
    
    var displayName: String {
        switch self {
        case .excellent:
            return "Excellent Conditions"
        case .good:
            return "Good Conditions"
        case .moderate:
            return "Moderate Conditions"
        case .poor:
            return "Poor Conditions"
        case .unlikely:
            return "Unlikely Conditions"
        }
    }
    
    var icon: String {
        switch self {
        case .excellent:
            return "star.fill"
        case .good:
            return "checkmark.circle.fill"
        case .moderate:
            return "minus.circle.fill"
        case .poor:
            return "xmark.circle.fill"
        case .unlikely:
            return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Marine Species

struct MarineSpecies: Codable, Identifiable, Equatable {
    let id = UUID()
    let name: String
    let scientificName: String
    let likelihood: Double // 0.0 to 1.0
    let historicalFrequency: Double
    let optimalConditions: [String: Double]
    
    enum CodingKeys: String, CodingKey {
        case name, scientificName, likelihood
        case historicalFrequency, optimalConditions
    }
    
    static let commonSpecies = [
        MarineSpecies(
            name: "Blue Crab",
            scientificName: "Callinectes sapidus",
            likelihood: 0.0,
            historicalFrequency: 0.85,
            optimalConditions: ["temperature": 75.0, "salinity": 15.0]
        ),
        MarineSpecies(
            name: "Flounder",
            scientificName: "Paralichthys lethostigma",
            likelihood: 0.0,
            historicalFrequency: 0.65,
            optimalConditions: ["temperature": 78.0, "salinity": 12.0]
        ),
        MarineSpecies(
            name: "Shrimp",
            scientificName: "Farfantepenaeus aztecus",
            likelihood: 0.0,
            historicalFrequency: 0.75,
            optimalConditions: ["temperature": 80.0, "salinity": 18.0]
        ),
        MarineSpecies(
            name: "Red Snapper",
            scientificName: "Lutjanus campechanus",
            likelihood: 0.0,
            historicalFrequency: 0.45,
            optimalConditions: ["temperature": 82.0, "salinity": 20.0]
        )
    ]
}

// MARK: - Location Data

struct LocationData: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let name: String?
    let region: String?
    
    init(coordinate: CLLocationCoordinate2D, name: String? = nil, region: String? = nil) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.name = name
        self.region = region
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Prediction History

struct PredictionHistory: Codable, Identifiable {
    let id = UUID()
    let predictions: [JubileePrediction]
    let dateRange: DateInterval
    let averageAccuracy: Double?
    let totalPredictions: Int
    
    enum CodingKeys: String, CodingKey {
        case predictions, dateRange, averageAccuracy, totalPredictions
    }
    
    var successRate: Double {
        averageAccuracy ?? 0.0
    }
    
    var mostRecentPrediction: JubileePrediction? {
        predictions.max(by: { $0.timestamp < $1.timestamp })
    }
}

// MARK: - Model Performance Metrics

struct ModelPerformanceMetrics: Codable {
    let modelVersion: String
    let accuracy: Double
    let precision: Double
    let recall: Double
    let f1Score: Double
    let evaluationDate: Date
    let sampleSize: Int
    
    var isHighPerformance: Bool {
        accuracy >= 0.8 && precision >= 0.75 && recall >= 0.75
    }
    
    var performanceGrade: String {
        switch accuracy {
        case 0.9...1.0:
            return "A+"
        case 0.85..<0.9:
            return "A"
        case 0.8..<0.85:
            return "B+"
        case 0.75..<0.8:
            return "B"
        case 0.7..<0.75:
            return "C+"
        default:
            return "C"
        }
    }
}

// MARK: - Prediction Error Types

enum PredictionError: LocalizedError {
    case modelNotLoaded
    case insufficientData
    case networkTimeout
    case invalidLocation
    case modelVersionMismatch
    case environmentalDataUnavailable
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Machine learning model could not be loaded"
        case .insufficientData:
            return "Insufficient environmental data for prediction"
        case .networkTimeout:
            return "Network timeout while fetching environmental data"
        case .invalidLocation:
            return "Invalid location coordinates provided"
        case .modelVersionMismatch:
            return "Model version compatibility issue"
        case .environmentalDataUnavailable:
            return "Environmental data service unavailable"
        }
    }
}

// MARK: - Mock Data

extension JubileePrediction {
    static let mockPrediction = JubileePrediction(
        probability: 0.78,
        confidenceScore: 0.85,
        environmentalFactors: [
            "waterTemperature": 76.5,
            "airTemperature": 82.0,
            "windSpeed": 8.5,
            "barometricPressure": 30.15,
            "tideLevel": 2.3,
            "dissolvedOxygen": 4.2
        ],
        predictedIntensity: .moderate,
        predictedSpecies: MarineSpecies.commonSpecies.map { species in
            var updated = species
            updated = MarineSpecies(
                name: species.name,
                scientificName: species.scientificName,
                likelihood: Double.random(in: 0.3...0.9),
                historicalFrequency: species.historicalFrequency,
                optimalConditions: species.optimalConditions
            )
            return updated
        },
        timestamp: Date(),
        location: LocationData(
            coordinate: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            name: "Mobile Bay",
            region: "Alabama"
        ),
        modelVersion: "1.0.0"
    )
}