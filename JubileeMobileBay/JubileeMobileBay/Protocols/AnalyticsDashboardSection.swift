//
//  AnalyticsDashboardSection.swift
//  JubileeMobileBay
//
//  Protocol for modular dashboard sections
//

import SwiftUI

// MARK: - Dashboard Section Protocol

protocol AnalyticsDashboardSection {
    var id: String { get }
    var title: String { get }
    var priority: Int { get }
    var isEnabled: Bool { get set }
    var viewType: DashboardViewType { get }
    var requiredDataSources: Set<DataSource> { get }
    
    func createView() -> AnyView
    func hasData() -> Bool
    func refreshData() async throws
}

// MARK: - Dashboard View Types

enum DashboardViewType: String, CaseIterable {
    case timeSeries = "Time Series"
    case barChart = "Bar Chart"
    case scatterPlot = "Scatter Plot"
    case heatMap = "Heat Map"
    case statCards = "Statistics Cards"
    case predictions = "Predictions"
    case alerts = "Alerts"
    case summary = "Summary"
    
    var icon: String {
        switch self {
        case .timeSeries: return "chart.line.uptrend.xyaxis"
        case .barChart: return "chart.bar"
        case .scatterPlot: return "chart.dots.scatter"
        case .heatMap: return "square.grid.3x3"
        case .statCards: return "square.grid.2x2"
        case .predictions: return "brain"
        case .alerts: return "exclamationmark.triangle"
        case .summary: return "doc.text"
        }
    }
}

// MARK: - Dashboard Configuration

struct DashboardConfiguration: Codable {
    var enabledSections: Set<String>
    var sectionOrder: [String]
    var refreshInterval: TimeInterval
    var dataRetentionDays: Int
    var theme: DashboardTheme
    
    enum DashboardTheme: String, CaseIterable, Codable {
        case automatic = "Automatic"
        case light = "Light"
        case dark = "Dark"
        case ocean = "Ocean"
        
        var colorScheme: ColorScheme? {
            switch self {
            case .automatic: return nil
            case .light: return .light
            case .dark: return .dark
            case .ocean: return .dark
            }
        }
    }
    
    static let `default` = DashboardConfiguration(
        enabledSections: Set(["temperature", "species", "correlation", "activity", "stats"]),
        sectionOrder: ["stats", "temperature", "species", "correlation", "activity"],
        refreshInterval: 300, // 5 minutes
        dataRetentionDays: 30,
        theme: .automatic
    )
}

// MARK: - Section Base Implementation

class BaseDashboardSection: AnalyticsDashboardSection {
    let id: String
    let title: String
    let priority: Int
    var isEnabled: Bool
    let viewType: DashboardViewType
    let requiredDataSources: Set<DataSource>
    
    init(
        id: String,
        title: String,
        priority: Int,
        isEnabled: Bool = true,
        viewType: DashboardViewType,
        requiredDataSources: Set<DataSource>
    ) {
        self.id = id
        self.title = title
        self.priority = priority
        self.isEnabled = isEnabled
        self.viewType = viewType
        self.requiredDataSources = requiredDataSources
    }
    
    func createView() -> AnyView {
        fatalError("Subclasses must implement createView()")
    }
    
    func hasData() -> Bool {
        return true // Default implementation
    }
    
    func refreshData() async throws {
        // Default implementation - subclasses can override
    }
}

// MARK: - Dashboard Section Factory

struct DashboardSectionFactory {
    static func createDefaultSections() -> [AnalyticsDashboardSection] {
        [
            StatisticsSummarySection(),
            TemperatureTrendsSection(),
            SpeciesDistributionSection(),
            CorrelationAnalysisSection(),
            ActivityPatternsSection(),
            PredictionsSection(),
            AlertsSection()
        ]
    }
    
    static func createSection(for type: DashboardViewType) -> AnalyticsDashboardSection? {
        switch type {
        case .statCards:
            return StatisticsSummarySection()
        case .timeSeries:
            return TemperatureTrendsSection()
        case .barChart:
            return SpeciesDistributionSection()
        case .scatterPlot:
            return CorrelationAnalysisSection()
        case .heatMap:
            return ActivityPatternsSection()
        case .predictions:
            return PredictionsSection()
        case .alerts:
            return AlertsSection()
        case .summary:
            return nil // Not implemented yet
        }
    }
}