//
//  CloudKitService.swift
//  JubileeMobileBay
//
//  CloudKit service for managing container and data operations
//

import Foundation
import CloudKit
import CoreLocation

@MainActor
class CloudKitService: ObservableObject {
    
    // MARK: - Properties
    
    let container: CKContainer
    
    var publicDatabase: CKDatabase {
        container.database(with: .public)
    }
    
    var privateDatabase: CKDatabase {
        container.database(with: .private)
    }
    
    // MARK: - Record Types
    
    enum RecordType: String {
        case jubileeEvent = "JubileeEvent"
        case userReport = "UserReport"
        case environmentalData = "EnvironmentalData"
        case userProfile = "UserProfile"
        case communityPost = "CommunityPost"
        case postLike = "PostLike"
        case postComment = "PostComment"
    }
    
    // MARK: - Field Keys
    
    private enum JubileeEventField: String {
        case location
        case intensity
        case startTime
        case endTime
        case verificationStatus
        case environmentalData
        case photoURLs
    }
    
    private enum UserReportField: String {
        case jubileeEventId
        case userId
        case timestamp
        case description
        case intensity
        case photoURLs
        case location
    }
    
    private enum CommunityPostField: String {
        case userId
        case userName
        case title
        case description
        case location
        case photoURLs
        case marineLifeTypes
        case likeCount
        case commentCount
        case createdAt
    }
    
    private enum PostLikeField: String {
        case postId
        case userId
        case createdAt
    }
    
    // MARK: - Initialization
    
    init(container: CKContainer? = nil) {
        self.container = container ?? CKContainer(identifier: "iCloud.com.jubileemobilebay.container")
    }
    
    // MARK: - Save Operations
    
    func saveUserReport(_ report: UserReport) async throws -> UserReport {
        let record = CKRecord(recordType: RecordType.userReport.rawValue)
        
        if let jubileeEventId = report.jubileeEventId {
            record[UserReportField.jubileeEventId.rawValue] = jubileeEventId.uuidString as CKRecordValue
        }
        record[UserReportField.userId.rawValue] = report.userId.uuidString as CKRecordValue
        record[UserReportField.timestamp.rawValue] = report.timestamp as CKRecordValue
        record[UserReportField.description.rawValue] = report.description as CKRecordValue
        record[UserReportField.intensity.rawValue] = report.intensity.rawValue as CKRecordValue
        
        // Save location
        let location = CLLocation(
            latitude: report.location.latitude,
            longitude: report.location.longitude
        )
        record[UserReportField.location.rawValue] = location as CKRecordValue
        
        if !report.photos.isEmpty {
            let photoURLs = report.photos.map { $0.url.absoluteString }
            record[UserReportField.photoURLs.rawValue] = photoURLs as CKRecordValue
        }
        
        let _ = try await publicDatabase.save(record)
        return report
    }
    
    func saveJubileeEvent(_ event: JubileeEvent) async throws -> JubileeEvent {
        let record = CKRecord(recordType: RecordType.jubileeEvent.rawValue)
        
        let location = CLLocation(
            latitude: event.location.latitude,
            longitude: event.location.longitude
        )
        record[JubileeEventField.location.rawValue] = location as CKRecordValue
        record[JubileeEventField.intensity.rawValue] = event.intensity.rawValue as CKRecordValue
        record[JubileeEventField.startTime.rawValue] = event.startTime as CKRecordValue
        
        if let endTime = event.endTime {
            record[JubileeEventField.endTime.rawValue] = endTime as CKRecordValue
        }
        
        record[JubileeEventField.verificationStatus.rawValue] = event.verificationStatus.rawValue as CKRecordValue
        
        // Save metadata as embedded fields
        saveJubileeMetadata(event.metadata, to: record)
        
        record["reportCount"] = event.reportCount as CKRecordValue
        
        let _ = try await publicDatabase.save(record)
        return event
    }
    
    private func saveJubileeMetadata(_ metadata: JubileeMetadata, to record: CKRecord) {
        record["temperature"] = metadata.temperature as CKRecordValue
        record["humidity"] = metadata.humidity as CKRecordValue
        record["windSpeed"] = metadata.windSpeed as CKRecordValue
        record["windDirection"] = metadata.windDirection as CKRecordValue
        record["waterTemperature"] = metadata.waterTemperature as CKRecordValue
        record["dissolvedOxygen"] = metadata.dissolvedOxygen as CKRecordValue
        record["salinity"] = metadata.salinity as CKRecordValue
        record["tide"] = metadata.tide.rawValue as CKRecordValue
        record["moonPhase"] = metadata.moonPhase.rawValue as CKRecordValue
    }
    
    func saveEnvironmentalData(_ data: EnvironmentalData) async throws {
        let record = CKRecord(recordType: RecordType.environmentalData.rawValue)
        
        let location = CLLocation(
            latitude: data.location.latitude,
            longitude: data.location.longitude
        )
        record["location"] = location as CKRecordValue
        record["timestamp"] = data.timestamp as CKRecordValue
        record["temperature"] = data.temperature as CKRecordValue
        record["humidity"] = data.humidity as CKRecordValue
        record["windSpeed"] = data.windSpeed as CKRecordValue
        record["windDirection"] = data.windDirection as CKRecordValue
        
        if let pressure = data.pressure {
            record["pressure"] = pressure as CKRecordValue
        }
        if let waterTemp = data.waterTemperature {
            record["waterTemperature"] = waterTemp as CKRecordValue
        }
        if let dissolved = data.dissolvedOxygen {
            record["dissolvedOxygen"] = dissolved as CKRecordValue
        }
        if let salinity = data.salinity {
            record["salinity"] = salinity as CKRecordValue
        }
        if let ph = data.ph {
            record["ph"] = ph as CKRecordValue
        }
        if let turbidity = data.turbidity {
            record["turbidity"] = turbidity as CKRecordValue
        }
        
        record["dataSource"] = data.dataSource.rawValue as CKRecordValue
        
        let _ = try await publicDatabase.save(record)
    }
    
    // MARK: - Fetch Operations
    
    func fetchJubileeEvents() async throws -> [JubileeEvent] {
        return try await fetchRecentJubileeEvents(limit: 100)
    }
    
    func uploadPhoto(_ data: Data) async throws -> String {
        // In a real implementation, this would upload to CloudKit Assets
        // For now, return a mock URL
        return "https://cloudkit.example.com/photo/\(UUID().uuidString)"
    }
    
    func fetchRecentJubileeEvents(limit: Int = 50) async throws -> [JubileeEvent] {
        let query = CKQuery(
            recordType: RecordType.jubileeEvent.rawValue,
            predicate: NSPredicate(value: true)
        )
        
        query.sortDescriptors = [
            NSSortDescriptor(key: JubileeEventField.startTime.rawValue, ascending: false)
        ]
        
        let records = try await publicDatabase.perform(query, resultsLimit: limit)
        return records.compactMap { record in
            jubileeEventFromRecord(record)
        }
    }
    
    func fetchUserReports(for eventId: UUID) async throws -> [UserReport] {
        let predicate = NSPredicate(
            format: "%K == %@",
            UserReportField.jubileeEventId.rawValue,
            eventId.uuidString
        )
        
        let query = CKQuery(
            recordType: RecordType.userReport.rawValue,
            predicate: predicate
        )
        
        query.sortDescriptors = [
            NSSortDescriptor(key: UserReportField.timestamp.rawValue, ascending: false)
        ]
        
        let records = try await publicDatabase.perform(query)
        return records.compactMap { record in
            userReportFromRecord(record)
        }
    }
    
    // MARK: - Subscriptions
    
    func subscribeToJubileeEvents() async throws -> CKQuerySubscription {
        let predicate = NSPredicate(value: true)
        
        let subscription = CKQuerySubscription(
            recordType: RecordType.jubileeEvent.rawValue,
            predicate: predicate,
            subscriptionID: "jubilee-event-subscription",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "New jubilee event reported nearby!"
        notificationInfo.shouldBadge = true
        notificationInfo.soundName = "default"
        
        subscription.notificationInfo = notificationInfo
        
        return try await publicDatabase.save(subscription) as! CKQuerySubscription
    }
    
    // MARK: - Record Conversion
    
    private func jubileeEventFromRecord(_ record: CKRecord) -> JubileeEvent? {
        guard let location = record[JubileeEventField.location.rawValue] as? CLLocation,
              let intensityString = record[JubileeEventField.intensity.rawValue] as? String,
              let intensity = JubileeIntensity(rawValue: intensityString),
              let startTime = record[JubileeEventField.startTime.rawValue] as? Date,
              let verificationStatusString = record[JubileeEventField.verificationStatus.rawValue] as? String,
              let verificationStatus = VerificationStatus(rawValue: verificationStatusString) else {
            return nil
        }
        
        let endTime = record[JubileeEventField.endTime.rawValue] as? Date
        let reportCount = record["reportCount"] as? Int ?? 0
        
        // Extract metadata
        guard let temperature = record["temperature"] as? Double,
              let humidity = record["humidity"] as? Double,
              let windSpeed = record["windSpeed"] as? Double,
              let windDirection = record["windDirection"] as? Int,
              let waterTemperature = record["waterTemperature"] as? Double,
              let dissolvedOxygen = record["dissolvedOxygen"] as? Double,
              let salinity = record["salinity"] as? Double,
              let tideString = record["tide"] as? String,
              let tide = TideState(rawValue: tideString),
              let moonPhaseString = record["moonPhase"] as? String,
              let moonPhase = MoonPhase(rawValue: moonPhaseString) else {
            return nil
        }
        
        let metadata = JubileeMetadata(
            windSpeed: windSpeed,
            windDirection: windDirection,
            temperature: temperature,
            humidity: humidity,
            waterTemperature: waterTemperature,
            dissolvedOxygen: dissolvedOxygen,
            salinity: salinity,
            tide: tide,
            moonPhase: moonPhase
        )
        
        return JubileeEvent(
            id: UUID(),
            startTime: startTime,
            endTime: endTime,
            location: location.coordinate,
            intensity: intensity,
            verificationStatus: verificationStatus,
            reportCount: reportCount,
            metadata: metadata
        )
    }
    
    private func userReportFromRecord(_ record: CKRecord) -> UserReport? {
        guard let userIdString = record[UserReportField.userId.rawValue] as? String,
              let userId = UUID(uuidString: userIdString),
              let timestamp = record[UserReportField.timestamp.rawValue] as? Date,
              let description = record[UserReportField.description.rawValue] as? String,
              let intensityString = record[UserReportField.intensity.rawValue] as? String,
              let intensity = JubileeIntensity(rawValue: intensityString),
              let location = record[UserReportField.location.rawValue] as? CLLocation else {
            return nil
        }
        
        let eventIdString = record[UserReportField.jubileeEventId.rawValue] as? String
        let eventId = eventIdString.flatMap { UUID(uuidString: $0) }
        
        let photoURLStrings = record[UserReportField.photoURLs.rawValue] as? [String] ?? []
        let photoReferences = photoURLStrings.compactMap { urlString in
            URL(string: urlString).map { PhotoReference(id: UUID(), url: $0, thumbnailUrl: $0) }
        }
        
        return UserReport(
            id: UUID(),
            userId: userId,
            timestamp: timestamp,
            location: location.coordinate,
            jubileeEventId: eventId,
            description: description,
            photos: photoReferences,
            intensity: intensity
        )
    }
}

// MARK: - CKDatabase Extension for Async/Await

extension CKDatabase {
    func save(_ record: CKRecord) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            save(record) { savedRecord, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let savedRecord = savedRecord {
                    continuation.resume(returning: savedRecord)
                } else {
                    continuation.resume(throwing: CloudKitError.unknown)
                }
            }
        }
    }
    
    func save(_ subscription: CKSubscription) async throws -> CKSubscription {
        try await withCheckedThrowingContinuation { continuation in
            save(subscription) { savedSubscription, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let savedSubscription = savedSubscription {
                    continuation.resume(returning: savedSubscription)
                } else {
                    continuation.resume(throwing: CloudKitError.unknown)
                }
            }
        }
    }
    
    func perform(_ query: CKQuery, resultsLimit: Int = CKQueryOperation.maximumResults) async throws -> [CKRecord] {
        try await withCheckedThrowingContinuation { continuation in
            var records: [CKRecord] = []
            
            let operation = CKQueryOperation(query: query)
            operation.resultsLimit = resultsLimit
            
            operation.recordMatchedBlock = { _, result in
                switch result {
                case .success(let record):
                    records.append(record)
                case .failure:
                    break
                }
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: records)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            self.add(operation)
        }
    }
}

// MARK: - CloudKit Error

enum CloudKitError: LocalizedError {
    case unknown
    case recordNotFound
    case invalidData
    case networkError
    case unauthorized
    case serverError
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "An unknown CloudKit error occurred"
        case .recordNotFound:
            return "The requested record was not found"
        case .invalidData:
            return "The CloudKit data is invalid"
        case .networkError:
            return "Network connection error. Please check your internet connection."
        case .unauthorized:
            return "You are not authorized to perform this action."
        case .serverError:
            return "Server error. Please try again later."
        case .notFound:
            return "The requested item was not found."
        }
    }
}

// MARK: - Community Post Methods

extension CloudKitService {
    
    func fetchCommunityPosts(cursor: CKQueryOperation.Cursor? = nil) async throws -> (posts: [CommunityPost], cursor: CKQueryOperation.Cursor?) {
        let query = CKQuery(recordType: RecordType.communityPost.rawValue, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: CommunityPostField.createdAt.rawValue, ascending: false)]
        
        var posts: [CommunityPost] = []
        var nextCursor: CKQueryOperation.Cursor?
        
        let operation = CKQueryOperation(query: query)
        operation.cursor = cursor
        operation.resultsLimit = 20
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.recordMatchedBlock = { _, result in
                switch result {
                case .success(let record):
                    if let post = self.communityPostFromRecord(record) {
                        posts.append(post)
                    }
                case .failure:
                    break
                }
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success(let cursor):
                    nextCursor = cursor
                    continuation.resume(returning: (posts, nextCursor))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            publicDatabase.add(operation)
        }
    }
    
    func createCommunityPost(from report: UserReport, user: User? = nil) async throws -> CommunityPost {
        let record = CKRecord(recordType: RecordType.communityPost.rawValue)
        
        // Use authenticated user or generate anonymous user
        let userId = user?.appleUserID ?? UUID().uuidString
        let userName = user?.displayName ?? "JubileeSpotter\(Int.random(in: 100...999))"
        
        record[CommunityPostField.userId.rawValue] = userId
        record[CommunityPostField.userName.rawValue] = userName
        record[CommunityPostField.title.rawValue] = "Jubilee Event - \(report.intensity.displayName)"
        record[CommunityPostField.description.rawValue] = report.description
        record[CommunityPostField.location.rawValue] = CLLocation(latitude: report.location.latitude, longitude: report.location.longitude)
        record[CommunityPostField.photoURLs.rawValue] = report.photos.map { $0.url.absoluteString }
        record[CommunityPostField.marineLifeTypes.rawValue] = report.marineLife
        record[CommunityPostField.likeCount.rawValue] = 0
        record[CommunityPostField.commentCount.rawValue] = 0
        record[CommunityPostField.createdAt.rawValue] = Date()
        
        let savedRecord = try await publicDatabase.save(record)
        
        guard let post = communityPostFromRecord(savedRecord) else {
            throw CloudKitError.invalidData
        }
        
        return post
    }
    
    func likePost(postId: String) async throws {
        // Check if already liked
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K == %@", PostLikeField.postId.rawValue, postId),
            NSPredicate(format: "%K == %@", PostLikeField.userId.rawValue, getCurrentUserId())
        ])
        
        let query = CKQuery(recordType: RecordType.postLike.rawValue, predicate: predicate)
        let existingLikes = try await publicDatabase.perform(query, resultsLimit: 1)
        
        guard existingLikes.isEmpty else {
            return // Already liked
        }
        
        // Create like record
        let likeRecord = CKRecord(recordType: RecordType.postLike.rawValue)
        likeRecord[PostLikeField.postId.rawValue] = postId
        likeRecord[PostLikeField.userId.rawValue] = getCurrentUserId()
        likeRecord[PostLikeField.createdAt.rawValue] = Date()
        
        _ = try await publicDatabase.save(likeRecord)
        
        // Update post like count
        try await incrementPostLikeCount(postId: postId, by: 1)
    }
    
    func unlikePost(postId: String) async throws {
        // Find existing like
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K == %@", PostLikeField.postId.rawValue, postId),
            NSPredicate(format: "%K == %@", PostLikeField.userId.rawValue, getCurrentUserId())
        ])
        
        let query = CKQuery(recordType: RecordType.postLike.rawValue, predicate: predicate)
        let likes = try await publicDatabase.perform(query, resultsLimit: 1)
        
        guard let likeRecord = likes.first else {
            return // Not liked
        }
        
        // Delete like record
        _ = try await publicDatabase.delete(withRecordID: likeRecord.recordID)
        
        // Update post like count
        try await incrementPostLikeCount(postId: postId, by: -1)
    }
    
    private func incrementPostLikeCount(postId: String, by amount: Int) async throws {
        let recordId = CKRecord.ID(recordName: postId)
        
        let record = try await publicDatabase.fetch(withRecordID: recordId)
        let currentCount = record[CommunityPostField.likeCount.rawValue] as? Int ?? 0
        record[CommunityPostField.likeCount.rawValue] = max(0, currentCount + amount)
        
        _ = try await publicDatabase.save(record)
    }
    
    private func communityPostFromRecord(_ record: CKRecord) -> CommunityPost? {
        guard let userId = record[CommunityPostField.userId.rawValue] as? String,
              let userName = record[CommunityPostField.userName.rawValue] as? String,
              let title = record[CommunityPostField.title.rawValue] as? String,
              let description = record[CommunityPostField.description.rawValue] as? String,
              let location = record[CommunityPostField.location.rawValue] as? CLLocation,
              let createdAt = record[CommunityPostField.createdAt.rawValue] as? Date else {
            return nil
        }
        
        let photoURLs = record[CommunityPostField.photoURLs.rawValue] as? [String] ?? []
        let marineLifeStrings = record[CommunityPostField.marineLifeTypes.rawValue] as? [String] ?? []
        // For now, convert strings to MarineLifeType.other since we store as strings
        let marineLifeTypes = Set(marineLifeStrings.map { _ in MarineLifeType.other })
        let likeCount = record[CommunityPostField.likeCount.rawValue] as? Int ?? 0
        let commentCount = record[CommunityPostField.commentCount.rawValue] as? Int ?? 0
        
        // Check if current user liked this post
        // In a real app, this would be done with a separate query or cached data
        let isLikedByCurrentUser = false
        
        return CommunityPost(
            id: record.recordID.recordName,
            userId: userId,
            userName: userName,
            title: title,
            description: description,
            location: location.coordinate,
            photoURLs: photoURLs,
            marineLifeTypes: marineLifeTypes,
            createdAt: createdAt,
            likeCount: likeCount,
            commentCount: commentCount,
            isLikedByCurrentUser: isLikedByCurrentUser
        )
    }
    
    private func getCurrentUserId() -> String {
        // In a real app, this would come from authentication
        return UUID().uuidString
    }
    
    func fetchComments(for postId: String) async throws -> [CommunityComment] {
        // Placeholder implementation
        return []
    }
    
    func addComment(to postId: String, text: String) async throws -> CommunityComment {
        // Placeholder implementation
        let comment = CommunityComment(
            id: UUID().uuidString,
            postId: postId,
            userId: getCurrentUserId(),
            userName: "User",
            text: text,
            createdAt: Date()
        )
        return comment
    }
}

// MARK: - User Authentication Methods

extension CloudKitService {
    
    private enum UserProfileField: String {
        case appleUserID
        case email
        case displayName
        case createdAt
    }
    
    func saveUser(_ user: User) async throws {
        let record = CKRecord(recordType: RecordType.userProfile.rawValue, recordID: CKRecord.ID(recordName: user.id))
        
        record[UserProfileField.appleUserID.rawValue] = user.appleUserID
        record[UserProfileField.email.rawValue] = user.email
        record[UserProfileField.displayName.rawValue] = user.displayName
        record[UserProfileField.createdAt.rawValue] = user.createdAt
        
        _ = try await privateDatabase.save(record)
    }
    
    func fetchCurrentUser() async throws -> User? {
        // Check if user has an active CloudKit account
        do {
            let userRecordID = try await container.userRecordID()
            
            // Fetch user profile from private database
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: RecordType.userProfile.rawValue, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: UserProfileField.createdAt.rawValue, ascending: false)]
            
            let records = try await privateDatabase.perform(query, resultsLimit: 10)
            
            // Find the first valid user record
            for record in records {
                if let user = userFromRecord(record) {
                    return user
                }
            }
            
            return nil
        } catch {
            // If there's an error fetching the user, return nil
            print("Error fetching current user: \(error)")
            return nil
        }
    }
    
    private func userFromRecord(_ record: CKRecord) -> User? {
        guard let appleUserID = record[UserProfileField.appleUserID.rawValue] as? String,
              let email = record[UserProfileField.email.rawValue] as? String,
              let displayName = record[UserProfileField.displayName.rawValue] as? String,
              let createdAt = record[UserProfileField.createdAt.rawValue] as? Date else {
            return nil
        }
        
        return User(
            id: record.recordID.recordName,
            appleUserID: appleUserID,
            email: email,
            displayName: displayName,
            createdAt: createdAt
        )
    }
}

// MARK: - CKDatabase Extension

extension CKDatabase {
    func fetch(withRecordID recordID: CKRecord.ID) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            fetch(withRecordID: recordID) { record, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let record = record {
                    continuation.resume(returning: record)
                } else {
                    continuation.resume(throwing: CloudKitError.recordNotFound)
                }
            }
        }
    }
    
    func delete(withRecordID recordID: CKRecord.ID) async throws -> CKRecord.ID {
        try await withCheckedThrowingContinuation { continuation in
            delete(withRecordID: recordID) { recordID, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let recordID = recordID {
                    continuation.resume(returning: recordID)
                } else {
                    continuation.resume(throwing: CloudKitError.unknown)
                }
            }
        }
    }
}