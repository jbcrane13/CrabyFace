# CloudKit Schema Definition

## Container
- **Identifier**: iCloud.com.jubileemobilebay.app

## Record Types

### JubileeEvent (Public Database)
Primary record type for jubilee events.

**Fields:**
- `location` (Location) - Event coordinates
- `intensity` (String) - Event intensity level
- `startTime` (Date) - When the event started
- `endTime` (Date, optional) - When the event ended
- `verificationStatus` (String) - Verification status
- `reportCount` (Int64) - Number of reports for this event
- `temperature` (Double) - Air temperature in Fahrenheit
- `humidity` (Double) - Humidity percentage
- `windSpeed` (Double) - Wind speed in mph
- `windDirection` (Int64) - Wind direction in degrees
- `waterTemperature` (Double) - Water temperature in Fahrenheit
- `dissolvedOxygen` (Double) - Dissolved oxygen in mg/L
- `salinity` (Double) - Salinity in parts per thousand
- `tide` (String) - Tide state
- `moonPhase` (String) - Moon phase

**Indexes:**
- `startTime` (SORTABLE)
- `location` (QUERYABLE)
- `intensity` (QUERYABLE)

### UserReport (Public Database)
User-submitted reports about jubilee events.

**Fields:**
- `jubileeEventId` (String, optional) - Associated event ID
- `userId` (String) - Reporting user ID
- `timestamp` (Date) - Report submission time
- `description` (String) - Report description
- `intensity` (String) - Reported intensity
- `location` (Location) - Report location
- `photoURLs` (String List, optional) - Photo URLs
- `marineLife` (String List, optional) - Observed marine life
- `upvotes` (Int64) - Number of upvotes
- `downvotes` (Int64) - Number of downvotes
- `verificationStatus` (String) - Verification status

**Indexes:**
- `timestamp` (SORTABLE)
- `jubileeEventId` (QUERYABLE)
- `userId` (QUERYABLE)
- `location` (QUERYABLE)

### EnvironmentalData (Public Database)
Environmental monitoring data points.

**Fields:**
- `location` (Location) - Measurement location
- `timestamp` (Date) - Measurement time
- `temperature` (Double) - Air temperature in Fahrenheit
- `humidity` (Double) - Humidity percentage
- `pressure` (Double, optional) - Atmospheric pressure in millibars
- `windSpeed` (Double) - Wind speed in mph
- `windDirection` (Int64) - Wind direction in degrees
- `waterTemperature` (Double, optional) - Water temperature in Fahrenheit
- `dissolvedOxygen` (Double, optional) - Dissolved oxygen in mg/L
- `salinity` (Double, optional) - Salinity in parts per thousand
- `ph` (Double, optional) - pH level
- `turbidity` (Double, optional) - Turbidity in NTU
- `dataSource` (String) - Data source identifier

**Indexes:**
- `timestamp` (SORTABLE)
- `location` (QUERYABLE)
- `dataSource` (QUERYABLE)

### UserProfile (Private Database)
User profile and preferences.

**Fields:**
- `userId` (String) - User identifier
- `displayName` (String) - Display name
- `email` (String, optional) - Email address
- `favoriteLocations` (Location List) - Favorite monitoring locations
- `notificationRadius` (Double) - Notification radius in miles
- `notificationPreferences` (Bytes) - Serialized preferences
- `reportCount` (Int64) - Total reports submitted
- `verifiedReportCount` (Int64) - Verified reports
- `credibilityScore` (Double) - User credibility score

**Indexes:**
- `userId` (QUERYABLE)

## Subscriptions

### JubileeEventSubscription
- **Record Type**: JubileeEvent
- **Predicate**: All records
- **Options**: Fires on creation and update
- **Notification**: Push notification with event details

### UserReportSubscription
- **Record Type**: UserReport
- **Predicate**: Within user's notification radius
- **Options**: Fires on creation
- **Notification**: Silent push for feed updates

## Security Roles

### Public Database
- **Authenticated Users**: Can create UserReport records
- **All Users**: Can read JubileeEvent, UserReport, and EnvironmentalData records

### Private Database
- **Owner**: Full access to their UserProfile record

## Community Features Schema

### CommunityPost (Public Database)
User-generated posts about jubilee sightings in a social feed format.

**Fields:**
- `userId` (String) - ID of the user who created the post
- `userName` (String) - Display name of the user
- `title` (String) - Post title (max 100 chars)
- `description` (String) - Detailed description (max 500 chars)
- `location` (Location) - Geographic coordinates
- `photoURLs` (String List) - URLs to uploaded photos (max 10)
- `marineLifeTypes` (String List) - Observed marine life types
- `likeCount` (Int64) - Number of likes
- `commentCount` (Int64) - Number of comments
- `createdAt` (Date) - Creation timestamp

**Indexes:**
- `createdAt` (SORTABLE)
- `location` (QUERYABLE)
- `userId` (QUERYABLE)
- `likeCount` (SORTABLE)

### PostLike (Public Database)
Tracks which users liked which posts.

**Fields:**
- `postId` (String) - Reference to CommunityPost recordID
- `userId` (String) - User who liked the post
- `createdAt` (Date) - When the like was created

**Indexes:**
- `postId` (QUERYABLE)
- `userId` (QUERYABLE)

### PostComment (Public Database)
Comments on community posts.

**Fields:**
- `postId` (String) - Reference to CommunityPost recordID
- `userId` (String) - ID of commenter
- `userName` (String) - Display name of commenter
- `text` (String) - Comment text (max 200 chars)
- `createdAt` (Date) - Comment timestamp

**Indexes:**
- `postId` (QUERYABLE, SORTABLE by createdAt)
- `userId` (QUERYABLE)