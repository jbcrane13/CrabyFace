# Core ML Framework Integration Instructions

## Adding Core ML Framework to Xcode Project

Since the Core ML framework cannot be added programmatically to the `.pbxproj` file without risking corruption, please follow these steps in Xcode:

### Steps to Add Core ML Framework:

1. **Open the project in Xcode**
   - Open `JubileeMobileBay.xcodeproj` in Xcode

2. **Select the Project Target**
   - In the project navigator, select the `JubileeMobileBay` project
   - Select the `JubileeMobileBay` target

3. **Add Core ML Framework**
   - Go to the "General" tab
   - Scroll down to "Frameworks, Libraries, and Embedded Content"
   - Click the "+" button
   - Search for "CoreML.framework"
   - Select it and click "Add"
   - Ensure it's set to "Do Not Embed"

4. **Add the ML Model to the Project**
   - Right-click on the `Models/ML` folder in Xcode
   - Select "Add Files to JubileeMobileBay..."
   - Navigate to and select `JubileePredictor.mlpackage`
   - Ensure "Copy items if needed" is checked
   - Ensure the target membership is checked for `JubileeMobileBay`
   - Click "Add"

5. **Build Settings Configuration (Optional)**
   - In Build Settings, search for "Core ML"
   - Ensure "Core ML Model Compiler - Code Generation Language" is set to "Automatic"
   - Ensure "Core ML Model Compiler - Generate Swift Class" is enabled

### Verifying the Integration

After completing these steps:

1. Build the project (⌘+B)
2. The `JubileePredictor` class should be automatically generated from the `.mlpackage`
3. The `CoreMLPredictionService` should compile without errors

### Note on the Placeholder Model

The current `JubileePredictor.mlpackage` is a placeholder. In Phase 4.2 (Create ML Model Development), we will:
- Train an actual Core ML model using Create ML
- Replace the placeholder with a trained model
- Update the model inputs/outputs as needed

### Troubleshooting

If you encounter build errors:
1. Clean the build folder (⌘+Shift+K)
2. Delete derived data
3. Ensure the `.mlpackage` is properly added to the target
4. Check that Core ML framework is linked correctly