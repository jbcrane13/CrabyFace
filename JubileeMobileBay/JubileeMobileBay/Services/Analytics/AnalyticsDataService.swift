//
//  AnalyticsDataService.swift
//  JubileeMobileBay
//
//  Service for aggregating and processing analytics data
//

import Foundation
import CoreLocation
import Combine

// MARK: - Analytics Metrics

enum AnalyticsMetric: String, CaseIterable {
    case temperature = "temperature"
    case activity = "activity"
    case salinity = "salinity"
    case windSpeed = "wind_speed"
    case barometricPressure = "pressure"
    case dissolvedOxygen = "dissolved_oxygen"
    case tideLevel = "tide_level"
    case speciesCount = "species_count"
    
    var displayName: String {
        switch self {
        case .temperature: return "Temperature"
        case .activity: return "Activity Score"
        case .salinity: return "Salinity"
        case .windSpeed: return "Wind Speed"
        case .barometricPressure: return "Pressure"
        case .dissolvedOxygen: return "Dissolved Oxygen"
        case .tideLevel: return "Tide Level"
        case .speciesCount: return "Species Count"
        }
    }
    
    var unit: String {
        switch self {
        case .temperature: return "°F"
        case .activity: return ""
        case .salinity: return "ppt"
        case .windSpeed: return "mph"
        case .barometricPressure: return "inHg"
        case .dissolvedOxygen: return "mg/L"
        case .tideLevel: return "ft"
        case .speciesCount: return ""
        }
    }
}

// MARK: - Date Range

enum DateRange {
    case hour
    case day
    case week
    case month
    case year
    case custom(from: Date, to: Date)
    
    var interval: DateInterval {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .hour:
            let start = calendar.date(byAdding: .hour, value: -1, to: now)!
            return DateInterval(start: start, end: now)
        case .day:
            let start = calendar.date(byAdding: .day, value: -1, to: now)!
            return DateInterval(start: start, end: now)
        case .week:
            let start = calendar.date(byAdding: .day, value: -7, to: now)!
            return DateInterval(start: start, end: now)
        case .month:
            let start = calendar.date(byAdding: .month, value: -1, to: now)!
            return DateInterval(start: start, end: now)
        case .year:
            let start = calendar.date(byAdding: .year, value: -1, to: now)!
            return DateInterval(start: start, end: now)
        case .custom(let from, let to):
            return DateInterval(start: from, end: to)
        }
    }
}

// MARK: - Grouping Dimension

enum GroupingDimension {
    case hour
    case day
    case week
    case month
    case location
    case species
    case none
}

// MARK: - Analytics Data Models

struct AnalyticsDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let location: CLLocationCoordinate2D
    let metrics: [AnalyticsMetric: Double]
    let metadata: [String: Any]
    
    init(timestamp: Date, location: CLLocationCoordinate2D, metrics: [AnalyticsMetric: Double], metadata: [String: Any] = [:]) {
        self.timestamp = timestamp
        self.location = location
        self.metrics = metrics
        self.metadata = metadata
    }
}

struct AggregatedAnalyticsData {
    let metric: AnalyticsMetric
    let dateRange: DateRange
    let grouping: GroupingDimension
    let dataPoints: [DataPoint]
    let aggregatedPoints: [AggregatedDataPoint]
    let statistics: DataStatistics
}

struct DataStatistics {
    let mean: Double
    let median: Double
    let standardDeviation: Double
    let min: Double
    let max: Double
    let percentiles: [Int: Double] // 25th, 50th, 75th, 90th, 95th
    let trend: Double // Percentage change over period
    let correlations: [AnalyticsMetric: Double]
}

struct CorrelationMatrix {
    let metrics: [AnalyticsMetric]
    let correlations: [[Double]] // Square matrix of correlation coefficients
    
    func correlation(between metric1: AnalyticsMetric, and metric2: AnalyticsMetric) -> Double? {
        guard let index1 = metrics.firstIndex(of: metric1),
              let index2 = metrics.firstIndex(of: metric2),
              index1 < correlations.count,
              index2 < correlations[index1].count else {
            return nil
        }
        return correlations[index1][index2]
    }
}

// MARK: - Analytics Data Service Protocol

protocol AnalyticsDataServiceProtocol {
    func fetchData(for metric: AnalyticsMetric, dateRange: DateRange) async throws -> [AnalyticsDataPoint]
    func aggregateData(points: [AnalyticsDataPoint], metric: AnalyticsMetric, grouping: GroupingDimension) -> AggregatedAnalyticsData
    func calculateCorrelations(between metrics: [AnalyticsMetric], dateRange: DateRange) async throws -> CorrelationMatrix
    func getStatistics(for metric: AnalyticsMetric, dateRange: DateRange) async throws -> DataStatistics
    func exportData(metrics: [AnalyticsMetric], dateRange: DateRange, format: ExportFormat) async throws -> Data
}

enum ExportFormat {
    case csv
    case json
    case pdf
}

// MARK: - Analytics Data Service Implementation

class AnalyticsDataService: AnalyticsDataServiceProtocol {
    private let cache = AnalyticsDataCache()
    private let apiService: WeatherAPIProtocol
    private let cloudKitService: CloudKitServiceProtocol
    private let queue = DispatchQueue(label: "com.jubileemobilebay.analytics", attributes: .concurrent)
    
    init(apiService: WeatherAPIProtocol = NOAAWeatherAPI(), 
         cloudKitService: CloudKitServiceProtocol = CloudKitService()) {
        self.apiService = apiService
        self.cloudKitService = cloudKitService
    }
    
    // MARK: - Fetch Data
    
    func fetchData(for metric: AnalyticsMetric, dateRange: DateRange) async throws -> [AnalyticsDataPoint] {
        // Check cache first
        if let cachedData = await cache.getData(for: metric, dateRange: dateRange) {
            return cachedData
        }
        
        // Fetch from appropriate source
        let dataPoints: [AnalyticsDataPoint]
        
        switch metric {
        case .temperature, .windSpeed, .barometricPressure:
            dataPoints = try await fetchWeatherData(metric: metric, dateRange: dateRange)
        case .activity, .speciesCount:
            dataPoints = try await fetchCloudKitData(metric: metric, dateRange: dateRange)
        default:
            dataPoints = generateMockData(for: metric, dateRange: dateRange)
        }
        
        // Cache the results
        await cache.setData(dataPoints, for: metric, dateRange: dateRange)
        
        return dataPoints
    }
    
    private func fetchWeatherData(metric: AnalyticsMetric, dateRange: DateRange) async throws -> [AnalyticsDataPoint] {
        // In a real implementation, this would call the weather API
        return generateMockData(for: metric, dateRange: dateRange)
    }
    
    private func fetchCloudKitData(metric: AnalyticsMetric, dateRange: DateRange) async throws -> [AnalyticsDataPoint] {
        // In a real implementation, this would query CloudKit
        return generateMockData(for: metric, dateRange: dateRange)
    }
    
    // MARK: - Aggregate Data
    
    func aggregateData(points: [AnalyticsDataPoint], metric: AnalyticsMetric, grouping: GroupingDimension) -> AggregatedAnalyticsData {
        let calendar = Calendar.current
        var grouped: [String: [Double]] = [:]
        
        // Group data points
        for point in points {
            guard let value = point.metrics[metric] else { continue }
            
            let key: String
            switch grouping {
            case .hour:
                let hour = calendar.component(.hour, from: point.timestamp)
                key = "\(hour):00"
            case .day:
                key = DateFormatter.dayFormatter.string(from: point.timestamp)
            case .week:
                let week = calendar.component(.weekOfYear, from: point.timestamp)
                key = "Week \(week)"
            case .month:
                key = DateFormatter.monthFormatter.string(from: point.timestamp)
            case .location:
                key = "\(point.location.latitude),\(point.location.longitude)"
            case .species:
                key = point.metadata["species"] as? String ?? "Unknown"
            case .none:
                key = "All"
            }
            
            grouped[key, default: []].append(value)
        }
        
        // Create aggregated points
        let aggregatedPoints = grouped.map { key, values in
            let average = values.reduce(0, +) / Double(values.count)
            return AggregatedDataPoint(
                category: key,
                value: average,
                count: values.count,
                percentage: nil
            )
        }.sorted { $0.category < $1.category }
        
        // Create time series data points
        let dataPoints = points.compactMap { point -> DataPoint? in
            guard let value = point.metrics[metric] else { return nil }
            return DataPoint(date: point.timestamp, value: value)
        }.sorted { $0.date < $1.date }
        
        // Calculate statistics
        let statistics = calculateStatistics(for: points.compactMap { $0.metrics[metric] })
        
        return AggregatedAnalyticsData(
            metric: metric,
            dateRange: .custom(from: points.first?.timestamp ?? Date(),
                              to: points.last?.timestamp ?? Date()),
            grouping: grouping,
            dataPoints: dataPoints,
            aggregatedPoints: aggregatedPoints,
            statistics: statistics
        )
    }
    
    // MARK: - Calculate Correlations
    
    func calculateCorrelations(between metrics: [AnalyticsMetric], dateRange: DateRange) async throws -> CorrelationMatrix {
        // Fetch data for all metrics
        var metricData: [AnalyticsMetric: [Double]] = [:]
        
        for metric in metrics {
            let dataPoints = try await fetchData(for: metric, dateRange: dateRange)
            metricData[metric] = dataPoints.compactMap { $0.metrics[metric] }
        }
        
        // Calculate correlation matrix
        var correlations: [[Double]] = Array(repeating: Array(repeating: 0.0, count: metrics.count), count: metrics.count)
        
        for (i, metric1) in metrics.enumerated() {
            for (j, metric2) in metrics.enumerated() {
                if i == j {
                    correlations[i][j] = 1.0
                } else if let values1 = metricData[metric1], let values2 = metricData[metric2] {
                    correlations[i][j] = pearsonCorrelation(values1, values2)
                }
            }
        }
        
        return CorrelationMatrix(metrics: metrics, correlations: correlations)
    }
    
    // MARK: - Get Statistics
    
    func getStatistics(for metric: AnalyticsMetric, dateRange: DateRange) async throws -> DataStatistics {
        let dataPoints = try await fetchData(for: metric, dateRange: dateRange)
        let values = dataPoints.compactMap { $0.metrics[metric] }
        
        return calculateStatistics(for: values)
    }
    
    // MARK: - Export Data
    
    func exportData(metrics: [AnalyticsMetric], dateRange: DateRange, format: ExportFormat) async throws -> Data {
        var allData: [AnalyticsDataPoint] = []
        
        // Fetch data for all metrics
        for metric in metrics {
            let dataPoints = try await fetchData(for: metric, dateRange: dateRange)
            allData.append(contentsOf: dataPoints)
        }
        
        switch format {
        case .csv:
            return try exportAsCSV(dataPoints: allData, metrics: metrics)
        case .json:
            return try exportAsJSON(dataPoints: allData, metrics: metrics)
        case .pdf:
            return try exportAsPDF(dataPoints: allData, metrics: metrics)
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateStatistics(for values: [Double]) -> DataStatistics {
        guard !values.isEmpty else {
            return DataStatistics(
                mean: 0, median: 0, standardDeviation: 0,
                min: 0, max: 0, percentiles: [:], trend: 0, correlations: [:]
            )
        }
        
        let sorted = values.sorted()
        let count = Double(values.count)
        
        // Mean
        let mean = values.reduce(0, +) / count
        
        // Median
        let median: Double
        if values.count % 2 == 0 {
            median = (sorted[values.count / 2 - 1] + sorted[values.count / 2]) / 2
        } else {
            median = sorted[values.count / 2]
        }
        
        // Standard deviation
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        let variance = squaredDifferences.reduce(0, +) / count
        let standardDeviation = sqrt(variance)
        
        // Min/Max
        let min = sorted.first!
        let max = sorted.last!
        
        // Percentiles
        let percentiles = [
            25: percentile(sorted, 0.25),
            50: median,
            75: percentile(sorted, 0.75),
            90: percentile(sorted, 0.90),
            95: percentile(sorted, 0.95)
        ]
        
        // Trend (compare first 25% to last 25%)
        let quarter = values.count / 4
        let firstQuarter = Array(values.prefix(quarter))
        let lastQuarter = Array(values.suffix(quarter))
        let firstAvg = firstQuarter.reduce(0, +) / Double(firstQuarter.count)
        let lastAvg = lastQuarter.reduce(0, +) / Double(lastQuarter.count)
        let trend = firstAvg != 0 ? ((lastAvg - firstAvg) / firstAvg) * 100 : 0
        
        return DataStatistics(
            mean: mean,
            median: median,
            standardDeviation: standardDeviation,
            min: min,
            max: max,
            percentiles: percentiles,
            trend: trend,
            correlations: [:]
        )
    }
    
    private func percentile(_ sorted: [Double], _ p: Double) -> Double {
        let index = p * Double(sorted.count - 1)
        let lower = Int(index)
        let upper = lower + 1
        let weight = index - Double(lower)
        
        if upper >= sorted.count {
            return sorted[lower]
        }
        
        return sorted[lower] * (1 - weight) + sorted[upper] * weight
    }
    
    private func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count && x.count > 1 else { return 0 }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        
        return denominator != 0 ? numerator / denominator : 0
    }
    
    private func generateMockData(for metric: AnalyticsMetric, dateRange: DateRange) -> [AnalyticsDataPoint] {
        let interval = dateRange.interval
        let calendar = Calendar.current
        var dataPoints: [AnalyticsDataPoint] = []
        
        var currentDate = interval.start
        while currentDate <= interval.end {
            let baseValue: Double
            let variation: Double
            
            switch metric {
            case .temperature:
                baseValue = 75.0 + sin(currentDate.timeIntervalSince1970 / 86400) * 10
                variation = Double.random(in: -3...3)
            case .activity:
                baseValue = 0.5 + sin(currentDate.timeIntervalSince1970 / 86400) * 0.3
                variation = Double.random(in: -0.1...0.1)
            case .salinity:
                baseValue = 15.0
                variation = Double.random(in: -2...2)
            case .windSpeed:
                baseValue = 10.0
                variation = Double.random(in: -5...5)
            case .barometricPressure:
                baseValue = 30.0
                variation = Double.random(in: -0.5...0.5)
            case .dissolvedOxygen:
                baseValue = 5.0
                variation = Double.random(in: -1...1)
            case .tideLevel:
                baseValue = 2.0 + sin(currentDate.timeIntervalSince1970 / 44712) * 2
                variation = Double.random(in: -0.2...0.2)
            case .speciesCount:
                baseValue = 10.0
                variation = Double.random(in: -5...5)
            }
            
            let value = max(0, baseValue + variation)
            
            let location = CLLocationCoordinate2D(
                latitude: 30.6954 + Double.random(in: -0.1...0.1),
                longitude: -88.0399 + Double.random(in: -0.1...0.1)
            )
            
            let dataPoint = AnalyticsDataPoint(
                timestamp: currentDate,
                location: location,
                metrics: [metric: value]
            )
            
            dataPoints.append(dataPoint)
            currentDate = calendar.date(byAdding: .hour, value: 1, to: currentDate)!
        }
        
        return dataPoints
    }
    
    // MARK: - Export Helpers
    
    private func exportAsCSV(dataPoints: [AnalyticsDataPoint], metrics: [AnalyticsMetric]) throws -> Data {
        var csv = "Timestamp,Latitude,Longitude"
        for metric in metrics {
            csv += ",\(metric.displayName)"
        }
        csv += "\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for point in dataPoints {
            csv += "\(dateFormatter.string(from: point.timestamp))"
            csv += ",\(point.location.latitude)"
            csv += ",\(point.location.longitude)"
            
            for metric in metrics {
                let value = point.metrics[metric] ?? 0
                csv += ",\(value)"
            }
            csv += "\n"
        }
        
        guard let data = csv.data(using: .utf8) else {
            throw AnalyticsError.exportFailed
        }
        
        return data
    }
    
    private func exportAsJSON(dataPoints: [AnalyticsDataPoint], metrics: [AnalyticsMetric]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let exportData = dataPoints.map { point in
            [
                "timestamp": point.timestamp,
                "location": [
                    "latitude": point.location.latitude,
                    "longitude": point.location.longitude
                ],
                "metrics": point.metrics.mapKeys { $0.rawValue }
            ] as [String: Any]
        }
        
        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    private func exportAsPDF(dataPoints: [AnalyticsDataPoint], metrics: [AnalyticsMetric]) throws -> Data {
        // This would generate a PDF report
        // For now, return empty data
        return Data()
    }
}

// MARK: - Analytics Cache

actor AnalyticsDataCache {
    private var cache: [String: (data: [AnalyticsDataPoint], timestamp: Date)] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 minutes
    
    func getData(for metric: AnalyticsMetric, dateRange: DateRange) -> [AnalyticsDataPoint]? {
        let key = cacheKey(for: metric, dateRange: dateRange)
        
        guard let cached = cache[key] else { return nil }
        
        // Check if cache is expired
        if Date().timeIntervalSince(cached.timestamp) > cacheExpiration {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return cached.data
    }
    
    func setData(_ data: [AnalyticsDataPoint], for metric: AnalyticsMetric, dateRange: DateRange) {
        let key = cacheKey(for: metric, dateRange: dateRange)
        cache[key] = (data, Date())
    }
    
    private func cacheKey(for metric: AnalyticsMetric, dateRange: DateRange) -> String {
        "\(metric.rawValue)_\(dateRange.interval.start.timeIntervalSince1970)_\(dateRange.interval.end.timeIntervalSince1970)"
    }
}

// MARK: - Date Formatters

extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()
}

// MARK: - Dictionary Extension

extension Dictionary {
    func mapKeys<T>(_ transform: (Key) -> T) -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            result[transform(key)] = value
        }
        return result
    }
}

// MARK: - Analytics Error

enum AnalyticsError: LocalizedError {
    case exportFailed
    case dataNotAvailable
    case invalidDateRange
    
    var errorDescription: String? {
        switch self {
        case .exportFailed:
            return "Failed to export analytics data"
        case .dataNotAvailable:
            return "Analytics data is not available"
        case .invalidDateRange:
            return "Invalid date range specified"
        }
    }
}