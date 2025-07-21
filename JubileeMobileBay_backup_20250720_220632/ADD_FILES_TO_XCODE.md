# Files to Add to Xcode Project

Please add the following files to the Xcode project:

## Main App Files:

1. **Services/**
   - `AuthenticationService.swift`
   - `DemoDataService.swift`

2. **ViewModels/**
   - `AuthenticationViewModel.swift`

3. **Views/**
   - `LoginView.swift`
   - `DashboardView.swift`

## Test Files:

1. **JubileeMobileBayTests/Services/**
   - `AuthenticationServiceTests.swift`

2. **JubileeMobileBayTests/ViewModels/**
   - `AuthenticationViewModelTests.swift`

3. **JubileeMobileBayTests/Views/**
   - `LoginViewTests.swift`

## How to Add:

1. Open `JubileeMobileBay.xcodeproj` in Xcode
2. Right-click on the appropriate folder in the project navigator
3. Select "Add Files to JubileeMobileBay..."
4. Navigate to each file and add it
5. Make sure "Target Membership" is checked for:
   - Main app files → JubileeMobileBay target
   - Test files → JubileeMobileBayTests target