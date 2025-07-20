# Files to Add to Xcode Project - UPDATED

## New Files Created During Code Review Implementation:

### Main App Files:

1. **Services/**
   - `UserSessionManager.swift` (NEW - Critical for user tracking)
   - `CloudKitValidator.swift` (NEW - Input validation)
   - `CloudKitErrorRecovery.swift` (NEW - Retry logic)
   - `PhotoUploadService.swift` (NEW - Photo handling)

2. **Views/**
   - `PhotoPickerView.swift` (NEW - Photo selection UI)

### Test Files:

1. **JubileeMobileBayTests/TestHelpers/**
   - `MockServices.swift` (NEW - Mock implementations)

2. **JubileeMobileBayTests/ViewModels/**
   - `ReportViewModelTests.swift` (NEW - ViewModel tests)

3. **JubileeMobileBayTests/Views/**
   - `PhotoPickerViewTests.swift` (NEW - View tests)

## Modified Files (Already in Project):

- `Services/CloudKitService.swift` (Modified)
- `Services/AuthenticationService.swift` (Modified)
- `JubileeMobileBayApp.swift` (Modified)
- `ViewModels/ReportViewModel.swift` (Modified)

## How to Add:

1. Open `JubileeMobileBay.xcodeproj` in Xcode
2. Right-click on the appropriate folder in the project navigator
3. Select "Add Files to JubileeMobileBay..."
4. Navigate to each file and add it
5. **IMPORTANT**: Make sure "Target Membership" is checked for:
   - Main app files → JubileeMobileBay target
   - Test files → JubileeMobileBayTests target

## Critical Files for App to Function:

The most critical file is `UserSessionManager.swift` as it's referenced by:
- CloudKitService
- AuthenticationService
- ReportViewModel

Without this file, the app cannot compile.