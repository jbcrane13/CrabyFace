import Foundation
import CoreML
import CoreLocation

@MainActor
final class PredictionService: @preconcurrency PredictionServiceProtocol {
    private let weatherAPI: WeatherAPIProtocol
    private let marineAPI: MarineDataProtocol
    private let coreMLService: CoreMLPredictionService
    
    // Model management properties
    var isModelLoaded: Bool {
        coreMLService.isModelLoaded
    }
    
    var currentModelVersion: String {
        coreMLService.currentModelVersion
    }
    
    init(weatherAPI: WeatherAPIProtocol, marineAPI: MarineDataProtocol) {
        self.weatherAPI = weatherAPI
        self.marineAPI = marineAPI
        self.coreMLService = CoreMLPredictionService(weatherAPI: weatherAPI, marineAPI: marineAPI)
    }
    
    // MARK: - Public Methods
    
    func calculateJubileeProbability() async throws -> Double {
        // Fetch current conditions
        async let weatherConditions = weatherAPI.fetchCurrentConditions()
        async let marineConditions = marineAPI.fetchCurrentConditions()
        
        let (weather, marine) = try await (weatherConditions, marineConditions)
        
        // Calculate base probability from current conditions
        let oxygenScore = calculateOxygenScore(marine.waterQuality.dissolvedOxygen)
        let temperatureScore = calculateTemperatureScore(weather.temperature, waterTemp: marine.waterQuality.temperature)
        let windScore = calculateWindScore(weather.windSpeed)
        let humidityScore = calculateHumidityScore(weather.humidity)
        
        // Weight the scores
        let baseProbability = (
            oxygenScore * PredictionConfiguration.oxygenWeight +
            temperatureScore * PredictionConfiguration.temperatureWeight +
            windScore * PredictionConfiguration.windWeight +
            humidityScore * PredictionConfiguration.humidityWeight
        ) * 100
        
        // Apply trend adjustment
        let trend = try await analyzeTrends()
        let trendAdjustment = calculateTrendAdjustment(trend)
        
        let finalProbability = min(100, max(0, baseProbability + trendAdjustment))
        
        return finalProbability
    }
    
    func generate24HourPrediction() async throws -> [HourlyPrediction] {
        // Fetch necessary data
        async let weatherForecast = weatherAPI.fetchHourlyForecast(hours: 24)
        async let currentMarine = marineAPI.fetchCurrentConditions()
        async let historicalData = marineAPI.fetchHistoricalData(
            from: Date().addingTimeInterval(-7 * 86400),
            to: Date()
        )
        
        let (forecasts, marine, historical) = try await (weatherForecast, currentMarine, historicalData)
        
        // Calculate oxygen decay rate from historical data
        let oxygenDecayRate = calculateOxygenDecayRate(from: historical)
        
        var predictions: [HourlyPrediction] = []
        var projectedOxygen = marine.waterQuality.dissolvedOxygen
        
        for (index, forecast) in forecasts.enumerated() {
            // Project oxygen level
            projectedOxygen = max(0, projectedOxygen - (oxygenDecayRate * Double(index)))
            
            // Calculate probability for this hour
            let oxygenScore = calculateOxygenScore(projectedOxygen)
            let temperatureScore = calculateTemperatureScore(forecast.temperature, waterTemp: marine.waterQuality.temperature + Double(index) * 0.1)
            let windScore = calculateWindScore(forecast.windSpeed)
            let humidityScore = calculateHumidityScore(forecast.humidity)
            
            let hourlyProbability = (
                oxygenScore * PredictionConfiguration.oxygenWeight +
                temperatureScore * PredictionConfiguration.temperatureWeight +
                windScore * PredictionConfiguration.windWeight +
                humidityScore * PredictionConfiguration.humidityWeight
            ) * 100
            
            // Calculate confidence based on how far in the future
            let confidence = 1.0 - (Double(index) / 48.0) // Decreases over time
            
            let conditions = PredictedConditions(
                temperature: forecast.temperature,
                dissolvedOxygen: projectedOxygen,
                windSpeed: forecast.windSpeed,
                humidity: forecast.humidity
            )
            
            let prediction = HourlyPrediction(
                hour: index,
                probability: min(100, max(0, hourlyProbability)),
                confidence: confidence,
                conditions: conditions
            )
            
            predictions.append(prediction)
        }
        
        return predictions
    }
    
    func analyzeTrends() async throws -> JubileeTrend {
        // Fetch 7 days of historical data
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-7 * 86400)
        
        let historicalData = try await marineAPI.fetchHistoricalData(from: startDate, to: endDate)
        
        guard historicalData.count > 1 else {
            return JubileeTrend(
                direction: .stable,
                changeRate: 0,
                summary: "Insufficient data for trend analysis",
                keyFactors: []
            )
        }
        
        // Calculate oxygen trend
        let oxygenValues = historicalData.map { $0.waterQuality.dissolvedOxygen }
        let oxygenTrend = calculateTrend(values: oxygenValues)
        
        // Calculate temperature trend
        let tempValues = historicalData.map { $0.waterQuality.temperature }
        let tempTrend = calculateTrend(values: tempValues)
        
        // Determine overall trend direction
        let direction: TrendDirection
        var keyFactors: [String] = []
        
        if oxygenTrend < -0.1 {
            direction = .increasing // Lower oxygen = higher jubilee probability
            keyFactors.append("Dissolved oxygen declining")
        } else if oxygenTrend > 0.1 {
            direction = .decreasing
            keyFactors.append("Dissolved oxygen improving")
        } else {
            direction = .stable
            keyFactors.append("Dissolved oxygen stable")
        }
        
        if tempTrend > 0.5 {
            keyFactors.append("Water temperature rising")
        }
        
        let changeRate = abs(oxygenTrend) * 10 // Convert to percentage
        
        let summary = generateTrendSummary(direction: direction, changeRate: changeRate, factors: keyFactors)
        
        return JubileeTrend(
            direction: direction,
            changeRate: changeRate,
            summary: summary,
            keyFactors: keyFactors
        )
    }
    
    func getRiskFactors() async throws -> [RiskFactor] {
        // Fetch current conditions
        async let weatherConditions = weatherAPI.fetchCurrentConditions()
        async let marineConditions = marineAPI.fetchCurrentConditions()
        
        let (weather, marine) = try await (weatherConditions, marineConditions)
        
        var factors: [RiskFactor] = []
        
        // Oxygen factor
        let oxygenFactor = RiskFactor(
            name: "Dissolved Oxygen",
            weight: PredictionConfiguration.oxygenWeight,
            currentValue: marine.waterQuality.dissolvedOxygen,
            threshold: PredictionConfiguration.criticalOxygenLevel,
            contribution: calculateOxygenScore(marine.waterQuality.dissolvedOxygen) * PredictionConfiguration.oxygenWeight
        )
        factors.append(oxygenFactor)
        
        // Temperature factor
        let tempFactor = RiskFactor(
            name: "Water Temperature",
            weight: PredictionConfiguration.temperatureWeight,
            currentValue: marine.waterQuality.temperature,
            threshold: PredictionConfiguration.highTemperatureThreshold,
            contribution: calculateTemperatureScore(weather.temperature, waterTemp: marine.waterQuality.temperature) * PredictionConfiguration.temperatureWeight
        )
        factors.append(tempFactor)
        
        // Wind factor
        let windFactor = RiskFactor(
            name: "Wind Speed",
            weight: PredictionConfiguration.windWeight,
            currentValue: weather.windSpeed,
            threshold: PredictionConfiguration.lowWindSpeedThreshold,
            contribution: calculateWindScore(weather.windSpeed) * PredictionConfiguration.windWeight
        )
        factors.append(windFactor)
        
        // Humidity factor
        let humidityFactor = RiskFactor(
            name: "Humidity",
            weight: PredictionConfiguration.humidityWeight,
            currentValue: weather.humidity,
            threshold: PredictionConfiguration.highHumidityThreshold,
            contribution: calculateHumidityScore(weather.humidity) * PredictionConfiguration.humidityWeight
        )
        factors.append(humidityFactor)
        
        return factors
    }
    
    // MARK: - Private Calculation Methods
    
    private func calculateOxygenScore(_ oxygen: Double) -> Double {
        if oxygen < PredictionConfiguration.criticalOxygenLevel {
            return 1.0 // Maximum score for critical levels
        } else if oxygen < PredictionConfiguration.lowOxygenLevel {
            // Linear interpolation between critical and low
            let range = PredictionConfiguration.lowOxygenLevel - PredictionConfiguration.criticalOxygenLevel
            let position = oxygen - PredictionConfiguration.criticalOxygenLevel
            return 1.0 - (position / range) * 0.3 // Score from 1.0 to 0.7
        } else {
            // Exponential decay for normal levels
            return max(0, 0.7 - (oxygen - PredictionConfiguration.lowOxygenLevel) * 0.1)
        }
    }
    
    private func calculateTemperatureScore(_ airTemp: Double, waterTemp: Double) -> Double {
        let avgTemp = (airTemp + waterTemp) / 2
        if avgTemp > PredictionConfiguration.highTemperatureThreshold {
            // Higher temperatures increase probability
            let excess = avgTemp - PredictionConfiguration.highTemperatureThreshold
            return min(1.0, 0.5 + excess * 0.05)
        } else {
            return max(0, 0.5 - (PredictionConfiguration.highTemperatureThreshold - avgTemp) * 0.02)
        }
    }
    
    private func calculateWindScore(_ windSpeed: Double) -> Double {
        if windSpeed < PredictionConfiguration.lowWindSpeedThreshold {
            // Low wind increases probability
            return 1.0 - (windSpeed / PredictionConfiguration.lowWindSpeedThreshold) * 0.3
        } else {
            // Higher wind decreases probability
            return max(0, 0.7 - (windSpeed - PredictionConfiguration.lowWindSpeedThreshold) * 0.05)
        }
    }
    
    private func calculateHumidityScore(_ humidity: Double) -> Double {
        if humidity > PredictionConfiguration.highHumidityThreshold {
            // High humidity slightly increases probability
            let excess = humidity - PredictionConfiguration.highHumidityThreshold
            return min(1.0, 0.5 + excess * 0.01)
        } else {
            return 0.5
        }
    }
    
    private func calculateOxygenDecayRate(from historical: [MarineConditions]) -> Double {
        guard historical.count > 1 else { return 0.01 }
        
        let oxygenValues = historical.map { $0.waterQuality.dissolvedOxygen }
        let dailyChanges = zip(oxygenValues.dropFirst(), oxygenValues).map { $0.0 - $0.1 }
        let averageChange = dailyChanges.reduce(0, +) / Double(dailyChanges.count)
        
        // Convert to hourly rate
        return abs(averageChange) / 24.0
    }
    
    private func calculateTrend(values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        
        // Simple linear regression
        let n = Double(values.count)
        let indices = Array(0..<values.count).map { Double($0) }
        
        let sumX = indices.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(indices, values).map { $0 * $1 }.reduce(0, +)
        let sumX2 = indices.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        
        return slope
    }
    
    private func calculateTrendAdjustment(_ trend: JubileeTrend) -> Double {
        switch trend.direction {
        case .increasing:
            return trend.changeRate * 0.5 // Add up to 5% for strong increasing trend
        case .decreasing:
            return -trend.changeRate * 0.5 // Subtract for decreasing trend
        case .stable:
            return 0
        }
    }
    
    private func generateTrendSummary(direction: TrendDirection, changeRate: Double, factors: [String]) -> String {
        let directionText: String
        switch direction {
        case .increasing:
            directionText = "Jubilee probability is increasing"
        case .decreasing:
            directionText = "Jubilee probability is decreasing"
        case .stable:
            directionText = "Conditions remain stable"
        }
        
        let rateText = changeRate > 5 ? "rapidly" : changeRate > 2 ? "moderately" : "slowly"
        let factorText = factors.isEmpty ? "" : ". Key factors: \(factors.joined(separator: ", "))"
        
        return "\(directionText) \(rateText)\(factorText)"
    }
    
    // MARK: - Phase 4 ML-based Methods
    
    func predictJubileeEvent(location: CLLocation, date: Date) async throws -> JubileePrediction {
        return try await coreMLService.predictJubileeEvent(location: location, date: date)
    }
    
    func predictJubileeEvent(coordinate: CLLocationCoordinate2D, date: Date) async throws -> JubileePrediction {
        return try await coreMLService.predictJubileeEvent(coordinate: coordinate, date: date)
    }
    
    func updateModelWithNewData() async throws {
        try await coreMLService.updateModelWithNewData()
    }
    
    func getModelPerformanceMetrics() async throws -> ModelPerformanceMetrics {
        return try await coreMLService.getModelPerformanceMetrics()
    }
    
    func loadModel() async throws {
        try await coreMLService.loadModel()
    }
    
    func unloadModel() {
        coreMLService.unloadModel()
    }
    
    
    
    func getPredictionHistory(for location: CLLocation, dateRange: DateInterval) async throws -> PredictionHistory {
        return try await coreMLService.getPredictionHistory(for: location, dateRange: dateRange)
    }
    
    func getConfidenceInterval(for prediction: JubileePrediction) -> ConfidenceInterval {
        return coreMLService.getConfidenceInterval(for: prediction)
    }
}