//
//  SyncStatusView.swift
//  JubileeMobileBay
//
//  SwiftUI view for displaying sync status and managing sync operations
//

import SwiftUI
import CoreData

struct SyncStatusView: View {
    @StateObject private var syncService: CloudKitSyncService
    @StateObject private var conflictResolution: ConflictResolutionService
    @State private var showingSyncSettings = false
    @State private var showingConflictResolution = false
    @State private var pendingConflicts: [JubileeReport] = []
    
    init(syncService: CloudKitSyncService? = nil) {
        let service = syncService ?? CloudKitSyncService.shared
        _syncService = StateObject(wrappedValue: service)
        _conflictResolution = StateObject(wrappedValue: ConflictResolutionService.shared)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            syncStatusIndicator
            
            if syncService.isSyncing {
                syncProgressView
            }
            
            if !pendingConflicts.isEmpty {
                conflictAlert
            }
            
            actionButtons
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
        .onAppear {
            loadPendingConflicts()
        }
        .sheet(isPresented: $showingSyncSettings) {
            SyncSettingsView(conflictResolution: conflictResolution)
        }
        .sheet(isPresented: $showingConflictResolution) {
            ConflictResolutionView(
                conflicts: pendingConflicts,
                conflictResolution: conflictResolution
            ) {
                loadPendingConflicts()
            }
        }
    }
    
    // MARK: - View Components
    
    private var syncStatusIndicator: some View {
        HStack {
            syncStatusIcon
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Sync Status")
                    .font(.headline)
                
                Text(syncStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let lastSync = syncService.lastSyncDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Last Sync")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(lastSync, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var syncStatusIcon: some View {
        Group {
            if syncService.isSyncing {
                ProgressView()
                    .scaleEffect(0.8)
            } else if !pendingConflicts.isEmpty {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .frame(width: 24, height: 24)
    }
    
    private var syncStatusText: String {
        if syncService.isSyncing {
            return "Syncing..."
        } else if !pendingConflicts.isEmpty {
            return "\(pendingConflicts.count) conflict(s) need resolution"
        } else {
            return "Up to date"
        }
    }
    
    private var syncProgressView: some View {
        VStack(spacing: 8) {
            ProgressView(value: syncService.syncProgress.fractionCompleted) {
                HStack {
                    Text("Syncing")
                        .font(.caption)
                    
                    Spacer()
                    
                    Text("\(Int(syncService.syncProgress.completedUnitCount))/\(Int(syncService.syncProgress.totalUnitCount))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .progressViewStyle(LinearProgressViewStyle())
        }
    }
    
    private var conflictAlert: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text("\(pendingConflicts.count) sync conflict(s) require your attention")
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button("Resolve") {
                showingConflictResolution = true
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var actionButtons: some View {
        HStack {
            Button(action: manualSync) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Sync Now")
                }
            }
            .disabled(syncService.isSyncing)
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("Settings") {
                showingSyncSettings = true
            }
            .buttonStyle(.borderless)
            .foregroundColor(.blue)
        }
    }
    
    // MARK: - Actions
    
    private func manualSync() {
        Task {
            do {
                _ = try await syncService.syncPendingChanges()
                await loadPendingConflicts()
            } catch {
                print("Manual sync failed: \(error)")
                // Handle error - could show an alert
            }
        }
    }
    
    private func loadPendingConflicts() {
        Task {
            do {
                let conflicts = try await conflictResolution.getPendingManualResolutions()
                await MainActor.run {
                    pendingConflicts = conflicts
                }
            } catch {
                print("Failed to load conflicts: \(error)")
            }
        }
    }
}

// MARK: - Extensions

extension CloudKitSyncService {
    static let shared = CloudKitSyncService()
}

extension ConflictResolutionService {
    static let shared = ConflictResolutionService()
}

// MARK: - Preview

struct SyncStatusView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Normal state
            SyncStatusView()
                .previewDisplayName("Normal")
            
            // Syncing state
            SyncStatusView()
                .previewDisplayName("Syncing")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}