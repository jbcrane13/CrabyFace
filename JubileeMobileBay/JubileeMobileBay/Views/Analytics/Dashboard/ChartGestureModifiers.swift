//
//  ChartGestureModifiers.swift
//  JubileeMobileBay
//
//  Gesture modifiers for interactive chart features
//

import SwiftUI
import Charts

// MARK: - Zoom Gesture Modifier

struct ChartZoomModifier: ViewModifier {
    @State private var currentZoom: CGFloat = 1.0
    @State private var totalZoom: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    @State private var totalOffset: CGSize = .zero
    
    let minZoom: CGFloat
    let maxZoom: CGFloat
    let onZoomChanged: ((CGFloat) -> Void)?
    
    init(
        minZoom: CGFloat = 0.5,
        maxZoom: CGFloat = 3.0,
        onZoomChanged: ((CGFloat) -> Void)? = nil
    ) {
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.onZoomChanged = onZoomChanged
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(currentZoom * totalZoom)
            .offset(
                x: currentOffset.width + totalOffset.width,
                y: currentOffset.height + totalOffset.height
            )
            .gesture(
                SimultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            currentZoom = value
                        }
                        .onEnded { value in
                            let newZoom = min(max(totalZoom * value, minZoom), maxZoom)
                            totalZoom = newZoom
                            currentZoom = 1.0
                            onZoomChanged?(newZoom)
                        },
                    DragGesture()
                        .onChanged { value in
                            currentOffset = value.translation
                        }
                        .onEnded { value in
                            totalOffset.width += value.translation.width
                            totalOffset.height += value.translation.height
                            currentOffset = .zero
                        }
                )
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring()) {
                    totalZoom = totalZoom > 1.0 ? 1.0 : 2.0
                    totalOffset = .zero
                    currentOffset = .zero
                    onZoomChanged?(totalZoom)
                }
            }
    }
}

// MARK: - Chart Selection Modifier

struct ChartSelectionModifier<SelectionValue: Plottable>: ViewModifier {
    @Binding var selection: SelectionValue?
    let onSelectionChanged: ((SelectionValue?) -> Void)?
    
    func body(content: Content) -> some View {
        content
            .chartAngleSelection(value: .constant(0))
            .chartXSelection(value: Binding(
                get: { selection },
                set: { newValue in
                    selection = newValue
                    onSelectionChanged?(newValue)
                }
            ))
    }
}

// MARK: - Pan to Load More Modifier

struct PanToLoadMoreModifier: ViewModifier {
    @State private var isDragging = false
    @State private var dragOffset: CGFloat = 0
    
    let threshold: CGFloat
    let onLoadMore: (LoadDirection) -> Void
    
    enum LoadDirection {
        case leading, trailing
    }
    
    init(
        threshold: CGFloat = 100,
        onLoadMore: @escaping (LoadDirection) -> Void
    ) {
        self.threshold = threshold
        self.onLoadMore = onLoadMore
    }
    
    func body(content: Content) -> some View {
        content
            .offset(x: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation.width * 0.3 // Rubber band effect
                    }
                    .onEnded { value in
                        isDragging = false
                        
                        if abs(value.translation.width) > threshold {
                            if value.translation.width > 0 {
                                onLoadMore(.leading)
                            } else {
                                onLoadMore(.trailing)
                            }
                        }
                        
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
            )
            .animation(.interactiveSpring(), value: dragOffset)
    }
}

// MARK: - Interactive Tooltip Modifier

struct InteractiveTooltipModifier: ViewModifier {
    @State private var showTooltip = false
    @State private var tooltipLocation: CGPoint = .zero
    
    let content: (CGPoint) -> AnyView
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if showTooltip {
                        tooltipView
                            .position(
                                x: tooltipLocation.x,
                                y: max(40, tooltipLocation.y - 60)
                            )
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                    }
                }
            )
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    tooltipLocation = location
                    showTooltip = true
                case .ended:
                    showTooltip = false
                }
            }
    }
    
    private var tooltipView: some View {
        self.content(tooltipLocation)
            .fixedSize()
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            )
    }
}

// MARK: - Chart Animation Modifier

struct ChartAnimationModifier: ViewModifier {
    @State private var isAnimating = false
    
    let duration: Double
    let delay: Double
    
    init(duration: Double = 1.0, delay: Double = 0.0) {
        self.duration = duration
        self.delay = delay
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.0 : 0.001, anchor: .bottom)
            .opacity(isAnimating ? 1.0 : 0.0)
            .animation(
                .spring(response: duration, dampingFraction: 0.8)
                    .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - View Extensions

extension View {
    func chartZoom(
        minZoom: CGFloat = 0.5,
        maxZoom: CGFloat = 3.0,
        onZoomChanged: ((CGFloat) -> Void)? = nil
    ) -> some View {
        modifier(ChartZoomModifier(
            minZoom: minZoom,
            maxZoom: maxZoom,
            onZoomChanged: onZoomChanged
        ))
    }
    
    func chartSelection<T: Plottable>(
        value: Binding<T?>,
        onSelectionChanged: ((T?) -> Void)? = nil
    ) -> some View {
        modifier(ChartSelectionModifier(
            selection: value,
            onSelectionChanged: onSelectionChanged
        ))
    }
    
    func panToLoadMore(
        threshold: CGFloat = 100,
        onLoadMore: @escaping (PanToLoadMoreModifier.LoadDirection) -> Void
    ) -> some View {
        modifier(PanToLoadMoreModifier(
            threshold: threshold,
            onLoadMore: onLoadMore
        ))
    }
    
    func interactiveTooltip(
        @ViewBuilder content: @escaping (CGPoint) -> AnyView
    ) -> some View {
        modifier(InteractiveTooltipModifier(content: content))
    }
    
    func chartAnimation(
        duration: Double = 1.0,
        delay: Double = 0.0
    ) -> some View {
        modifier(ChartAnimationModifier(
            duration: duration,
            delay: delay
        ))
    }
}

// MARK: - Gesture Recognizer Coordinator

class ChartGestureCoordinator: ObservableObject {
    @Published var currentZoom: CGFloat = 1.0
    @Published var selectedValue: (x: Double, y: Double)?
    @Published var isInteracting = false
    
    private var gestureTimer: Timer?
    
    func handleInteractionBegan() {
        isInteracting = true
        gestureTimer?.invalidate()
    }
    
    func handleInteractionEnded() {
        gestureTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            self.isInteracting = false
            self.selectedValue = nil
        }
    }
    
    func reset() {
        currentZoom = 1.0
        selectedValue = nil
        isInteracting = false
        gestureTimer?.invalidate()
    }
}

// MARK: - Enhanced Chart Container

struct EnhancedChartContainer<Content: View>: View {
    @StateObject private var gestureCoordinator = ChartGestureCoordinator()
    
    let content: Content
    let enableZoom: Bool
    let enablePanToLoad: Bool
    let onLoadMore: ((PanToLoadMoreModifier.LoadDirection) -> Void)?
    
    init(
        enableZoom: Bool = true,
        enablePanToLoad: Bool = false,
        onLoadMore: ((PanToLoadMoreModifier.LoadDirection) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.enableZoom = enableZoom
        self.enablePanToLoad = enablePanToLoad
        self.onLoadMore = onLoadMore
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
                .if(enableZoom) { view in
                    view.chartZoom { zoom in
                        gestureCoordinator.currentZoom = zoom
                    }
                }
                .if(enablePanToLoad && onLoadMore != nil) { view in
                    view.panToLoadMore { direction in
                        onLoadMore?(direction)
                    }
                }
            
            // Zoom indicator
            if enableZoom && gestureCoordinator.currentZoom != 1.0 {
                VStack {
                    HStack {
                        Spacer()
                        ZoomIndicator(zoom: gestureCoordinator.currentZoom)
                            .padding()
                    }
                    Spacer()
                }
            }
        }
        .environmentObject(gestureCoordinator)
    }
}

// MARK: - Zoom Indicator

struct ZoomIndicator: View {
    let zoom: CGFloat
    
    var body: some View {
        Text("\(Int(zoom * 100))%")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(4)
    }
}

// MARK: - Conditional View Modifier

extension View {
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}