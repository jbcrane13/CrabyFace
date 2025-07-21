# Phase 3 Files to Add to Xcode Project

These files need to be added to the Xcode project for Phase 3 (Community Board - Threading & Real-time Updates).

## Instructions

1. Open JubileeMobileBay.xcodeproj in Xcode
2. Right-click on the appropriate group in the project navigator
3. Select "Add Files to JubileeMobileBay..."
4. Navigate to each file and add it
5. Ensure "JubileeMobileBay" target is checked

## Files to Add

### Models/Domain

**Group:** JubileeMobileBay/Models/Domain

- [ ] CommunityComment.swift
  - Path: JubileeMobileBay/Models/Domain/CommunityComment.swift
  - Target: JubileeMobileBay

### Views/Community

**Group:** JubileeMobileBay/Views/Community (create this group if it doesn't exist)

- [ ] CommentRowView.swift
  - Path: JubileeMobileBay/Views/Community/CommentRowView.swift
  - Target: JubileeMobileBay

- [ ] CommentThreadView.swift
  - Path: JubileeMobileBay/Views/Community/CommentThreadView.swift
  - Target: JubileeMobileBay

## Build Verification

After adding all files:
1. Clean Build Folder (Shift+Cmd+K)
2. Build (Cmd+B)
3. Run on Simulator (Cmd+R)

## Services

**Group:** JubileeMobileBay/Services

- [ ] NotificationManager.swift
  - Path: JubileeMobileBay/Services/NotificationManager.swift
  - Target: JubileeMobileBay

- [ ] AppDelegate.swift
  - Path: JubileeMobileBay/AppDelegate.swift
  - Target: JubileeMobileBay

## Views/Community (Additional)

**Group:** JubileeMobileBay/Views/Community

- [ ] NotificationPermissionView.swift
  - Path: JubileeMobileBay/Views/Community/NotificationPermissionView.swift
  - Target: JubileeMobileBay

- [ ] NotificationBadgeView.swift
  - Path: JubileeMobileBay/Views/Community/NotificationBadgeView.swift
  - Target: JubileeMobileBay

## Phase 3 Implementation Status

### Completed
- ✅ Thread data models for nested comments (CommunityComment.swift)
- ✅ Threaded comment view hierarchy (CommentRowView.swift, CommentThreadView.swift)
- ✅ Real-time updates using CloudKit subscriptions (in CloudKitService.swift)
- ✅ Comment composer with reply functionality (integrated in views)
- ✅ Moderation and reporting features (ReportView in CommentRowView.swift)
- ✅ Notification system for replies (task 6.3.5)

## Notes

- CommunityComment supports full threading with depth tracking
- CommentThreadView manages real-time subscriptions
- CloudKitService has been extended with comment methods
- Reporting functionality is built into CommentRowView