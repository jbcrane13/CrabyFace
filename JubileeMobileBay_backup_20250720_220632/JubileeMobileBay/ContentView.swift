import SwiftUI

struct ContentView: View {
    @EnvironmentObject var cloudKitService: CloudKitService
    @EnvironmentObject var authenticationService: AuthenticationService
    @State private var showingLoginSheet = false
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            JubileeMapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
            
            CommunityFeedView(cloudKitService: cloudKitService)
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


struct MapPlaceholderView: View {
    var body: some View {
        NavigationStack {
            Text("Map View - Coming Soon")
                .navigationTitle("Jubilee Events")
        }
    }
}


struct SettingsPlaceholderView: View {
    @EnvironmentObject var authenticationService: AuthenticationService
    @State private var showingLoginSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    if let user = authenticationService.currentUser {
                        AuthenticatedUserView(user: user) {
                            await authenticationService.signOut()
                        }
                    } else {
                        Button {
                            showingLoginSheet = true
                        } label: {
                            Label("Sign in with Apple", systemImage: "person.crop.circle.badge.plus")
                        }
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingLoginSheet) {
                LoginView(authenticationService: authenticationService)
            }
        }
    }
}

#Preview {
    ContentView()
}