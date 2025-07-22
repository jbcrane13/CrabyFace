# Core ML Files to Add to Xcode Project

These files need to be added to the Xcode project to fix the Core ML model loading error.

## Instructions

1. Open JubileeMobileBay.xcodeproj in Xcode
2. Right-click on the appropriate group in the project navigator
3. Select "Add Files to JubileeMobileBay..."
4. Navigate to each file and add it
5. Ensure "JubileeMobileBay" target is checked

## Files to Add

### Models/ML

**Group:** JubileeMobileBay/Models/ML

- [ ] JubileePredictor.mlmodel
  - Path: JubileeMobileBay/Models/ML/JubileePredictor.mlmodel
  - Target: JubileeMobileBay
  - **IMPORTANT:** This is the Core ML model file. Xcode will compile it automatically.

- [ ] JubileePredictorModel.swift
  - Path: JubileeMobileBay/Models/ML/JubileePredictorModel.swift
  - Target: JubileeMobileBay
  - **Note:** This implements the custom model logic for predictions

## Build Verification

After adding all files:
1. Clean Build Folder (Shift+Cmd+K)
2. Build (Cmd+B)
3. Verify no Core ML errors appear
4. Run on Simulator (Cmd+R)

## What This Fixes

The error "Failed to read model package at file:///Users/blake/GitHub/CrabyFace/JubileeMobileBay/JubileeMobileBay/Models/ML/JubileePredictor.mlpackage/" occurred because:

1. The placeholder JSON files in the .mlpackage directory were not a valid Core ML model
2. The app was trying to load a non-existent compiled model

The solution:
1. Created a proper Core ML model file (.mlmodel) using Python's coremltools
2. Implemented the custom model class (JubileePredictorModel.swift) with @objc annotation
3. The model uses simple environmental conditions to predict jubilee probability

## Model Details

**Inputs:**
- airTemperature (Double) - Air temperature in Fahrenheit
- waterTemperature (Double) - Water temperature in Fahrenheit  
- windSpeed (Double) - Wind speed in miles per hour
- dissolvedOxygen (Double) - Dissolved oxygen in mg/L

**Outputs:**
- jubileeProbability (Double) - Probability of jubilee event (0.0-1.0)
- confidenceScore (Double) - Model confidence score (0.0-1.0)

The model uses a custom implementation that calculates probability based on optimal conditions for jubilee events.