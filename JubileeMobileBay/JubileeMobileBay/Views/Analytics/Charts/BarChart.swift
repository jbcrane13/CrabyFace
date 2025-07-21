//
//  BarChart.swift
//  JubileeMobileBay
//
//  Bar chart implementation for categorical data
//

import SwiftUI
import Charts

struct BarChart: View {
    let data: [AggregatedDataPoint]
    let title: String
    let yAxisLabel: String
    let colorScheme: BarChartColorScheme
    let showValues: Bool
    let orientation: BarChartOrientation
    
    @State private var selectedCategory: String?
    @State private var animateChart = false
    
    enum BarChartColorScheme {
        case monochrome(Color)
        case gradient(from: Color, to: Color)
        case categorical
        
        func color(for index: Int, total: Int) -> Color {
            switch self {
            case .monochrome(let color):
                return color
            case .gradient(let from, let to):
                let progress = Double(index) / Double(max(total - 1, 1))
                return Color(
                    red: from.components.red + (to.components.red - from.components.red) * progress,
                    green: from.components.green + (to.components.green - from.components.green) * progress,
                    blue: from.components.blue + (to.components.blue - from.components.blue) * progress
                )
            case .categorical:
                return ChartTheme.chartColors[index % ChartTheme.chartColors.count]
            }
        }
    }
    
    enum BarChartOrientation {
        case vertical
        case horizontal
    }
    
    init(
        data: [AggregatedDataPoint],
        title: String,
        yAxisLabel: String = "Value",
        colorScheme: BarChartColorScheme = .categorical,
        showValues: Bool = true,
        orientation: BarChartOrientation = .vertical
    ) {
        self.data = data
        self.title = title
        self.yAxisLabel = yAxisLabel
        self.colorScheme = colorScheme
        self.showValues = showValues
        self.orientation = orientation
    }
    
    var body: some View {
        ChartContainer {
            VStack(alignment: .leading, spacing: ChartTheme.chartPadding) {
                // Header
                HStack {
                    Text(title)
                        .font(ChartTheme.titleFont)
                    
                    Spacer()
                    
                    if selectedCategory != nil {
                        Button("Clear Selection") {
                            withAnimation {
                                selectedCategory = nil
                            }
                        }
                        .font(ChartTheme.labelFont)
                        .buttonStyle(.bordered)
                    }
                    
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
                if case .categorical = colorScheme {
                    ChartLegend(
                        items: data.enumerated().map { index, point in
                            ChartLegend.LegendItem(
                                color: colorScheme.color(for: index, total: data.count),
                                label: point.category,
                                value: point.displayPercentage.isEmpty ? nil : point.displayPercentage
                            )
                        },
                        orientation: .horizontal
                    )
                    .padding(.horizontal, ChartTheme.chartPadding)
                    .padding(.bottom, ChartTheme.chartPadding)
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateChart = true
            }
        }
        .chartAccessibility(
            label: "\(title) bar chart",
            value: "Shows \(data.count) categories",
            hint: "Tap on bars to see details"
        )
    }
    
    @ViewBuilder
    private var chartContent: some View {
        if data.isEmpty {
            EmptyChartView(
                message: "No data available",
                systemImage: "chart.bar"
            )
        } else {
            Chart(Array(data.enumerated()), id: \.element.id) { index, point in
                if orientation == .vertical {
                    BarMark(
                        x: .value("Category", point.category),
                        y: .value(yAxisLabel, animateChart ? point.value : 0)
                    )
                    .foregroundStyle(barColor(for: index, point: point))
                    .cornerRadius(4)
                    .opacity(selectedCategory == nil || selectedCategory == point.category ? 1.0 : 0.3)
                    
                    if showValues && animateChart {
                        BarMark(
                            x: .value("Category", point.category),
                            y: .value(yAxisLabel, point.value)
                        )
                        .foregroundStyle(Color.clear)
                        .annotation(position: .top) {
                            Text(formatValue(point.value))
                                .font(ChartTheme.captionFont)
                                .foregroundColor(.primary)
                        }
                    }
                } else {
                    BarMark(
                        x: .value(yAxisLabel, animateChart ? point.value : 0),
                        y: .value("Category", point.category)
                    )
                    .foregroundStyle(barColor(for: index, point: point))
                    .cornerRadius(4)
                    .opacity(selectedCategory == nil || selectedCategory == point.category ? 1.0 : 0.3)
                    
                    if showValues && animateChart {
                        BarMark(
                            x: .value(yAxisLabel, point.value),
                            y: .value("Category", point.category)
                        )
                        .foregroundStyle(Color.clear)
                        .annotation(position: .trailing) {
                            Text(formatValue(point.value))
                                .font(ChartTheme.captionFont)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(ChartTheme.captionFont)
                        .foregroundColor(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                        .foregroundStyle(ChartTheme.gridLineColor)
                    AxisValueLabel()
                        .font(ChartTheme.captionFont)
                        .foregroundColor(.secondary)
                }
            }
            .chartAngleSelection(value: .constant(nil))
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            if let category = findCategory(at: location, in: geometry, proxy: chartProxy) {
                                withAnimation {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }
                            }
                        }
                }
            }
        }
    }
    
    private func barColor(for index: Int, point: AggregatedDataPoint) -> Color {
        let baseColor = colorScheme.color(for: index, total: data.count)
        return selectedCategory == nil || selectedCategory == point.category
            ? baseColor
            : baseColor.opacity(0.3)
    }
    
    private func formatValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = value < 10 ? 1 : 0
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }
    
    private func findCategory(at location: CGPoint, in geometry: GeometryProxy, proxy: ChartProxy) -> String? {
        // This is a simplified implementation
        // In a real app, you'd calculate the exact bar positions
        let categoryWidth = geometry.size.width / CGFloat(data.count)
        let index = Int(location.x / categoryWidth)
        
        guard index >= 0 && index < data.count else { return nil }
        return data[index].category
    }
}

// MARK: - Color Components Extension

extension Color {
    var components: (red: Double, green: Double, blue: Double, opacity: Double) {
        guard let cgColor = UIColor(self).cgColor.components else {
            return (0, 0, 0, 0)
        }
        
        let red = cgColor.count > 0 ? cgColor[0] : 0
        let green = cgColor.count > 1 ? cgColor[1] : 0
        let blue = cgColor.count > 2 ? cgColor[2] : 0
        let opacity = cgColor.count > 3 ? cgColor[3] : 1
        
        return (Double(red), Double(green), Double(blue), Double(opacity))
    }
}

// MARK: - Preview

struct BarChart_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BarChart(
                data: sampleData,
                title: "Species Distribution",
                yAxisLabel: "Count",
                colorScheme: .categorical
            )
            
            BarChart(
                data: sampleData,
                title: "Species by Percentage",
                yAxisLabel: "Percentage",
                colorScheme: .gradient(from: .blue, to: .purple),
                orientation: .horizontal
            )
        }
        .padding()
    }
    
    static var sampleData: [AggregatedDataPoint] {
        [
            AggregatedDataPoint(category: "Blue Crab", value: 45, count: 45, percentage: 0.35),
            AggregatedDataPoint(category: "Flounder", value: 32, count: 32, percentage: 0.25),
            AggregatedDataPoint(category: "Shrimp", value: 28, count: 28, percentage: 0.22),
            AggregatedDataPoint(category: "Red Snapper", value: 23, count: 23, percentage: 0.18)
        ]
    }
}