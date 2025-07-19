# Jubilee Mobile Bay iOS App - Product Requirements Document

## 1. Executive Summary

### 1.1 Product Vision
A comprehensive iOS application that empowers Mobile Bay fishing enthusiasts, marine researchers, and coastal residents to monitor, predict, and report jubilee events through real-time environmental data analysis and community collaboration.

### 1.2 Business Objectives
- **Primary**: Provide accurate jubilee predictions to maximize fishing opportunities and marine life observation
- **Secondary**: Build a community platform for environmental data collection and marine conservation awareness
- **Tertiary**: Support scientific research through crowd-sourced data collection

### 1.3 Success Metrics
- **User Engagement**: 75% of users open app within 24 hours of jubilee alert
- **Prediction Accuracy**: 80% accuracy rate for jubilee probability forecasts
- **Community Participation**: 30% of active users submit monthly reports
- **Retention**: 60% monthly active user retention rate

## 2. User Research & Personas

### 2.1 Primary Personas

#### Persona 1: Recreational Fisher (75% of user base)
- **Name**: "Bay Angler Bob"
- **Demographics**: Male, 35-65, Alabama coastal resident
- **Goals**: Maximize fishing success, minimize wasted trips
- **Pain Points**: Unpredictable jubilee timing, lack of real-time conditions
- **Technical Comfort**: Medium, uses basic smartphone features

#### Persona 2: Marine Researcher (15% of user base)
- **Name**: "Dr. Sarah Marine"
- **Demographics**: Female, 28-50, Marine biology professional
- **Goals**: Collect environmental data, study jubilee patterns
- **Pain Points**: Limited data collection resources, need for standardized reporting
- **Technical Comfort**: High, comfortable with data analysis tools

#### Persona 3: Coastal Tourist (10% of user base)
- **Name**: "Visitor Victor"
- **Demographics**: Any gender, 25-55, Visiting Alabama Gulf Coast
- **Goals**: Experience unique natural phenomenon, learn about local ecosystem
- **Pain Points**: Limited local knowledge, unfamiliar with jubilee timing
- **Technical Comfort**: Medium to high, relies on mobile apps for travel

## 3. Functional Requirements

### 3.1 Epic 1: Real-time Environmental Monitoring

#### Feature 1.1: Environmental Data Dashboard
**User Story**: As a Bay Angler Bob, I want to see current environmental conditions so that I can assess jubilee probability.

**Acceptance Criteria**:
- Display current temperature (°F), humidity (%), wind speed (mph), atmospheric pressure (inHg)
- Show oxygen levels when available (mg/L or % saturation)
- Update data every 5 minutes maximum
- Display last update timestamp
- Show data source and reliability indicator
- Offline mode displays last cached data with clear indicators

**Technical Requirements**:
- Integrate with NOAA/NWS APIs for weather data
- Implement CoreData for local caching
- Use Combine framework for reactive data updates
- Follow MVVM pattern with @ObservableObject data services

#### Feature 1.2: Jubilee Probability Calculator
**User Story**: As a Dr. Sarah Marine, I want to see calculated jubilee probability based on current conditions so that I can plan research activities.

**Acceptance Criteria**:
- Display probability percentage (0-100%)
- Show contributing factors breakdown
- Provide confidence level indicator
- Include historical context ("Similar conditions led to jubilees X% of the time")
- Update probability in real-time as conditions change
- Store probability history for trend analysis

**Technical Requirements**:
- Implement machine learning model using CreateML
- Weight factors: temperature (25%), humidity (20%), wind (15%), pressure (15%), oxygen (25%)
- Store historical correlation data in CloudKit
- Implement prediction caching for performance

### 3.2 Epic 2: Interactive Mapping System

#### Feature 2.1: Live Jubilee Event Map
**User Story**: As a Visitor Victor, I want to see jubilee events on a map so that I can find the best viewing locations.

**Acceptance Criteria**:
- Display MapKit-based interactive map centered on Mobile Bay
- Show event markers with color-coded intensity (Green: Minor, Yellow: Moderate, Orange: Major, Red: Extreme)
- Display event details on marker tap (time, duration, intensity, conditions)
- Filter events by time range (last 6 hours, 24 hours, week)
- Show user's current location with permission
- Implement smooth map animations and clustering for dense areas

**Technical Requirements**:
- Use MapKit with custom annotation views
- Implement MKClusterAnnotation for performance
- Store map state using @StateObject
- Integrate Core Location for user positioning
- Implement custom map styles following iOS design guidelines

#### Feature 2.2: Location-based Event Alerts
**User Story**: As a Bay Angler Bob, I want to receive alerts for jubilee events near my favorite fishing spots so that I don't miss opportunities.

**Acceptance Criteria**:
- Allow users to set up to 5 monitoring locations
- Define custom radius for each location (0.5-10 miles)
- Send push notifications when events occur within radius
- Include event intensity and estimated duration in notification
- Provide "Navigate to Event" quick action
- Store location preferences in iCloud for device sync

**Technical Requirements**:
- Implement CLLocationManager for geofencing
- Use UserNotifications framework for alerts
- Store preferences in CloudKit for cross-device sync
- Implement background app refresh for location monitoring

### 3.3 Epic 3: Community Reporting Platform

#### Feature 3.1: Event Reporting Interface
**User Story**: As a Dr. Sarah Marine, I want to report jubilee events I observe so that the community has accurate, real-time information.

**Acceptance Criteria**:
- Quick report form with essential fields: location, intensity, start time, description
- Photo attachment capability (up to 3 photos)
- GPS auto-location with manual adjustment option
- Intensity selection with visual guides
- Submit reports offline (sync when connected)
- Report validation and moderation system

**Technical Requirements**:
- Implement SwiftUI forms with proper validation
- Use PhotosPicker for image selection
- Implement CloudKit for report storage and sync
- Add background sync using BackgroundTasks framework
- Include image compression and thumbnail generation

#### Feature 3.2: Community Feed and Statistics
**User Story**: As a Visitor Victor, I want to see what other users are reporting so that I can learn from experienced locals.

**Acceptance Criteria**:
- Display chronological feed of community reports
- Show user reputation/experience level
- Include photo gallery for each report
- Provide voting system for report accuracy
- Display community statistics (total reports, active users, recent activity)
- Filter reports by location, time, and intensity

**Technical Requirements**:
- Implement lazy loading with List and LazyVStack
- Use CloudKit subscriptions for real-time updates
- Implement user authentication with Sign in with Apple
- Add content moderation and reporting features

### 3.4 Epic 4: Intelligent Notification System

#### Feature 4.1: Predictive Alert Engine
**User Story**: As a Bay Angler Bob, I want to receive advance warning when conditions favor jubilee formation so that I can plan my fishing trips.

**Acceptance Criteria**:
- Send notifications 2-6 hours before predicted jubilee events
- Include probability percentage and confidence level
- Provide reasoning ("High humidity + calm winds + warm temperature")
- Allow custom probability thresholds (default: 70%)
- Include weather forecast that supports prediction
- Respect user's quiet hours preferences

**Technical Requirements**:
- Implement background processing for prediction calculations
- Use APNs for reliable notification delivery
- Store user preferences in UserDefaults with CloudKit sync
- Implement notification scheduling with UNNotificationRequest

#### Feature 4.2: Alert Customization System
**User Story**: As a Dr. Sarah Marine, I want to customize alert types and timing so that I receive relevant notifications for my research.

**Acceptance Criteria**:
- Separate alert types: High Probability (>80%), Medium Probability (60-80%), Community Reports, Weather Changes
- Custom time windows for each alert type
- Location-specific alert settings
- Alert delivery method options (banner, lock screen, Apple Watch)
- Test notification feature
- Export notification history for analysis

**Technical Requirements**:
- Implement comprehensive Settings screen using SwiftUI
- Use @AppStorage for preference persistence
- Integrate with WatchKit for Apple Watch notifications
- Implement notification categories for interactive responses

## 4. Non-Functional Requirements

### 4.1 Performance Requirements
- **App Launch Time**: < 3 seconds on iPhone 12 or newer
- **Map Rendering**: Display 100+ markers within 2 seconds
- **Data Refresh**: Complete environmental data update within 10 seconds
- **Offline Functionality**: Core features available without internet for 24 hours
- **Memory Usage**: Stay under 100MB during normal operation
- **Battery Impact**: Minimal background battery usage (<2% per hour)

### 4.2 Scalability Requirements
- **User Capacity**: Support 10,000 concurrent users
- **Data Volume**: Handle 1,000 daily community reports
- **Geographic Scope**: Expandable to other Gulf Coast bays
- **API Rate Limits**: Respect NOAA API limits (1,000 requests/hour)
- **Storage**: Efficient CloudKit usage within Apple limits

### 4.3 Security & Privacy Requirements
- **Data Privacy**: Full compliance with iOS privacy guidelines
- **Location Data**: Never store precise location without explicit consent
- **User Authentication**: Optional but secure (Sign in with Apple)
- **API Security**: Secure key management for weather services
- **Data Transmission**: HTTPS for all network communications
- **Local Storage**: Encrypt sensitive data using iOS Keychain

### 4.4 Reliability Requirements
- **Uptime**: 99.5% availability for core features
- **Error Recovery**: Graceful degradation when APIs unavailable
- **Data Integrity**: Prevent corruption during offline/online sync
- **Crash Rate**: < 0.1% crash rate across all supported iOS versions
- **Backup**: Automatic iCloud backup for user preferences and reports

## 5. Technical Architecture

### 5.1 Technology Stack
- **Platform**: iOS 17.0+ (supporting iPhone SE 2nd gen and newer)
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI 5.0
- **Architecture Pattern**: MVVM with ObservableObject
- **Data Persistence**: CloudKit + CoreData hybrid
- **Networking**: URLSession with Combine
- **Testing**: XCTest with Test-Driven Development

### 5.2 Project Structure
```
JubileeMobileBay/
├── App/
│   ├── JubileeMobileBayApp.swift
│   └── Configuration/
├── Models/
│   ├── JubileeEvent.swift
│   ├── EnvironmentalData.swift
│   ├── UserReport.swift
│   └── LocationMonitor.swift
├── ViewModels/
│   ├── EnvironmentalDataViewModel.swift
│   ├── MapViewModel.swift
│   ├── CommunityViewModel.swift
│   └── NotificationViewModel.swift
├── Views/
│   ├── Main/
│   │   ├── ContentView.swift
│   │   └── TabBarView.swift
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   └── ProbabilityCardView.swift
│   ├── Map/
│   │   ├── JubileeMapView.swift
│   │   ├── EventAnnotationView.swift
│   │   └── EventDetailView.swift
│   ├── Community/
│   │   ├── CommunityFeedView.swift
│   │   ├── ReportFormView.swift
│   │   └── ReportDetailView.swift
│   └── Settings/
│       ├── SettingsView.swift
│       ├── NotificationSettingsView.swift
│       └── LocationSettingsView.swift
├── Services/
│   ├── EnvironmentalDataService.swift
│   ├── NotificationService.swift
│   ├── LocationService.swift
│   ├── CloudKitService.swift
│   └── PredictionEngine.swift
├── Utilities/
│   ├── Extensions/
│   ├── Constants.swift
│   └── Helpers/
└── Tests/
    ├── Unit/
    ├── Integration/
    └── UI/
```

### 5.3 Data Models

#### 5.3.1 JubileeEvent Model
```swift
struct JubileeEvent: Identifiable, Codable {
    let id: UUID
    let location: CLLocationCoordinate2D
    let intensity: JubileeIntensity
    let startTime: Date
    let endTime: Date?
    let reportedBy: UserReport?
    let environmentalConditions: EnvironmentalData
    let verificationStatus: VerificationStatus
    let photos: [URL]
}

enum JubileeIntensity: String, CaseIterable, Codable {
    case minor = "Minor"
    case moderate = "Moderate" 
    case major = "Major"
    case extreme = "Extreme"
}
```

#### 5.3.2 EnvironmentalData Model
```swift
struct EnvironmentalData: Codable {
    let timestamp: Date
    let temperature: Double // Fahrenheit
    let humidity: Double // Percentage
    let windSpeed: Double // MPH
    let windDirection: Double // Degrees
    let atmosphericPressure: Double // inHg
    let oxygenLevel: Double? // mg/L
    let dataSource: DataSource
    let reliability: Double // 0.0-1.0
}
```

### 5.4 API Integration Strategy

#### 5.4.1 Weather Data Sources
- **Primary**: NOAA/National Weather Service API
- **Secondary**: OpenWeatherMap API (backup)
- **Oxygen Data**: Gulf Coast Research Laboratory API
- **Rate Limiting**: Implement exponential backoff and caching

#### 5.4.2 CloudKit Schema
- **Public Database**: Event reports, community statistics
- **Private Database**: User preferences, personal locations
- **Shared Database**: Research data collaboration

## 6. User Experience Requirements

### 6.1 Design Principles
- **Accessibility**: Full VoiceOver support, Dynamic Type compatibility
- **iOS Design Guidelines**: Follow Human Interface Guidelines strictly
- **Performance**: Prioritize 60fps animations and smooth scrolling
- **Intuitive Navigation**: Maximum 3 taps to reach any feature
- **Dark Mode**: Full support with appropriate color schemes

### 6.2 Key User Flows

#### 6.2.1 First-Time User Onboarding
1. Welcome screen with app value proposition
2. Location permission request with clear explanation
3. Notification permission with examples
4. Optional account creation
5. Tutorial of main features
6. Set initial monitoring locations

#### 6.2.2 Daily Usage Pattern
1. Open app to check current conditions
2. Review jubilee probability
3. Check map for recent events
4. Set/adjust location alerts if needed
5. Report events if witnessed

#### 6.2.3 Event Response Flow
1. Receive notification of high probability/event
2. Open app to detailed conditions
3. Navigate to map for location details
4. Use navigation to reach optimal viewing spot
5. Report observations back to community

## 7. Testing Strategy

### 7.1 Test-Driven Development Approach
- **Unit Tests**: 90% code coverage for ViewModels and Services
- **Integration Tests**: API connectivity, CloudKit sync, Core Location
- **UI Tests**: Critical user journeys and accessibility
- **Performance Tests**: Memory usage, battery impact, load testing

### 7.2 Test Scenarios
#### 7.2.1 Core Functionality Tests
- Environmental data retrieval and parsing
- Jubilee probability calculation accuracy
- Map rendering and interaction
- Notification delivery and timing
- Offline functionality and sync

#### 7.2.2 Edge Case Testing
- Network connectivity issues
- API rate limiting responses
- Large dataset handling (1000+ events)
- Low memory conditions
- Background app limitations

### 7.3 User Acceptance Testing
- **Beta Testing**: 50 users across three persona groups
- **Metrics**: Task completion rate, error rate, user satisfaction
- **Duration**: 4-week beta period before App Store submission

## 8. Development Phases

### Phase 1: Core Foundation (Weeks 1-4)
- Project setup with proper architecture
- Environmental data service implementation
- Basic dashboard with real-time data
- Jubilee probability calculation engine
- Unit test framework establishment

### Phase 2: Mapping & Visualization (Weeks 5-8)
- MapKit integration with custom annotations
- Event visualization and clustering
- Location services and geofencing
- Map-based event details
- Integration testing

### Phase 3: Community Platform (Weeks 9-12)
- CloudKit setup and data models
- Event reporting interface
- Community feed implementation
- Photo upload and management
- User authentication integration

### Phase 4: Notifications & Polish (Weeks 13-16)
- Push notification system
- Predictive alert engine
- Settings and customization
- Comprehensive UI testing
- Performance optimization

### Phase 5: Testing & Launch (Weeks 17-20)
- Beta testing program
- Bug fixes and performance tuning
- App Store preparation
- Documentation completion
- Launch preparation

## 9. Risk Assessment & Mitigation

### 9.1 Technical Risks
- **API Reliability**: Mitigation through multiple data sources and local caching
- **Prediction Accuracy**: Continuous model improvement and user feedback integration
- **CloudKit Limitations**: Hybrid approach with CoreData for offline functionality
- **Performance at Scale**: Load testing and optimization throughout development

### 9.2 Business Risks
- **User Adoption**: Comprehensive marketing to fishing communities
- **Seasonal Usage**: Develop year-round features and Gulf Coast expansion
- **Competition**: Focus on unique local knowledge and community aspects

### 9.3 Regulatory Risks
- **Privacy Compliance**: Strict adherence to iOS privacy guidelines
- **Marine Regulations**: Consultation with NOAA and local authorities
- **App Store Guidelines**: Regular compliance review and updates

## 10. Success Criteria & Metrics

### 10.1 Launch Metrics (First 30 Days)
- **Downloads**: 1,000 downloads
- **Active Users**: 500 monthly active users
- **Engagement**: 3+ sessions per user per week during jubilee season
- **Reports**: 50 community reports submitted
- **Ratings**: 4.0+ App Store rating

### 10.2 Growth Metrics (First Year)
- **User Base**: 5,000 total downloads, 2,000 monthly active users
- **Accuracy**: 75%+ prediction accuracy validation
- **Community**: 500+ community reports, 50+ verified events
- **Retention**: 40%+ monthly retention rate

### 10.3 Long-term Success Indicators
- **Scientific Impact**: Integration with marine research institutions
- **Geographic Expansion**: Adaptation for other Gulf Coast locations
- **Community Growth**: Self-sustaining user-generated content
- **Revenue Potential**: Successful freemium or subscription model

## 11. Post-Launch Roadmap

### Version 1.1 (3 months post-launch)
- Apple Watch companion app
- Widget support for iOS home screen
- Enhanced prediction algorithms based on user feedback
- Social sharing features

### Version 1.2 (6 months post-launch)
- Fish species tracking integration
- Water quality expanded monitoring
- Professional research dashboard
- Export functionality for scientific use

### Version 2.0 (12 months post-launch)
- Machine learning model improvements
- Expansion to other Gulf Coast bays
- Premium features and subscription model
- Integration with fishing gear manufacturers

---

## Document Control
- **Version**: 1.0
- **Last Updated**: [Current Date]
- **Prepared By**: Senior iOS Architect
- **Approved By**: [Product Manager]
- **Next Review**: [Date + 30 days]

This PRD serves as the comprehensive specification for the Jubilee Mobile Bay iOS application, providing detailed requirements suitable for task breakdown and development planning using TaskMaster in Claude Code.