# Complete List of Files to Add to Xcode Project

## Overview
This document contains a complete list of all files that need to be manually added to the Xcode project. Files are organized by feature/task.

## Task 1: Core ML Integration Files

### Models/ML Group
1. **JubileePredictor.mlmodel**
   - Path: `JubileeMobileBay/Models/ML/JubileePredictor.mlmodel`
   - Description: Core ML model for jubilee prediction (placeholder)
   - Target: JubileeMobileBay
   - **NOTE**: Xcode will compile this to .mlmodelc format automatically

2. **JubileePredictorWrapper.swift**
   - Path: `JubileeMobileBay/Models/ML/JubileePredictorWrapper.swift`
   - Description: Wrapper class that provides the expected interface with both outputs
   - Target: JubileeMobileBay

## Task 3: Core Data & Sync Files

### Models/CoreData Group
Create a new group called "CoreData" under Models, then add:

3. **CoreDataStack.swift**
   - Path: `JubileeMobileBay/Models/CoreData/CoreDataStack.swift`
   - Description: Core Data stack with CloudKit integration
   - Target: JubileeMobileBay

4. **CoreDataModelBuilder.swift**
   - Path: `JubileeMobileBay/Models/CoreData/CoreDataModelBuilder.swift`
   - Description: Programmatic Core Data model creation
   - Target: JubileeMobileBay

5. **CoreDataMigrationManager.swift**
   - Path: `JubileeMobileBay/Models/CoreData/CoreDataMigrationManager.swift`
   - Description: Handles Core Data migrations
   - Target: JubileeMobileBay

6. **JubileeReport+CoreDataClass.swift**
   - Path: `JubileeMobileBay/Models/CoreData/JubileeReport+CoreDataClass.swift`
   - Description: NSManagedObject subclass for JubileeReport
   - Target: JubileeMobileBay

7. **JubileeReport+CoreDataProperties.swift**
   - Path: `JubileeMobileBay/Models/CoreData/JubileeReport+CoreDataProperties.swift`
   - Description: Properties extension for JubileeReport
   - Target: JubileeMobileBay

8. **ConflictHistoryEntry+CoreDataClass.swift**
   - Path: `JubileeMobileBay/Models/CoreData/ConflictHistoryEntry+CoreDataClass.swift`
   - Description: NSManagedObject subclass for ConflictHistoryEntry
   - Target: JubileeMobileBay

9. **ConflictHistoryEntry+CoreDataProperties.swift**
   - Path: `JubileeMobileBay/Models/CoreData/ConflictHistoryEntry+CoreDataProperties.swift`
   - Description: Properties extension for ConflictHistoryEntry
   - Target: JubileeMobileBay

### Protocols Group
Add to existing Protocols group:

10. **SyncableEntity.swift**
    - Path: `JubileeMobileBay/Protocols/SyncableEntity.swift`
    - Description: Protocol for syncable Core Data entities
    - Target: JubileeMobileBay

11. **SyncService.swift**
    - Path: `JubileeMobileBay/Protocols/SyncService.swift`
    - Description: Protocol defining synchronization service capabilities
    - Target: JubileeMobileBay

### Services/Sync Group
Create a new group called "Sync" under Services, then add:

12. **CloudKitSyncService.swift**
    - Path: `JubileeMobileBay/Services/Sync/CloudKitSyncService.swift`
    - Description: CloudKit implementation of the SyncService protocol
    - Target: JubileeMobileBay

13. **SyncManager.swift**
    - Path: `JubileeMobileBay/Services/Sync/SyncManager.swift`
    - Description: Singleton manager for coordinating sync operations
    - Target: JubileeMobileBay

14. **BackgroundSyncService.swift**
    - Path: `JubileeMobileBay/Services/Sync/BackgroundSyncService.swift`
    - Description: Handles background sync using iOS Background Tasks
    - Target: JubileeMobileBay

15. **ConflictResolutionService.swift**
    - Path: `JubileeMobileBay/Services/Sync/ConflictResolutionService.swift`
    - Description: Service for detecting and resolving sync conflicts
    - Target: JubileeMobileBay

### Views/Components Group
Create a new group called "Components" under Views if it doesn't exist, then add:

16. **SyncStatusView.swift**
    - Path: `JubileeMobileBay/Views/Components/SyncStatusView.swift`
    - Description: SwiftUI view for displaying sync status
    - Target: JubileeMobileBay

17. **SyncSettingsView.swift**
    - Path: `JubileeMobileBay/Views/Components/SyncSettingsView.swift`
    - Description: SwiftUI view for configuring sync settings
    - Target: JubileeMobileBay

18. **ConflictResolutionView.swift**
    - Path: `JubileeMobileBay/Views/Components/ConflictResolutionView.swift`
    - Description: SwiftUI view for manual conflict resolution
    - Target: JubileeMobileBay

### Test Files
Create appropriate group structure in JubileeMobileBayTests:

19. **JubileeReportTests.swift**
    - Path: `JubileeMobileBayTests/Models/CoreData/JubileeReportTests.swift`
    - Description: Unit tests for JubileeReport entity
    - Target: JubileeMobileBayTests

20. **CloudKitSyncServiceTests.swift**
    - Path: `JubileeMobileBayTests/Services/Sync/CloudKitSyncServiceTests.swift`
    - Description: Unit tests for CloudKit sync service
    - Target: JubileeMobileBayTests

21. **SyncManagerTests.swift**
    - Path: `JubileeMobileBayTests/Services/Sync/SyncManagerTests.swift`
    - Description: Unit tests for sync coordination and management
    - Target: JubileeMobileBayTests

22. **BackgroundSyncServiceTests.swift**
    - Path: `JubileeMobileBayTests/Services/Sync/BackgroundSyncServiceTests.swift`
    - Description: Unit tests for background sync functionality
    - Target: JubileeMobileBayTests

23. **ConflictResolutionServiceTests.swift**
    - Path: `JubileeMobileBayTests/Services/Sync/ConflictResolutionServiceTests.swift`
    - Description: Unit tests for conflict resolution functionality
    - Target: JubileeMobileBayTests

## Required Project Configuration

### 1. Capabilities
Make sure these capabilities are enabled in your app:

1. **CloudKit**
   - Go to Signing & Capabilities
   - Add CloudKit capability if not already present
   - Ensure the container "iCloud.com.jubileemobilebay.app" is selected

2. **Background Modes**
   - Background fetch
   - Remote notifications

### 2. Entitlements
The `JubileeMobileBay.entitlements` file should already be added to your project. If not:
1. Go to project settings → Target → Signing & Capabilities
2. The entitlements file should be automatically selected
3. If not visible, look for "Code Signing Entitlements" in Build Settings

### 3. Info.plist Updates
Ensure these entries exist in Info.plist:
- Background task identifiers (BGTaskSchedulerPermittedIdentifiers)
- Background modes (UIBackgroundModes)

## How to Add Files to Xcode

1. Open `JubileeMobileBay.xcodeproj` in Xcode
2. Right-click on the appropriate group in the project navigator
3. Select "Add Files to JubileeMobileBay..."
4. Navigate to each file and add it to the project
5. **IMPORTANT**: Ensure "Copy items if needed" is UNCHECKED (files are already in place)
6. Ensure the correct target membership is selected
7. Click "Add"

## Build and Test

After adding all files:
1. Clean the build folder (Cmd+Shift+K)
2. Build the project (Cmd+B)
3. Run the test suite (Cmd+U)
4. Fix any remaining import or reference issues

## Notes
- The Core Data model is created programmatically, no .xcdatamodeld file is needed
- The Core ML model will be compiled automatically by Xcode
- All sync functionality requires active CloudKit entitlements
- Background tasks require proper Info.plist configuration