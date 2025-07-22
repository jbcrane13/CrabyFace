import SwiftUI
import CloudKit

@main
struct JubileeMobileBayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var cloudKitService: CloudKitService
    @StateObject private var authenticationService: AuthenticationService
    @StateObject private var notificationManager = NotificationManager.shared
    
    let coreDataStack = CoreDataStack.shared
    
    init() {
        let cloudKit = CloudKitService()
        _cloudKitService = StateObject(wrappedValue: cloudKit)
        _authenticationService = StateObject(wrappedValue: AuthenticationService(cloudKitService: cloudKit))
        
        // Perform any necessary Core Data migrations
        CoreDataMigrationManager.performMigrationsIfNeeded(for: coreDataStack.persistentContainer)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cloudKitService)
                .environmentObject(authenticationService)
                .environmentObject(notificationManager)
                .environment(\.managedObjectContext, coreDataStack.viewContext)
                .task {
                    // Check if user is already authenticated on app launch
                    try? await authenticationService.checkAuthentication()
                }
                .onReceive(NotificationCenter.default.publisher(for: .handleNotificationAction)) { notification in
                    if let action = notification.userInfo?["action"] as? NotificationAction {
                        handleNotificationAction(action)
                    }
                }
        }
    }
    
    private func handleNotificationAction(_ action: NotificationAction) {
        // Handle navigation based on notification action
        switch action {
        case .openComment(let commentId):
            // Navigate to comment
            // This would typically update a navigation state that ContentView observes
            print("Navigate to comment: \(commentId)")
        case .openPost(let postId):
            // Navigate to post
            print("Navigate to post: \(postId)")
        case .openProfile(let userId):
            // Navigate to profile
            print("Navigate to profile: \(userId)")
        }
    }
}