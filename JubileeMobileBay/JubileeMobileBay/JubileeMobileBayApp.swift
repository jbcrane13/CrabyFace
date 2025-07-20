import SwiftUI

@main
struct JubileeMobileBayApp: App {
    @StateObject private var cloudKitService = CloudKitService()
    @StateObject private var authenticationService: AuthenticationService
    
    init() {
        let cloudKit = CloudKitService()
        _cloudKitService = StateObject(wrappedValue: cloudKit)
        _authenticationService = StateObject(wrappedValue: AuthenticationService(cloudKitService: cloudKit))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cloudKitService)
                .environmentObject(authenticationService)
                .task {
                    // Check if user is already authenticated on app launch
                    try? await authenticationService.checkAuthentication()
                }
        }
    }
}