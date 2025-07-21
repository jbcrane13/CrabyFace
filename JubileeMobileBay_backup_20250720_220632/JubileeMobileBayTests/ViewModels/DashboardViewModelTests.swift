import XCTest
import CoreLocation
@testable import JubileeMobileBay

@MainActor
final class DashboardViewModelTests: XCTestCase {
    var sut: DashboardViewModel!
    var mockWeatherAPI: MockWeatherAPIService!
    var mockMarineAPI: MockMarineDataService!
    var mockPredictionService: MockPredictionService!
    var mockCloudKitService: MockCloudKitService!
    var mockAuthService: MockAuthenticationService!
    
    override func setUp() async throws {
        try await super.setUp()
        mockWeatherAPI = MockWeatherAPIService()
        mockMarineAPI = MockMarineDataService()
        mockPredictionService = MockPredictionService()
        mockCloudKitService = MockCloudKitService()
        mockAuthService = MockAuthenticationService()
        
        sut = DashboardViewModel(
            weatherAPI: mockWeatherAPI,
            marineAPI: mockMarineAPI,
            predictionService: mockPredictionService,
            cloudKitService: mockCloudKitService,
            authService: mockAuthService
        )
    }
    
    override func tearDown() {
        sut = nil
        mockWeatherAPI = nil
        mockMarineAPI = nil
        mockPredictionService = nil
        mockCloudKitService = nil
        mockAuthService = nil
        super.tearDown()
    }
    
    // MARK: - Loading State Tests
    
    func test_initialState_shouldBeIdle() {
        XCTAssertEqual(sut.loadingState, .idle)
        XCTAssertNil(sut.currentProbability)
        XCTAssertNil(sut.currentConditions)
        XCTAssertNil(sut.hourlyPredictions)
        XCTAssertTrue(sut.recentEvents.isEmpty)
        XCTAssertTrue(sut.riskFactors.isEmpty)
    }
    
    func test_loadDashboardData_shouldSetLoadingState() async {
        // Given
        mockWeatherAPI.mockCurrentConditions = createMockWeatherConditions()
        mockMarineAPI.mockCurrentConditions = createMockMarineConditions()
        mockPredictionService.mockProbability = 75.0
        
        // When
        let task = Task {
            await sut.loadDashboardData()
        }
        
        // Wait a moment for loading to start
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Then
        XCTAssertEqual(sut.loadingState, .loading)
        
        await task.value
    }
    
    // MARK: - Data Loading Tests
    
    func test_loadDashboardData_withSuccessfulAPICalls_shouldUpdateAllProperties() async {
        // Given
        let weatherConditions = createMockWeatherConditions()
        let marineConditions = createMockMarineConditions()
        let probability = 85.5
        let predictions = createMockHourlyPredictions()
        let trend = JubileeTrend(
            direction: .increasing,
            changeRate: 5.2,
            summary: "Conditions worsening",
            keyFactors: ["Oxygen declining", "Temperature rising"]
        )
        let riskFactors = createMockRiskFactors()
        let events = createMockJubileeEvents()
        
        mockWeatherAPI.mockCurrentConditions = weatherConditions
        mockMarineAPI.mockCurrentConditions = marineConditions
        mockPredictionService.mockProbability = probability
        mockPredictionService.mockPredictions = predictions
        mockPredictionService.mockTrend = trend
        mockPredictionService.mockRiskFactors = riskFactors
        mockCloudKitService.mockEvents = events
        
        // When
        await sut.loadDashboardData()
        
        // Then
        XCTAssertEqual(sut.loadingState, .loaded)
        XCTAssertEqual(sut.currentProbability, probability)
        XCTAssertNotNil(sut.currentConditions)
        XCTAssertEqual(sut.currentConditions?.waterTemperature, marineConditions.waterQuality.temperature)
        XCTAssertEqual(sut.currentConditions?.dissolvedOxygen, marineConditions.waterQuality.dissolvedOxygen)
        XCTAssertEqual(sut.currentConditions?.windSpeed, weatherConditions.windSpeed)
        XCTAssertEqual(sut.currentConditions?.humidity, weatherConditions.humidity)
        XCTAssertEqual(sut.hourlyPredictions?.count, predictions.count)
        XCTAssertEqual(sut.trend, trend)
        XCTAssertEqual(sut.riskFactors.count, riskFactors.count)
        XCTAssertEqual(sut.recentEvents.count, events.count)
    }
    
    func test_loadDashboardData_withAPIFailure_shouldSetErrorState() async {
        // Given
        mockWeatherAPI.shouldThrowError = true
        
        // When
        await sut.loadDashboardData()
        
        // Then
        XCTAssertEqual(sut.loadingState, .error("The operation couldn't be completed. (JubileeMobileBay.WeatherAPIError error 0.)"))
        XCTAssertNil(sut.currentProbability)
        XCTAssertNil(sut.currentConditions)
    }
    
    // MARK: - Refresh Tests
    
    func test_refresh_shouldReloadAllData() async {
        // Given - Initial load
        mockPredictionService.mockProbability = 50.0
        await sut.loadDashboardData()
        XCTAssertEqual(sut.currentProbability, 50.0)
        
        // When - Update mock and refresh
        mockPredictionService.mockProbability = 75.0
        await sut.refresh()
        
        // Then
        XCTAssertEqual(sut.currentProbability, 75.0)
    }
    
    // MARK: - User Submitted Events Tests
    
    func test_activeEventCount_shouldCountEventsFromLast24Hours() async {
        // Given
        let now = Date()
        let events = [
            createMockJubileeEvent(startTime: now.addingTimeInterval(-3600)), // 1 hour ago
            createMockJubileeEvent(startTime: now.addingTimeInterval(-86400)), // 24 hours ago
            createMockJubileeEvent(startTime: now.addingTimeInterval(-172800)) // 48 hours ago
        ]
        mockCloudKitService.mockEvents = events
        
        // When
        await sut.loadDashboardData()
        
        // Then
        XCTAssertEqual(sut.activeEventCount, 2)
    }
    
    func test_todayReportCount_shouldCountTodaysReports() async {
        // Given
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let events = [
            createMockJubileeEvent(startTime: today, reportCount: 5),
            createMockJubileeEvent(startTime: today, reportCount: 3),
            createMockJubileeEvent(startTime: yesterday, reportCount: 10)
        ]
        mockCloudKitService.mockEvents = events
        
        // When
        await sut.loadDashboardData()
        
        // Then
        XCTAssertEqual(sut.todayReportCount, 8)
    }
    
    // MARK: - Alert Threshold Tests
    
    func test_shouldShowAlert_whenProbabilityExceedsThreshold() async {
        // Given
        sut.alertThreshold = 70.0
        mockPredictionService.mockProbability = 75.0
        
        // When
        await sut.loadDashboardData()
        
        // Then
        XCTAssertTrue(sut.shouldShowHighProbabilityAlert)
    }
    
    func test_shouldNotShowAlert_whenProbabilityBelowThreshold() async {
        // Given
        sut.alertThreshold = 70.0
        mockPredictionService.mockProbability = 65.0
        
        // When
        await sut.loadDashboardData()
        
        // Then
        XCTAssertFalse(sut.shouldShowHighProbabilityAlert)
    }
    
    // MARK: - Chart Data Tests
    
    func test_chartData_shouldFormatPredictionsForSwiftUICharts() async {
        // Given
        let predictions = createMockHourlyPredictions()
        mockPredictionService.mockPredictions = predictions
        
        // When
        await sut.loadDashboardData()
        
        // Then
        XCTAssertEqual(sut.chartData.count, predictions.count)
        for (index, dataPoint) in sut.chartData.enumerated() {
            XCTAssertEqual(dataPoint.hour, index)
            XCTAssertEqual(dataPoint.probability, predictions[index].probability)
            XCTAssertNotNil(dataPoint.date)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockWeatherConditions() -> WeatherConditions {
        WeatherConditions(
            temperature: 82.0,
            humidity: 85.0,
            windSpeed: 3.0,
            windDirection: "E",
            pressure: 1013.0,
            visibility: 10.0,
            uvIndex: 8,
            cloudCover: 25
        )
    }
    
    private func createMockMarineConditions() -> MarineConditions {
        MarineConditions(
            waterQuality: WaterQuality(
                temperature: 78.0,
                dissolvedOxygen: 1.8,
                ph: 7.5,
                salinity: 35.0,
                turbidity: 12.0,
                chlorophyll: 2.5
            ),
            current: CurrentData(speed: 0.5, direction: 180, temperature: 78.0),
            wave: WaveData(height: 2.5, period: 8.0, direction: 90),
            timestamp: Date()
        )
    }
    
    private func createMockHourlyPredictions() -> [HourlyPrediction] {
        (0..<24).map { hour in
            HourlyPrediction(
                hour: hour,
                probability: 50.0 + Double(hour),
                confidence: 1.0 - (Double(hour) / 48.0),
                conditions: PredictedConditions(
                    temperature: 78.0 + Double(hour) * 0.2,
                    dissolvedOxygen: 2.0 - Double(hour) * 0.05,
                    windSpeed: 5.0 + Double(hour) * 0.3,
                    humidity: 80.0 + Double(hour) * 0.5
                )
            )
        }
    }
    
    private func createMockRiskFactors() -> [RiskFactor] {
        [
            RiskFactor(
                name: "Dissolved Oxygen",
                weight: 0.4,
                currentValue: 1.8,
                threshold: 2.0,
                contribution: 0.35
            ),
            RiskFactor(
                name: "Water Temperature",
                weight: 0.2,
                currentValue: 78.0,
                threshold: 80.0,
                contribution: 0.15
            ),
            RiskFactor(
                name: "Wind Speed",
                weight: 0.2,
                currentValue: 3.0,
                threshold: 5.0,
                contribution: 0.18
            ),
            RiskFactor(
                name: "Humidity",
                weight: 0.1,
                currentValue: 85.0,
                threshold: 80.0,
                contribution: 0.08
            )
        ]
    }
    
    private func createMockJubileeEvents() -> [JubileeEvent] {
        [
            createMockJubileeEvent(startTime: Date().addingTimeInterval(-3600)),
            createMockJubileeEvent(startTime: Date().addingTimeInterval(-7200)),
            createMockJubileeEvent(startTime: Date().addingTimeInterval(-10800))
        ]
    }
    
    private func createMockJubileeEvent(startTime: Date, reportCount: Int = 1) -> JubileeEvent {
        JubileeEvent(
            id: UUID(),
            startTime: startTime,
            endTime: startTime.addingTimeInterval(3600),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            intensity: .moderate,
            verificationStatus: .unverified,
            reportCount: reportCount,
            metadata: JubileeMetadata()
        )
    }
}

// MARK: - Mock Services

class MockPredictionService: PredictionServiceProtocol {
    var mockProbability: Double = 0
    var mockPredictions: [HourlyPrediction] = []
    var mockTrend = JubileeTrend(direction: .stable, changeRate: 0, summary: "Stable", keyFactors: [])
    var mockRiskFactors: [RiskFactor] = []
    var shouldThrowError = false
    
    func calculateJubileeProbability() async throws -> Double {
        if shouldThrowError {
            throw PredictionError.calculationFailed
        }
        return mockProbability
    }
    
    func generate24HourPrediction() async throws -> [HourlyPrediction] {
        if shouldThrowError {
            throw PredictionError.calculationFailed
        }
        return mockPredictions
    }
    
    func analyzeTrends() async throws -> JubileeTrend {
        if shouldThrowError {
            throw PredictionError.calculationFailed
        }
        return mockTrend
    }
    
    func getRiskFactors() async throws -> [RiskFactor] {
        if shouldThrowError {
            throw PredictionError.calculationFailed
        }
        return mockRiskFactors
    }
}

enum PredictionError: Error {
    case calculationFailed
}

class MockCloudKitService: CloudKitServiceProtocol {
    var mockEvents: [JubileeEvent] = []
    var shouldThrowError = false
    
    func fetchRecentJubileeEvents(limit: Int) async throws -> [JubileeEvent] {
        if shouldThrowError {
            throw CloudKitError.networkError
        }
        return Array(mockEvents.prefix(limit))
    }
    
    func saveJubileeEvent(_ event: JubileeEvent) async throws -> JubileeEvent {
        return event
    }
    
    func updateJubileeEvent(_ event: JubileeEvent) async throws -> JubileeEvent {
        return event
    }
    
    func deleteJubileeEvent(_ event: JubileeEvent) async throws {
        // No-op for tests
    }
}

class MockAuthenticationService: AuthenticationService {
    override init(cloudKitService: CloudKitServiceProtocol = MockCloudKitService()) {
        super.init(cloudKitService: cloudKitService)
    }
}