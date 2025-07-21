//
//  HeatMapChart.swift
//  JubileeMobileBay
//
//  Heat map visualization for spatial-temporal data
//

import SwiftUI
import Charts

struct HeatMapChart: View {
    let data: [[HeatMapDataPoint]]
    let title: String
    let xLabels: [String]
    let yLabels: [String]
    let colorScheme: HeatMapColorScheme
    let showValues: Bool
    
    @State private var selectedCell: (row: Int, col: Int)?
    @State private var hoveredCell: (row: Int, col: Int)?
    
    struct HeatMapDataPoint {
        let value: Double
        let label: String?
        
        init(value: Double, label: String? = nil) {
            self.value = value
            self.label = label
        }
    }
    
    enum HeatMapColorScheme {
        case temperature
        case activity
        case correlation
        case custom(colors: [Color])
        
        func color(for normalizedValue: Double) -> Color {
            let colors: [Color]
            
            switch self {
            case .temperature:
                colors = [.blue, .cyan, .green, .yellow, .orange, .red]
            case .activity:
                colors = [.gray, .blue, .green, .yellow, .orange, .red]
            case .correlation:
                colors = [.blue, .white, .red]
            case .custom(let customColors):
                colors = customColors
            }
            
            let index = Int(normalizedValue * Double(colors.count - 1))
            let fraction = normalizedValue * Double(colors.count - 1) - Double(index)
            
            guard index < colors.count - 1 else { return colors.last ?? .clear }
            
            let fromColor = colors[index]
            let toColor = colors[index + 1]
            
            return interpolateColor(from: fromColor, to: toColor, fraction: fraction)
        }
        
        private func interpolateColor(from: Color, to: Color, fraction: Double) -> Color {
            let fromComponents = from.components
            let toComponents = to.components
            
            return Color(
                red: fromComponents.red + (toComponents.red - fromComponents.red) * fraction,
                green: fromComponents.green + (toComponents.green - fromComponents.green) * fraction,
                blue: fromComponents.blue + (toComponents.blue - fromComponents.blue) * fraction
            )
        }
    }
    
    init(
        data: [[HeatMapDataPoint]],
        title: String,
        xLabels: [String],
        yLabels: [String],
        colorScheme: HeatMapColorScheme = .activity,
        showValues: Bool = false
    ) {
        self.data = data
        self.title = title
        self.xLabels = xLabels
        self.yLabels = yLabels
        self.colorScheme = colorScheme
        self.showValues = showValues
    }
    
    var body: some View {
        ChartContainer {
            VStack(alignment: .leading, spacing: ChartTheme.chartPadding) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(ChartTheme.titleFont)
                        
                        if let selected = selectedCell {
                            Text(cellInfo(row: selected.row, col: selected.col))
                                .font(ChartTheme.labelFont)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    ChartExportButton(
                        chartView: AnyView(heatMapGrid),
                        fileName: "\(title)_\(Date().ISO8601Format())"
                    )
                }
                .padding(.horizontal, ChartTheme.chartPadding)
                .padding(.top, ChartTheme.chartPadding)
                
                // Heat Map Grid
                heatMapGrid
                    .padding(ChartTheme.chartPadding)
                
                // Color Scale Legend
                colorScaleLegend
                    .padding(.horizontal, ChartTheme.chartPadding)
                    .padding(.bottom, ChartTheme.chartPadding)
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .chartAccessibility(
            label: "\(title) heat map",
            value: "Shows \(yLabels.count) by \(xLabels.count) grid",
            hint: "Explore cells to see values"
        )
    }
    
    @ViewBuilder
    private var heatMapGrid: some View {
        if data.isEmpty || data.first?.isEmpty ?? true {
            EmptyChartView(
                message: "No heat map data available",
                systemImage: "square.grid.3x3"
            )
        } else {
            GeometryReader { geometry in
                let cellWidth = (geometry.size.width - CGFloat(xLabels.count + 1) * 2) / CGFloat(xLabels.count)
                let cellHeight = (geometry.size.height - CGFloat(yLabels.count + 1) * 2) / CGFloat(yLabels.count)
                
                ZStack(alignment: .topLeading) {
                    // Y-axis labels
                    VStack(spacing: 2) {
                        ForEach(yLabels.indices, id: \.self) { row in
                            Text(yLabels[row])
                                .font(ChartTheme.captionFont)
                                .foregroundColor(.secondary)
                                .frame(width: 60, height: cellHeight, alignment: .trailing)
                        }
                    }
                    .offset(x: -65, y: 30)
                    
                    // X-axis labels
                    HStack(spacing: 2) {
                        ForEach(xLabels.indices, id: \.self) { col in
                            Text(xLabels[col])
                                .font(ChartTheme.captionFont)
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(-45))
                                .frame(width: cellWidth, height: 30)
                        }
                    }
                    .offset(x: 70, y: -35)
                    
                    // Heat map cells
                    VStack(spacing: 2) {
                        ForEach(data.indices, id: \.self) { row in
                            HStack(spacing: 2) {
                                ForEach(data[row].indices, id: \.self) { col in
                                    heatMapCell(
                                        row: row,
                                        col: col,
                                        width: cellWidth,
                                        height: cellHeight
                                    )
                                }
                            }
                        }
                    }
                    .offset(x: 70, y: 30)
                }
            }
            .frame(height: CGFloat(yLabels.count) * 40 + 80)
        }
    }
    
    @ViewBuilder
    private func heatMapCell(row: Int, col: Int, width: CGFloat, height: CGFloat) -> some View {
        let dataPoint = data[row][col]
        let normalizedValue = normalizeValue(dataPoint.value)
        let isSelected = selectedCell?.row == row && selectedCell?.col == col
        let isHovered = hoveredCell?.row == row && hoveredCell?.col == col
        
        RoundedRectangle(cornerRadius: 4)
            .fill(colorScheme.color(for: normalizedValue))
            .frame(width: width, height: height)
            .overlay(
                Group {
                    if showValues || isSelected {
                        Text(formatValue(dataPoint.value))
                            .font(ChartTheme.captionFont)
                            .foregroundColor(textColor(for: normalizedValue))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        isSelected ? Color.primary : Color.clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isHovered)
            .onTapGesture {
                withAnimation {
                    selectedCell = (row, col)
                }
            }
            .onHover { hovering in
                hoveredCell = hovering ? (row, col) : nil
            }
            .accessibilityElement()
            .accessibilityLabel("\(yLabels[row]), \(xLabels[col])")
            .accessibilityValue(formatValue(dataPoint.value))
    }
    
    @ViewBuilder
    private var colorScaleLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scale")
                .font(ChartTheme.labelFont.weight(.semibold))
                .foregroundColor(.secondary)
            
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    // Gradient bar
                    LinearGradient(
                        stops: (0..<100).map { i in
                            Gradient.Stop(
                                color: colorScheme.color(for: Double(i) / 99.0),
                                location: Double(i) / 99.0
                            )
                        },
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 20)
                    .cornerRadius(4)
                    
                    // Scale labels
                    HStack {
                        Text(formatValue(minValue))
                        Spacer()
                        Text(formatValue((minValue + maxValue) / 2))
                        Spacer()
                        Text(formatValue(maxValue))
                    }
                    .font(ChartTheme.captionFont)
                    .foregroundColor(.secondary)
                    .offset(y: 25)
                }
            }
            .frame(height: 40)
        }
    }
    
    // MARK: - Helper Methods
    
    private var minValue: Double {
        data.flatMap { $0 }.map { $0.value }.min() ?? 0
    }
    
    private var maxValue: Double {
        data.flatMap { $0 }.map { $0.value }.max() ?? 1
    }
    
    private func normalizeValue(_ value: Double) -> Double {
        guard maxValue > minValue else { return 0.5 }
        return (value - minValue) / (maxValue - minValue)
    }
    
    private func formatValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = value < 1 ? 2 : value < 10 ? 1 : 0
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }
    
    private func textColor(for normalizedValue: Double) -> Color {
        normalizedValue > 0.6 ? .white : .primary
    }
    
    private func cellInfo(row: Int, col: Int) -> String {
        let value = data[row][col].value
        let label = data[row][col].label ?? "\(yLabels[row]), \(xLabels[col])"
        return "\(label): \(formatValue(value))"
    }
}

// MARK: - Preview

struct HeatMapChart_Previews: PreviewProvider {
    static var previews: some View {
        HeatMapChart(
            data: sampleHeatMapData,
            title: "Jubilee Activity by Time and Location",
            xLabels: ["6AM", "9AM", "12PM", "3PM", "6PM", "9PM"],
            yLabels: ["Point Clear", "Fairhope", "Daphne", "Spanish Fort", "Mobile"],
            colorScheme: .activity,
            showValues: false
        )
        .padding()
    }
    
    static var sampleHeatMapData: [[HeatMapChart.HeatMapDataPoint]] {
        let locations = 5
        let times = 6
        
        return (0..<locations).map { location in
            (0..<times).map { time in
                let baseValue = Double(location + time) / Double(locations + times)
                let variation = Double.random(in: -0.2...0.2)
                let value = max(0, min(1, baseValue + variation))
                
                return HeatMapChart.HeatMapDataPoint(
                    value: value,
                    label: "Activity: \(Int(value * 100))%"
                )
            }
        }
    }
}