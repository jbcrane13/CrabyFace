# Files to Add to Xcode Project - Sync and Analytics

## Instructions
These files need to be added to the Xcode project. Open Xcode and add them to the appropriate groups:

### Core Data & Sync Files

1. **Core Data Models** (Add to JubileeMobileBay/Models/CoreData/)
   - `JubileeMobileBay.xcdatamodeld`
   - `CoreDataStack.swift`
   - `CoreDataMigrationManager.swift`
   - `NSManagedObjectContext+Extensions.swift`

2. **Core Data Entities** (Add to JubileeMobileBay/Models/CoreData/Entities/)
   - `JubileeObservation+CoreDataClass.swift`
   - `JubileeObservation+CoreDataProperties.swift`
   - `SpeciesObservation+CoreDataClass.swift`
   - `SpeciesObservation+CoreDataProperties.swift`
   - `EnvironmentalReading+CoreDataClass.swift`
   - `EnvironmentalReading+CoreDataProperties.swift`
   - `LocationRecord+CoreDataClass.swift`
   - `LocationRecord+CoreDataProperties.swift`
   - `UserProfile+CoreDataClass.swift`
   - `UserProfile+CoreDataProperties.swift`
   - `MediaAsset+CoreDataClass.swift`
   - `MediaAsset+CoreDataProperties.swift`
   - `SyncMetadata+CoreDataClass.swift`
   - `SyncMetadata+CoreDataProperties.swift`

3. **Sync Services** (Add to JubileeMobileBay/Services/Sync/)
   - `CloudKitSyncService.swift`
   - `BackgroundSyncService.swift`
   - `ConflictResolutionService.swift`
   - `SyncManager.swift`
   - `SyncCoordinator.swift`
   - `OfflineDataManager.swift`

4. **Protocols** (Add to JubileeMobileBay/Protocols/)
   - `SyncService.swift`
   - `SyncableEntity.swift`

### Analytics Dashboard Files

5. **Dashboard Components** (Add to JubileeMobileBay/Views/Analytics/Dashboard/)
   - `DashboardStateCodable.swift`
   - **IMPORTANT**: This file provides Codable conformance for DashboardState

6. **Analytics Services** (Add to JubileeMobileBay/Services/Analytics/)
   - `DashboardDataProvider.swift`
   - **IMPORTANT**: This file is required by InteractiveDashboardView

### Test Files

7. **Core Data Tests** (Add to JubileeMobileBayTests/Models/CoreData/)
   - `CoreDataStackTests.swift`
   - `CoreDataMigrationManagerTests.swift`
   - `JubileeObservationTests.swift`
   - `SpeciesObservationTests.swift`
   - `EnvironmentalReadingTests.swift`
   - `LocationRecordTests.swift`
   - `UserProfileTests.swift`
   - `MediaAssetTests.swift`
   - `SyncMetadataTests.swift`

8. **Sync Tests** (Add to JubileeMobileBayTests/Services/Sync/)
   - `CloudKitSyncServiceTests.swift`
   - `BackgroundSyncServiceTests.swift`
   - `ConflictResolutionServiceTests.swift`
   - `SyncManagerTests.swift`
   - `SyncCoordinatorTests.swift`
   - `OfflineDataManagerTests.swift`

## Build Settings to Update

1. Enable CloudKit capability in project settings
2. Add Background Modes capability and enable:
   - Background fetch
   - Remote notifications
   - Background processing

## Important Notes

- Make sure the .xcdatamodeld file is properly added to the "Copy Bundle Resources" build phase
- Ensure all Swift files are added to the appropriate targets (main app and test targets)
- The Core Data model file should be added to both the main app target and test target