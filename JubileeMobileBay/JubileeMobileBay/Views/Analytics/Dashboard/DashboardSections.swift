//
//  DashboardSections.swift
//  JubileeMobileBay
//
//  Individual dashboard section implementations
//

import SwiftUI
import Charts

// MARK: - Statistics Summary Section

class StatisticsSummarySection: BaseDashboardSection {
    @Published private var stats: DashboardStatistics?
    
    init() {
        super.init(
            id: "stats",
            title: "Quick Statistics",
            priority: 100,
            viewType: .statCards,
            requiredDataSources: [.noaa, .userSubmitted]
        )
    }
    
    override func createView() -> AnyView {
        AnyView(StatisticsSummaryView(stats: stats))
    }
    
    override func hasData() -> Bool {
        stats != nil
    }
    
    override func refreshData() async throws {
        // Simulate data loading
        try await Task.sleep(nanoseconds: 500_000_000)
        
        await MainActor.run {
            self.stats = DashboardStatistics(
                averageTemperature: 76.5,
                temperatureTrend: 2.3,
                averageActivityScore: 0.72,
                activityTrend: 5.1,
                peakActivityTime: "6-9 AM",
                topSpecies: "Blue Crab",
                totalObservations: 342,
                activeUsers: 89
            )
        }
    }
}

struct DashboardStatistics {
    let averageTemperature: Double
    let temperatureTrend: Double
    let averageActivityScore: Double
    let activityTrend: Double
    let peakActivityTime: String
    let topSpecies: String
    let totalObservations: Int
    let activeUsers: Int
}

struct StatisticsSummaryView: View {
    let stats: DashboardStatistics?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                if let stats = stats {
                    StatCard(
                        title: "Avg Temperature",
                        value: String(format: "%.1f°F", stats.averageTemperature),
                        trend: stats.temperatureTrend,
                        icon: "thermometer.medium",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Activity Score",
                        value: String(format: "%.2f", stats.averageActivityScore),
                        trend: stats.activityTrend,
                        icon: "waveform.path.ecg",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Peak Hours",
                        value: stats.peakActivityTime,
                        trend: nil,
                        icon: "clock.fill",
                        color: .purple
                    )
                    
                    StatCard(
                        title: "Top Species",
                        value: stats.topSpecies,
                        trend: nil,
                        icon: "fish.fill",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Observations",
                        value: "\(stats.totalObservations)",
                        trend: nil,
                        icon: "eye.fill",
                        color: .indigo
                    )
                    
                    StatCard(
                        title: "Active Users",
                        value: "\(stats.activeUsers)",
                        trend: nil,
                        icon: "person.2.fill",
                        color: .pink
                    )
                } else {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .frame(width: 150, height: 100)
                            .shimmer()
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Temperature Trends Section

class TemperatureTrendsSection: BaseDashboardSection {
    @Published private var temperatureData: [DataPoint] = []
    
    init() {
        super.init(
            id: "temperature",
            title: "Temperature Trends",
            priority: 90,
            viewType: .timeSeries,
            requiredDataSources: [.noaa]
        )
    }
    
    override func createView() -> AnyView {
        AnyView(
            TimeSeriesChart(
                dataPoints: temperatureData,
                title: "Water Temperature (7 Days)",
                yAxisLabel: "Temperature (°F)"
            )
            .padding(.horizontal)
        )
    }
    
    override func hasData() -> Bool {
        !temperatureData.isEmpty
    }
    
    override func refreshData() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        
        var dataPoints: [DataPoint] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let baseTemp = 75.0 + sin(currentDate.timeIntervalSince1970 / 86400) * 8
            let randomVariation = Double.random(in: -2...2)
            let temperature = baseTemp + randomVariation
            
            dataPoints.append(DataPoint(
                date: currentDate,
                value: temperature,
                category: "Temperature",
                label: String(format: "%.1f°F", temperature)
            ))
            
            currentDate = calendar.date(byAdding: .hour, value: 6, to: currentDate)!
        }
        
        await MainActor.run {
            self.temperatureData = dataPoints
        }
    }
}

// MARK: - Species Distribution Section

class SpeciesDistributionSection: BaseDashboardSection {
    @Published private var speciesData: [AggregatedDataPoint] = []
    
    init() {
        super.init(
            id: "species",
            title: "Species Distribution",
            priority: 80,
            viewType: .barChart,
            requiredDataSources: [.userSubmitted]
        )
    }
    
    override func createView() -> AnyView {
        AnyView(
            BarChart(
                data: speciesData,
                title: "Species Observations (30 Days)",
                yAxisLabel: "Count",
                colorScheme: .categorical
            )
            .padding(.horizontal)
        )
    }
    
    override func hasData() -> Bool {
        !speciesData.isEmpty
    }
    
    override func refreshData() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let species = MarineSpecies.commonSpecies
        let total = 250.0
        
        let data = species.enumerated().map { index, marineSpecies in
            let baseValue = Double(species.count - index) * 25
            let value = baseValue + Double.random(in: -10...10)
            let percentage = value / total
            
            return AggregatedDataPoint(
                category: marineSpecies.name,
                value: value,
                count: Int(value),
                percentage: percentage
            )
        }
        
        await MainActor.run {
            self.speciesData = data
        }
    }
}

// MARK: - Correlation Analysis Section

class CorrelationAnalysisSection: BaseDashboardSection {
    @Published private var correlationData: [CorrelationDataPoint] = []
    
    init() {
        super.init(
            id: "correlation",
            title: "Environmental Correlations",
            priority: 70,
            viewType: .scatterPlot,
            requiredDataSources: [.noaa, .sensor]
        )
    }
    
    override func createView() -> AnyView {
        AnyView(
            ScatterPlotChart(
                data: correlationData,
                title: "Temperature vs Activity",
                xAxisLabel: "Water Temperature (°F)",
                yAxisLabel: "Jubilee Activity Score"
            )
            .padding(.horizontal)
        )
    }
    
    override func hasData() -> Bool {
        !correlationData.isEmpty
    }
    
    override func refreshData() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let data = (0..<40).map { _ in
            let temperature = Double.random(in: 68...85)
            let baseActivity = (temperature - 68) / 17 * 0.6 + 0.2
            let randomFactor = Double.random(in: -0.15...0.15)
            let activity = max(0, min(1, baseActivity + randomFactor))
            
            let category: String
            if temperature < 73 {
                category = "Low Activity"
            } else if temperature < 78 {
                category = "Moderate Activity"
            } else {
                category = "High Activity"
            }
            
            return CorrelationDataPoint(
                xValue: temperature,
                yValue: activity,
                category: category,
                label: String(format: "%.1f°F", temperature)
            )
        }
        
        await MainActor.run {
            self.correlationData = data
        }
    }
}

// MARK: - Activity Patterns Section

class ActivityPatternsSection: BaseDashboardSection {
    @Published private var heatMapData: [[HeatMapChart.HeatMapDataPoint]] = []
    private let timeLabels = ["12AM", "3AM", "6AM", "9AM", "12PM", "3PM", "6PM", "9PM"]
    private let locationLabels = ["Point Clear", "Fairhope", "Daphne", "Spanish Fort", "Mobile"]
    
    init() {
        super.init(
            id: "activity",
            title: "Activity Patterns",
            priority: 60,
            viewType: .heatMap,
            requiredDataSources: [.userSubmitted]
        )
    }
    
    override func createView() -> AnyView {
        AnyView(
            HeatMapChart(
                data: heatMapData,
                title: "Activity by Location & Time",
                xLabels: timeLabels,
                yLabels: locationLabels,
                colorScheme: .activity
            )
            .padding(.horizontal)
        )
    }
    
    override func hasData() -> Bool {
        !heatMapData.isEmpty
    }
    
    override func refreshData() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let data = locationLabels.indices.map { locationIndex in
            timeLabels.indices.map { timeIndex in
                let baseActivity = sin(Double(timeIndex) * .pi / 4) * 0.5 + 0.5
                let locationFactor = Double(locationLabels.count - locationIndex) / Double(locationLabels.count)
                let activity = baseActivity * locationFactor + Double.random(in: -0.1...0.1)
                
                return HeatMapChart.HeatMapDataPoint(
                    value: max(0, min(1, activity)),
                    label: String(format: "%.0f%%", activity * 100)
                )
            }
        }
        
        await MainActor.run {
            self.heatMapData = data
        }
    }
}

// MARK: - Predictions Section

class PredictionsSection: BaseDashboardSection {
    @Published private var prediction: JubileePrediction?
    
    init() {
        super.init(
            id: "predictions",
            title: "ML Predictions",
            priority: 50,
            viewType: .predictions,
            requiredDataSources: [.noaa, .sensor]
        )
    }
    
    override func createView() -> AnyView {
        AnyView(PredictionSummaryView(prediction: prediction))
    }
    
    override func hasData() -> Bool {
        prediction != nil
    }
    
    override func refreshData() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        await MainActor.run {
            self.prediction = JubileePrediction.mockPrediction
        }
    }
}

struct PredictionSummaryView: View {
    let prediction: JubileePrediction?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let prediction = prediction {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Jubilee Probability")
                            .font(.headline)
                        
                        Text("\(prediction.probabilityPercentage)%")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(colorForProbability(prediction.probability))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Label("Confidence", systemImage: "checkmark.shield")
                            .font(.caption)
                        
                        Text("\(Int(prediction.confidenceScore * 100))%")
                            .font(.title2.weight(.semibold))
                    }
                }
                
                Divider()
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Predicted Intensity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(prediction.predictedIntensity.displayName)
                            .font(.subheadline.weight(.medium))
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Recommendation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(prediction.recommendationLevel.displayName)
                            .font(.subheadline.weight(.medium))
                    }
                }
            } else {
                ProgressView("Loading predictions...")
                    .frame(maxWidth: .infinity, minHeight: 150)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func colorForProbability(_ probability: Double) -> Color {
        switch probability {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .yellow
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

// MARK: - Alerts Section

class AlertsSection: BaseDashboardSection {
    @Published private var alerts: [DashboardAlert] = []
    
    init() {
        super.init(
            id: "alerts",
            title: "Active Alerts",
            priority: 95,
            viewType: .alerts,
            requiredDataSources: [.noaa]
        )
    }
    
    override func createView() -> AnyView {
        AnyView(AlertsView(alerts: alerts))
    }
    
    override func hasData() -> Bool {
        !alerts.isEmpty
    }
    
    override func refreshData() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let mockAlerts = [
            DashboardAlert(
                id: UUID(),
                type: .weather,
                severity: .warning,
                title: "High Winds Expected",
                message: "Winds up to 25 mph expected this evening",
                timestamp: Date()
            ),
            DashboardAlert(
                id: UUID(),
                type: .jubilee,
                severity: .info,
                title: "Favorable Conditions",
                message: "Temperature and tide conditions are optimal",
                timestamp: Date().addingTimeInterval(-3600)
            )
        ]
        
        await MainActor.run {
            self.alerts = mockAlerts
        }
    }
}

struct DashboardAlert: Identifiable {
    let id: UUID
    let type: AlertType
    let severity: AlertSeverity
    let title: String
    let message: String
    let timestamp: Date
    
    enum AlertType {
        case weather, jubilee, system
    }
    
    enum AlertSeverity {
        case info, warning, critical
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .critical: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle"
            case .warning: return "exclamationmark.triangle"
            case .critical: return "exclamationmark.octagon"
            }
        }
    }
}

struct AlertsView: View {
    let alerts: [DashboardAlert]
    
    var body: some View {
        VStack(spacing: 12) {
            if alerts.isEmpty {
                Text("No active alerts")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                ForEach(alerts) { alert in
                    HStack(spacing: 12) {
                        Image(systemName: alert.severity.icon)
                            .foregroundColor(alert.severity.color)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(alert.title)
                                .font(.headline)
                            
                            Text(alert.message)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(alert.timestamp, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.tertiary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(alert.severity.color.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Shimmer Effect

extension View {
    func shimmer() -> some View {
        self
            .redacted(reason: .placeholder)
            .shimmering()
    }
}

struct ShimmeringView: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 200 - 100)
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: phase
                )
            )
            .onAppear { phase = 1 }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmeringView())
    }
}