//
//  NotificationBadgeView.swift
//  JubileeMobileBay
//
//  Badge view for showing notification status and count
//

import SwiftUI

struct NotificationBadgeView: View {
    
    @EnvironmentObject var notificationManager: NotificationManager
    let showCount: Bool
    
    init(showCount: Bool = true) {
        self.showCount = showCount
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: notificationManager.hasNotificationPermission ? "bell.fill" : "bell.slash.fill")
                .font(.system(size: 16))
                .foregroundColor(notificationManager.hasNotificationPermission ? .blue : .gray)
            
            if showCount && notificationManager.pendingNotificationCount > 0 {
                Text("\(notificationManager.pendingNotificationCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .clipShape(Capsule())
            }
        }
    }
}

struct NotificationStatusView: View {
    
    @EnvironmentObject var notificationManager: NotificationManager
    let postId: String
    
    var body: some View {
        HStack {
            if notificationManager.hasNotificationPermission &&
               notificationManager.isSubscribedToPost(postId) {
                Label("Notifications On", systemImage: "bell.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Label("Notifications Off", systemImage: "bell.slash")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct NotificationBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            NotificationBadgeView()
                .environmentObject(NotificationManager.shared)
            
            NotificationStatusView(postId: "test-post")
                .environmentObject(NotificationManager.shared)
        }
        .padding()
    }
}