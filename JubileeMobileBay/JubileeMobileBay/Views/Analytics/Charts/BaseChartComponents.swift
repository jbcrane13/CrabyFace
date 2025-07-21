//
//  BaseChartComponents.swift
//  JubileeMobileBay
//
//  Reusable chart components for the analytics dashboard
//

import SwiftUI
import Charts

// MARK: - Data Point Models

struct DataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let category: String?
    let label: String?
    
    init(date: Date, value: Double, category: String? = nil, label: String? = nil) {
        self.date = date
        self.value = value
        self.category = category
        self.label = label
    }
}

struct AggregatedDataPoint: Identifiable {
    let id = UUID()
    let category: String
    let value: Double
    let count: Int
    let percentage: Double?
    
    var displayPercentage: String {
        guard let percentage = percentage else { return "" }
        return String(format: "%.1f%%", percentage * 100)
    }
}

struct CorrelationDataPoint: Identifiable {
    let id = UUID()
    let xValue: Double
    let yValue: Double
    let category: String
    let label: String?
}

// MARK: - Chart Axes Components

struct CustomXAxisLabel: View {
    let value: Date
    let format: Date.FormatStyle
    
    var body: some View {
        Text(value, format: format)
            .font(ChartTheme.captionFont)
            .foregroundColor(.secondary)
            .rotationEffect(.degrees(-45))
            .offset(y: 10)
    }
}

struct CustomYAxisLabel: View {
    let value: Double
    let formatter: NumberFormatter
    
    init(value: Double, formatter: NumberFormatter? = nil) {
        self.value = value
        self.formatter = formatter ?? {
            let f = NumberFormatter()
            f.numberStyle = .decimal
            f.maximumFractionDigits = 1
            return f
        }()
    }
    
    var body: some View {
        Text(formatter.string(from: NSNumber(value: value)) ?? "")
            .font(ChartTheme.captionFont)
            .foregroundColor(.secondary)
    }
}

// MARK: - Chart Tooltip View

struct ChartTooltip: View {
    let title: String
    let value: String
    let subtitle: String?
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(title)
                    .font(ChartTheme.labelFont.weight(.semibold))
                    .foregroundColor(.primary)
            }
            
            Text(value)
                .font(ChartTheme.titleFont)
                .foregroundColor(.primary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(ChartTheme.captionFont)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Interactive Chart Overlay

struct InteractiveChartOverlay: View {
    @Binding var selectedDate: Date?
    @Binding var selectedValue: Double?
    let chartProxy: ChartProxy
    let dataPoints: [DataPoint]
    
    @State private var currentLocation: CGPoint = .zero
    @State private var isInteracting = false
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        currentLocation = location
                        isInteracting = true
                        updateSelection(at: location, in: geometry)
                    case .ended:
                        isInteracting = false
                        selectedDate = nil
                        selectedValue = nil
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            currentLocation = value.location
                            isInteracting = true
                            updateSelection(at: value.location, in: geometry)
                        }
                        .onEnded { _ in
                            isInteracting = false
                        }
                )
            
            // Selection indicator
            if isInteracting, let date = selectedDate, let value = selectedValue {
                if let position = chartProxy.position(forX: date, y: value) {
                    ZStack {
                        Circle()
                            .fill(ChartTheme.primaryColor.opacity(0.2))
                            .frame(width: 20, height: 20)
                        
                        Circle()
                            .fill(ChartTheme.primaryColor)
                            .frame(width: 8, height: 8)
                    }
                    .position(position)
                    .allowsHitTesting(false)
                }
            }
        }
    }
    
    private func updateSelection(at location: CGPoint, in geometry: GeometryProxy) {
        guard let (date, _) = chartProxy.value(at: location) else { return }
        
        // Find nearest data point
        let nearest = dataPoints.min(by: { abs($0.date.timeIntervalSince(date as! Date)) < abs($1.date.timeIntervalSince(date as! Date)) })
        
        selectedDate = nearest?.date
        selectedValue = nearest?.value
    }
}

// MARK: - Chart Grid Background

struct ChartGridBackground: View {
    let horizontalLines: Int
    let verticalLines: Int
    
    init(horizontalLines: Int = 5, verticalLines: Int = 5) {
        self.horizontalLines = horizontalLines
        self.verticalLines = verticalLines
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Horizontal lines
                ForEach(0..<horizontalLines, id: \.self) { index in
                    Path { path in
                        let y = geometry.size.height * CGFloat(index) / CGFloat(horizontalLines - 1)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(ChartTheme.gridLineColor, lineWidth: ChartTheme.gridLineWidth)
                }
                
                // Vertical lines
                ForEach(0..<verticalLines, id: \.self) { index in
                    Path { path in
                        let x = geometry.size.width * CGFloat(index) / CGFloat(verticalLines - 1)
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    }
                    .stroke(ChartTheme.gridLineColor, lineWidth: ChartTheme.gridLineWidth)
                }
            }
        }
    }
}

// MARK: - Empty Chart State

struct EmptyChartView: View {
    let message: String
    let systemImage: String
    let action: (() -> Void)?
    
    init(
        message: String = "No data available",
        systemImage: String = "chart.line.uptrend.xyaxis",
        action: (() -> Void)? = nil
    ) {
        self.message = message
        self.systemImage = systemImage
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(message)
                .font(ChartTheme.subtitleFont)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let action = action {
                Button(action: action) {
                    Label("Load Data", systemImage: "arrow.clockwise")
                        .font(ChartTheme.labelFont)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Chart Export Button

struct ChartExportButton: View {
    let chartView: AnyView
    let fileName: String
    
    @State private var showingExportOptions = false
    
    var body: some View {
        Menu {
            Button(action: exportAsImage) {
                Label("Export as Image", systemImage: "photo")
            }
            
            Button(action: exportAsPDF) {
                Label("Export as PDF", systemImage: "doc")
            }
            
            Button(action: shareChart) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 16))
                .foregroundColor(ChartTheme.primaryColor)
                .padding(8)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
        }
    }
    
    private func exportAsImage() {
        // Implementation for image export
    }
    
    private func exportAsPDF() {
        // Implementation for PDF export
    }
    
    private func shareChart() {
        // Implementation for sharing
    }
}