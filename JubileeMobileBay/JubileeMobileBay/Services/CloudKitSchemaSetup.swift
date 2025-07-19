//
//  CloudKitSchemaSetup.swift
//  JubileeMobileBay
//
//  CloudKit schema setup helper
//

import Foundation
import CloudKit
import CoreLocation

/// Helper class to verify CloudKit schema setup
/// This class is used during development to ensure all required record types are properly configured
@MainActor
class CloudKitSchemaSetup: ObservableObject {
    
    private let container: CKContainer
    private let publicDatabase: CKDatabase
    private let privateDatabase: CKDatabase
    
    @Published var schemaStatus: SchemaStatus = .notChecked
    @Published var statusMessage = ""
    
    enum SchemaStatus {
        case notChecked
        case checking
        case ready
        case needsSetup
        case error
    }
    
    init(container: CKContainer? = nil) {
        self.container = container ?? CKContainer(identifier: "iCloud.com.jubileemobilebay.app")
        self.publicDatabase = self.container.publicCloudDatabase
        self.privateDatabase = self.container.privateCloudDatabase
    }
    
    // MARK: - Schema Verification
    
    func verifySchema() async {
        schemaStatus = .checking
        statusMessage = "Checking CloudKit schema..."
        
        do {
            // Check public database record types
            let publicRecordTypes = [
                CloudKitService.RecordType.jubileeEvent.rawValue,
                CloudKitService.RecordType.userReport.rawValue,
                CloudKitService.RecordType.environmentalData.rawValue
            ]
            
            for recordType in publicRecordTypes {
                try await verifyRecordType(recordType, in: publicDatabase)
            }
            
            // Check private database record types
            let privateRecordTypes = [
                CloudKitService.RecordType.userProfile.rawValue
            ]
            
            for recordType in privateRecordTypes {
                try await verifyRecordType(recordType, in: privateDatabase)
            }
            
            schemaStatus = .ready
            statusMessage = "CloudKit schema is properly configured"
            
        } catch {
            schemaStatus = .error
            statusMessage = "Schema verification failed: \(error.localizedDescription)"
        }
    }
    
    private func verifyRecordType(_ recordType: String, in database: CKDatabase) async throws {
        // Create a dummy query to verify the record type exists
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: false))
        
        do {
            // This will fail if the record type doesn't exist
            _ = try await database.perform(query, resultsLimit: 1)
        } catch let error as CKError {
            if error.code == .unknownItem || error.code == .invalidArguments {
                throw SchemaError.recordTypeNotFound(recordType)
            }
            // Other errors might just mean no records exist, which is fine
        }
    }
    
    // MARK: - Sample Data Creation
    
    func createSampleData() async throws {
        guard schemaStatus == .ready else {
            throw SchemaError.schemaNotReady
        }
        
        statusMessage = "Creating sample data..."
        
        // Create sample jubilee event
        let metadata = JubileeMetadata(
            windSpeed: 3.5,
            windDirection: 225,
            temperature: 78.0,
            humidity: 92.0,
            waterTemperature: 76.0,
            dissolvedOxygen: 2.1,
            salinity: 28.5,
            tide: .falling,
            moonPhase: .waxingGibbous
        )
        
        let sampleEvent = JubileeEvent(
            startTime: Date().addingTimeInterval(-3600), // 1 hour ago
            location: CLLocationCoordinate2D(latitude: 30.4672, longitude: -87.9833),
            intensity: .moderate,
            verificationStatus: .verified,
            reportCount: 3,
            metadata: metadata
        )
        
        let cloudKitService = CloudKitService(container: container)
        try await cloudKitService.saveJubileeEvent(sampleEvent)
        
        statusMessage = "Sample data created successfully"
    }
    
    // MARK: - Error Types
    
    enum SchemaError: LocalizedError {
        case recordTypeNotFound(String)
        case schemaNotReady
        
        var errorDescription: String? {
            switch self {
            case .recordTypeNotFound(let recordType):
                return "Record type '\(recordType)' not found in CloudKit schema"
            case .schemaNotReady:
                return "CloudKit schema is not ready"
            }
        }
    }
}

// MARK: - Schema Documentation

extension CloudKitSchemaSetup {
    
    /// Prints the CloudKit schema documentation to the console
    /// Useful for developers setting up the CloudKit dashboard
    static func printSchemaDocumentation() {
        print("""
        CloudKit Schema Setup Instructions
        ==================================
        
        1. Go to CloudKit Dashboard: https://icloud.developer.apple.com/dashboard
        2. Select the container: iCloud.com.jubileemobilebay.app
        3. Create the following record types:
        
        PUBLIC DATABASE:
        
        JubileeEvent:
        - location (Location)
        - intensity (String)
        - startTime (Date)
        - endTime (Date, optional)
        - verificationStatus (String)
        - reportCount (Int64)
        - temperature (Double)
        - humidity (Double)
        - windSpeed (Double)
        - windDirection (Int64)
        - waterTemperature (Double)
        - dissolvedOxygen (Double)
        - salinity (Double)
        - tide (String)
        - moonPhase (String)
        
        UserReport:
        - jubileeEventId (String, optional)
        - userId (String)
        - timestamp (Date)
        - description (String)
        - intensity (String)
        - location (Location)
        - photoURLs (String List, optional)
        
        EnvironmentalData:
        - location (Location)
        - timestamp (Date)
        - temperature (Double)
        - humidity (Double)
        - pressure (Double, optional)
        - windSpeed (Double)
        - windDirection (Int64)
        - waterTemperature (Double, optional)
        - dissolvedOxygen (Double, optional)
        - salinity (Double, optional)
        - ph (Double, optional)
        - turbidity (Double, optional)
        - dataSource (String)
        
        PRIVATE DATABASE:
        
        UserProfile:
        - userId (String)
        - displayName (String)
        - email (String, optional)
        - favoriteLocations (Location List)
        - notificationRadius (Double)
        - notificationPreferences (Bytes)
        - reportCount (Int64)
        - verifiedReportCount (Int64)
        - credibilityScore (Double)
        
        4. Add indexes as specified in CloudKitSchema.md
        5. Configure security roles for authenticated users
        """)
    }
}