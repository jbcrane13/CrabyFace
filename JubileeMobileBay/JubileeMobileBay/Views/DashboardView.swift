//
//  DashboardView.swift
//  JubileeMobileBay
//
//  Dashboard showing jubilee event statistics and recent activity
//

import SwiftUI
import MapKit

struct DashboardView: View {
    @EnvironmentObject var cloudKitService: CloudKitService
    @EnvironmentObject var authenticationService: AuthenticationService
    @State private var recentEvents: [JubileeEvent] = []
    @State private var isLoading = true
    @State private var activeEventCount = 0
    @State private var showingReportView = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    welcomeHeader
                    
                    // Quick Stats
                    statsSection
                    
                    // Quick Actions
                    actionButtons
                    
                    // Recent Events
                    recentEventsSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await loadDashboardData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingReportView) {
                ReportView()
            }
            .task {
                await loadDashboardData()
            }
        }
    }
    
    // MARK: - View Components
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let user = authenticationService.currentUser {
                Text("Welcome back, \(user.displayName)!")
                    .font(.title2)
                    .fontWeight(.semibold)
            } else {
                Text("Welcome to Jubilee Mobile Bay")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Text("Monitor and report jubilee events in Mobile Bay")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Active Events",
                value: "\(activeEventCount)",
                icon: "water.waves",
                color: .blue
            )
            
            StatCard(
                title: "Reports Today",
                value: "\(todayReportCount)",
                icon: "doc.text",
                color: .green
            )
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showingReportView = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Report Jubilee Event")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            NavigationLink(destination: JubileeMapView()) {
                HStack {
                    Image(systemName: "map.fill")
                        .font(.title2)
                    Text("View Events Map")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var recentEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Events")
                .font(.headline)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if recentEvents.isEmpty {
                EmptyEventCard()
            } else {
                ForEach(recentEvents.prefix(5)) { event in
                    EventCard(event: event)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var todayReportCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return recentEvents.filter { event in
            calendar.isDate(event.startTime, inSameDayAs: today)
        }.reduce(0) { $0 + $1.reportCount }
    }
    
    // MARK: - Methods
    
    private func loadDashboardData() async {
        isLoading = true
        
        do {
            recentEvents = try await cloudKitService.fetchRecentJubileeEvents(limit: 10)
            
            // Count active events (events from the last 24 hours)
            let oneDayAgo = Date().addingTimeInterval(-24 * 60 * 60)
            activeEventCount = recentEvents.filter { $0.startTime > oneDayAgo }.count
        } catch {
            print("Error loading dashboard data: \(error)")
            
            // For development/demo: Show demo data if CloudKit fails
            if error.localizedDescription.contains("Bad Container") || 
               error.localizedDescription.contains("Network") {
                recentEvents = DemoDataService.createDemoJubileeEvents()
                let oneDayAgo = Date().addingTimeInterval(-24 * 60 * 60)
                activeEventCount = recentEvents.filter { $0.startTime > oneDayAgo }.count
            } else {
                recentEvents = []
                activeEventCount = 0
            }
        }
        
        isLoading = false
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct EventCard: View {
    let event: JubileeEvent
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.intensity.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(event.intensity.color)
                    
                    Spacer()
                    
                    Text(event.startTime, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Reports: \(event.reportCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if event.verificationStatus == .verified {
                    Label("Verified", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct EmptyEventCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "water.waves")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No recent jubilee events")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Be the first to report an event!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    DashboardView()
        .environmentObject(CloudKitService())
        .environmentObject(AuthenticationService(cloudKitService: CloudKitService()))
}