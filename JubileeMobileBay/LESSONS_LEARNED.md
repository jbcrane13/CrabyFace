# Lessons Learned - JubileeMobileBay

## Build Error Solutions

### 1. JubileePredictorWrapper Type Errors
**Problem**: Types like `JubileePredictorWrapper` were undefined because files had `.disabled` extension.
**Solution**: 
- Rename files from `.swift.disabled` to `.swift`
- Add renamed files to Xcode project's Compile Sources build phase
- User must manually add file in Xcode after renaming

### 2. Missing Framework Imports
**Problem**: `CLLocationCoordinate2D` undefined, `UIApplication` not found
**Solution**:
```swift
import CoreLocation  // For CLLocationCoordinate2D
import UIKit        // For UIApplication, UIDevice
```

### 3. Actor Isolation Errors
**Problem**: "Main actor-isolated property can not be referenced from a nonisolated context"
**Solution**:
- Add `@MainActor` to classes that access main actor properties
- Use `await MainActor.run { }` for async contexts
- Example:
```swift
@MainActor
class BackgroundSyncNetworkMonitor {
    var isConnected: Bool {
        return SyncManager.shared.networkStatus != .disconnected
    }
}
```

### 4. Async/Await in Core Data Contexts
**Problem**: Cannot use async/await inside synchronous `context.perform` blocks
**Solution**: Use `withCheckedThrowingContinuation`:
```swift
return try await withCheckedThrowingContinuation { continuation in
    context.perform {
        do {
            // Your Core Data operations
            continuation.resume(returning: result)
        } catch {
            continuation.resume(throwing: error)
        }
    }
}
```

### 5. Charts Framework API Changes
**Problem**: ChartLegend extra parameters, chartAngleSelection not available, ChartProxy API changes
**Solution**:
- Remove `orientation` parameter from ChartLegend
- Remove `chartAngleSelection` modifier completely
- Use `chartProxy.value(atX:as:)` instead of `chartProxy.value(at:)`
- Use `chartProxy.position(forX:)` which returns CGFloat, not CGPoint
- Calculate Y position manually for scatter plots

### 6. SwiftUI Preview vs Actual Runtime
**Problem**: "foregroundColor" works in some contexts but not in Charts AxisMarks
**Solution**: 
- Remove `.foregroundColor()` from AxisValueLabel inside AxisMarks
- Use theme colors in the Chart's foregroundStyle instead

### 7. Missing Methods in Protocol Implementations
**Problem**: "Value has no member 'cancelPendingSync'"
**Solution**: Add stub implementations even if empty:
```swift
func cancelPendingSync() {
    // Cancel any pending sync operations
    syncState = .idle
}
```

### 8. Security Issues
**Problem**: Device tokens logged in plain text
**Solution**: Remove all print statements containing sensitive data:
```swift
// Remove: print("Device token: \(tokenString)")
```

### 9. Fatal Errors in Production
**Problem**: `fatalError()` crashes app in production
**Solution**: Implement proper error handling with fallbacks:
```swift
container.loadPersistentStores { (storeDescription, error) in
    if let error = error {
        // Log error
        print("❌ Failed to load Core Data: \(error)")
        
        // Create in-memory fallback
        let inMemoryDescription = NSPersistentStoreDescription()
        inMemoryDescription.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [inMemoryDescription]
        
        // Post notification for UI handling
        NotificationCenter.default.post(
            name: NSNotification.Name("CoreDataFailedToLoad"),
            object: nil,
            userInfo: ["error": error]
        )
    }
}
```

## Verification Best Practices

### 1. Build Verification
**Problem**: `xcodebuild` shows "BUILD SUCCEEDED" but app doesn't actually run
**Solution**: Proper verification requires:
1. Clean build folder first
2. Build for specific simulator
3. Install and launch the app
4. Verify app reaches main screen without crashes

**Correct verification command**:
```bash
# Clean
xcodebuild clean -project JubileeMobileBay.xcodeproj -scheme JubileeMobileBay

# Build AND install
xcodebuild -project JubileeMobileBay.xcodeproj \
    -scheme JubileeMobileBay \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
    build

# Launch (requires simulator to be running)
xcrun simctl launch booted com.jubileemobilebay.app
```

### 2. Feature Verification
**Problem**: Dashboard shows but data doesn't load
**Common Causes**:
- Mock data services not connected properly
- Dependency injection issues
- Missing environment objects
- Async data loading not triggered

**Solution Checklist**:
- [ ] Verify ViewModels are properly initialized with dependencies
- [ ] Check @StateObject vs @ObservedObject usage
- [ ] Ensure async tasks are called in `.task { }` modifier
- [ ] Verify mock services return data
- [ ] Check for runtime errors in console

### 3. Requirements Verification
**Problem**: Claiming requirements are met without proper testing
**Solution**: Create explicit verification checklist:

```markdown
## Verification Checklist
- [ ] Build completes without errors
- [ ] App launches on simulator without crashes
- [ ] Navigation between screens works
- [ ] Dashboard displays with mock data
- [ ] ML predictions show placeholder values
- [ ] No runtime warnings in console
- [ ] All user interactions respond appropriately
```

### 4. Common Xcode Project Issues
**Problem**: Files exist but Xcode doesn't compile them
**Solution**:
1. Check project.pbxproj for file references
2. Ensure files are in "Compile Sources" build phase
3. Remove .disabled file references
4. Run `xcodegen generate` if using XcodeGen

## Architecture Improvements

### 1. Dependency Injection
**Problem**: Services creating their own dependencies
**Solution**:
```swift
// Bad
init() {
    self.service = CloudKitService()
}

// Good
init(service: CloudKitServiceProtocol = CloudKitService()) {
    self.service = service
}
```

### 2. Protocol-Based Design
**Problem**: Tight coupling between layers
**Solution**: Always use protocols for dependencies:
```swift
protocol WeatherAPIProtocol {
    func fetchCurrentConditions() async throws -> WeatherConditions
}

// Use protocol in init
init(weatherAPI: WeatherAPIProtocol = WeatherAPIService()) {
    self.weatherAPI = weatherAPI
}
```

## Testing Approach

### Unit Testing Build Errors
When fixing build errors, test each fix:
1. Fix one error type at a time
2. Run incremental builds
3. Verify fix doesn't introduce new errors
4. Document the solution

### Integration Testing
After all builds succeed:
1. Launch app on simulator
2. Navigate through all screens
3. Verify data loads
4. Test user interactions
5. Check for runtime errors

## Prevention Strategies

1. **Regular Builds**: Run builds after each significant change
2. **Incremental Changes**: Make small, testable changes
3. **Version Control**: Commit working states before major refactors
4. **Documentation**: Update CLAUDE.md with new patterns/solutions
5. **Type Safety**: Use concrete types instead of forcing unwraps
6. **Error Handling**: Never use fatalError() in production code

## Today's Specific Solutions (2025-07-22)

### 1. Mock Data Service for Development
**Problem**: Dashboard wasn't loading data because real API services were failing
**Solution**: Created comprehensive mock data services:
```swift
// MockDataService.swift
final class MockWeatherAPIService: WeatherAPIProtocol {
    func fetchCurrentConditions() async throws -> WeatherConditions {
        // Return mock data
    }
}

// DashboardView.swift - Use mock data in DEBUG
#if DEBUG
let provider = DevelopmentDataProvider.shared
_viewModel = StateObject(wrappedValue: DashboardViewModel(
    weatherAPI: provider.weatherAPI,
    marineAPI: provider.marineAPI,
    // ... other mock services
))
#else
// Production initialization
#endif
```

### 2. Enum Value Corrections
**Problem**: Using incorrect enum values
**Solutions**:
- JubileeIntensity: Use `.minimal, .light, .moderate, .heavy, .extreme` (not `.minor`)
- VerificationStatus: Use `.userReported` (not `.pending`)

### 3. Protocol Actor Isolation
**Problem**: Protocol conformance issues with @MainActor
**Solution**: Add @MainActor to protocol definitions:
```swift
@MainActor
protocol WebRTCServiceProtocol: AnyObject {
    // Protocol methods
}

@MainActor
protocol SyncService {
    // Protocol methods
}
```

### 4. MockDataService Type Issues
**Problem**: MonitoringStation struct mismatch, TideData extra parameters
**Solution**: Use correct struct definitions from protocol files:
```swift
// Correct MonitoringStation
MonitoringStation(
    id: "MBLA1",
    name: "Mobile Bay - Meaher Park",
    latitude: 30.6954,
    longitude: -88.0399,
    type: .buoy,
    status: .active
)

// Correct TideData (no location parameter)
TideData(
    time: now.addingTimeInterval(2 * 3600),
    height: 1.8,
    type: .high
)
```

### 5. Complex Expression Type-Checking
**Problem**: "The compiler is unable to type-check this expression in reasonable time"
**Solution**: Break complex expressions into simpler parts:
```swift
// Instead of complex map expression
return (0..<hours).map { hour in
    WeatherForecast(...)
}

// Use a for loop
var forecasts: [WeatherForecast] = []
for hour in 0..<hours {
    let forecast = WeatherForecast(...)
    forecasts.append(forecast)
}
return forecasts
```

### 6. CloudKit Mock Data in Development
**Problem**: CloudKit queries failing in development
**Solution**: Added conditional compilation in CloudKitService:
```swift
func fetchRecentJubileeEvents(limit: Int = 50) async throws -> [JubileeEvent] {
    #if DEBUG
    return createMockJubileeEvents(count: min(limit, 5))
    #else
    // Production CloudKit query
    #endif
}
```

### 7. Proper Build Verification Process
**Problem**: Multiple false reports of "build successful and app running"
**Solution**: Complete verification requires:
1. Clean build succeeds
2. Install app on simulator
3. Launch app successfully
4. Verify data loads on dashboard

**Commands**:
```bash
# 1. Find available simulator
xcodebuild -showdestinations -project JubileeMobileBay.xcodeproj

# 2. Clean and build
xcodebuild -project JubileeMobileBay.xcodeproj \
    -scheme JubileeMobileBay \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' \
    clean build

# 3. Boot simulator
xcrun simctl boot "iPhone 16 Pro"

# 4. Install app
xcrun simctl install "iPhone 16 Pro" \
    /path/to/DerivedData/.../JubileeMobileBay.app

# 5. Launch app
xcrun simctl launch "iPhone 16 Pro" com.jubileemobilebay.app
```

### Key Takeaway
**Always verify actual runtime behavior, not just build success. A successful build does not mean the app functions correctly.**