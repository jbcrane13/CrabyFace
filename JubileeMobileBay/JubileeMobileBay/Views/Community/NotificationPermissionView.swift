//
//  NotificationPermissionView.swift
//  JubileeMobileBay
//
//  View for requesting notification permissions
//

import SwiftUI

struct NotificationPermissionView: View {
    
    @EnvironmentObject var notificationManager: NotificationManager
    @Binding var showPermissionRequest: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding(.top)
            
            // Title
            Text("Stay Updated")
                .font(.title)
                .fontWeight(.bold)
            
            // Description
            Text("Get notified when someone replies to your comments")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Benefits list
            VStack(alignment: .leading, spacing: 12) {
                BenefitRow(
                    icon: "bubble.left.and.bubble.right",
                    text: "Real-time comment replies"
                )
                BenefitRow(
                    icon: "bell",
                    text: "Community activity alerts"
                )
                BenefitRow(
                    icon: "gearshape",
                    text: "Customizable notification preferences"
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: requestPermission) {
                    Text("Enable Notifications")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button(action: { showPermissionRequest = false }) {
                    Text("Not Now")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
    
    private func requestPermission() {
        Task {
            let granted = await notificationManager.requestNotificationPermission()
            await MainActor.run {
                showPermissionRequest = false
                if granted {
                    // Show success feedback
                    showSuccessFeedback()
                }
            }
        }
    }
    
    private func showSuccessFeedback() {
        // This could be a toast or alert
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct NotificationPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPermissionView(showPermissionRequest: .constant(true))
            .environmentObject(NotificationManager.shared)
    }
}