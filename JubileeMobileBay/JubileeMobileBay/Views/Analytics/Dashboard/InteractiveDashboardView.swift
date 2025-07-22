//
//  InteractiveDashboardView.swift
//  JubileeMobileBay
//
//  Enhanced interactive analytics dashboard with advanced features
//

import SwiftUI
import Charts
import CoreLocation

struct InteractiveDashboardView: View {
    @StateObject private var dashboardManager = InteractiveDashboardManager()
    @StateObject private var dataProvider = DashboardDataProvider()
    @State private var configuration = DashboardConfiguration.default
    
    // Interactive Features
    @State private var selectedTimeRange = DashboardTimeRange.week
    @State private var customDateRange: DateInterval?
    @State private var showingDateRangePicker = false
    @State private var activeFilters: Set<FilterOption> = []
    @State private var zoomScale: CGFloat = 1.0
    @State private var dashboardLayout = DashboardLayout.grid
    @State private var columnCount = 2
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main Dashboard Content
                dashboardContent
                
                // Floating Controls
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingActionButtons
                    }
                    .padding()
                }
            }
            .navigationTitle("Analytics Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    layoutButton
                    filterButton
                    timeRangeButton
                }
            }
            .sheet(isPresented: $showingDateRangePicker) {
                DateRangePickerView(
                    selectedRange: $customDateRange,
                    onSelect: { range in
                        selectedTimeRange = .custom(from: range.start, to: range.end)
                        Task {
                            await refreshDashboard()
                        }
                    }
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadDashboardState()
        }
        .onDisappear {
            saveDashboardState()
        }
        .task {
            await dashboardManager.loadSections()
            await refreshDashboard()
        }
    }
    
    // MARK: - Dashboard Content
    
    @ViewBuilder
    private var dashboardContent: some View {
        ScrollView {
            switch dashboardLayout {
            case .grid:
                gridLayout
            case .list:
                listLayout
            case .focus:
                focusLayout
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .refreshable {
            await refreshDashboard()
        }
    }
    
    // MARK: - Layout Views
    
    private var gridLayout: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: adaptiveColumnCount)
        
        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(filteredSections, id: \.id) { section in
                DashboardSectionCard(
                    section: section,
                    isZoomed: zoomScale > 1.0
                )
                .scaleEffect(zoomScale)
                .animation(.spring(), value: zoomScale)
                .onTapGesture(count: 2) {
                    withAnimation {
                        zoomScale = zoomScale == 1.0 ? 1.5 : 1.0
                    }
                }
            }
        }
        .padding()
    }
    
    private var listLayout: some View {
        LazyVStack(spacing: 16) {
            ForEach(filteredSections, id: \.id) { section in
                DashboardSectionCard(
                    section: section,
                    isZoomed: false
                )
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    private var focusLayout: some View {
        TabView(selection: $dashboardManager.focusedSectionId) {
            ForEach(filteredSections, id: \.id) { section in
                DashboardSectionCard(
                    section: section,
                    isZoomed: true,
                    showFullScreen: true
                )
                .padding()
                .tag(section.id)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .frame(height: UIScreen.main.bounds.height * 0.7)
    }
    
    // MARK: - Floating Action Buttons
    
    private var floatingActionButtons: some View {
        VStack(spacing: 12) {
            // Zoom Controls
            if dashboardLayout == .grid {
                FloatingActionButton(
                    icon: "plus.magnifyingglass",
                    action: { withAnimation { zoomScale = min(zoomScale + 0.25, 2.0) } }
                )
                
                FloatingActionButton(
                    icon: "minus.magnifyingglass",
                    action: { withAnimation { zoomScale = max(zoomScale - 0.25, 0.5) } }
                )
            }
            
            // Quick Refresh
            FloatingActionButton(
                icon: "arrow.clockwise",
                action: { Task { await refreshDashboard() } }
            )
        }
    }
    
    // MARK: - Toolbar Items
    
    private var layoutButton: some View {
        Menu {
            ForEach(DashboardLayout.allCases, id: \.self) { layout in
                Button(action: { dashboardLayout = layout }) {
                    Label(layout.title, systemImage: layout.icon)
                        .symbolVariant(dashboardLayout == layout ? .fill : .none)
                }
            }
            
            if dashboardLayout == .grid {
                Divider()
                
                Stepper(value: $columnCount, in: 1...4) {
                    Label("Columns: \(columnCount)", systemImage: "square.grid.\(columnCount)x2")
                }
            }
        } label: {
            Image(systemName: dashboardLayout.icon)
                .symbolVariant(.fill)
        }
    }
    
    private var filterButton: some View {
        Menu {
            Section("Data Sources") {
                ForEach(FilterOption.dataSources, id: \.self) { filter in
                    Toggle(isOn: Binding(
                        get: { activeFilters.contains(filter) },
                        set: { isActive in
                            if isActive {
                                activeFilters.insert(filter)
                            } else {
                                activeFilters.remove(filter)
                            }
                            Task { await refreshDashboard() }
                        }
                    )) {
                        Label(filter.title, systemImage: filter.icon)
                    }
                }
            }
            
            Section("Chart Types") {
                ForEach(FilterOption.chartTypes, id: \.self) { filter in
                    Toggle(isOn: Binding(
                        get: { activeFilters.contains(filter) },
                        set: { isActive in
                            if isActive {
                                activeFilters.insert(filter)
                            } else {
                                activeFilters.remove(filter)
                            }
                        }
                    )) {
                        Label(filter.title, systemImage: filter.icon)
                    }
                }
            }
            
            if !activeFilters.isEmpty {
                Section {
                    Button(action: {
                        activeFilters.removeAll()
                        Task { await refreshDashboard() }
                    }) {
                        Label("Clear Filters", systemImage: "xmark.circle")
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .symbolVariant(activeFilters.isEmpty ? .none : .fill)
        }
    }
    
    private var timeRangeButton: some View {
        Menu {
            ForEach(DashboardTimeRange.allCases, id: \.self) { range in
                Button(action: {
                    selectedTimeRange = range
                    Task { await refreshDashboard() }
                }) {
                    Label(range.title, systemImage: range.icon)
                        .symbolVariant(selectedTimeRange == range ? .fill : .none)
                }
            }
            
            Divider()
            
            Button(action: { showingDateRangePicker = true }) {
                Label("Custom Range...", systemImage: "calendar")
            }
        } label: {
            Image(systemName: "calendar.badge.clock")
        }
    }
    
    // MARK: - Computed Properties
    
    private var adaptiveColumnCount: Int {
        if horizontalSizeClass == .regular {
            return columnCount + 1
        }
        return columnCount
    }
    
    private var filteredSections: [AnalyticsDashboardSection] {
        dashboardManager.sections.filter { section in
            // Filter by enabled state
            guard section.isEnabled else { return false }
            
            // Filter by active filters
            if !activeFilters.isEmpty {
                let matchesDataSource = activeFilters.contains(where: { filter in
                    guard case .dataSource(let source) = filter else { return false }
                    return section.requiredDataSources.contains(source)
                })
                
                let matchesChartType = activeFilters.contains(where: { filter in
                    guard case .chartType(let type) = filter else { return false }
                    return section.viewType == type
                })
                
                if !matchesDataSource && !matchesChartType {
                    return false
                }
            }
            
            return true
        }
    }
    
    // MARK: - Actions
    
    private func refreshDashboard() async {
        await dashboardManager.refreshAllSections()
    }
    
    private func loadDashboardState() {
        if let savedState = DashboardStateManager.loadState() {
            selectedTimeRange = savedState.timeRange
            activeFilters = savedState.activeFilters
            dashboardLayout = savedState.layout
            columnCount = savedState.columnCount
            configuration = savedState.configuration
        }
    }
    
    private func saveDashboardState() {
        let state = DashboardState(
            timeRange: selectedTimeRange,
            activeFilters: activeFilters,
            layout: dashboardLayout,
            columnCount: columnCount,
            configuration: configuration
        )
        DashboardStateManager.saveState(state)
    }
}

// MARK: - Supporting Types

enum DashboardLayout: String, CaseIterable {
    case grid = "Grid"
    case list = "List"
    case focus = "Focus"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        case .focus: return "rectangle.center.inset.filled"
        }
    }
}

enum FilterOption: Hashable {
    case dataSource(DataSource)
    case chartType(DashboardViewType)
    
    var title: String {
        switch self {
        case .dataSource(let source):
            return source.displayName
        case .chartType(let type):
            return type.rawValue
        }
    }
    
    var icon: String {
        switch self {
        case .dataSource:
            return "antenna.radiowaves.left.and.right"
        case .chartType(let type):
            return type.icon
        }
    }
    
    static let dataSources: [FilterOption] = DataSource.allCases.map { .dataSource($0) }
    static let chartTypes: [FilterOption] = DashboardViewType.allCases.map { .chartType($0) }
}

enum DashboardTimeRange: Hashable, CaseIterable {
    case hour
    case day
    case week
    case month
    case year
    case custom(from: Date, to: Date)
    
    static var allCases: [DashboardTimeRange] {
        [.hour, .day, .week, .month, .year]
    }
    
    var title: String {
        switch self {
        case .hour: return "Last Hour"
        case .day: return "Last 24 Hours"
        case .week: return "Last 7 Days"
        case .month: return "Last 30 Days"
        case .year: return "Last Year"
        case .custom(let from, let to):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "\(formatter.string(from: from)) - \(formatter.string(from: to))"
        }
    }
    
    var icon: String {
        switch self {
        case .hour: return "clock"
        case .day: return "sun.max"
        case .week: return "calendar.day.timeline.left"
        case .month: return "calendar"
        case .year: return "calendar.circle"
        case .custom: return "calendar.badge.plus"
        }
    }
}

// MARK: - Dashboard Section Card

struct DashboardSectionCard: View {
    let section: AnalyticsDashboardSection
    let isZoomed: Bool
    var showFullScreen: Bool = false
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: section.viewType.icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                
                Text(section.title)
                    .font(.headline)
                
                Spacer()
                
                if !showFullScreen {
                    Button(action: { withAnimation { isExpanded.toggle() } }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.tertiarySystemBackground))
            
            // Content
            if isExpanded || showFullScreen {
                section.createView()
                    .transition(.asymmetric(
                        insertion: .push(from: .top),
                        removal: .push(from: .bottom)
                    ))
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Date Range Picker View

struct DateRangePickerView: View {
    @Binding var selectedRange: DateInterval?
    let onSelect: (DateInterval) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var startDate = Date().addingTimeInterval(-7 * 24 * 3600)
    @State private var endDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Start Date") {
                    DatePicker(
                        "From",
                        selection: $startDate,
                        in: ...endDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                Section("End Date") {
                    DatePicker(
                        "To",
                        selection: $endDate,
                        in: startDate...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                Section {
                    HStack {
                        Text("Duration:")
                        Spacer()
                        Text(formatDuration())
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Custom Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        let range = DateInterval(start: startDate, end: endDate)
                        selectedRange = range
                        onSelect(range)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func formatDuration() -> String {
        let duration = endDate.timeIntervalSince(startDate)
        let days = Int(duration / (24 * 3600))
        let hours = Int((duration.truncatingRemainder(dividingBy: 24 * 3600)) / 3600)
        
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s"), \(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
    }
}

// MARK: - Dashboard State Management

struct DashboardState: Codable {
    let timeRange: DashboardTimeRange
    let activeFilters: Set<FilterOption>
    let layout: DashboardLayout
    let columnCount: Int
    let configuration: DashboardConfiguration
    
    enum CodingKeys: String, CodingKey {
        case timeRange, activeFilters, layout, columnCount, configuration
    }
    
    // Custom encoding/decoding for enums
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode with defaults
        self.timeRange = (try? container.decode(DashboardTimeRange.self, forKey: .timeRange)) ?? .week
        self.activeFilters = (try? container.decode(Set<FilterOption>.self, forKey: .activeFilters)) ?? []
        self.layout = (try? container.decode(DashboardLayout.self, forKey: .layout)) ?? .grid
        self.columnCount = (try? container.decode(Int.self, forKey: .columnCount)) ?? 2
        self.configuration = (try? container.decode(DashboardConfiguration.self, forKey: .configuration)) ?? .default
    }
    
    init(timeRange: DashboardTimeRange, activeFilters: Set<FilterOption>, layout: DashboardLayout, columnCount: Int, configuration: DashboardConfiguration) {
        self.timeRange = timeRange
        self.activeFilters = activeFilters
        self.layout = layout
        self.columnCount = columnCount
        self.configuration = configuration
    }
}

class DashboardStateManager {
    private static let userDefaultsKey = "DashboardState"
    
    static func saveState(_ state: DashboardState) {
        if let encoded = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    static func loadState() -> DashboardState? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let state = try? JSONDecoder().decode(DashboardState.self, from: data) else {
            return nil
        }
        return state
    }
    
    static func clearState() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}

// MARK: - Interactive Dashboard Manager

@MainActor
class InteractiveDashboardManager: AnalyticsDashboardManager {
    @Published var focusedSectionId: String?
    
    override func loadSections() async {
        await super.loadSections()
        
        // Set initial focused section
        focusedSectionId = sections.first?.id
    }
}

// MARK: - Preview

struct InteractiveDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        InteractiveDashboardView()
    }
}