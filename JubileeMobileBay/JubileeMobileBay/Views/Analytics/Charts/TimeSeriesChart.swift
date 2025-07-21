//
//  TimeSeriesChart.swift
//  JubileeMobileBay
//
//  Time series chart implementation with interactive features
//

import SwiftUI
import Charts

struct TimeSeriesChart: View {
    let dataPoints: [DataPoint]
    let title: String
    let yAxisLabel: String
    let dateRange: ClosedRange<Date>?
    let showTrendLine: Bool
    let showDataPoints: Bool
    
    @State private var selectedDate: Date?
    @State private var selectedValue: Double?
    @State private var isExpanded = false
    
    init(
        dataPoints: [DataPoint],
        title: String,
        yAxisLabel: String = "Value",
        dateRange: ClosedRange<Date>? = nil,
        showTrendLine: Bool = true,
        showDataPoints: Bool = true
    ) {
        self.dataPoints = dataPoints
        self.title = title
        self.yAxisLabel = yAxisLabel
        self.dateRange = dateRange
        self.showTrendLine = showTrendLine
        self.showDataPoints = showDataPoints
    }
    
    var body: some View {
        ChartContainer {
            VStack(alignment: .leading, spacing: 0) {
                // Chart Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(ChartTheme.titleFont)
                        
                        if let selectedDate = selectedDate,
                           let point = nearestDataPoint(to: selectedDate) {
                            Text(formatSelectedInfo(point))
                                .font(ChartTheme.labelFont)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { withAnimation { isExpanded.toggle() } }) {
                        Image(systemName: isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 16))
                            .foregroundColor(ChartTheme.primaryColor)
                    }
                    
                    ChartExportButton(
                        chartView: AnyView(chartContent),
                        fileName: "\(title)_\(Date().ISO8601Format())"
                    )
                }
                .padding(.horizontal, ChartTheme.chartPadding)
                .padding(.top, ChartTheme.chartPadding)
                
                // Main Chart
                chartContent
                    .frame(height: isExpanded ? ChartTheme.expandedChartHeight : ChartTheme.defaultChartHeight)
                    .padding(ChartTheme.chartPadding)
                    .animation(ChartTheme.springAnimation, value: isExpanded)
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .chartAccessibility(
            label: "\(title) time series chart",
            value: "Shows \(dataPoints.count) data points",
            hint: "Swipe to explore data points"
        )
    }
    
    @ViewBuilder
    private var chartContent: some View {
        if dataPoints.isEmpty {
            EmptyChartView(
                message: "No data available for the selected time period",
                systemImage: "chart.line.uptrend.xyaxis"
            )
        } else {
            Chart(dataPoints) { point in
                // Main line
                LineMark(
                    x: .value("Date", point.date),
                    y: .value(yAxisLabel, point.value)
                )
                .foregroundStyle(ChartTheme.primaryColor)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                // Area under curve
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value(yAxisLabel, point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            ChartTheme.primaryColor.opacity(0.3),
                            ChartTheme.primaryColor.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Data points
                if showDataPoints {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value(yAxisLabel, point.value)
                    )
                    .foregroundStyle(ChartTheme.primaryColor)
                    .symbolSize(30)
                }
                
                // Trend line
                if showTrendLine {
                    RuleMark(y: .value("Average", averageValue))
                        .foregroundStyle(ChartTheme.secondaryColor.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                        .annotation(position: .trailing, alignment: .trailing) {
                            Text("Avg: \(averageValue, specifier: "%.1f")")
                                .font(ChartTheme.captionFont)
                                .foregroundColor(ChartTheme.secondaryColor)
                                .padding(.horizontal, 4)
                                .background(Color(UIColor.systemBackground))
                        }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                        .foregroundStyle(ChartTheme.gridLineColor)
                    AxisValueLabel()
                        .font(ChartTheme.captionFont)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                        .foregroundStyle(ChartTheme.gridLineColor)
                    AxisValueLabel()
                        .font(ChartTheme.captionFont)
                }
            }
            .if(dateRange != nil) { view in
                view.chartXScale(domain: dateRange!)
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(ChartGridBackground().opacity(0.5))
                    .overlay(alignment: .topLeading) {
                        chartOverlay(plotArea: plotArea)
                    }
            }
        }
    }
    
    @ViewBuilder
    private func chartOverlay(plotArea: ChartProxy) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        if let date = plotArea.value(atX: location.x, as: Date.self) {
                            selectedDate = date
                            selectedValue = nearestDataPoint(to: date)?.value
                        }
                    case .ended:
                        selectedDate = nil
                        selectedValue = nil
                    }
                }
        }
        
        // Selection indicator
        if let selectedDate = selectedDate,
           let selectedValue = selectedValue,
           let position = plotArea.position(forX: selectedDate, y: selectedValue) {
            Circle()
                .fill(ChartTheme.primaryColor)
                .frame(width: 8, height: 8)
                .position(position)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 12, height: 12)
                        .position(position)
                )
        }
    }
    
    private var averageValue: Double {
        guard !dataPoints.isEmpty else { return 0 }
        return dataPoints.reduce(0) { $0 + $1.value } / Double(dataPoints.count)
    }
    
    private func nearestDataPoint(to date: Date) -> DataPoint? {
        dataPoints.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }
    
    private func formatSelectedInfo(_ point: DataPoint) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let valueFormatter = NumberFormatter()
        valueFormatter.numberStyle = .decimal
        valueFormatter.maximumFractionDigits = 2
        
        let dateStr = formatter.string(from: point.date)
        let valueStr = valueFormatter.string(from: NSNumber(value: point.value)) ?? ""
        
        return "\(dateStr): \(valueStr) \(yAxisLabel)"
    }
}

// MARK: - View Extension

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview

struct TimeSeriesChart_Previews: PreviewProvider {
    static var previews: some View {
        TimeSeriesChart(
            dataPoints: generateSampleData(),
            title: "Temperature Trends",
            yAxisLabel: "°F"
        )
        .padding()
    }
    
    static func generateSampleData() -> [DataPoint] {
        let calendar = Calendar.current
        let today = Date()
        
        return (0..<30).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let value = 70 + Double.random(in: -10...10) + sin(Double(dayOffset) * 0.3) * 5
            return DataPoint(date: date, value: value)
        }.reversed()
    }
}