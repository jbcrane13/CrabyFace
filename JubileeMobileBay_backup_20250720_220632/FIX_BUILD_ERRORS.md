# Fix Build Errors

## Issue: Duplicate DashboardViewModel.swift Reference

The project has a reference to a duplicate `DashboardViewModel.swift` file that was in the Services folder. This file has been deleted from the filesystem but Xcode still has a reference to it.

## Steps to Fix:

1. **Open Xcode**
2. **Find the duplicate reference:**
   - In the project navigator, look for `DashboardViewModel.swift` in the Services folder
   - It will appear in RED (missing file)
3. **Remove the duplicate reference:**
   - Right-click on the red `DashboardViewModel.swift` in Services folder
   - Select "Delete" 
   - Choose "Remove Reference" (not "Move to Trash" since file is already deleted)
4. **Verify the correct file exists:**
   - Ensure `DashboardViewModel.swift` exists in ViewModels folder
   - It should NOT be red
5. **Clean and Build:**
   - Product → Clean Build Folder (⇧⌘K)
   - Product → Build (⌘B)

## Alternative Method:

If you still see build errors after removing the reference:

1. Close Xcode
2. Delete the DerivedData folder:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/JubileeMobileBay-*
   ```
3. Reopen Xcode and build again

## Expected Result:

After these steps, the project should build successfully without the "filename used twice" error.