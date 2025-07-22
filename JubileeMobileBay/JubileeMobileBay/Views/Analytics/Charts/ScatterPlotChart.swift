//
//  ScatterPlotChart.swift
//  JubileeMobileBay
//
//  Scatter plot implementation for correlation analysis
//

import SwiftUI
import Charts

struct ScatterPlotChart: View {
    let data: [CorrelationDataPoint]
    let title: String
    let xAxisLabel: String
    let yAxisLabel: String
    let showTrendLine: Bool
    let showCorrelationCoefficient: Bool
    let colorByCategory: Bool
    
    @State private var selectedPoint: CorrelationDataPoint?
    @State private var hoveredCategory: String?
    
    init(
        data: [CorrelationDataPoint],
        title: String,
        xAxisLabel: String,
        yAxisLabel: String,
        showTrendLine: Bool = true,
        showCorrelationCoefficient: Bool = true,
        colorByCategory: Bool = true
    ) {
        self.data = data
        self.title = title
        self.xAxisLabel = xAxisLabel
        self.yAxisLabel = yAxisLabel
        self.showTrendLine = showTrendLine
        self.showCorrelationCoefficient = showCorrelationCoefficient
        self.colorByCategory = colorByCategory
    }
    
    var body: some View {
        ChartContainer {
            VStack(alignment: .leading, spacing: ChartTheme.chartPadding) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(ChartTheme.titleFont)
                        
                        if showCorrelationCoefficient {
                            Text("Correlation: \(correlationCoefficient, specifier: "%.3f")")
                                .font(ChartTheme.labelFont)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    ChartExportButton(
                        chartView: AnyView(chartContent),
                        fileName: "\(title)_\(Date().ISO8601Format())"
                    )
                }
                .padding(.horizontal, ChartTheme.chartPadding)
                .padding(.top, ChartTheme.chartPadding)
                
                // Chart
                chartContent
                    .frame(height: ChartTheme.defaultChartHeight)
                    .padding(ChartTheme.chartPadding)
                
                // Legend
                if colorByCategory {
                    ChartLegend(
                        items: uniqueCategories.enumerated().map { index, category in
                            ChartLegend.LegendItem(
                                color: categoryColor(for: category),
                                label: category,
                                value: "\(dataPointsInCategory(category)) points"
                            )
                        }
                    )
                    .padding(.horizontal, ChartTheme.chartPadding)
                    .padding(.bottom, ChartTheme.chartPadding)
                }
                
                // Selected Point Info
                if let selectedPoint = selectedPoint {
                    selectedPointInfo(for: selectedPoint)
                        .padding(ChartTheme.chartPadding)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                        .padding(.horizontal, ChartTheme.chartPadding)
                        .padding(.bottom, ChartTheme.chartPadding)
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .chartAccessibility(
            label: "\(title) scatter plot",
            value: "Shows correlation between \(xAxisLabel) and \(yAxisLabel)",
            hint: "Explore data points to see correlations"
        )
    }
    
    @ViewBuilder
    private var chartContent: some View {
        if data.isEmpty {
            EmptyChartView(
                message: "No correlation data available",
                systemImage: "chart.dots.scatter"
            )
        } else {
            Chart(data) { point in
                PointMark(
                    x: .value(xAxisLabel, point.xValue),
                    y: .value(yAxisLabel, point.yValue)
                )
                .foregroundStyle(pointColor(for: point))
                .symbolSize(selectedPoint?.id == point.id ? 150 : 100)
                .opacity(hoveredCategory == nil || hoveredCategory == point.category ? 1.0 : 0.3)
                
                if showTrendLine && trendLinePoints.count == 2 {
                    LineMark(
                        x: .value("X", trendLinePoints[0].0),
                        y: .value("Y", trendLinePoints[0].1)
                    )
                    .foregroundStyle(Color.red.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    
                    LineMark(
                        x: .value("X", trendLinePoints[1].0),
                        y: .value("Y", trendLinePoints[1].1)
                    )
                    .foregroundStyle(Color.red.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                        .foregroundStyle(ChartTheme.gridLineColor)
                    AxisValueLabel()
                        .font(ChartTheme.captionFont)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                        .foregroundStyle(ChartTheme.gridLineColor)
                    AxisValueLabel()
                        .font(ChartTheme.captionFont)
                }
            }
            .chartXAxisLabel(position: .bottom, alignment: .center) {
                Text(xAxisLabel)
                    .font(ChartTheme.labelFont)
                    .foregroundColor(.secondary)
            }
            .chartYAxisLabel(position: .leading, alignment: .center) {
                Text(yAxisLabel)
                    .font(ChartTheme.labelFont)
                    .foregroundColor(.secondary)
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                if let point = findNearestPoint(at: location, in: geometry, proxy: chartProxy) {
                                    selectedPoint = point
                                    hoveredCategory = point.category
                                }
                            case .ended:
                                hoveredCategory = nil
                            }
                        }
                }
            }
        }
    }
    
    @ViewBuilder
    private func selectedPointInfo(for point: CorrelationDataPoint) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(categoryColor(for: point.category))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(point.label ?? point.category)
                    .font(ChartTheme.labelFont.weight(.semibold))
                
                HStack(spacing: 12) {
                    Label("\(xAxisLabel): \(point.xValue, specifier: "%.2f")", systemImage: "arrow.right")
                        .font(ChartTheme.captionFont)
                    
                    Label("\(yAxisLabel): \(point.yValue, specifier: "%.2f")", systemImage: "arrow.up")
                        .font(ChartTheme.captionFont)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { selectedPoint = nil }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var uniqueCategories: [String] {
        Array(Set(data.map { $0.category })).sorted()
    }
    
    private func categoryColor(for category: String) -> Color {
        guard colorByCategory else { return ChartTheme.primaryColor }
        let index = uniqueCategories.firstIndex(of: category) ?? 0
        return ChartTheme.chartColors[index % ChartTheme.chartColors.count]
    }
    
    private func pointColor(for point: CorrelationDataPoint) -> Color {
        categoryColor(for: point.category)
    }
    
    private func dataPointsInCategory(_ category: String) -> Int {
        data.filter { $0.category == category }.count
    }
    
    private var correlationCoefficient: Double {
        guard data.count > 1 else { return 0 }
        
        let xValues = data.map { $0.xValue }
        let yValues = data.map { $0.yValue }
        
        let xMean = xValues.reduce(0, +) / Double(xValues.count)
        let yMean = yValues.reduce(0, +) / Double(yValues.count)
        
        let numerator = zip(xValues, yValues).map { ($0 - xMean) * ($1 - yMean) }.reduce(0, +)
        let xDenominator = sqrt(xValues.map { pow($0 - xMean, 2) }.reduce(0, +))
        let yDenominator = sqrt(yValues.map { pow($0 - yMean, 2) }.reduce(0, +))
        
        guard xDenominator != 0 && yDenominator != 0 else { return 0 }
        return numerator / (xDenominator * yDenominator)
    }
    
    private var trendLinePoints: [(Double, Double)] {
        guard data.count > 1 else { return [] }
        
        let xValues = data.map { $0.xValue }
        let yValues = data.map { $0.yValue }
        
        let xMean = xValues.reduce(0, +) / Double(xValues.count)
        let yMean = yValues.reduce(0, +) / Double(yValues.count)
        
        let slope = zip(xValues, yValues).map { ($0 - xMean) * ($1 - yMean) }.reduce(0, +) /
                   xValues.map { pow($0 - xMean, 2) }.reduce(0, +)
        
        let intercept = yMean - slope * xMean
        
        let minX = xValues.min() ?? 0
        let maxX = xValues.max() ?? 0
        
        return [
            (minX, slope * minX + intercept),
            (maxX, slope * maxX + intercept)
        ]
    }
    
    private func findNearestPoint(at location: CGPoint, in geometry: GeometryProxy, proxy: ChartProxy) -> CorrelationDataPoint? {
        // Convert tap location to data values
        guard let xValue = proxy.value(atX: location.x, as: Double.self) else { return nil }
        
        // For scatter plots, we need to estimate Y value differently
        let chartHeight = geometry.size.height
        let yRange = (data.map { $0.yValue }.max() ?? 1) - (data.map { $0.yValue }.min() ?? 0)
        let yValue = yRange * (1 - location.y / chartHeight) + (data.map { $0.yValue }.min() ?? 0)
        
        var nearestPoint: CorrelationDataPoint?
        var minDistance: Double = .infinity
        
        for point in data {
            let distance = sqrt(pow(point.xValue - xValue, 2) + pow(point.yValue - yValue, 2))
            if distance < minDistance {
                minDistance = distance
                nearestPoint = point
            }
        }
        
        // Only return if the point is reasonably close to the tap
        return minDistance < (0.1 * yRange) ? nearestPoint : nil
    }
}

// MARK: - Preview

struct ScatterPlotChart_Previews: PreviewProvider {
    static var previews: some View {
        ScatterPlotChart(
            data: sampleCorrelationData,
            title: "Temperature vs Jubilee Activity",
            xAxisLabel: "Water Temperature (°F)",
            yAxisLabel: "Activity Score"
        )
        .padding()
    }
    
    static var sampleCorrelationData: [CorrelationDataPoint] {
        (0..<50).map { _ in
            let temp = Double.random(in: 65...85)
            let baseActivity = (temp - 65) / 20 * 0.7 + Double.random(in: -0.2...0.2)
            let category = temp < 72 ? "Low" : temp < 78 ? "Medium" : "High"
            
            return CorrelationDataPoint(
                xValue: temp,
                yValue: max(0, min(1, baseActivity)),
                category: category,
                label: String(format: "%.1f°F", temp)
            )
        }
    }
}