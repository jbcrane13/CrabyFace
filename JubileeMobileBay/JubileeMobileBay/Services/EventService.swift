//
//  EventService.swift
//  JubileeMobileBay
//
//  Created on 1/19/25.
//

import Foundation
import CoreLocation

protocol EventServiceProtocol {
    func loadEvents() async throws -> [JubileeEvent]
    func reportEvent(_ event: JubileeEvent) async throws
}

// Temporary mock implementation for Phase 2
class MockEventService: EventServiceProtocol {
    func loadEvents() async throws -> [JubileeEvent] {
        // Return some mock events for testing
        return [
            JubileeEvent(
                id: UUID(),
                startTime: Date().addingTimeInterval(-3600),
                endTime: nil,
                location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
                intensity: .moderate,
                verificationStatus: .userReported,
                reportCount: 5,
                reportedBy: "User1",
                metadata: JubileeMetadata(
                    windSpeed: 5.0,
                    windDirection: 180,
                    temperature: 75.0,
                    humidity: 85.0,
                    waterTemperature: 74.0,
                    dissolvedOxygen: 2.0,
                    salinity: 25.0,
                    tide: .rising,
                    moonPhase: .full
                )
            ),
            JubileeEvent(
                id: UUID(),
                startTime: Date().addingTimeInterval(-7200),
                endTime: Date().addingTimeInterval(-3600),
                location: CLLocationCoordinate2D(latitude: 30.72, longitude: -88.06),
                intensity: .light,
                verificationStatus: .verified,
                reportCount: 12,
                reportedBy: "User2",
                metadata: JubileeMetadata(
                    windSpeed: 3.0,
                    windDirection: 90,
                    temperature: 73.0,
                    humidity: 90.0,
                    waterTemperature: 72.0,
                    dissolvedOxygen: 1.5,
                    salinity: 24.0,
                    tide: .high,
                    moonPhase: .full
                )
            ),
            JubileeEvent(
                id: UUID(),
                startTime: Date().addingTimeInterval(-1800),
                endTime: nil,
                location: CLLocationCoordinate2D(latitude: 30.68, longitude: -88.03),
                intensity: .heavy,
                verificationStatus: .predicted,
                reportCount: 0,
                reportedBy: "System",
                metadata: JubileeMetadata(
                    windSpeed: 2.0,
                    windDirection: 270,
                    temperature: 76.0,
                    humidity: 95.0,
                    waterTemperature: 75.0,
                    dissolvedOxygen: 1.0,
                    salinity: 26.0,
                    tide: .falling,
                    moonPhase: .waningGibbous
                )
            )
        ]
    }
    
    func reportEvent(_ event: JubileeEvent) async throws {
        // Mock implementation - in real app would save to CloudKit
        print("Event reported: \(event.id)")
    }
}