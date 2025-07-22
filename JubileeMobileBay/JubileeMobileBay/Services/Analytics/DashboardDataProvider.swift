//
//  DashboardDataProvider.swift
//  JubileeMobileBay
//
//  Provides data integration between AnalyticsDataService and Dashboard sections
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

// MARK: - Dashboard Data Provider

@MainActor
public class DashboardDataProvider: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    
    private let analyticsService: AnalyticsDataServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(analyticsService: AnalyticsDataServiceProtocol? = nil) {
        self.analyticsService = analyticsService ?? AnalyticsDataService(cloudKitService: CloudKitService())
    }
    
    // MARK: - Time Series Data
    
    func fetchTimeSeriesData(
        for metric: AnalyticsMetric,
        dateRange: DateRange,
        interval: TimeInterval = 3600 // 1 hour default
    ) async throws -> [DataPoint] {
        let analyticsData = try await analyticsService.fetchData(for: metric, dateRange: dateRange)
        
        return analyticsData.compactMap { dataPoint in
            guard let value = dataPoint.metrics[metric] else { return nil }
            return DataPoint(
                date: dataPoint.timestamp,
                value: value,
                category: metric.displayName,
                label: "\(value.formatted(.number.precision(.fractionLength(1)))) \(metric.unit)"
            )
        }.sorted { $0.date < $1.date }
    }
    
    // MARK: - Aggregated Bar Chart Data
    
    func fetchAggregatedData(
        for metric: AnalyticsMetric,
        dateRange: DateRange,
        grouping: GroupingDimension
    ) async throws -> [AggregatedDataPoint] {
        let analyticsData = try await analyticsService.fetchData(for: metric, dateRange: dateRange)
        let aggregated = analyticsService.aggregateData(
            points: analyticsData,
            metric: metric,
            grouping: grouping
        )
        
        return aggregated.aggregatedPoints
    }
    
    // MARK: - Correlation Data
    
    func fetchCorrelationData(
        metric1: AnalyticsMetric,
        metric2: AnalyticsMetric,
        dateRange: DateRange
    ) async throws -> [CorrelationDataPoint] {
        let data1 = try await analyticsService.fetchData(for: metric1, dateRange: dateRange)
        let data2 = try await analyticsService.fetchData(for: metric2, dateRange: dateRange)
        
        // Match data points by timestamp
        var correlationPoints: [CorrelationDataPoint] = []
        
        for point1 in data1 {
            if let point2 = data2.first(where: { abs($0.timestamp.timeIntervalSince(point1.timestamp)) < 60 }),
               let value1 = point1.metrics[metric1],
               let value2 = point2.metrics[metric2] {
                
                let category = categorizeCorrelation(value1: value1, metric1: metric1)
                
                correlationPoints.append(CorrelationDataPoint(
                    xValue: value1,
                    yValue: value2,
                    category: category,
                    label: "\(metric1.displayName): \(value1.formatted(.number.precision(.fractionLength(1))))"
                ))
            }
        }
        
        return correlationPoints
    }
    
    // MARK: - Heat Map Data
    
    func fetchHeatMapData(
        metric: AnalyticsMetric,
        dateRange: DateRange,
        locationGrid: [(name: String, coordinate: CLLocationCoordinate2D)],
        timeSlots: [String]
    ) async throws -> [[HeatMapChart.HeatMapDataPoint]] {
        let analyticsData = try await analyticsService.fetchData(for: metric, dateRange: dateRange)
        
        // Create a grid of heat map data
        var heatMapGrid: [[HeatMapChart.HeatMapDataPoint]] = []
        
        for location in locationGrid {
            var row: [HeatMapChart.HeatMapDataPoint] = []
            
            for (index, _) in timeSlots.enumerated() {
                // Find data points near this location and time
                let relevantPoints = analyticsData.filter { point in
                    let distance = calculateDistance(from: point.location, to: location.coordinate)
                    let hour = Calendar.current.component(.hour, from: point.timestamp)
                    let timeSlotHour = index * 3 // 3-hour intervals
                    
                    return distance < 10 && abs(hour - timeSlotHour) < 2
                }
                
                let averageValue: Double
                if relevantPoints.isEmpty {
                    averageValue = Double.random(in: 0.2...0.8) // Mock data
                } else {
                    let values = relevantPoints.compactMap { $0.metrics[metric] }
                    averageValue = values.reduce(0, +) / Double(values.count)
                }
                
                let normalizedValue = normalizeValue(averageValue, for: metric)
                
                row.append(HeatMapChart.HeatMapDataPoint(
                    value: normalizedValue,
                    label: "\(Int(normalizedValue * 100))%"
                ))
            }
            
            heatMapGrid.append(row)
        }
        
        return heatMapGrid
    }
    
    // MARK: - Statistics
    
    func fetchStatistics(for metrics: [AnalyticsMetric], dateRange: DateRange) async throws -> DashboardStatistics {
        var stats: [AnalyticsMetric: DataStatistics] = [:]
        
        for metric in metrics {
            stats[metric] = try await analyticsService.getStatistics(for: metric, dateRange: dateRange)
        }
        
        // Extract specific statistics for dashboard
        let tempStats = stats[.temperature]
        let activityStats = stats[.activity]
        
        return DashboardStatistics(
            averageTemperature: tempStats?.mean ?? 0,
            temperatureTrend: tempStats?.trend ?? 0,
            averageActivityScore: activityStats?.mean ?? 0,
            activityTrend: activityStats?.trend ?? 0,
            peakActivityTime: determinePeakActivityTime(from: try await analyticsService.fetchData(for: .activity, dateRange: dateRange)),
            topSpecies: await determineTopSpecies(dateRange: dateRange),
            totalObservations: await countObservations(dateRange: dateRange),
            activeUsers: await countActiveUsers(dateRange: dateRange)
        )
    }
    
    // MARK: - Helper Methods
    
    private func categorizeCorrelation(value1: Double, metric1: AnalyticsMetric) -> String {
        switch metric1 {
        case .temperature:
            if value1 < 70 { return "Low" }
            else if value1 < 80 { return "Moderate" }
            else { return "High" }
        case .activity:
            if value1 < 0.3 { return "Low" }
            else if value1 < 0.7 { return "Moderate" }
            else { return "High" }
        default:
            return "Normal"
        }
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let deltaLat = (to.latitude - from.latitude) * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180
        
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1) * cos(lat2) *
                sin(deltaLon / 2) * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return 6371 * c // Earth's radius in kilometers
    }
    
    private func normalizeValue(_ value: Double, for metric: AnalyticsMetric) -> Double {
        switch metric {
        case .temperature:
            return (value - 60) / 30 // Normalize 60-90°F to 0-1
        case .activity:
            return value // Already 0-1
        case .salinity:
            return value / 35 // Normalize 0-35 ppt to 0-1
        case .windSpeed:
            return min(value / 30, 1) // Normalize 0-30 mph to 0-1
        case .barometricPressure:
            return (value - 29) / 2 // Normalize 29-31 inHg to 0-1
        case .dissolvedOxygen:
            return value / 10 // Normalize 0-10 mg/L to 0-1
        case .tideLevel:
            return (value + 2) / 8 // Normalize -2 to 6 ft to 0-1
        case .speciesCount:
            return min(value / 20, 1) // Normalize 0-20 to 0-1
        }
    }
    
    private func determinePeakActivityTime(from dataPoints: [AnalyticsDataPoint]) -> String {
        var hourlyActivity: [Int: [Double]] = [:]
        
        for point in dataPoints {
            if let activity = point.metrics[.activity] {
                let hour = Calendar.current.component(.hour, from: point.timestamp)
                hourlyActivity[hour, default: []].append(activity)
            }
        }
        
        let averageByHour = hourlyActivity.mapValues { values in
            values.reduce(0, +) / Double(values.count)
        }
        
        if let peakHour = averageByHour.max(by: { $0.value < $1.value })?.key {
            return "\(peakHour):00-\(peakHour + 3):00"
        }
        
        return "6:00-9:00"
    }
    
    private func determineTopSpecies(dateRange: DateRange) async -> String {
        // In a real app, this would query species observations
        let species = ["Blue Crab", "Flounder", "Shrimp", "Red Snapper"]
        return species.randomElement() ?? "Blue Crab"
    }
    
    private func countObservations(dateRange: DateRange) async -> Int {
        // In a real app, this would count actual observations
        return Int.random(in: 200...500)
    }
    
    private func countActiveUsers(dateRange: DateRange) async -> Int {
        // In a real app, this would count unique users
        return Int.random(in: 50...150)
    }
}

// MARK: - Dashboard Data Refresh Coordinator

class DashboardDataRefreshCoordinator {
    private let dataProvider: DashboardDataProvider
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval
    
    init(dataProvider: DashboardDataProvider, refreshInterval: TimeInterval = 300) {
        self.dataProvider = dataProvider
        self.refreshInterval = refreshInterval
    }
    
    func startAutoRefresh() {
        stopAutoRefresh()
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
            Task { @MainActor in
                // Trigger refresh for all active sections
                NotificationCenter.default.post(name: .dashboardDataRefresh, object: nil)
            }
        }
    }
    
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let dashboardDataRefresh = Notification.Name("dashboardDataRefresh")
}

// MARK: - CLLocationCoordinate2D Extension

extension CLLocationCoordinate2D {
    static let mobileBayLocations = [
        (name: "Point Clear", coordinate: CLLocationCoordinate2D(latitude: 30.4944, longitude: -87.9289)),
        (name: "Fairhope", coordinate: CLLocationCoordinate2D(latitude: 30.5229, longitude: -87.9033)),
        (name: "Daphne", coordinate: CLLocationCoordinate2D(latitude: 30.6035, longitude: -87.9036)),
        (name: "Spanish Fort", coordinate: CLLocationCoordinate2D(latitude: 30.6749, longitude: -87.9153)),
        (name: "Mobile", coordinate: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399))
    ]
}