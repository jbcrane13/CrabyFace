# CloudKit Schema - Record Types and Fields

| Record Type | Field Name | Data Type | Description |
|-------------|------------|-----------|-------------|
| **JubileeEvent** | location | Location | Geographic coordinates of the jubilee event |
| | intensity | String | Event intensity level (Minor, Moderate, Major, Extreme) |
| | startTime | Date/Time | When the jubilee event began |
| | endTime | Date/Time | When the jubilee event ended |
| | verificationStatus | String | Verification status (Unverified, Verified, Expert-Verified) |
| | reportCount | Int64 | Number of user reports for this event |
| | temperature | Double | Air temperature at time of event (°F) |
| | humidity | Double | Humidity percentage at time of event |
| | windSpeed | Double | Wind speed at time of event (mph) |
| | windDirection | Int64 | Wind direction in degrees (0-360) |
| | waterTemperature | Double | Water temperature at time of event (°F) |
| | dissolvedOxygen | Double | Dissolved oxygen level (mg/L) |
| | salinity | Double | Water salinity level (ppt) |
| | tide | String | Tide condition (High, Low, Rising, Falling) |
| | moonPhase | String | Moon phase during event |
| **UserReport** | jubileeEventId | String | Reference to associated JubileeEvent record |
| | userId | String | ID of user who submitted the report |
| | timestamp | Date/Time | When the report was submitted |
| | description | String | User's description of the event |
| | intensity | String | User's assessment of event intensity |
| | photoURLs | String List | URLs of photos attached to the report |
| | location | Location | Where the user observed the event |
| **CommunityPost** | userId | String | ID of user who created the post |
| | userName | String | Display name of the post author |
| | title | String | Title of the community post |
| | description | String | Main content of the post |
| | location | Location | Location relevant to the post |
| | photoURLs | String List | URLs of photos attached to the post |
| | marineLifeTypes | String List | Types of marine life mentioned in post |
| | likeCount | Int64 | Number of likes the post has received |
| | commentCount | Int64 | Number of comments on the post |
| | createdAt | Date/Time | When the post was created |
| **UserProfile** | appleUserID | String | Apple Sign-In user identifier |
| | email | String | User's email address |
| | displayName | String | User's chosen display name |
| | createdAt | Date/Time | When the user profile was created |
| **PostLike** | postId | String | Reference to the liked CommunityPost |
| | userId | String | ID of user who liked the post |
| | createdAt | Date/Time | When the like was created |
| **PostComment** | postId | String | Reference to the commented CommunityPost |
| | userId | String | ID of user who made the comment |
| | userName | String | Display name of the commenter |
| | text | String | Content of the comment |
| | createdAt | Date/Time | When the comment was created |

## CloudKit Implementation Notes

### Database Organization
- **Public Database**: JubileeEvent, CommunityPost, PostLike, PostComment
- **Private Database**: UserProfile, UserReport (user's personal reports)
- **Shared Database**: Research collaboration data (future implementation)

### Indexing Strategy
- **JubileeEvent**: Index on `startTime`, `location`, `intensity`
- **UserReport**: Index on `jubileeEventId`, `timestamp`
- **CommunityPost**: Index on `createdAt`, `location`, `likeCount`
- **PostLike**: Composite index on `postId` + `userId`
- **PostComment**: Index on `postId`, `createdAt`

### Security & Permissions
- **Public Database**: Read access for all users, write access for authenticated users
- **Private Database**: Full access for record owner only
- **User Authentication**: Required for creating records, optional for reading public data

### Data Validation Rules
- **Intensity**: Must be one of ["Minor", "Moderate", "Major", "Extreme"]
- **Coordinates**: Must be within Mobile Bay geographic bounds
- **Photos**: Maximum 3 photos per report/post, 5MB per image
- **Text Fields**: Description max 1000 characters, title max 100 characters