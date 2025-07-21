//
//  DashboardSettingsView.swift
//  JubileeMobileBay
//
//  Settings view for configuring the analytics dashboard
//

import SwiftUI

struct DashboardSettingsView: View {
    @Binding var configuration: DashboardConfiguration
    @ObservedObject var dashboardManager: AnalyticsDashboardManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var sectionOrder: [String] = []
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationView {
            Form {
                // Section Visibility
                Section {
                    ForEach(dashboardManager.sections, id: \.id) { section in
                        Toggle(isOn: Binding(
                            get: { configuration.enabledSections.contains(section.id) },
                            set: { isEnabled in
                                if isEnabled {
                                    configuration.enabledSections.insert(section.id)
                                } else {
                                    configuration.enabledSections.remove(section.id)
                                }
                                dashboardManager.updateSectionVisibility(section.id, isEnabled: isEnabled)
                            }
                        )) {
                            Label {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(section.title)
                                        .font(.body)
                                    
                                    Text(section.viewType.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: section.viewType.icon)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                } header: {
                    Text("Dashboard Sections")
                } footer: {
                    Text("Enable or disable sections to customize your dashboard view")
                }
                
                // Section Order
                Section {
                    if editMode == .active {
                        List {
                            ForEach(sectionOrder, id: \.self) { sectionId in
                                if let section = dashboardManager.sections.first(where: { $0.id == sectionId }) {
                                    HStack {
                                        Image(systemName: "line.3.horizontal")
                                            .foregroundColor(.secondary)
                                        
                                        Image(systemName: section.viewType.icon)
                                            .foregroundColor(.accentColor)
                                        
                                        Text(section.title)
                                    }
                                }
                            }
                            .onMove(perform: moveSections)
                        }
                    } else {
                        Button(action: { editMode = .active }) {
                            Label("Reorder Sections", systemImage: "arrow.up.arrow.down")
                        }
                    }
                } header: {
                    HStack {
                        Text("Section Order")
                        Spacer()
                        if editMode == .active {
                            Button("Done") {
                                editMode = .inactive
                            }
                            .font(.caption)
                        }
                    }
                }
                
                // Refresh Settings
                Section {
                    Picker("Auto Refresh", selection: $configuration.refreshInterval) {
                        Text("Off").tag(TimeInterval(0))
                        Text("1 Minute").tag(TimeInterval(60))
                        Text("5 Minutes").tag(TimeInterval(300))
                        Text("15 Minutes").tag(TimeInterval(900))
                        Text("30 Minutes").tag(TimeInterval(1800))
                        Text("1 Hour").tag(TimeInterval(3600))
                    }
                    
                    Stepper(value: $configuration.dataRetentionDays, in: 1...90) {
                        HStack {
                            Text("Data Retention")
                            Spacer()
                            Text("\(configuration.dataRetentionDays) days")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Data Settings")
                } footer: {
                    Text("Configure how often data refreshes and how long it's retained")
                }
                
                // Appearance
                Section {
                    Picker("Theme", selection: $configuration.theme) {
                        ForEach(DashboardConfiguration.DashboardTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                } header: {
                    Text("Appearance")
                }
                
                // Data Sources
                Section {
                    DataSourceToggle(source: .noaa, label: "NOAA Weather Data")
                    DataSourceToggle(source: .openWeatherMap, label: "OpenWeatherMap")
                    DataSourceToggle(source: .userSubmitted, label: "User Reports")
                    DataSourceToggle(source: .sensor, label: "IoT Sensors")
                } header: {
                    Text("Data Sources")
                } footer: {
                    Text("Select which data sources to include in analytics")
                }
                
                // Actions
                Section {
                    Button(action: clearCache) {
                        Label("Clear Cache", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    
                    Button(action: resetToDefaults) {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Dashboard Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .environment(\.editMode, $editMode)
        }
        .onAppear {
            sectionOrder = Array(configuration.sectionOrder)
        }
    }
    
    // MARK: - Actions
    
    private func moveSections(from source: IndexSet, to destination: Int) {
        sectionOrder.move(fromOffsets: source, toOffset: destination)
        configuration.sectionOrder = sectionOrder
    }
    
    private func clearCache() {
        // Implementation for clearing cache
        print("Clearing analytics cache...")
    }
    
    private func resetToDefaults() {
        configuration = DashboardConfiguration.default
        sectionOrder = Array(configuration.sectionOrder)
    }
}

// MARK: - Data Source Toggle

struct DataSourceToggle: View {
    let source: DataSource
    let label: String
    @State private var isEnabled = true
    
    var body: some View {
        Toggle(isOn: $isEnabled) {
            HStack {
                Text(label)
                Spacer()
                if !isEnabled {
                    Text("Disabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Preview

struct DashboardSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardSettingsView(
            configuration: .constant(DashboardConfiguration.default),
            dashboardManager: AnalyticsDashboardManager()
        )
    }
}