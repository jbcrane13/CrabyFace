import CreateML
import Foundation
import TabularData

// Jubilee Predictor Model Training
// This playground generates synthetic training data and trains a Core ML model
// for predicting jubilee events based on environmental conditions

// MARK: - Data Generation

struct JubileeTrainingData {
    let airTemperature: Double      // Fahrenheit
    let waterTemperature: Double    // Fahrenheit
    let windSpeed: Double           // mph
    let dissolvedOxygen: Double     // mg/L
    let jubileeProbability: Double  // 0.0-1.0
    let confidenceScore: Double     // 0.0-1.0
}

// Generate synthetic training data based on jubilee patterns
func generateTrainingData(count: Int = 10000) -> [JubileeTrainingData] {
    var trainingData: [JubileeTrainingData] = []
    
    for _ in 0..<count {
        // Generate environmental conditions
        let airTemp = Double.random(in: 65...95)
        let waterTemp = Double.random(in: 70...88)
        let windSpeed = Double.random(in: 0...25)
        let dissolvedOxygen = Double.random(in: 2...8)
        
        // Calculate jubilee probability based on environmental factors
        // Jubilees are more likely when:
        // - Air temperature is high (75-85°F)
        // - Water temperature is warm (78-85°F)
        // - Wind speed is low (< 5 mph)
        // - Dissolved oxygen is low (< 4 mg/L)
        
        var probability: Double = 0.1 // Base probability
        
        // Temperature factor
        if airTemp >= 75 && airTemp <= 85 {
            probability += 0.2
        }
        if waterTemp >= 78 && waterTemp <= 85 {
            probability += 0.2
        }
        
        // Wind factor (low wind increases probability)
        if windSpeed < 5 {
            probability += 0.3
        } else if windSpeed > 15 {
            probability -= 0.2
        }
        
        // Dissolved oxygen factor (low DO increases probability)
        if dissolvedOxygen < 4 {
            probability += 0.2
        } else if dissolvedOxygen > 6 {
            probability -= 0.1
        }
        
        // Add some randomness
        probability += Double.random(in: -0.1...0.1)
        
        // Clamp probability
        probability = max(0.0, min(1.0, probability))
        
        // Calculate confidence based on how extreme the conditions are
        let tempDeviation = abs(airTemp - 80) / 15.0
        let windDeviation = min(windSpeed / 25.0, 1.0)
        let doDeviation = abs(dissolvedOxygen - 5) / 3.0
        
        let confidence = 1.0 - (tempDeviation + windDeviation + doDeviation) / 3.0
        let finalConfidence = max(0.3, min(0.95, confidence))
        
        trainingData.append(JubileeTrainingData(
            airTemperature: airTemp,
            waterTemperature: waterTemp,
            windSpeed: windSpeed,
            dissolvedOxygen: dissolvedOxygen,
            jubileeProbability: probability,
            confidenceScore: finalConfidence
        ))
    }
    
    return trainingData
}

// MARK: - Model Training

func trainJubileeModel() {
    print("Generating training data...")
    let trainingData = generateTrainingData(count: 20000)
    let validationData = generateTrainingData(count: 5000)
    
    // Convert to DataFrame
    var trainingDict: [String: [Double]] = [
        "airTemperature": [],
        "waterTemperature": [],
        "windSpeed": [],
        "dissolvedOxygen": [],
        "jubileeProbability": [],
        "confidenceScore": []
    ]
    
    for data in trainingData {
        trainingDict["airTemperature"]!.append(data.airTemperature)
        trainingDict["waterTemperature"]!.append(data.waterTemperature)
        trainingDict["windSpeed"]!.append(data.windSpeed)
        trainingDict["dissolvedOxygen"]!.append(data.dissolvedOxygen)
        trainingDict["jubileeProbability"]!.append(data.jubileeProbability)
        trainingDict["confidenceScore"]!.append(data.confidenceScore)
    }
    
    var validationDict: [String: [Double]] = [
        "airTemperature": [],
        "waterTemperature": [],
        "windSpeed": [],
        "dissolvedOxygen": [],
        "jubileeProbability": [],
        "confidenceScore": []
    ]
    
    for data in validationData {
        validationDict["airTemperature"]!.append(data.airTemperature)
        validationDict["waterTemperature"]!.append(data.waterTemperature)
        validationDict["windSpeed"]!.append(data.windSpeed)
        validationDict["dissolvedOxygen"]!.append(data.dissolvedOxygen)
        validationDict["jubileeProbability"]!.append(data.jubileeProbability)
        validationDict["confidenceScore"]!.append(data.confidenceScore)
    }
    
    do {
        let trainingDataFrame = try DataFrame(trainingDict)
        let validationDataFrame = try DataFrame(validationDict)
        
        print("Training data shape: \(trainingDataFrame.rows.count) rows x \(trainingDataFrame.columns.count) columns")
        
        // Train model for jubilee probability
        print("\nTraining jubilee probability model...")
        let probabilityRegressor = try MLRegressor(
            trainingData: trainingDataFrame,
            targetColumn: "jubileeProbability",
            featureColumns: ["airTemperature", "waterTemperature", "windSpeed", "dissolvedOxygen"]
        )
        
        // Train model for confidence score
        print("\nTraining confidence score model...")
        let confidenceRegressor = try MLRegressor(
            trainingData: trainingDataFrame,
            targetColumn: "confidenceScore",
            featureColumns: ["airTemperature", "waterTemperature", "windSpeed", "dissolvedOxygen"]
        )
        
        // Evaluate models
        print("\nEvaluating models...")
        let probabilityMetrics = probabilityRegressor.evaluation(on: validationDataFrame)
        let confidenceMetrics = confidenceRegressor.evaluation(on: validationDataFrame)
        
        print("\nProbability Model Metrics:")
        print("RMSE: \(probabilityMetrics.rootMeanSquaredError)")
        print("Max Error: \(probabilityMetrics.maximumError)")
        
        print("\nConfidence Model Metrics:")
        print("RMSE: \(confidenceMetrics.rootMeanSquaredError)")
        print("Max Error: \(confidenceMetrics.maximumError)")
        
        // Since we need a single model with multiple outputs, we'll need to use
        // a pipeline or custom model. For now, let's save the probability model
        // as the primary model
        
        let modelPath = URL(fileURLWithPath: "/Users/blake/GitHub/CrabyFace/JubileeMobileBay/JubileeMobileBay/Models/ML/JubileePredictor_Trained.mlmodel")
        
        print("\nSaving model to: \(modelPath.path)")
        try probabilityRegressor.write(to: modelPath)
        
        print("\nModel training complete!")
        
    } catch {
        print("Error during training: \(error)")
    }
}

// Run the training
trainJubileeModel()