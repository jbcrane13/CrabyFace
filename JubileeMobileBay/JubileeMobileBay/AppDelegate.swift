//
//  AppDelegate.swift
//  JubileeMobileBay
//
//  Handles push notification registration and remote notification processing
//

import UIKit
import CloudKit
import UserNotifications
import BackgroundTasks

/// The main application delegate responsible for handling app lifecycle events,
/// remote notifications, and background task management.
///
/// This class manages:
/// - Push notification registration and handling
/// - CloudKit subscription setup for real-time updates
/// - Background task registration for Core ML model updates
/// - Remote notification processing for sync operations
///
/// ## Dependencies
/// - `NotificationManager`: Handles notification permissions and processing
/// - `SyncManager`: Manages data synchronization with CloudKit
/// - `BackgroundSyncService`: Handles background sync operations
///
/// ## Call Flow
/// - Called by: iOS System during app launch and notification events
/// - Calls into: NotificationManager, SyncManager, BackgroundSyncService
class AppDelegate: NSObject, UIApplicationDelegate {
    
    // MARK: - App Lifecycle
    
    /// Called when the application finishes launching.
    ///
    /// This method performs initial setup including:
    /// - Configuring the notification manager
    /// - Checking notification permissions
    /// - Processing any launch notifications
    /// - Registering background tasks
    ///
    /// - Parameters:
    ///   - application: The singleton app object
    ///   - launchOptions: Launch options dictionary containing launch reason information
    /// - Returns: `true` if launch was successful
    ///
    /// ## Complexity
    /// - Time: O(1) - Constant time operations
    /// - Space: O(1) - No significant memory allocation
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Set up notification manager
        NotificationManager.shared.handleAppDelegateNotifications()
        
        // Check notification permission on launch
        Task {
            await NotificationManager.shared.checkNotificationPermission()
        }
        
        // Handle notification if app was launched from one
        if let notificationUserInfo = launchOptions?[.remoteNotification] as? [String: Any] {
            handleRemoteNotification(userInfo: notificationUserInfo)
        }
        
        // Register background tasks for Core ML model updates
        registerBackgroundTasks()
        
        return true
    }
    
    // MARK: - Remote Notifications
    
    /// Called when the app successfully registers for remote notifications.
    ///
    /// This method:
    /// 1. Broadcasts the device token to interested components via NotificationCenter
    /// 2. Creates a CloudKit subscription for new PostComment records
    ///
    /// - Parameters:
    ///   - application: The singleton app object
    ///   - deviceToken: The device token for push notifications
    ///
    /// ## Security Considerations
    /// - CRITICAL: No authentication validation before creating CloudKit subscription
    /// - Device token should be securely transmitted to backend services
    ///
    /// ## Call Flow
    /// - Broadcasts to: Components listening for `.deviceTokenReceived` notification
    /// - Creates: CloudKit subscription for PostComment record updates
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Forward to notification manager
        NotificationCenter.default.post(
            name: .deviceTokenReceived,
            object: nil,
            userInfo: ["deviceToken": deviceToken]
        )
        
        // Also register with CloudKit for subscriptions
        // TODO: Add authentication check before creating subscription
        let subscription = CKQuerySubscription(recordType: "PostComment",
                                             predicate: NSPredicate(value: true),
                                             options: .firesOnRecordCreation)
        subscription.notificationInfo = CKSubscription.NotificationInfo()
        subscription.notificationInfo?.shouldSendContentAvailable = true
        
        CKContainer.default().publicCloudDatabase.save(subscription) { _, error in
            if let error = error {
                // TODO: Implement proper error handling and logging
                print("Failed to save CloudKit subscription: \(error)")
            }
        }
    }
    
    /// Called when the app fails to register for remote notifications.
    ///
    /// Broadcasts the registration error to interested components for error handling.
    ///
    /// - Parameters:
    ///   - application: The singleton app object
    ///   - error: The error that occurred during registration
    ///
    /// ## Call Flow
    /// - Broadcasts to: Components listening for `.remoteNotificationRegistrationError` notification
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Forward to notification manager
        NotificationCenter.default.post(
            name: .remoteNotificationRegistrationError,
            object: nil,
            userInfo: ["error": error]
        )
    }
    
    /// Handles incoming remote notifications while the app is running.
    ///
    /// This method processes two types of notifications:
    /// 1. CloudKit sync notifications (identified by "ck" key)
    /// 2. Regular CloudKit notifications for data changes
    ///
    /// - Parameters:
    ///   - application: The singleton app object
    ///   - userInfo: The notification payload
    ///   - completionHandler
    
    // MARK: - Background Tasks
    
    private func registerBackgroundTasks() {
        // Model update task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.jubileemobilebay.model-update",
            using: nil
        ) { task in
            self.handleModelUpdateBackgroundTask(task as! BGProcessingTask)
        }
        
        // Sync background tasks
        let backgroundSyncService = BackgroundSyncService()
        backgroundSyncService.registerBackgroundTasks()
        
        // Schedule initial sync if enabled
        if backgroundSyncService.isBackgroundSyncEnabled {
            backgroundSyncService.scheduleNextSync()
        }
    }
    
    private func handleModelUpdateBackgroundTask(_ task: BGProcessingTask) {
        // This will be handled by the PredictionService
        // For now, just mark as completed
        task.setTaskCompleted(success: true)
    }
    
    // MARK: - CloudKit Notification Handling
    
    private func handleCloudKitNotification(
        _ notification: CKNotification,
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        guard let queryNotification = notification as? CKQueryNotification else {
            completionHandler(.noData)
            return
        }
        
        Task {
            await NotificationManager.shared.handleCloudKitNotification(queryNotification)
            completionHandler(.newData)
        }
    }
    
    private func handleRemoteNotification(userInfo: [String: Any]) {
        if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) {
            Task {
                if let queryNotification = notification as? CKQueryNotification {
                    await NotificationManager.shared.handleCloudKitNotification(queryNotification)
                }
            }
        }
    }
}