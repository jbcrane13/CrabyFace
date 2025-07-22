//
//  JubileePredictorWrapper.swift
//  JubileeMobileBay
//
//  Wrapper for the Core ML model to handle missing outputs
//

import Foundation
import CoreML

/// Wrapper class for JubileePredictor model that adds missing outputs
@available(iOS 15.0, *)
@objc(JubileePredictorWrapper)
class JubileePredictorWrapper: NSObject {
    
    private let model: MLModel
    
    init(contentsOf url: URL, configuration: MLModelConfiguration) throws {
        self.model = try MLModel(contentsOf: url, configuration: configuration)
        super.init()
    }
    
    convenience init(configuration: MLModelConfiguration = MLModelConfiguration()) throws {
        let bundle = Bundle(for: JubileePredictorWrapper.self)
        let modelURL = bundle.url(forResource: "JubileePredictor", withExtension: "mlmodelc")!
        try self.init(contentsOf: modelURL, configuration: configuration)
    }
    
    func prediction(input: JubileePredictorWrapperInput) throws -> JubileePredictorWrapperOutput {
        // Create feature provider from input
        let inputFeatures = try MLDictionaryFeatureProvider(dictionary: [
            "airTemperature": input.airTemperature,
            "waterTemperature": input.waterTemperature,
            "windSpeed": input.windSpeed,
            "dissolvedOxygen": input.dissolvedOxygen
        ])
        
        // Get prediction from model
        let output = try model.prediction(from: inputFeatures)
        
        // Extract jubilee probability
        let jubileeProbability = output.featureValue(for: "jubileeProbability")?.doubleValue ?? 0.5
        
        // Calculate confidence score based on input conditions
        let confidenceScore = calculateConfidence(
            airTemp: input.airTemperature,
            waterTemp: input.waterTemperature,
            windSpeed: input.windSpeed,
            dissolvedOxygen: input.dissolvedOxygen,
            probability: jubileeProbability
        )
        
        return JubileePredictorWrapperOutput(
            jubileeProbability: jubileeProbability,
            confidenceScore: confidenceScore
        )
    }
    
    private func calculateConfidence(airTemp: Double, waterTemp: Double, 
                                   windSpeed: Double, dissolvedOxygen: Double,
                                   probability: Double) -> Double {
        // Simple confidence calculation based on how extreme the conditions are
        var confidence = 0.5
        
        // If probability is very high or very low, we're more confident
        if probability > 0.8 || probability < 0.2 {
            confidence = 0.85
        } else if probability > 0.7 || probability < 0.3 {
            confidence = 0.75
        } else if probability > 0.6 || probability < 0.4 {
            confidence = 0.65
        }
        
        // Adjust based on input extremes
        if windSpeed < 5 && dissolvedOxygen < 4 {
            confidence += 0.1 // Very favorable conditions
        }
        if windSpeed > 20 || dissolvedOxygen > 7 {
            confidence += 0.05 // Very unfavorable conditions
        }
        
        // Temperature consistency
        let tempDiff = abs(airTemp - waterTemp)
        if tempDiff < 3 {
            confidence += 0.05 // Stable temperatures
        }
        
        return min(confidence, 0.95)
    }
}

/// Input class for JubileePredictor
@available(iOS 15.0, *)
@objc(JubileePredictorWrapperInput)
class JubileePredictorWrapperInput: NSObject {
    let airTemperature: Double
    let waterTemperature: Double
    let windSpeed: Double
    let dissolvedOxygen: Double
    
    init(airTemperature: Double, waterTemperature: Double, 
         windSpeed: Double, dissolvedOxygen: Double) {
        self.airTemperature = airTemperature
        self.waterTemperature = waterTemperature
        self.windSpeed = windSpeed
        self.dissolvedOxygen = dissolvedOxygen
        super.init()
    }
}

/// Output class for JubileePredictor
@available(iOS 15.0, *)
@objc(JubileePredictorWrapperOutput)
class JubileePredictorWrapperOutput: NSObject {
    let jubileeProbability: Double
    let confidenceScore: Double
    
    init(jubileeProbability: Double, confidenceScore: Double) {
        self.jubileeProbability = jubileeProbability
        self.confidenceScore = confidenceScore
        super.init()
    }
}