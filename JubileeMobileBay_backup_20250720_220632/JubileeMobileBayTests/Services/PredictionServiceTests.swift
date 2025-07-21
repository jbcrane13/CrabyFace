import XCTest
@testable import JubileeMobileBay

final class PredictionServiceTests: XCTestCase {
    var sut: PredictionService!
    var mockWeatherAPI: MockWeatherAPIService!
    var mockMarineAPI: MockMarineDataService!
    
    override func setUp() {
        super.setUp()
        mockWeatherAPI = MockWeatherAPIService()
        mockMarineAPI = MockMarineDataService()
        sut = PredictionService(
            weatherAPI: mockWeatherAPI,
            marineAPI: mockMarineAPI
        )
    }
    
    override func tearDown() {
        sut = nil
        mockWeatherAPI = nil
        mockMarineAPI = nil
        super.tearDown()
    }
    
    // MARK: - Probability Calculation Tests
    
    func test_calculateJubileeProbability_withCriticalOxygen_shouldReturnHighProbability() async throws {
        // Given
        let marineConditions = MarineConditions(
            waterQuality: WaterQuality(
                temperature: 78,
                dissolvedOxygen: 1.5, // Critical level
                ph: 7.5,
                salinity: 35,
                turbidity: 15,
                chlorophyll: 3
            ),
            current: CurrentData(speed: 0.3, direction: 180, temperature: 78),
            wave: WaveData(height: 1.5, period: 6, direction: 90),
            timestamp: Date()
        )
        
        let weatherConditions = WeatherConditions(
            temperature: 82,
            humidity: 85,
            windSpeed: 2, // Low wind
            windDirection: "E",
            pressure: 1010,
            visibility: 8,
            uvIndex: 8,
            cloudCover: 30
        )
        
        mockMarineAPI.mockCurrentConditions = marineConditions
        mockWeatherAPI.mockCurrentConditions = weatherConditions
        
        // When
        let probability = try await sut.calculateJubileeProbability()
        
        // Then
        XCTAssertGreaterThan(probability, 70)
        XCTAssertLessThanOrEqual(probability, 100)
    }
    
    func test_calculateJubileeProbability_withNormalConditions_shouldReturnLowProbability() async throws {
        // Given
        let marineConditions = MarineConditions(
            waterQuality: WaterQuality(
                temperature: 72,
                dissolvedOxygen: 6.0, // Normal level
                ph: 7.8,
                salinity: 32,
                turbidity: 8,
                chlorophyll: 1.5
            ),
            current: CurrentData(speed: 0.8, direction: 90, temperature: 72),
            wave: WaveData(height: 3, period: 10, direction: 180),
            timestamp: Date()
        )
        
        let weatherConditions = WeatherConditions(
            temperature: 75,
            humidity: 65,
            windSpeed: 15, // Higher wind
            windDirection: "SW",
            pressure: 1015,
            visibility: 10,
            uvIndex: 5,
            cloudCover: 50
        )
        
        mockMarineAPI.mockCurrentConditions = marineConditions
        mockWeatherAPI.mockCurrentConditions = weatherConditions
        
        // When
        let probability = try await sut.calculateJubileeProbability()
        
        // Then
        XCTAssertLessThan(probability, 30)
        XCTAssertGreaterThanOrEqual(probability, 0)
    }
    
    // MARK: - 24-Hour Prediction Tests
    
    func test_generate24HourPrediction_shouldReturnHourlyPredictions() async throws {
        // Given
        let currentMarine = MarineConditions(
            waterQuality: WaterQuality(
                temperature: 78,
                dissolvedOxygen: 2.0,
                ph: 7.5,
                salinity: 35,
                turbidity: 12,
                chlorophyll: 2.5
            ),
            current: CurrentData(speed: 0.5, direction: 180, temperature: 78),
            wave: WaveData(height: 2, period: 8, direction: 90),
            timestamp: Date()
        )
        
        let forecasts = (0..<24).map { hour in
            WeatherForecast(
                date: Date().addingTimeInterval(Double(hour) * 3600),
                temperature: 78 + Double(hour % 6),
                humidity: 80 + Double(hour % 10),
                windSpeed: 5 + Double(hour % 8),
                windDirection: "E",
                precipitationChance: hour * 2,
                conditions: "Partly Cloudy",
                icon: "partly-cloudy"
            )
        }
        
        let historicalData = (0..<7).map { day in
            MarineConditions(
                waterQuality: WaterQuality(
                    temperature: 76 + Double(day),
                    dissolvedOxygen: 2.5 - Double(day) * 0.1,
                    ph: 7.5,
                    salinity: 35,
                    turbidity: 10 + Double(day),
                    chlorophyll: 2 + Double(day) * 0.1
                ),
                current: CurrentData(speed: 0.5, direction: 180, temperature: 76),
                wave: WaveData(height: 2, period: 8, direction: 90),
                timestamp: Date().addingTimeInterval(Double(-day) * 86400)
            )
        }
        
        mockMarineAPI.mockCurrentConditions = currentMarine
        mockWeatherAPI.mockForecast = forecasts
        mockMarineAPI.mockHistoricalData = historicalData
        
        // When
        let predictions = try await sut.generate24HourPrediction()
        
        // Then
        XCTAssertEqual(predictions.count, 24)
        
        // Verify each prediction
        for (index, prediction) in predictions.enumerated() {
            XCTAssertEqual(prediction.hour, index)
            XCTAssertGreaterThanOrEqual(prediction.probability, 0)
            XCTAssertLessThanOrEqual(prediction.probability, 100)
            XCTAssertGreaterThanOrEqual(prediction.confidence, 0)
            XCTAssertLessThanOrEqual(prediction.confidence, 1)
            XCTAssertNotNil(prediction.conditions)
        }
    }
    
    // MARK: - Trend Analysis Tests
    
    func test_analyzeTrends_withDecliningOxygen_shouldShowIncreasingTrend() async throws {
        // Given - oxygen declining over past week
        let historicalData = (0..<7).map { day in
            MarineConditions(
                waterQuality: WaterQuality(
                    temperature: 78,
                    dissolvedOxygen: 4.0 - Double(day) * 0.3, // Declining from 4.0 to 2.2
                    ph: 7.5,
                    salinity: 35,
                    turbidity: 10,
                    chlorophyll: 2
                ),
                current: CurrentData(speed: 0.5, direction: 180, temperature: 78),
                wave: WaveData(height: 2, period: 8, direction: 90),
                timestamp: Date().addingTimeInterval(Double(-day) * 86400)
            )
        }
        
        mockMarineAPI.mockHistoricalData = historicalData.reversed() // Oldest first
        
        // When
        let trend = try await sut.analyzeTrends()
        
        // Then
        XCTAssertEqual(trend.direction, .increasing)
        XCTAssertNotNil(trend.summary)
        XCTAssertGreaterThan(trend.changeRate, 0)
    }
    
    func test_analyzeTrends_withStableConditions_shouldShowStableTrend() async throws {
        // Given - stable conditions
        let historicalData = (0..<7).map { day in
            MarineConditions(
                waterQuality: WaterQuality(
                    temperature: 78,
                    dissolvedOxygen: 5.5 + Double(day % 2) * 0.2, // Minor fluctuations
                    ph: 7.5,
                    salinity: 35,
                    turbidity: 10,
                    chlorophyll: 2
                ),
                current: CurrentData(speed: 0.5, direction: 180, temperature: 78),
                wave: WaveData(height: 2, period: 8, direction: 90),
                timestamp: Date().addingTimeInterval(Double(-day) * 86400)
            )
        }
        
        mockMarineAPI.mockHistoricalData = historicalData.reversed()
        
        // When
        let trend = try await sut.analyzeTrends()
        
        // Then
        XCTAssertEqual(trend.direction, .stable)
        XCTAssertNotNil(trend.summary)
        XCTAssertLessThan(abs(trend.changeRate), 5)
    }
}

// MARK: - Mock Services

class MockWeatherAPIService: WeatherAPIProtocol {
    var mockCurrentConditions: WeatherConditions?
    var mockForecast: [WeatherForecast] = []
    var mockTideData: [TideData] = []
    var shouldThrowError = false
    
    func fetchCurrentConditions() async throws -> WeatherConditions {
        if shouldThrowError {
            throw WeatherAPIError.networkError
        }
        guard let conditions = mockCurrentConditions else {
            throw WeatherAPIError.invalidResponse
        }
        return conditions
    }
    
    func fetchHourlyForecast(hours: Int) async throws -> [WeatherForecast] {
        if shouldThrowError {
            throw WeatherAPIError.networkError
        }
        return Array(mockForecast.prefix(hours))
    }
    
    func fetchTideData() async throws -> [TideData] {
        if shouldThrowError {
            throw WeatherAPIError.networkError
        }
        return mockTideData
    }
}

class MockMarineDataService: MarineDataProtocol {
    var mockCurrentConditions: MarineConditions?
    var mockHistoricalData: [MarineConditions] = []
    var mockStations: [MonitoringStation] = []
    var shouldThrowError = false
    
    func fetchCurrentConditions() async throws -> MarineConditions {
        if shouldThrowError {
            throw MarineDataError.networkError
        }
        guard let conditions = mockCurrentConditions else {
            throw MarineDataError.dataNotAvailable
        }
        return conditions
    }
    
    func fetchHistoricalData(from startDate: Date, to endDate: Date) async throws -> [MarineConditions] {
        if shouldThrowError {
            throw MarineDataError.networkError
        }
        return mockHistoricalData
    }
    
    func fetchNearbyStations(latitude: Double, longitude: Double, radius: Double) async throws -> [MonitoringStation] {
        if shouldThrowError {
            throw MarineDataError.networkError
        }
        return mockStations
    }
}