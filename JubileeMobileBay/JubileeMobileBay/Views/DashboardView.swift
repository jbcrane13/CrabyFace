//
//  DashboardView.swift
//  JubileeMobileBay
//
//  Enhanced dashboard showing real-time jubilee predictions, conditions, and user reports
//

import SwiftUI
import Charts
import CoreLocation

struct DashboardView: View {
    @StateObject var viewModel: DashboardViewModel
    @State private var showingReportView = false
    @State private var showingAlertSettings = false
    @State private var showingHighProbabilityAlert = false
    
    init(viewModel: DashboardViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            // Use mock data for development
            #if DEBUG
            let provider = DevelopmentDataProvider.shared
            _viewModel = StateObject(wrappedValue: DashboardViewModel(
                weatherAPI: provider.weatherAPI,
                marineAPI: provider.marineAPI,
                predictionService: provider.predictionService,
                cloudKitService: provider.cloudKitService,
                authService: provider.authService
            ))
            #else
            // Production initialization
            let weatherAPI = WeatherAPIService()
            let marineAPI = MarineDataService()
            let predictionService = PredictionService(
                weatherAPI: weatherAPI,
                marineAPI: marineAPI
            )
            let cloudKitService = CloudKitService()
            let authService = AuthenticationService(cloudKitService: cloudKitService)
            
            _viewModel = StateObject(wrappedValue: DashboardViewModel(
                weatherAPI: weatherAPI,
                marineAPI: marineAPI,
                predictionService: predictionService,
                cloudKitService: cloudKitService,
                authService: authService
            ))
            #endif
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    switch viewModel.loadingState {
                    case .idle, .loading:
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 400)
                    
                    case .loaded:
                        // Probability Gauge Section
                        probabilitySection
                        
                        // Current Conditions Grid
                        currentConditionsSection
                        
                        // Action Buttons
                        actionButtonsSection
                        
                        // 24-Hour Prediction Chart
                        predictionChartSection
                        
                        // Recent User Reports
                        recentReportsSection
                    
                    case .error(let message):
                        ErrorView(message: message) {
                            Task {
                                await viewModel.refresh()
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Jubilee Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.refresh()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingReportView) {
                ReportView()
            }
            .sheet(isPresented: $showingAlertSettings) {
                AlertSettingsView(viewModel: viewModel)
            }
            .alert("High Jubilee Probability", isPresented: $showingHighProbabilityAlert) {
                Button("OK") {
                    showingHighProbabilityAlert = false
                }
            } message: {
                Text("Current probability is \(Int(viewModel.currentProbability ?? 0))%. Conditions are favorable for a jubilee event.")
            }
            .task {
                await viewModel.loadDashboardData()
            }
            .onChange(of: viewModel.shouldShowHighProbabilityAlert) { _, newValue in
                showingHighProbabilityAlert = newValue
            }
        }
    }
    
    // MARK: - View Components
    
    private var probabilitySection: some View {
        VStack(spacing: 16) {
            // Circular Probability Gauge (like old app)
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: CGFloat((viewModel.currentProbability ?? 0) / 100))
                    .stroke(viewModel.probabilityColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: viewModel.currentProbability)
                
                VStack {
                    Text("\(Int(viewModel.currentProbability ?? 0))%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(viewModel.probabilityColor)
                    
                    Text(viewModel.probabilityDescription)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Probability")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
        }
    }
    
    private var currentConditionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Conditions")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                if let conditions = viewModel.currentConditions {
                    ConditionCard(
                        title: "Water Temp",
                        value: "\(Int(conditions.waterTemperature))°F",
                        icon: "thermometer.medium",
                        color: .blue,
                        trend: nil
                    )
                    
                    ConditionCard(
                        title: "Dissolved O₂",
                        value: String(format: "%.1f mg/L", conditions.dissolvedOxygen),
                        icon: "drop.fill",
                        color: conditions.oxygenStatus == .critical ? .red : 
                               conditions.oxygenStatus == .low ? .orange : .green,
                        trend: viewModel.trend?.direction == .decreasing ? "arrow.down" : 
                               viewModel.trend?.direction == .increasing ? "arrow.up" : nil
                    )
                    
                    ConditionCard(
                        title: "Wind",
                        value: "\(Int(conditions.windSpeed)) mph",
                        icon: "wind",
                        color: .cyan,
                        trend: nil
                    )
                    
                    ConditionCard(
                        title: "Humidity",
                        value: "\(Int(conditions.humidity))%",
                        icon: "humidity.fill",
                        color: .teal,
                        trend: nil
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            Button {
                showingReportView = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                    Text("Report Jubilee")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Button {
                showingAlertSettings = true
            } label: {
                HStack {
                    Image(systemName: "bell.fill")
                        .font(.title2)
                    Text("Set Alert")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var predictionChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("24-Hour Probability Forecast")
                .font(.headline)
                .padding(.horizontal)
            
            if !viewModel.chartData.isEmpty {
                Chart(viewModel.chartData) { data in
                    LineMark(
                        x: .value("Hour", data.date),
                        y: .value("Probability", data.probability)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Hour", data.date),
                        y: .value("Probability", data.probability)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 200)
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)%")
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
            }
        }
    }
    
    private var recentReportsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent User Reports")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.activeEventCount) active")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            if viewModel.recentEvents.isEmpty {
                EmptyEventCard()
            } else {
                ForEach(viewModel.recentEvents.prefix(5)) { event in
                    UserReportCard(event: event)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ConditionCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String?
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                if let trend = trend {
                    Image(systemName: trend)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct UserReportCard: View {
    let event: JubileeEvent
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.intensity.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(event.intensity.color)
                    
                    Spacer()
                    
                    Text(event.startTime, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Reports: \(event.reportCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if event.verificationStatus == .verified {
                    Label("Verified", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

struct EmptyEventCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "water.waves")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No recent jubilee events")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Be the first to report an event!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Error Loading Data")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: retry) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

struct AlertSettingsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var tempThreshold: Double
    
    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
        self._tempThreshold = State(initialValue: viewModel.alertThreshold)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Alert Threshold")
                            .font(.headline)
                        
                        Text("You'll be notified when jubilee probability exceeds this threshold")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $tempThreshold, in: 40...90, step: 5) {
                            Text("Threshold")
                        }
                        
                        HStack {
                            Text("\(Int(tempThreshold))%")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text(getThresholdDescription(tempThreshold))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Notification Settings")
                }
                
                Section {
                    Toggle("Push Notifications", isOn: .constant(true))
                    Toggle("Email Alerts", isOn: .constant(false))
                    Toggle("SMS Alerts", isOn: .constant(false))
                } header: {
                    Text("Alert Methods")
                } footer: {
                    Text("Configure notification methods in Settings")
                }
            }
            .navigationTitle("Alert Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.setAlertThreshold(tempThreshold)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func getThresholdDescription(_ threshold: Double) -> String {
        switch threshold {
        case 40..<50:
            return "Conservative"
        case 50..<65:
            return "Balanced"
        case 65..<80:
            return "Moderate"
        default:
            return "Aggressive"
        }
    }
}

struct DashboardStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct EventCard: View {
    let event: JubileeEvent
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.intensity.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(event.intensity.color)
                    
                    Spacer()
                    
                    Text(event.startTime, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Reports: \(event.reportCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if event.verificationStatus == .verified {
                    Label("Verified", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    DashboardView()
        .environmentObject(CloudKitService())
        .environmentObject(AuthenticationService(cloudKitService: CloudKitService()))
}