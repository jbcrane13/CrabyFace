//
//  AnalyticsDashboardViewModel.swift
//  JubileeMobileBay
//
//  ViewModel for the Analytics Dashboard
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AnalyticsDashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var temperatureData: [DataPoint] = []
    @Published var speciesDistribution: [AggregatedDataPoint] = []
    @Published var correlationData: [CorrelationDataPoint] = []
    @Published var heatMapData: [[HeatMapChart.HeatMapDataPoint]] = []
    
    @Published var averageTemperature: Double = 0.0
    @Published var averageActivityScore: Double = 0.0
    @Published var temperatureTrend: Double = 0.0
    @Published var activityTrend: Double = 0.0
    @Published var peakActivityTime: String = "6-9 AM"
    @Published var topSpecies: String = "Blue Crab"
    
    @Published var lastUpdated = Date()
    @Published var isLoading = false
    @Published var error: Error?
    
    // Filter Options
    @Published var includeNOAAData = true
    @Published var includeUserReports = true
    @Published var includeSensorData = true
    @Published var includeAllLocations = true
    
    // Chart Labels
    let timeLabels = ["12AM", "3AM", "6AM", "9AM", "12PM", "3PM", "6PM", "9PM"]
    let locationLabels = ["Point Clear", "Fairhope", "Daphne", "Spanish Fort", "Mobile"]
    
    // Services
    private let predictionService = PredictionService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Data Loading
    
    func loadData(for timeRange: AnalyticsDashboardView.TimeRange) async {
        isLoading = true
        error = nil
        
        do {
            // In a real app, these would be actual API calls
            async let tempData = loadTemperatureData(for: timeRange)
            async let speciesData = loadSpeciesDistribution(for: timeRange)
            async let correlations = loadCorrelationData(for: timeRange)
            async let heatMap = loadHeatMapData(for: timeRange)
            
            self.temperatureData = try await tempData
            self.speciesDistribution = try await speciesData
            self.correlationData = try await correlations
            self.heatMapData = try await heatMap
            
            calculateStatistics()
            lastUpdated = Date()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func refreshData(for timeRange: AnalyticsDashboardView.TimeRange) async {
        await loadData(for: timeRange)
    }
    
    // MARK: - Data Loading Methods
    
    private func loadTemperatureData(for timeRange: AnalyticsDashboardView.TimeRange) async throws -> [DataPoint] {
        // Simulate API delay
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -timeRange.days, to: endDate)!
        
        var dataPoints: [DataPoint] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let baseTemp = 75.0 + sin(currentDate.timeIntervalSince1970 / 86400) * 10
            let randomVariation = Double.random(in: -3...3)
            let temperature = baseTemp + randomVariation
            
            dataPoints.append(DataPoint(
                date: currentDate,
                value: temperature,
                category: "Temperature",
                label: String(format: "%.1f°F", temperature)
            ))
            
            currentDate = calendar.date(byAdding: .hour, value: 6, to: currentDate)!
        }
        
        return dataPoints
    }
    
    private func loadSpeciesDistribution(for timeRange: AnalyticsDashboardView.TimeRange) async throws -> [AggregatedDataPoint] {
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let species = ["Blue Crab", "Flounder", "Shrimp", "Red Snapper", "Speckled Trout"]
        let total = 150.0
        
        return species.enumerated().map { index, name in
            let baseValue = Double(species.count - index) * 15
            let value = baseValue + Double.random(in: -5...5)
            let percentage = value / total
            
            return AggregatedDataPoint(
                category: name,
                value: value,
                count: Int(value),
                percentage: percentage
            )
        }
    }
    
    private func loadCorrelationData(for timeRange: AnalyticsDashboardView.TimeRange) async throws -> [CorrelationDataPoint] {
        try await Task.sleep(nanoseconds: 100_000_000)
        
        return (0..<50).map { _ in
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
                label: String(format: "%.1f°F, %.2f", temperature, activity)
            )
        }
    }
    
    private func loadHeatMapData(for timeRange: AnalyticsDashboardView.TimeRange) async throws -> [[HeatMapChart.HeatMapDataPoint]] {
        try await Task.sleep(nanoseconds: 100_000_000)
        
        return locationLabels.indices.map { locationIndex in
            timeLabels.indices.map { timeIndex in
                // Simulate activity patterns
                let baseActivity = sin(Double(timeIndex) * .pi / 4) * 0.5 + 0.5
                let locationFactor = Double(locationLabels.count - locationIndex) / Double(locationLabels.count)
                let activity = baseActivity * locationFactor + Double.random(in: -0.1...0.1)
                
                return HeatMapChart.HeatMapDataPoint(
                    value: max(0, min(1, activity)),
                    label: String(format: "%.0f%%", activity * 100)
                )
            }
        }
    }
    
    // MARK: - Statistics
    
    private func calculateStatistics() {
        // Average temperature
        if !temperatureData.isEmpty {
            averageTemperature = temperatureData.reduce(0) { $0 + $1.value } / Double(temperatureData.count)
            
            // Temperature trend (compare last 25% to first 25%)
            let quarter = temperatureData.count / 4
            let firstQuarter = temperatureData.prefix(quarter)
            let lastQuarter = temperatureData.suffix(quarter)
            
            let firstAvg = firstQuarter.reduce(0) { $0 + $1.value } / Double(firstQuarter.count)
            let lastAvg = lastQuarter.reduce(0) { $0 + $1.value } / Double(lastQuarter.count)
            
            temperatureTrend = ((lastAvg - firstAvg) / firstAvg) * 100
        }
        
        // Average activity score
        if !correlationData.isEmpty {
            averageActivityScore = correlationData.reduce(0) { $0 + $1.yValue } / Double(correlationData.count)
            
            // Activity trend
            let quarter = correlationData.count / 4
            let firstQuarter = correlationData.prefix(quarter)
            let lastQuarter = correlationData.suffix(quarter)
            
            let firstAvg = firstQuarter.reduce(0) { $0 + $1.yValue } / Double(firstQuarter.count)
            let lastAvg = lastQuarter.reduce(0) { $0 + $1.yValue } / Double(lastQuarter.count)
            
            activityTrend = ((lastAvg - firstAvg) / firstAvg) * 100
        }
        
        // Peak activity time
        if !heatMapData.isEmpty && !heatMapData[0].isEmpty {
            var maxActivity = 0.0
            var maxTimeIndex = 0
            
            for timeIndex in 0..<heatMapData[0].count {
                let avgActivityAtTime = heatMapData.reduce(0) { sum, row in
                    sum + row[timeIndex].value
                } / Double(heatMapData.count)
                
                if avgActivityAtTime > maxActivity {
                    maxActivity = avgActivityAtTime
                    maxTimeIndex = timeIndex
                }
            }
            
            peakActivityTime = timeLabels[maxTimeIndex]
        }
        
        // Top species
        if let topSpeciesData = speciesDistribution.max(by: { $0.value < $1.value }) {
            topSpecies = topSpeciesData.category
        }
    }
    
    // MARK: - Export Functions
    
    func exportAsPDF() {
        // Implementation for PDF export
        print("Exporting as PDF...")
    }
    
    func exportAsCSV() {
        // Implementation for CSV export
        print("Exporting as CSV...")
    }
    
    func shareReport() {
        // Implementation for sharing
        print("Sharing report...")
    }
    
    // MARK: - Helper Methods
    
    func dateRange(for timeRange: AnalyticsDashboardView.TimeRange) -> ClosedRange<Date> {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -timeRange.days, to: endDate)!
        return startDate...endDate
    }
}