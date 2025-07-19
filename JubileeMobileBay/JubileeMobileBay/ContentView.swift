import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            MapPlaceholderView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
            
            CommunityPlaceholderView()
                .tabItem {
                    Label("Community", systemImage: "person.3.fill")
                }
            
            SettingsPlaceholderView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "water.waves")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding()
                
                Text("Welcome to Jubilee Mobile Bay")
                    .font(.title)
                    .multilineTextAlignment(.center)
                
                Text("Monitor and predict jubilee events")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
            .padding()
            .navigationTitle("Dashboard")
        }
    }
}

struct MapPlaceholderView: View {
    var body: some View {
        NavigationStack {
            Text("Map View - Coming Soon")
                .navigationTitle("Jubilee Events")
        }
    }
}

struct CommunityPlaceholderView: View {
    var body: some View {
        NavigationStack {
            Text("Community Feed - Coming Soon")
                .navigationTitle("Community Reports")
        }
    }
}

struct SettingsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            Text("Settings - Coming Soon")
                .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
}