//
//  SyncSettingsView.swift
//  JubileeMobileBay
//
//  SwiftUI view for configuring sync settings and conflict resolution strategies
//

import SwiftUI

struct SyncSettingsView: View {
    @ObservedObject var conflictResolution: ConflictResolutionService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                conflictResolutionSection
                syncPreferencesSection
                diagnosticsSection
            }
            .navigationTitle("Sync Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var conflictResolutionSection: some View {
        Section {
            Picker("Resolution Strategy", selection: $conflictResolution.resolutionStrategy) {
                ForEach(ConflictResolutionStrategy.allCases, id: \.self) { strategy in
                    VStack(alignment: .leading) {
                        Text(strategy.displayName)
                            .font(.headline)
                        Text(strategy.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(strategy)
                }
            }
            .pickerStyle(.navigationLink)
        } header: {
            Text("Conflict Resolution")
        } footer: {
            Text("How to handle conflicts when the same data is modified on multiple devices.")
        }
    }
    
    private var syncPreferencesSection: some View {
        Section {
            HStack {
                Text("Auto Sync")
                Spacer()
                Toggle("", isOn: .constant(true))
            }
            
            HStack {
                Text("Sync on WiFi Only")
                Spacer()
                Toggle("", isOn: .constant(false))
            }
            
            HStack {
                Text("Background Sync")
                Spacer()
                Toggle("", isOn: .constant(true))
            }
        } header: {
            Text("Sync Preferences")
        } footer: {
            Text("Configure when and how data should be synchronized.")
        }
    }
    
    private var diagnosticsSection: some View {
        Section {
            NavigationLink("Sync History") {
                SyncHistoryView()
            }
            
            NavigationLink("Conflict History") {
                ConflictHistoryView(conflictResolution: conflictResolution)
            }
            
            Button("Reset Sync State") {
                // Implementation for resetting sync state
            }
            .foregroundColor(.red)
        } header: {
            Text("Diagnostics")
        } footer: {
            Text("View sync history and diagnostic information.")
        }
    }
}

// MARK: - Supporting Views

struct SyncHistoryView: View {
    var body: some View {
        List {
            Text("Sync history implementation coming soon")
        }
        .navigationTitle("Sync History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ConflictHistoryView: View {
    @ObservedObject var conflictResolution: ConflictResolutionService
    @State private var conflictHistory: [ConflictHistoryEntry] = []
    
    var body: some View {
        List(conflictHistory, id: \.uuid) { entry in
            VStack(alignment: .leading, spacing: 4) {
                Text("Entity: \(entry.entityUUID ?? "Unknown")")
                    .font(.headline)
                
                if let occurred = entry.occurredAt {
                    Text("Occurred: \(occurred, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let strategy = entry.resolutionStrategy {
                    Text("Strategy: \(strategy)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                if entry.isResolved {
                    Text("Resolved")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Pending")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Conflict History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadConflictHistory()
        }
    }
    
    private func loadConflictHistory() {
        // Implementation to load all conflict history
        // This would need a method in ConflictResolutionService
    }
}

// MARK: - Preview

struct SyncSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SyncSettingsView(conflictResolution: ConflictResolutionService())
    }
}