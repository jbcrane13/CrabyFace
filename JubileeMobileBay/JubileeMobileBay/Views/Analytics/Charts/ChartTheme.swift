//
//  ChartTheme.swift
//  JubileeMobileBay
//
//  Advanced Analytics Dashboard - Chart Theme Configuration
//

import SwiftUI
import Charts

// MARK: - Chart Theme Configuration

struct ChartTheme {
    // Color scheme
    static let primaryColor = Color.blue
    static let secondaryColor = Color.orange
    static let tertiaryColor = Color.green
    static let quaternaryColor = Color.purple
    static let warningColor = Color.orange
    static let errorColor = Color.red
    static let successColor = Color.green
    
    // Gradient colors for heat maps
    static let heatMapGradient = [
        Color.blue.opacity(0.2),
        Color.green.opacity(0.4),
        Color.yellow.opacity(0.6),
        Color.orange.opacity(0.8),
        Color.red
    ]
    
    // Chart colors array for multiple series
    static let chartColors = [
        primaryColor,
        secondaryColor,
        tertiaryColor,
        quaternaryColor,
        Color.pink,
        Color.indigo,
        Color.teal,
        Color.brown
    ]
    
    // Text styles
    static let titleFont = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let subtitleFont = Font.system(size: 16, weight: .medium, design: .rounded)
    static let labelFont = Font.system(size: 12, weight: .regular, design: .rounded)
    static let captionFont = Font.system(size: 10, weight: .light, design: .rounded)
    
    // Chart dimensions
    static let defaultChartHeight: CGFloat = 300
    static let compactChartHeight: CGFloat = 200
    static let expandedChartHeight: CGFloat = 400
    
    // Padding and spacing
    static let chartPadding: CGFloat = 16
    static let interChartSpacing: CGFloat = 24
    static let sectionSpacing: CGFloat = 32
    
    // Animation
    static let animationDuration: Double = 0.3
    static let springAnimation = Animation.spring(response: 0.5, dampingFraction: 0.8)
    
    // Grid lines
    static let gridLineColor = Color.gray.opacity(0.2)
    static let gridLineWidth: CGFloat = 0.5
    
    // Accessibility
    static let minimumTouchTarget: CGFloat = 44
}

// MARK: - Chart Style Modifiers

struct ChartStyleModifier: ViewModifier {
    let title: String
    let subtitle: String?
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(ChartTheme.titleFont)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(ChartTheme.subtitleFont)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            
            content
                .frame(height: ChartTheme.defaultChartHeight)
                .padding(ChartTheme.chartPadding)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal, ChartTheme.chartPadding)
    }
}

// MARK: - Chart Accessibility

struct ChartAccessibilityModifier: ViewModifier {
    let label: String
    let value: String
    let hint: String?
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityHint(hint ?? "")
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isImage)
    }
}

// MARK: - Extensions

extension View {
    func chartStyle(title: String, subtitle: String? = nil) -> some View {
        modifier(ChartStyleModifier(title: title, subtitle: subtitle))
    }
    
    func chartAccessibility(label: String, value: String, hint: String? = nil) -> some View {
        modifier(ChartAccessibilityModifier(label: label, value: value, hint: hint))
    }
}

// MARK: - Chart Container View

struct ChartContainer<Content: View>: View {
    let content: Content
    let isLoading: Bool
    let error: Error?
    let onRetry: (() -> Void)?
    
    init(
        isLoading: Bool = false,
        error: Error? = nil,
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.isLoading = isLoading
        self.error = error
        self.onRetry = onRetry
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
            } else if let error = error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(ChartTheme.errorColor)
                    
                    Text("Chart Error")
                        .font(ChartTheme.titleFont)
                    
                    Text(error.localizedDescription)
                        .font(ChartTheme.labelFont)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if let onRetry = onRetry {
                        Button(action: onRetry) {
                            Label("Retry", systemImage: "arrow.clockwise")
                                .font(ChartTheme.subtitleFont)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            } else {
                content
            }
        }
        .animation(ChartTheme.springAnimation, value: isLoading)
        .animation(ChartTheme.springAnimation, value: error != nil)
    }
}

// MARK: - Chart Legend View

struct ChartLegend: View {
    struct LegendItem {
        let color: Color
        let label: String
        let value: String?
    }
    
    let items: [LegendItem]
    let orientation: Axis = .horizontal
    
    var body: some View {
        if orientation == .horizontal {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items.indices, id: \.self) { index in
                        legendItemView(items[index])
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items.indices, id: \.self) { index in
                    legendItemView(items[index])
                }
            }
        }
    }
    
    private func legendItemView(_ item: LegendItem) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(item.color)
                .frame(width: 12, height: 12)
            
            Text(item.label)
                .font(ChartTheme.labelFont)
                .foregroundColor(.primary)
            
            if let value = item.value {
                Text(value)
                    .font(ChartTheme.labelFont)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}