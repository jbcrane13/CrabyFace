# Fix Duplicate File References - Comprehensive Solution

## Problem Summary

The project has 60+ duplicate file references in the Xcode project file (project.pbxproj), causing widespread "filename used twice" build errors.

## Affected Files (All Have Duplicates)

```
AuthenticationService.swift
AuthenticationViewModel.swift
CloudKitErrorRecovery.swift
CloudKitSchemaSetup.swift
CloudKitService.swift
CloudKitServiceTests.swift
CloudKitValidator.swift
CommunityFeedView.swift
CommunityFeedViewModel.swift
CommunityPost.swift
CommunityPostTests.swift
ContentView.swift
DashboardView.swift
DashboardViewModel.swift
DemoDataService.swift
EnvironmentalData.swift
EnvironmentalDataTests.swift
EventAnnotation.swift
EventService.swift
Hex.swift
JubileeEnums.swift
JubileeEvent.swift
JubileeEventTests.swift
JubileeMapView.swift
JubileeMetadata.swift
JubileeMobileBayApp.swift
LocationAccuracy.swift
LocationService.swift
LocationServiceProtocol.swift
LocationServiceTests.swift
LoginView.swift
MapViewModel.swift
MapViewModelTests.swift
MarineData.swift
MarineDataProtocol.swift
MarineDataService.swift
MarineDataServiceTests.swift
MarineDataTests.swift
MarineLifeType.swift
MockServices.swift
PhotoItem.swift
PhotoPickerView.swift
PhotoPickerViewTests.swift
PhotoReference.swift
PhotoUploadService.swift
PredictionModels.swift
PredictionService.swift
PredictionServiceProtocol.swift
PredictionServiceTests.swift
ReportView.swift
ReportViewModel.swift
ReportViewModelTests.swift
ReportViewTests.swift
TimeRange.swift
URLSessionProtocol.swift
UserReport.swift
UserReportTests.swift
UserSessionManager.swift
WeatherAPIProtocol.swift
WeatherAPIService.swift
WeatherAPIServiceTests.swift
WeatherData.swift
WeatherDataTests.swift
```

## Solution Options

### Option 1: Manual Cleanup in Xcode (Tedious but Safe)

1. Open Xcode
2. For EACH duplicate file:
   - Look for red (missing) file references
   - Right-click → Delete → Remove Reference
   - Verify the correct file still exists (not red)
3. Clean Build Folder (⇧⌘K)
4. Build (⌘B)

### Option 2: Automated Cleanup Script

Create and run this Python script to clean the project file:

```python
#!/usr/bin/env python3
import re
import os
from collections import defaultdict

# Path to your project file
project_file = "JubileeMobileBay.xcodeproj/project.pbxproj"

# Backup the original
import shutil
shutil.copy(project_file, project_file + ".backup")

# Read the file
with open(project_file, 'r') as f:
    content = f.read()

# Find all file references
file_pattern = r'([A-F0-9]{24})\s*/\*\s*([^*]+\.swift)\s*\*/'
file_refs = re.findall(file_pattern, content)

# Track duplicates
file_names = defaultdict(list)
for uuid, filename in file_refs:
    file_names[filename].append(uuid)

# Find UUIDs to remove (keep first occurrence)
uuids_to_remove = set()
for filename, uuids in file_names.items():
    if len(uuids) > 1:
        print(f"Duplicate found: {filename} - {len(uuids)} references")
        # Keep the first, remove the rest
        for uuid in uuids[1:]:
            uuids_to_remove.add(uuid)

print(f"\nRemoving {len(uuids_to_remove)} duplicate references...")

# Remove all lines containing these UUIDs
lines = content.split('\n')
filtered_lines = []
for line in lines:
    should_keep = True
    for uuid in uuids_to_remove:
        if uuid in line:
            should_keep = False
            print(f"Removing: {line.strip()}")
            break
    if should_keep:
        filtered_lines.append(line)

# Write back
with open(project_file, 'w') as f:
    f.write('\n'.join(filtered_lines))

print("\nDone! Open Xcode and build the project.")
```

### Option 3: Create New Project (Nuclear Option)

If the above options fail:

1. Create a new Xcode project with the same name
2. Copy all Swift files from the old project
3. Add files to the new project through Xcode UI
4. Copy over any custom build settings
5. Re-add any frameworks or packages

## Recommended Approach

Given the scale of the problem (60+ duplicates), I recommend:

1. **First, try Option 2** (the Python script) - it's fastest
2. If that fails, **use Option 3** (new project) - it's cleanest
3. Only use Option 1 if you need surgical precision

## Prevention

To prevent this in the future:
- Always move files through Xcode's UI, not Finder
- When reorganizing, use Xcode's "Move to Group" feature
- Regularly clean the project (Product → Clean Build Folder)
- Use version control to track project.pbxproj changes

## Verification

After fixing:
1. Build should succeed without "filename used twice" errors
2. All Swift files should appear only once in the navigator
3. No red (missing) file references should exist