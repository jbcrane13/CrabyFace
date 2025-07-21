# Complete List of Files to Add to Xcode Project

This is a consolidated list of ALL files that need to be added to the Xcode project.

## Phase 1 Files (API Integration & Dashboard)

### ViewModels
- `JubileeMobileBay/ViewModels/DashboardViewModel.swift`

### Models
- `JubileeMobileBay/Models/WeatherData.swift`
- `JubileeMobileBay/Models/MarineData.swift`
- `JubileeMobileBay/Models/PredictionModels.swift`

### Services
- `JubileeMobileBay/Services/WeatherAPIService.swift`
- `JubileeMobileBay/Services/MarineDataService.swift`
- `JubileeMobileBay/Services/PredictionService.swift`

### Services/Protocols
- `JubileeMobileBay/Services/Protocols/PredictionServiceProtocol.swift`

## Previously Created Files (From Earlier Sessions)

### Services
- `JubileeMobileBay/Services/UserSessionManager.swift`
- `JubileeMobileBay/Services/CloudKitValidator.swift`
- `JubileeMobileBay/Services/CloudKitErrorRecovery.swift`
- `JubileeMobileBay/Services/PhotoUploadService.swift`

### Views
- `JubileeMobileBay/Views/PhotoPickerView.swift`

## Test Files

### Phase 1 Tests
- `JubileeMobileBayTests/Models/WeatherDataTests.swift`
- `JubileeMobileBayTests/Models/MarineDataTests.swift`
- `JubileeMobileBayTests/Models/PredictionModelsTests.swift`
- `JubileeMobileBayTests/Services/WeatherAPIServiceTests.swift`
- `JubileeMobileBayTests/Services/MarineDataServiceTests.swift`
- `JubileeMobileBayTests/Services/PredictionServiceTests.swift`
- `JubileeMobileBayTests/ViewModels/DashboardViewModelTests.swift`
- `JubileeMobileBayTests/Views/DashboardViewTests.swift`

### Previously Created Tests
- `JubileeMobileBayTests/TestHelpers/MockServices.swift`
- `JubileeMobileBayTests/ViewModels/ReportViewModelTests.swift`
- `JubileeMobileBayTests/Views/PhotoPickerViewTests.swift`

## How to Add Files to Xcode

1. Open `JubileeMobileBay.xcodeproj` in Xcode
2. For each group of files:
   - Right-click on the appropriate folder in the project navigator
   - Select "Add Files to JubileeMobileBay..."
   - Navigate to and select the files
   - **IMPORTANT**: Ensure proper target membership:
     - Files in `JubileeMobileBay/`: Check only "JubileeMobileBay" target
     - Files in `JubileeMobileBayTests/`: Check only "JubileeMobileBayTests" target
   - Ensure "Copy items if needed" is UNCHECKED (files already exist)

## Verification

After adding all files, build the project to ensure:
1. No missing file errors
2. All imports resolve correctly
3. Tests can run successfully

## Critical Dependencies

The following files are critical and referenced by multiple components:
- `UserSessionManager.swift` - Required by CloudKitService, AuthenticationService, ReportViewModel
- `DashboardViewModel.swift` - Required by DashboardView
- `PredictionService.swift` - Required by DashboardViewModel