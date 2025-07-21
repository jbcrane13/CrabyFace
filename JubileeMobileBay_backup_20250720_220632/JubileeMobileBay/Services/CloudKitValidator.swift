//
//  CloudKitValidator.swift
//  JubileeMobileBay
//
//  Validates data before saving to CloudKit
//

import Foundation
import CoreLocation

final class CloudKitValidator {
    
    // MARK: - Constants
    
    private enum ValidationConstants {
        static let maxDescriptionLength = 1000
        static let minDescriptionLength = 10
        static let maxTitleLength = 100
        static let maxUserNameLength = 50
        static let maxMarineLifeCount = 10
        static let maxPhotoCount = 10
        static let validEmailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        static let validLatitudeRange = -90.0...90.0
        static let validLongitudeRange = -180.0...180.0
    }
    
    // MARK: - Error Types
    
    enum ValidationError: LocalizedError {
        case invalidEmail
        case descriptionTooShort
        case descriptionTooLong
        case titleTooLong
        case userNameTooLong
        case tooManyMarineLifeTypes
        case tooManyPhotos
        case invalidLocation
        case invalidIntensity
        case invalidTimestamp
        case missingRequiredField(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidEmail:
                return "Please provide a valid email address"
            case .descriptionTooShort:
                return "Description must be at least \(ValidationConstants.minDescriptionLength) characters"
            case .descriptionTooLong:
                return "Description cannot exceed \(ValidationConstants.maxDescriptionLength) characters"
            case .titleTooLong:
                return "Title cannot exceed \(ValidationConstants.maxTitleLength) characters"
            case .userNameTooLong:
                return "Username cannot exceed \(ValidationConstants.maxUserNameLength) characters"
            case .tooManyMarineLifeTypes:
                return "Cannot specify more than \(ValidationConstants.maxMarineLifeCount) marine life types"
            case .tooManyPhotos:
                return "Cannot upload more than \(ValidationConstants.maxPhotoCount) photos"
            case .invalidLocation:
                return "Invalid location coordinates"
            case .invalidIntensity:
                return "Invalid intensity value"
            case .invalidTimestamp:
                return "Invalid timestamp - cannot be in the future"
            case .missingRequiredField(let field):
                return "Required field missing: \(field)"
            }
        }
    }
    
    // MARK: - Validation Methods
    
    static func validateUserReport(_ report: UserReport) throws {
        // Validate description
        try validateDescription(report.description)
        
        // Validate location
        try validateLocation(report.location)
        
        // Validate marine life count
        if report.marineLife.count > ValidationConstants.maxMarineLifeCount {
            throw ValidationError.tooManyMarineLifeTypes
        }
        
        // Validate photo count
        if report.photos.count > ValidationConstants.maxPhotoCount {
            throw ValidationError.tooManyPhotos
        }
        
        // Validate timestamp not in future
        if report.timestamp > Date() {
            throw ValidationError.invalidTimestamp
        }
    }
    
    static func validateJubileeEvent(_ event: JubileeEvent) throws {
        // Validate location
        try validateLocation(event.location)
        
        // Validate timestamps
        if event.startTime > Date() {
            throw ValidationError.invalidTimestamp
        }
        
        if let endTime = event.endTime, endTime > Date() {
            throw ValidationError.invalidTimestamp
        }
        
        // Validate metadata
        try validateJubileeMetadata(event.metadata)
    }
    
    static func validateCommunityPost(title: String, description: String, location: CLLocationCoordinate2D, photoURLs: [String]) throws {
        // Validate title
        if title.isEmpty {
            throw ValidationError.missingRequiredField("title")
        }
        if title.count > ValidationConstants.maxTitleLength {
            throw ValidationError.titleTooLong
        }
        
        // Validate description
        try validateDescription(description)
        
        // Validate location
        try validateLocation(location)
        
        // Validate photo count
        if photoURLs.count > ValidationConstants.maxPhotoCount {
            throw ValidationError.tooManyPhotos
        }
    }
    
    static func validateUser(_ user: User) throws {
        // Validate email
        try validateEmail(user.email)
        
        // Validate display name
        if user.displayName.isEmpty {
            throw ValidationError.missingRequiredField("displayName")
        }
        if user.displayName.count > ValidationConstants.maxUserNameLength {
            throw ValidationError.userNameTooLong
        }
    }
    
    // MARK: - Helper Validation Methods
    
    private static func validateEmail(_ email: String) throws {
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", ValidationConstants.validEmailRegex)
        if !emailPredicate.evaluate(with: email) {
            throw ValidationError.invalidEmail
        }
    }
    
    private static func validateDescription(_ description: String) throws {
        if description.count < ValidationConstants.minDescriptionLength {
            throw ValidationError.descriptionTooShort
        }
        if description.count > ValidationConstants.maxDescriptionLength {
            throw ValidationError.descriptionTooLong
        }
    }
    
    private static func validateLocation(_ location: CLLocationCoordinate2D) throws {
        if !ValidationConstants.validLatitudeRange.contains(location.latitude) ||
           !ValidationConstants.validLongitudeRange.contains(location.longitude) {
            throw ValidationError.invalidLocation
        }
    }
    
    private static func validateJubileeMetadata(_ metadata: JubileeMetadata) throws {
        // Validate reasonable ranges for environmental data
        if metadata.temperature < -50 || metadata.temperature > 60 {
            throw ValidationError.missingRequiredField("valid temperature")
        }
        
        if metadata.humidity < 0 || metadata.humidity > 100 {
            throw ValidationError.missingRequiredField("valid humidity")
        }
        
        if metadata.windSpeed < 0 || metadata.windSpeed > 200 {
            throw ValidationError.missingRequiredField("valid wind speed")
        }
        
        if metadata.dissolvedOxygen < 0 || metadata.dissolvedOxygen > 20 {
            throw ValidationError.missingRequiredField("valid dissolved oxygen")
        }
    }
    
    // MARK: - Sanitization Methods
    
    static func sanitizeString(_ input: String) -> String {
        // Remove leading/trailing whitespace
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove any potential script injection attempts
        let sanitized = trimmed
            .replacingOccurrences(of: "<script", with: "&lt;script", options: .caseInsensitive)
            .replacingOccurrences(of: "</script", with: "&lt;/script", options: .caseInsensitive)
            .replacingOccurrences(of: "javascript:", with: "", options: .caseInsensitive)
        
        return sanitized
    }
    
    static func sanitizeUserInput(_ input: String, maxLength: Int) -> String {
        let sanitized = sanitizeString(input)
        
        // Truncate if too long
        if sanitized.count > maxLength {
            return String(sanitized.prefix(maxLength))
        }
        
        return sanitized
    }
}