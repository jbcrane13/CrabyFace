//
//  AnalyticsDashboard.swift
//  JubileeMobileBay
//
//  Main analytics dashboard with modular section management
//

import SwiftUI

struct AnalyticsDashboard: View {
    @StateObject private var dashboardManager = AnalyticsDashboardManager()
    @State private var configuration = DashboardConfiguration.default
    @State private var showingSettings = false
    @State private var selectedSection: String?
    @State private var isEditMode = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ChartTheme.sectionSpacing) {
                    // Dashboard Header
                    dashboardHeader
                    
                    // Dynamic Sections
                    ForEach(orderedSections, id: \.id) { section in
                        if section.isEnabled && section.hasData() {
                            sectionContainer(for: section)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }
                    
                    // Empty State
                    if enabledSections.isEmpty {
                        emptyStateView
                    }
                }
                .padding(.vertical)
                .animation(.spring(), value: configuration.enabledSections)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Analytics Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { isEditMode.toggle() }) {
                            Label(isEditMode ? "Done Editing" : "Edit Dashboard",
                                  systemImage: isEditMode ? "checkmark" : "square.and.pencil")
                        }
                        
                        Button(action: { showingSettings.toggle() }) {
                            Label("Settings", systemImage: "gear")
                        }
                        
                        Button(action: refreshDashboard) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                DashboardSettingsView(
                    configuration: $configuration,
                    dashboardManager: dashboardManager
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            await dashboardManager.loadSections()
        }
    }
    
    // MARK: - Components
    
    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Analytics Overview")
                        .font(.largeTitle.weight(.bold))
                    
                    Text("Last updated: \(dashboardManager.lastUpdated, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if dashboardManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if isEditMode {
                editModeInstructions
            }
        }
        .padding(.horizontal)
    }
    
    private var editModeInstructions: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
            
            Text("Tap sections to enable/disable. Drag to reorder.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func sectionContainer(for section: AnalyticsDashboardSection) -> some View {
        VStack(spacing: 0) {
            if isEditMode {
                editableSectionHeader(for: section)
            }
            
            section.createView()
                .opacity(isEditMode ? 0.6 : 1.0)
                .disabled(isEditMode)
                .onTapGesture {
                    if isEditMode {
                        toggleSection(section)
                    } else {
                        selectedSection = section.id
                    }
                }
        }
        .overlay(
            Group {
                if isEditMode && !section.isEnabled {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.5))
                        .overlay(
                            Text("Disabled")
                                .font(.headline)
                                .foregroundColor(.white)
                        )
                }
            }
        )
        .scaleEffect(selectedSection == section.id ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: selectedSection)
    }
    
    private func editableSectionHeader(for section: AnalyticsDashboardSection) -> some View {
        HStack {
            Image(systemName: section.viewType.icon)
                .foregroundColor(.accentColor)
            
            Text(section.title)
                .font(.headline)
            
            Spacer()
            
            Toggle("", isOn: .constant(section.isEnabled))
                .labelsHidden()
                .scaleEffect(0.8)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Dashboard Sections Enabled")
                .font(.title2.weight(.semibold))
            
            Text("Enable sections in settings to see analytics")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingSettings.toggle() }) {
                Label("Configure Dashboard", systemImage: "gear")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 400)
    }
    
    // MARK: - Computed Properties
    
    private var orderedSections: [AnalyticsDashboardSection] {
        let sections = dashboardManager.sections
        return configuration.sectionOrder.compactMap { id in
            sections.first(where: { $0.id == id })
        }
    }
    
    private var enabledSections: [AnalyticsDashboardSection] {
        orderedSections.filter { $0.isEnabled }
    }
    
    // MARK: - Actions
    
    private func toggleSection(_ section: AnalyticsDashboardSection) {
        withAnimation {
            if configuration.enabledSections.contains(section.id) {
                configuration.enabledSections.remove(section.id)
            } else {
                configuration.enabledSections.insert(section.id)
            }
            dashboardManager.updateSectionVisibility(section.id, isEnabled: configuration.enabledSections.contains(section.id))
        }
    }
    
    private func refreshDashboard() {
        Task {
            await dashboardManager.refreshAllSections()
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Dashboard Manager

@MainActor
class AnalyticsDashboardManager: ObservableObject {
    @Published var sections: [AnalyticsDashboardSection] = []
    @Published var lastUpdated = Date()
    @Published var isLoading = false
    @Published var error: Error?
    
    func loadSections() async {
        isLoading = true
        sections = DashboardSectionFactory.createDefaultSections()
        
        await refreshAllSections()
        isLoading = false
    }
    
    func refreshAllSections() async {
        await withTaskGroup(of: Void.self) { group in
            for section in sections where section.isEnabled {
                group.addTask {
                    try? await section.refreshData()
                }
            }
        }
        lastUpdated = Date()
    }
    
    func updateSectionVisibility(_ sectionId: String, isEnabled: Bool) {
        if let index = sections.firstIndex(where: { $0.id == sectionId }) {
            sections[index].isEnabled = isEnabled
        }
    }
}

// MARK: - Preview

struct AnalyticsDashboard_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsDashboard()
    }
}