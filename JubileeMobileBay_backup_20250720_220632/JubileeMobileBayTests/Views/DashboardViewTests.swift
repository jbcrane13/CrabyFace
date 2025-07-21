import XCTest
import ViewInspector
import SwiftUI
@testable import JubileeMobileBay

@MainActor
final class DashboardViewTests: XCTestCase {
    var mockViewModel: MockDashboardViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        mockViewModel = MockDashboardViewModel()
    }
    
    override func tearDown() {
        mockViewModel = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func test_dashboardView_whenLoading_shouldShowProgressView() throws {
        // Given
        mockViewModel.loadingState = .loading
        let view = DashboardView(viewModel: mockViewModel)
        
        // Then
        XCTAssertNoThrow(try view.inspect().find(ViewType.ProgressView.self))
    }
    
    func test_dashboardView_whenError_shouldShowErrorMessage() throws {
        // Given
        mockViewModel.loadingState = .error("Network error")
        let view = DashboardView(viewModel: mockViewModel)
        
        // Then
        let errorText = try view.inspect().find(text: "Network error")
        XCTAssertNotNil(errorText)
    }
    
    // MARK: - Probability Display Tests
    
    func test_dashboardView_shouldShowProbabilityGauge() throws {
        // Given
        mockViewModel.loadingState = .loaded
        mockViewModel.currentProbability = 75.5
        let view = DashboardView(viewModel: mockViewModel)
        
        // Then
        let probabilityText = try view.inspect().find(text: "75%")
        XCTAssertNotNil(probabilityText)
        
        let descriptionText = try view.inspect().find(text: "High")
        XCTAssertNotNil(descriptionText)
    }
    
    // MARK: - Current Conditions Tests
    
    func test_dashboardView_shouldShowCurrentConditionsCards() throws {
        // Given
        mockViewModel.loadingState = .loaded
        mockViewModel.currentConditions = CurrentConditionsDisplay(
            waterTemperature: 78.0,
            dissolvedOxygen: 1.8,
            windSpeed: 3.0,
            humidity: 85.0,
            oxygenStatus: .critical
        )
        let view = DashboardView(viewModel: mockViewModel)
        
        // Then
        // Check for water temp
        let waterTempText = try view.inspect().find(text: "78°F")
        XCTAssertNotNil(waterTempText)
        
        // Check for dissolved oxygen
        let oxygenText = try view.inspect().find(text: "1.8 mg/L")
        XCTAssertNotNil(oxygenText)
        
        // Check for wind
        let windText = try view.inspect().find(text: "3 mph")
        XCTAssertNotNil(windText)
        
        // Check for humidity
        let humidityText = try view.inspect().find(text: "85%")
        XCTAssertNotNil(humidityText)
    }
    
    // MARK: - Action Button Tests
    
    func test_dashboardView_shouldShowReportJubileeButton() throws {
        // Given
        mockViewModel.loadingState = .loaded
        let view = DashboardView(viewModel: mockViewModel)
        
        // Then
        let reportButton = try view.inspect().find(button: "Report Jubilee")
        XCTAssertNotNil(reportButton)
    }
    
    func test_dashboardView_shouldShowSetAlertButton() throws {
        // Given
        mockViewModel.loadingState = .loaded
        let view = DashboardView(viewModel: mockViewModel)
        
        // Then
        let alertButton = try view.inspect().find(button: "Set Alert")
        XCTAssertNotNil(alertButton)
    }
    
    // MARK: - Chart Tests
    
    func test_dashboardView_shouldShow24HourPredictionChart() throws {
        // Given
        mockViewModel.loadingState = .loaded
        mockViewModel.chartData = [
            PredictionChartData(hour: 0, date: Date(), probability: 50),
            PredictionChartData(hour: 1, date: Date().addingTimeInterval(3600), probability: 55)
        ]
        let view = DashboardView(viewModel: mockViewModel)
        
        // Then
        let chartTitle = try view.inspect().find(text: "24-Hour Probability Forecast")
        XCTAssertNotNil(chartTitle)
    }
    
    // MARK: - Recent Events Tests
    
    func test_dashboardView_shouldShowRecentEvents() throws {
        // Given
        mockViewModel.loadingState = .loaded
        mockViewModel.recentEvents = [
            createMockJubileeEvent(),
            createMockJubileeEvent()
        ]
        let view = DashboardView(viewModel: mockViewModel)
        
        // Then
        let eventsTitle = try view.inspect().find(text: "Recent User Reports")
        XCTAssertNotNil(eventsTitle)
    }
    
    // MARK: - Alert Tests
    
    func test_dashboardView_whenHighProbability_shouldShowAlert() throws {
        // Given
        mockViewModel.loadingState = .loaded
        mockViewModel.currentProbability = 80
        mockViewModel.shouldShowHighProbabilityAlert = true
        let view = DashboardView(viewModel: mockViewModel)
        
        // Then
        let alertTitle = try view.inspect().find(text: "High Jubilee Probability")
        XCTAssertNotNil(alertTitle)
    }
    
    // MARK: - Helper Methods
    
    private func createMockJubileeEvent() -> JubileeEvent {
        JubileeEvent(
            id: UUID(),
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            intensity: .moderate,
            verificationStatus: .verified,
            reportCount: 1,
            metadata: JubileeMetadata()
        )
    }
}

// MARK: - Mock ViewModel

@MainActor
class MockDashboardViewModel: DashboardViewModel {
    init() {
        let mockWeather = MockWeatherAPIService()
        let mockMarine = MockMarineDataService()
        let mockPrediction = MockPredictionService()
        let mockCloudKit = MockCloudKitService()
        let mockAuth = MockAuthenticationService()
        
        super.init(
            weatherAPI: mockWeather,
            marineAPI: mockMarine,
            predictionService: mockPrediction,
            cloudKitService: mockCloudKit,
            authService: mockAuth
        )
    }
}