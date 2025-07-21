//
//  AnalyticsDashboardView.swift
//  JubileeMobileBay
//
//  Main analytics dashboard view showcasing all chart types
//

import SwiftUI
import Charts

struct AnalyticsDashboardView: View {
    @StateObject private var viewModel = AnalyticsDashboardViewModel()
    @State private var selectedTimeRange = TimeRange.week
    @State private var showingFilterOptions = false
    
    enum TimeRange: String, CaseIterable {
        case day = "24 Hours"
        case week = "7 Days"
        case month = "30 Days"
        case year = "1 Year"
        
        var days: Int {
            switch self {
            case .day: return 1
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: ChartTheme.sectionSpacing) {
                // Header
                dashboardHeader
                
                // Quick Stats
                quickStatsSection
                
                // Time Series Chart
                if !viewModel.temperatureData.isEmpty {
                    TimeSeriesChart(
                        dataPoints: viewModel.temperatureData,
                        title: "Water Temperature Trends",
                        yAxisLabel: "Temperature (°F)",
                        dateRange: viewModel.dateRange(for: selectedTimeRange)
                    )
                }
                
                // Bar Chart
                if !viewModel.speciesDistribution.isEmpty {
                    BarChart(
                        data: viewModel.speciesDistribution,
                        title: "Species Distribution",
                        yAxisLabel: "Observations",
                        colorScheme: .categorical
                    )
                }
                
                // Scatter Plot
                if !viewModel.correlationData.isEmpty {
                    ScatterPlotChart(
                        data: viewModel.correlationData,
                        title: "Temperature vs Activity Correlation",
                        xAxisLabel: "Water Temperature (°F)",
                        yAxisLabel: "Jubilee Activity Score"
                    )
                }
                
                // Heat Map
                if !viewModel.heatMapData.isEmpty {
                    HeatMapChart(
                        data: viewModel.heatMapData,
                        title: "Activity Patterns by Location & Time",
                        xLabels: viewModel.timeLabels,
                        yLabels: viewModel.locationLabels,
                        colorScheme: .activity
                    )
                }
                
                // Export Options
                exportSection
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Analytics Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingFilterOptions.toggle() }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingFilterOptions) {
            FilterOptionsView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadData(for: selectedTimeRange)
        }
        .refreshable {
            await viewModel.refreshData(for: selectedTimeRange)
        }
    }
    
    // MARK: - Components
    
    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Jubilee Analytics")
                .font(.largeTitle.weight(.bold))
            
            Text("Last updated: \(viewModel.lastUpdated, formatter: dateFormatter)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Time Range Selector
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedTimeRange) { newRange in
                Task {
                    await viewModel.loadData(for: newRange)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var quickStatsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                StatCard(
                    title: "Avg Temperature",
                    value: String(format: "%.1f°F", viewModel.averageTemperature),
                    trend: viewModel.temperatureTrend,
                    icon: "thermometer.medium"
                )
                
                StatCard(
                    title: "Activity Score",
                    value: String(format: "%.2f", viewModel.averageActivityScore),
                    trend: viewModel.activityTrend,
                    icon: "waveform.path.ecg"
                )
                
                StatCard(
                    title: "Peak Hours",
                    value: viewModel.peakActivityTime,
                    trend: nil,
                    icon: "clock.fill"
                )
                
                StatCard(
                    title: "Top Species",
                    value: viewModel.topSpecies,
                    trend: nil,
                    icon: "fish.fill"
                )
            }
            .padding(.horizontal)
        }
    }
    
    private var exportSection: some View {
        VStack(spacing: 16) {
            Text("Export Options")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                Button(action: viewModel.exportAsPDF) {
                    Label("Export PDF", systemImage: "doc.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: viewModel.exportAsCSV) {
                    Label("Export CSV", systemImage: "tablecells")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: viewModel.shareReport) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let trend: Double?
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                if let trend = trend {
                    TrendIndicator(value: trend)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2.weight(.semibold))
        }
        .padding()
        .frame(width: 150, height: 100)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TrendIndicator: View {
    let value: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: value >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.caption.weight(.semibold))
            
            Text(String(format: "%.1f%%", abs(value)))
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(value >= 0 ? .green : .red)
    }
}

// MARK: - Filter Options View

struct FilterOptionsView: View {
    @ObservedObject var viewModel: AnalyticsDashboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Data Sources") {
                    Toggle("NOAA Data", isOn: $viewModel.includeNOAAData)
                    Toggle("User Reports", isOn: $viewModel.includeUserReports)
                    Toggle("Sensor Data", isOn: $viewModel.includeSensorData)
                }
                
                Section("Species Filter") {
                    ForEach(MarineSpecies.commonSpecies, id: \.id) { species in
                        Toggle(species.name, isOn: .constant(true))
                    }
                }
                
                Section("Location Filter") {
                    Toggle("All Locations", isOn: $viewModel.includeAllLocations)
                    if !viewModel.includeAllLocations {
                        // Location picker would go here
                    }
                }
            }
            .navigationTitle("Filter Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct AnalyticsDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AnalyticsDashboardView()
        }
    }
}