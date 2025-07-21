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

class AppDelegate: NSObject, UIApplicationDelegate {
    
    // MARK: - App Lifecycle
    
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
        let subscription = CKQuerySubscription(recordType: "PostComment",
                                             predicate: NSPredicate(value: true),
                                             options: .firesOnRecordCreation)
        subscription.notificationInfo = CKSubscription.NotificationInfo()
        subscription.notificationInfo?.shouldSendContentAvailable = true
        
        CKContainer.default().publicCloudDatabase.save(subscription) { _, error in
            if let error = error {
                print("Failed to save CloudKit subscription: \(error)")
            }
        }
    }
    
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
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Handle CloudKit notification
        if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String: Any]) {
            handleCloudKitNotification(notification, completionHandler: completionHandler)
        } else {
            completionHandler(.noData)
        }
    }
    
    // MARK: - Background Tasks
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.jubileemobilebay.model-update",
            using: nil
        ) { task in
            self.handleModelUpdateBackgroundTask(task as! BGProcessingTask)
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