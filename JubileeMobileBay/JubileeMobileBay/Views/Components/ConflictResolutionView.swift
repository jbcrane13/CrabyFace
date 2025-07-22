//
//  ConflictResolutionView.swift
//  JubileeMobileBay
//
//  SwiftUI view for manually resolving sync conflicts
//

import SwiftUI
import CoreData

struct ConflictResolutionView: View {
    let conflicts: [JubileeReport]
    @ObservedObject var conflictResolution: ConflictResolutionService
    let onResolved: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedConflictIndex = 0
    
    var body: some View {
        NavigationView {
            VStack {
                if conflicts.isEmpty {
                    emptyStateView
                } else {
                    conflictResolutionInterface
                }
            }
            .navigationTitle("Resolve Conflicts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onResolved()
                        dismiss()
                    }
                    .disabled(!conflicts.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("All Conflicts Resolved")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("There are no sync conflicts that need manual resolution.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var conflictResolutionInterface: some View {
        VStack {
            // Conflict selector
            if conflicts.count > 1 {
                Picker("Select Conflict", selection: $selectedConflictIndex) {
                    ForEach(0..<conflicts.count, id: \.self) { index in
                        Text("Conflict \(index + 1)")
                    }
                }
                .pickerStyle(.segmented)
                .padding()
            }
            
            // Current conflict details
            ScrollView {
                ConflictDetailView(
                    report: conflicts[selectedConflictIndex],
                    conflictResolution: conflictResolution
                ) {
                    // Refresh conflicts after resolution
                    onResolved()
                }
            }
        }
    }
}

struct ConflictDetailView: View {
    let report: JubileeReport
    @ObservedObject var conflictResolution: ConflictResolutionService
    let onResolved: () -> Void
    
    @State private var selectedResolution: ConflictResolution?
    @State private var isResolving = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            conflictInfoSection
            
            Divider()
            
            resolutionOptionsSection
            
            Divider()
            
            actionSection
        }
        .padding()
    }
    
    private var conflictInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Conflict Details")
                .font(.headline)
            
            if let uuid = report.uuid {
                DetailRow(label: "Report ID", value: String(uuid.prefix(8)))
            }
            
            if let timestamp = report.timestamp {
                DetailRow(label: "Timestamp", value: timestamp.formatted())
            }
            
            if let modified = report.lastModified {
                DetailRow(label: "Last Modified", value: modified.formatted())
            }
            
            DetailRow(label: "Species", value: report.speciesArray.joined(separator: ", "))
            
            if let intensity = report.intensity {
                DetailRow(label: "Intensity", value: intensity)
            }
            
            if let notes = report.notes, !notes.isEmpty {
                DetailRow(label: "Notes", value: notes)
            }
        }
    }
    
    private var resolutionOptionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resolution Options")
                .font(.headline)
            
            Button("Keep Local Version") {
                selectedResolution = .useLocal
            }
            .buttonStyle(.bordered)
            .foregroundColor(selectedResolution == .useLocal ? .white : .primary)
            .background(selectedResolution == .useLocal ? Color.blue : Color.clear)
            .cornerRadius(8)
            
            Button("Use Remote Version") {
                selectedResolution = .useRemote
            }
            .buttonStyle(.bordered)
            .foregroundColor(selectedResolution == .useRemote ? .white : .primary)
            .background(selectedResolution == .useRemote ? Color.blue : Color.clear)
            .cornerRadius(8)
            
            Button("Auto-Merge") {
                autoResolveConflict()
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var actionSection: some View {
        VStack {
            if let resolution = selectedResolution {
                Button("Apply Resolution") {
                    applyResolution(resolution)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isResolving)
            }
            
            if isResolving {
                ProgressView("Resolving...")
                    .padding(.top)
            }
        }
    }
    
    // MARK: - Actions
    
    private func autoResolveConflict() {
        isResolving = true
        
        Task {
            do {
                let resolution = try await conflictResolution.resolveConflict(
                    entity: report,
                    localVersion: report,
                    remoteVersion: report // This would need the actual remote version
                )
                
                await MainActor.run {
                    selectedResolution = resolution
                    isResolving = false
                }
                
                // Auto-apply the resolution
                applyResolution(resolution)
                
            } catch {
                await MainActor.run {
                    isResolving = false
                }
                print("Auto-resolution failed: \(error)")
            }
        }
    }
    
    private func applyResolution(_ resolution: ConflictResolution) {
        isResolving = true
        
        Task {
            do {
                // Apply the resolution
                switch resolution {
                case .useLocal, .useRemote:
                    report.resolveConflict()
                case .merge(let merged):
                    if let mergedReport = merged as? JubileeReport {
                        // Apply merged data
                        report.speciesArray = mergedReport.speciesArray
                        report.intensity = mergedReport.intensity
                        report.notes = mergedReport.notes
                        report.locationCoordinate = mergedReport.locationCoordinate
                        report.environmentalConditionsDict = mergedReport.environmentalConditionsDict
                        report.resolveConflict()
                    }
                case .manual:
                    break // Keep as manual
                }
                
                // Save the context
                if report.managedObjectContext?.hasChanges == true {
                    try report.managedObjectContext?.save()
                }
                
                await MainActor.run {
                    isResolving = false
                    onResolved()
                }
                
            } catch {
                await MainActor.run {
                    isResolving = false
                }
                print("Failed to apply resolution: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.body)
        }
    }
}

// MARK: - Preview

struct ConflictResolutionView_Previews: PreviewProvider {
    static var previews: some View {
        ConflictResolutionView(
            conflicts: [],
            conflictResolution: ConflictResolutionService()
        ) {
            // Preview action
        }
    }
}