# Create New Xcode Project - Clean Slate Approach

Given the 60+ duplicate file references, creating a new project is the cleanest solution.

## Step 1: Create New Project

1. Open Xcode
2. File → New → Project
3. Choose iOS → App
4. Configure:
   - Product Name: JubileeMobileBay
   - Team: (your team)
   - Organization Identifier: com.jubileemobilebay
   - Bundle Identifier: com.jubileemobilebay.app
   - Interface: SwiftUI
   - Language: Swift
   - Use Core Data: NO
   - Include Tests: YES
5. Save in a temporary location (e.g., Desktop/JubileeMobileBayNew)

## Step 2: Copy Configuration Files

```bash
# From old project to new project
cp JubileeMobileBay/Info.plist JubileeMobileBayNew/JubileeMobileBay/
cp JubileeMobileBay/JubileeMobileBay.entitlements JubileeMobileBayNew/JubileeMobileBay/
cp -r JubileeMobileBay/Assets.xcassets JubileeMobileBayNew/JubileeMobileBay/
```

## Step 3: Add All Swift Files

In Xcode with the new project open:

### Models
1. Right-click on JubileeMobileBay folder → New Group → "Models"
2. Right-click Models → Add Files to "JubileeMobileBay"
3. Navigate to old project's Models folder
4. Select all .swift files (NOT .gitkeep)
5. Ensure "Copy items if needed" is UNCHECKED
6. Ensure target membership is checked for JubileeMobileBay

### ViewModels
1. Create ViewModels group
2. Add all .swift files from ViewModels/
3. Don't add .gitkeep files

### Views
1. Create Views group
2. Add all .swift files from Views/
3. Create subgroups as needed (Map, Components, etc.)

### Services
1. Create Services group
2. Create Services/Protocols subgroup
3. Add all service .swift files to Services
4. Add all protocol .swift files to Services/Protocols

### Repeat for:
- Utilities
- Resources
- Any other folders with Swift files

### Test Files
1. Select JubileeMobileBayTests target
2. Add all test .swift files
3. Ensure target membership is JubileeMobileBayTests (not main app)

## Step 4: Configure Build Settings

1. Select project → JubileeMobileBay target
2. Build Settings → Swift Compiler - Language → Swift Language Version: 5
3. Signing & Capabilities → Add CloudKit capability
4. Info → Add required privacy descriptions:
   - Privacy - Location When In Use Usage Description
   - Privacy - Camera Usage Description
   - Privacy - Photo Library Usage Description

## Step 5: Replace Old Project

```bash
# Backup old project
mv JubileeMobileBay JubileeMobileBay_backup

# Move new project to correct location
mv JubileeMobileBayNew JubileeMobileBay

# Copy git history
cp -r JubileeMobileBay_backup/.git JubileeMobileBay/
```

## Step 6: Verify

1. Open new project
2. Build (⌘B)
3. Run tests (⌘U)
4. Run on simulator (⌘R)

## Files to Add by Category

### Main App Files
- JubileeMobileBayApp.swift
- ContentView.swift

### Models/Domain
- CommunityPost.swift
- EnvironmentalData.swift
- JubileeEvent.swift
- JubileeMetadata.swift
- MarineLifeType.swift
- PhotoItem.swift
- PhotoReference.swift
- TimeRange.swift
- UserReport.swift
- WeatherData.swift
- MarineData.swift
- PredictionModels.swift

### Models/Enums
- JubileeEnums.swift

### Models/DTOs
- EventAnnotation.swift

### ViewModels
- AuthenticationViewModel.swift
- CommunityFeedViewModel.swift
- DashboardViewModel.swift
- MapViewModel.swift
- ReportViewModel.swift

### Views
- CommunityFeedView.swift
- DashboardView.swift
- LoginView.swift
- PhotoPickerView.swift
- ReportView.swift

### Views/Map
- JubileeMapView.swift

### Services
- AuthenticationService.swift
- CloudKitErrorRecovery.swift
- CloudKitSchemaSetup.swift
- CloudKitService.swift
- CloudKitValidator.swift
- DemoDataService.swift
- EventService.swift
- LocationAccuracy.swift
- LocationService.swift
- LocationServiceProtocol.swift
- MarineDataService.swift
- PhotoUploadService.swift
- PredictionService.swift
- UserSessionManager.swift
- WeatherAPIService.swift

### Services/Protocols
- CloudKitServiceProtocol.swift
- MarineDataProtocol.swift
- PredictionServiceProtocol.swift
- URLSessionProtocol.swift
- WeatherAPIProtocol.swift

### Utilities/Extensions
- Color+Hex.swift

### Test Files
- CloudKitServiceTests.swift
- CommunityPostTests.swift
- EnvironmentalDataTests.swift
- JubileeEventTests.swift
- LocationServiceTests.swift
- MapViewModelTests.swift
- MarineDataServiceTests.swift
- MarineDataTests.swift
- MockServices.swift
- PhotoPickerViewTests.swift
- PredictionServiceTests.swift
- ReportViewModelTests.swift
- ReportViewTests.swift
- UserReportTests.swift
- WeatherAPIServiceTests.swift
- WeatherDataTests.swift

## Benefits

1. Clean project structure with no duplicates
2. Xcode properly tracks all files
3. No manual duplicate removal needed
4. Fresh build settings
5. Guaranteed to work

This approach takes about 30 minutes but results in a clean, working project.