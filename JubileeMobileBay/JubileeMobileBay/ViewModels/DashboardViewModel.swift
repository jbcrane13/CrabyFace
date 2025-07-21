import Foundation
import SwiftUI
import CoreLocation

// MARK: - View State

enum DashboardLoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}

// MARK: - Current Conditions Model

struct CurrentConditionsDisplay: Equatable {
    let waterTemperature: Double
    let dissolvedOxygen: Double
    let windSpeed: Double
    let humidity: Double
    let oxygenStatus: OxygenStatus
}

// MARK: - Chart Data Model

struct PredictionChartData: Identifiable {
    let id = UUID()
    let hour: Int
    let date: Date
    let probability: Double
}

// MARK: - Dashboard ViewModel

@MainActor
final class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var loadingState: DashboardLoadingState = .idle
    @Published var currentProbability: Double?
    @Published var currentConditions: CurrentConditionsDisplay?
    @Published var hourlyPredictions: [HourlyPrediction]?
    @Published var trend: JubileeTrend?
    @Published var riskFactors: [RiskFactor] = []
    @Published var recentEvents: [JubileeEvent] = []
    @Published var alertThreshold: Double = 70.0
    @Published var shouldShowHighProbabilityAlert = false
    
    // MARK: - Services
    
    private let weatherAPI: WeatherAPIProtocol
    private let marineAPI: MarineDataProtocol
    private let predictionService: PredictionServiceProtocol
    private let cloudKitService: CloudKitServiceProtocol
    private let authService: AuthenticationService
    
    // MARK: - Computed Properties
    
    var activeEventCount: Int {
        let oneDayAgo = Date().addingTimeInterval(-24 * 60 * 60)
        return recentEvents.filter { $0.startTime > oneDayAgo }.count
    }
    
    var todayReportCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return recentEvents.filter { event in
            calendar.isDate(event.startTime, inSameDayAs: today)
        }.reduce(0) { $0 + $1.reportCount }
    }
    
    var chartData: [PredictionChartData] {
        guard let predictions = hourlyPredictions else { return [] }
        
        let now = Date()
        return predictions.map { prediction in
            PredictionChartData(
                hour: prediction.hour,
                date: now.addingTimeInterval(Double(prediction.hour) * 3600),
                probability: prediction.probability
            )
        }
    }
    
    var probabilityColor: Color {
        guard let probability = currentProbability else { return .gray }
        
        switch probability {
        case 0..<30:
            return .green
        case 30..<50:
            return .yellow
        case 50..<70:
            return .orange
        default:
            return .red
        }
    }
    
    var probabilityDescription: String {
        guard let probability = currentProbability else { return "Unknown" }
        
        switch probability {
        case 0..<20:
            return "Very Low"
        case 20..<40:
            return "Low"
        case 40..<60:
            return "Moderate"
        case 60..<80:
            return "High"
        default:
            return "Very High"
        }
    }
    
    // MARK: - Initialization
    
    init(
        weatherAPI: WeatherAPIProtocol,
        marineAPI: MarineDataProtocol,
        predictionService: PredictionServiceProtocol,
        cloudKitService: CloudKitServiceProtocol,
        authService: AuthenticationService
    ) {
        self.weatherAPI = weatherAPI
        self.marineAPI = marineAPI
        self.predictionService = predictionService
        self.cloudKitService = cloudKitService
        self.authService = authService
    }
    
    // MARK: - Public Methods
    
    func loadDashboardData() async {
        loadingState = .loading
        
        do {
            // Fetch all data in parallel
            async let weatherTask = weatherAPI.fetchCurrentConditions()
            async let marineTask = marineAPI.fetchCurrentConditions()
            async let probabilityTask = predictionService.calculateJubileeProbability()
            async let predictionsTask = predictionService.generate24HourPrediction()
            async let trendTask = predictionService.analyzeTrends()
            async let riskTask = predictionService.getRiskFactors()
            async let eventsTask = cloudKitService.fetchRecentJubileeEvents(limit: 10)
            
            // Wait for all results
            let (weather, marine, probability, predictions, trendData, risks, events) = try await (
                weatherTask,
                marineTask,
                probabilityTask,
                predictionsTask,
                trendTask,
                riskTask,
                eventsTask
            )
            
            // Update UI properties
            currentProbability = probability
            hourlyPredictions = predictions
            trend = trendData
            riskFactors = risks
            recentEvents = events
            
            // Create display model for current conditions
            currentConditions = CurrentConditionsDisplay(
                waterTemperature: marine.waterQuality.temperature,
                dissolvedOxygen: marine.waterQuality.dissolvedOxygen,
                windSpeed: weather.windSpeed,
                humidity: weather.humidity,
                oxygenStatus: marine.waterQuality.dissolvedOxygenStatus
            )
            
            // Check if alert should be shown
            shouldShowHighProbabilityAlert = probability > alertThreshold
            
            loadingState = .loaded
        } catch {
            loadingState = .error(error.localizedDescription)
            print("Dashboard loading error: \(error)")
        }
    }
    
    func refresh() async {
        await loadDashboardData()
    }
    
    func setAlertThreshold(_ threshold: Double) {
        alertThreshold = threshold
        if let probability = currentProbability {
            shouldShowHighProbabilityAlert = probability > threshold
        }
    }
}

// MARK: - Protocol Conformances

protocol CloudKitServiceProtocol {
    func fetchRecentJubileeEvents(limit: Int) async throws -> [JubileeEvent]
    func saveJubileeEvent(_ event: JubileeEvent) async throws -> JubileeEvent
    func updateJubileeEvent(_ event: JubileeEvent) async throws -> JubileeEvent
    func deleteJubileeEvent(_ event: JubileeEvent) async throws
}

extension CloudKitService: CloudKitServiceProtocol {}