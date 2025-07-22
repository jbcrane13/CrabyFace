# Info.plist Updates for Core ML Background Tasks

To enable background tasks for Core ML model updates, add the following to your Info.plist:

## Background Modes

1. In Xcode, select your project's Info.plist
2. Add a new key: `UIBackgroundModes` (if not already present)
3. Add the following values to the array:
   - `processing` (for BGProcessingTask)

## Background Task Identifiers

1. Add a new key: `BGTaskSchedulerPermittedIdentifiers`
2. Add the following string to the array:
   - `com.jubileemobilebay.model-update`

## XML Format (if editing Info.plist as source code):

```xml
<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
</array>
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.jubileemobilebay.model-update</string>
</array>
```

## Testing Background Tasks

To test background tasks in the debugger:

1. Run the app on a device (not simulator)
2. Put the app in the background
3. In Xcode's debug console, run:
   ```
   e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.jubileemobilebay.model-update"]
   ```

This will trigger the background task immediately for testing.