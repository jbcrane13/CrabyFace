#!/bin/bash

BACKUP_DIR="../JubileeMobileBay_backup_20250720_220632"

# Main app file and ContentView
cp "$BACKUP_DIR/JubileeMobileBay/JubileeMobileBayApp.swift" JubileeMobileBay/
cp "$BACKUP_DIR/JubileeMobileBay/ContentView.swift" JubileeMobileBay/

# Models - Domain
cp "$BACKUP_DIR/JubileeMobileBay/Models/CommunityPost.swift" JubileeMobileBay/Models/Domain/ 2>/dev/null || echo "CommunityPost.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Models/Domain/CommunityPost.swift" JubileeMobileBay/Models/Domain/ 2>/dev/null || echo "Domain/CommunityPost.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Models/EnvironmentalData.swift" JubileeMobileBay/Models/Domain/ 2>/dev/null || echo "EnvironmentalData.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Models/Domain/EnvironmentalData.swift" JubileeMobileBay/Models/Domain/ 2>/dev/null || echo "Domain/EnvironmentalData.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Models/JubileeEvent.swift" JubileeMobileBay/Models/Domain/ 2>/dev/null || echo "JubileeEvent.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Models/Domain/JubileeEvent.swift" JubileeMobileBay/Models/Domain/ 2>/dev/null || echo "Domain/JubileeEvent.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Models/JubileeMetadata.swift" JubileeMobileBay/Models/Domain/ 2>/dev/null || echo "JubileeMetadata.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Models/Domain/JubileeMetadata.swift" JubileeMobileBay/Models/Domain/ 2>/dev/null || echo "Domain/JubileeMetadata.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Models/PhotoReference.swift" JubileeMobileBay/Models/Domain/ 2>/dev/null || echo "PhotoReference.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Models/Domain/PhotoReference.swift" JubileeMobileBay/Models/Domain/ 2>/dev/null || echo "Domain/PhotoReference.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Models/UserReport.swift" JubileeMobileBay/Models/Domain/ 2>/dev/null || echo "UserReport.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Models/Domain/UserReport.swift" JubileeMobileBay/Models/Domain/ 2>/dev/null || echo "Domain/UserReport.swift not found"

# Models - Root level
cp "$BACKUP_DIR/JubileeMobileBay/Models/MarineLifeType.swift" JubileeMobileBay/Models/ 2>/dev/null || echo "MarineLifeType.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Models/PhotoItem.swift" JubileeMobileBay/Models/ 2>/dev/null || echo "PhotoItem.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Models/TimeRange.swift" JubileeMobileBay/Models/ 2>/dev/null || echo "TimeRange.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Models/WeatherData.swift" JubileeMobileBay/Models/ 2>/dev/null || echo "WeatherData.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Models/MarineData.swift" JubileeMobileBay/Models/ 2>/dev/null || echo "MarineData.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Models/PredictionModels.swift" JubileeMobileBay/Models/ 2>/dev/null || echo "PredictionModels.swift not found"

# Models - DTOs
cp "$BACKUP_DIR/JubileeMobileBay/Models/EventAnnotation.swift" JubileeMobileBay/Models/DTOs/ 2>/dev/null || echo "EventAnnotation.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Models/DTOs/EventAnnotation.swift" JubileeMobileBay/Models/DTOs/ 2>/dev/null || echo "DTOs/EventAnnotation.swift not found"

# Models - Enums
cp "$BACKUP_DIR/JubileeMobileBay/Models/JubileeEnums.swift" JubileeMobileBay/Models/Enums/ 2>/dev/null || echo "JubileeEnums.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Models/Enums/JubileeEnums.swift" JubileeMobileBay/Models/Enums/ 2>/dev/null || echo "Enums/JubileeEnums.swift not found"

# ViewModels
cp "$BACKUP_DIR/JubileeMobileBay/ViewModels/AuthenticationViewModel.swift" JubileeMobileBay/ViewModels/
cp "$BACKUP_DIR/JubileeMobileBay/ViewModels/CommunityFeedViewModel.swift" JubileeMobileBay/ViewModels/
cp "$BACKUP_DIR/JubileeMobileBay/ViewModels/DashboardViewModel.swift" JubileeMobileBay/ViewModels/
cp "$BACKUP_DIR/JubileeMobileBay/ViewModels/MapViewModel.swift" JubileeMobileBay/ViewModels/
cp "$BACKUP_DIR/JubileeMobileBay/ViewModels/ReportViewModel.swift" JubileeMobileBay/ViewModels/

# Views
cp "$BACKUP_DIR/JubileeMobileBay/Views/CommunityFeedView.swift" JubileeMobileBay/Views/
cp "$BACKUP_DIR/JubileeMobileBay/Views/DashboardView.swift" JubileeMobileBay/Views/
cp "$BACKUP_DIR/JubileeMobileBay/Views/LoginView.swift" JubileeMobileBay/Views/
cp "$BACKUP_DIR/JubileeMobileBay/Views/PhotoPickerView.swift" JubileeMobileBay/Views/
cp "$BACKUP_DIR/JubileeMobileBay/Views/ReportView.swift" JubileeMobileBay/Views/

# Views - Map
cp "$BACKUP_DIR/JubileeMobileBay/Views/JubileeMapView.swift" JubileeMobileBay/Views/Map/ 2>/dev/null || echo "JubileeMapView.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Views/Map/JubileeMapView.swift" JubileeMobileBay/Views/Map/ 2>/dev/null || echo "Map/JubileeMapView.swift not found"

# Services
cp "$BACKUP_DIR/JubileeMobileBay/Services/AuthenticationService.swift" JubileeMobileBay/Services/
cp "$BACKUP_DIR/JubileeMobileBay/Services/CloudKitErrorRecovery.swift" JubileeMobileBay/Services/
cp "$BACKUP_DIR/JubileeMobileBay/Services/CloudKitSchemaSetup.swift" JubileeMobileBay/Services/
cp "$BACKUP_DIR/JubileeMobileBay/Services/CloudKitService.swift" JubileeMobileBay/Services/
cp "$BACKUP_DIR/JubileeMobileBay/Services/CloudKitValidator.swift" JubileeMobileBay/Services/
cp "$BACKUP_DIR/JubileeMobileBay/Services/DemoDataService.swift" JubileeMobileBay/Services/
cp "$BACKUP_DIR/JubileeMobileBay/Services/EventService.swift" JubileeMobileBay/Services/
cp "$BACKUP_DIR/JubileeMobileBay/Services/LocationAccuracy.swift" JubileeMobileBay/Services/
cp "$BACKUP_DIR/JubileeMobileBay/Services/LocationService.swift" JubileeMobileBay/Services/
cp "$BACKUP_DIR/JubileeMobileBay/Services/LocationServiceProtocol.swift" JubileeMobileBay/Services/
cp "$BACKUP_DIR/JubileeMobileBay/Services/MarineDataService.swift" JubileeMobileBay/Services/
cp "$BACKUP_DIR/JubileeMobileBay/Services/PhotoUploadService.swift" JubileeMobileBay/Services/
cp "$BACKUP_DIR/JubileeMobileBay/Services/PredictionService.swift" JubileeMobileBay/Services/
cp "$BACKUP_DIR/JubileeMobileBay/Services/UserSessionManager.swift" JubileeMobileBay/Services/
cp "$BACKUP_DIR/JubileeMobileBay/Services/WeatherAPIService.swift" JubileeMobileBay/Services/

# Services - Protocols
cp "$BACKUP_DIR/JubileeMobileBay/Services/Protocols/CloudKitServiceProtocol.swift" JubileeMobileBay/Services/Protocols/
cp "$BACKUP_DIR/JubileeMobileBay/Services/Protocols/MarineDataProtocol.swift" JubileeMobileBay/Services/Protocols/
cp "$BACKUP_DIR/JubileeMobileBay/Services/Protocols/PredictionServiceProtocol.swift" JubileeMobileBay/Services/Protocols/
cp "$BACKUP_DIR/JubileeMobileBay/Services/Protocols/URLSessionProtocol.swift" JubileeMobileBay/Services/Protocols/
cp "$BACKUP_DIR/JubileeMobileBay/Services/Protocols/WeatherAPIProtocol.swift" JubileeMobileBay/Services/Protocols/

# Utilities - Extensions
cp "$BACKUP_DIR/JubileeMobileBay/Extensions/Color+Hex.swift" JubileeMobileBay/Utilities/Extensions/ 2>/dev/null || echo "Color+Hex.swift not found"
cp "$BACKUP_DIR/JubileeMobileBay/Utilities/Extensions/Color+Hex.swift" JubileeMobileBay/Utilities/Extensions/ 2>/dev/null || echo "Extensions/Color+Hex.swift not found"

# Resources
cp "$BACKUP_DIR/JubileeMobileBay/Resources/CloudKitSchema.md" JubileeMobileBay/Resources/ 2>/dev/null || echo "CloudKitSchema.md not found"

# Test files
cp "$BACKUP_DIR/JubileeMobileBayTests/Info.plist" JubileeMobileBayTests/

# Test - Models
cp "$BACKUP_DIR/JubileeMobileBayTests/Models/"*.swift JubileeMobileBayTests/Models/ 2>/dev/null || echo "No model tests found"

# Test - Views  
cp "$BACKUP_DIR/JubileeMobileBayTests/Views/"*.swift JubileeMobileBayTests/Views/ 2>/dev/null || echo "No view tests found"

# Test - ViewModels
cp "$BACKUP_DIR/JubileeMobileBayTests/ViewModels/"*.swift JubileeMobileBayTests/ViewModels/ 2>/dev/null || echo "No viewmodel tests found"

# Test - Services
cp "$BACKUP_DIR/JubileeMobileBayTests/Services/"*.swift JubileeMobileBayTests/Services/ 2>/dev/null || echo "No service tests found"

# Test - Root level test files
cp "$BACKUP_DIR/JubileeMobileBayTests/CloudKitServiceTests.swift" JubileeMobileBayTests/ 2>/dev/null || echo "CloudKitServiceTests.swift not found"
cp "$BACKUP_DIR/JubileeMobileBayTests/MockServices.swift" JubileeMobileBayTests/TestHelpers/ 2>/dev/null || echo "MockServices.swift not found"
cp "$BACKUP_DIR/JubileeMobileBayTests/PhotoPickerViewTests.swift" JubileeMobileBayTests/Views/ 2>/dev/null || echo "PhotoPickerViewTests.swift not found"

echo "File copy complete. Check for any 'not found' messages above."