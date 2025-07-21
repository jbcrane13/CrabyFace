//
//  NotificationManager.swift
//  JubileeMobileBay
//
//  Manages push notifications for comment replies and community updates
//

import Foundation
import UserNotifications
import CloudKit
import UIKit

@MainActor
class NotificationManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = NotificationManager()
    
    // MARK: - Published Properties
    
    @Published var hasNotificationPermission = false
    @Published var pendingNotificationCount = 0
    @Published var notificationBadgeCount = 0
    
    // MARK: - Properties
    
    private let userDefaults = UserDefaults.standard
    private let notificationCenter = UNUserNotificationCenter.current()
    private var notificationSettings: UNNotificationSettings?
    
    // Keys for UserDefaults
    private let hasRequestedPermissionKey = "hasRequestedNotificationPermission"
    private let deviceTokenKey = "pushNotificationDeviceToken"
    private let subscribedPostsKey = "subscribedPostIds"
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        checkNotificationPermission()
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await MainActor.run {
                self.hasNotificationPermission = granted
                self.userDefaults.set(true, forKey: hasRequestedPermissionKey)
            }
            
            if granted {
                await registerForRemoteNotifications()
            }
            
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    func checkNotificationPermission() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            await MainActor.run {
                self.notificationSettings = settings
                self.hasNotificationPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Remote Notifications
    
    @MainActor
    private func registerForRemoteNotifications() async {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func handleDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        userDefaults.set(tokenString, forKey: deviceTokenKey)
        print("Device token registered: \(tokenString)")
    }
    
    func handleRemoteNotificationRegistrationError(_ error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    // MARK: - Comment Reply Notifications
    
    func subscribeToCommentReplies(for postId: String) {
        var subscribedPosts = getSubscribedPosts()
        subscribedPosts.insert(postId)
        userDefaults.set(Array(subscribedPosts), forKey: subscribedPostsKey)
    }
    
    func unsubscribeFromCommentReplies(for postId: String) {
        var subscribedPosts = getSubscribedPosts()
        subscribedPosts.remove(postId)
        userDefaults.set(Array(subscribedPosts), forKey: subscribedPostsKey)
    }
    
    func isSubscribedToPost(_ postId: String) -> Bool {
        getSubscribedPosts().contains(postId)
    }
    
    private func getSubscribedPosts() -> Set<String> {
        Set(userDefaults.stringArray(forKey: subscribedPostsKey) ?? [])
    }
    
    // MARK: - Local Notifications
    
    func scheduleReplyNotification(
        commentId: String,
        postTitle: String,
        replierName: String,
        replyText: String
    ) async {
        guard hasNotificationPermission else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "New reply to your comment"
        content.subtitle = "In \"\(postTitle)\""
        content.body = "\(replierName): \(replyText)"
        content.sound = .default
        content.badge = NSNumber(value: notificationBadgeCount + 1)
        content.userInfo = [
            "type": "comment_reply",
            "commentId": commentId,
            "postTitle": postTitle
        ]
        
        // Create trigger for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "reply-\(commentId)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            await MainActor.run {
                self.notificationBadgeCount += 1
                self.pendingNotificationCount += 1
            }
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    // MARK: - CloudKit Notification Handling
    
    func handleCloudKitNotification(_ notification: CKQueryNotification) async {
        guard notification.notificationType == .query else { return }
        
        // Check if it's a comment notification by examining the subscription ID
        if let subscriptionID = notification.subscriptionID,
           subscriptionID.hasPrefix("comment-subscription-") {
            await handleCommentNotification(notification)
        }
    }
    
    private func handleCommentNotification(_ notification: CKQueryNotification) async {
        guard let recordFields = notification.recordFields,
              let postId = recordFields["postId"] as? String,
              let parentCommentId = recordFields["parentCommentId"] as? String,
              !parentCommentId.isEmpty else {
            return
        }
        
        // Check if user is subscribed to this post
        guard isSubscribedToPost(postId) else { return }
        
        // Get current user ID
        guard let currentUserId = UserSessionManager.shared.currentUser?.id else { return }
        
        // Check if this is a reply to user's comment
        if let commentUserId = recordFields["userId"] as? String,
           commentUserId != currentUserId {
            // This is a reply from someone else
            let userName = recordFields["userName"] as? String ?? "Someone"
            let text = recordFields["text"] as? String ?? "replied to your comment"
            let postTitle = recordFields["postTitle"] as? String ?? "a post"
            
            await scheduleReplyNotification(
                commentId: parentCommentId,
                postTitle: postTitle,
                replierName: userName,
                replyText: String(text.prefix(100))
            )
        }
    }
    
    // MARK: - Badge Management
    
    func clearBadge() {
        Task {
            await MainActor.run {
                self.notificationBadgeCount = 0
                self.pendingNotificationCount = 0
            }
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    func decrementBadge() {
        Task {
            await MainActor.run {
                if self.notificationBadgeCount > 0 {
                    self.notificationBadgeCount -= 1
                }
                if self.pendingNotificationCount > 0 {
                    self.pendingNotificationCount -= 1
                }
            }
            UIApplication.shared.applicationIconBadgeNumber = notificationBadgeCount
        }
    }
    
    // MARK: - Notification Content
    
    func processNotificationResponse(_ response: UNNotificationResponse) -> NotificationAction? {
        let userInfo = response.notification.request.content.userInfo
        
        guard let type = userInfo["type"] as? String else { return nil }
        
        switch type {
        case "comment_reply":
            if let commentId = userInfo["commentId"] as? String {
                return .openComment(commentId: commentId)
            }
        default:
            break
        }
        
        return nil
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.banner, .sound, .badge]
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        if let action = processNotificationResponse(response) {
            await handleNotificationAction(action)
        }
    }
    
    private func handleNotificationAction(_ action: NotificationAction) async {
        // Post notification to handle navigation
        await MainActor.run {
            NotificationCenter.default.post(
                name: .handleNotificationAction,
                object: nil,
                userInfo: ["action": action]
            )
        }
    }
}

// MARK: - Notification Action

enum NotificationAction {
    case openComment(commentId: String)
    case openPost(postId: String)
    case openProfile(userId: String)
}

// MARK: - Notification Names

extension Notification.Name {
    static let handleNotificationAction = Notification.Name("handleNotificationAction")
}

// MARK: - App Delegate Extension

extension NotificationManager {
    func handleAppDelegateNotifications() {
        // This would be called from AppDelegate or SwiftUI App lifecycle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeviceTokenNotification(_:)),
            name: .deviceTokenReceived,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRegistrationErrorNotification(_:)),
            name: .remoteNotificationRegistrationError,
            object: nil
        )
    }
    
    @objc private func handleDeviceTokenNotification(_ notification: Notification) {
        if let deviceToken = notification.userInfo?["deviceToken"] as? Data {
            handleDeviceToken(deviceToken)
        }
    }
    
    @objc private func handleRegistrationErrorNotification(_ notification: Notification) {
        if let error = notification.userInfo?["error"] as? Error {
            handleRemoteNotificationRegistrationError(error)
        }
    }
}

// MARK: - Additional Notification Names

extension Notification.Name {
    static let deviceTokenReceived = Notification.Name("deviceTokenReceived")
    static let remoteNotificationRegistrationError = Notification.Name("remoteNotificationRegistrationError")
}