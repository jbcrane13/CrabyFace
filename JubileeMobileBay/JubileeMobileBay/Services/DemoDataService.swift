//
//  DemoDataService.swift
//  JubileeMobileBay
//
//  Creates demo data for testing when no real data exists
//

import Foundation
import CoreLocation

class DemoDataService {
    
    static func createDemoCommunityPosts() -> [CommunityPost] {
        let locations = [
            CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399), // Mobile Bay
            CLLocationCoordinate2D(latitude: 30.2672, longitude: -87.5503), // Eastern Shore
            CLLocationCoordinate2D(latitude: 30.3960, longitude: -87.6835), // Fairhope
            CLLocationCoordinate2D(latitude: 30.5274, longitude: -87.8814), // Daphne
            CLLocationCoordinate2D(latitude: 30.3767, longitude: -87.6831)  // Point Clear
        ]
        
        let posts = [
            CommunityPost(
                id: "demo1",
                userId: "demoUser1",
                userName: "MarineBiologist23",
                title: "Major Jubilee Event - Eastern Shore",
                description: "Incredible jubilee event happening right now! Thousands of flounder, crabs, and shrimp coming to shore. The water conditions are perfect - low oxygen levels after last night's calm conditions.",
                location: locations[1],
                photoURLs: [],
                marineLifeTypes: Set([.flounder, .crab, .shrimp]),
                createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
                likeCount: 45,
                commentCount: 12,
                isLikedByCurrentUser: false
            ),
            CommunityPost(
                id: "demo2",
                userId: "demoUser2",
                userName: "BayWatcher",
                title: "Small Jubilee Near Fairhope Pier",
                description: "Just spotted some blue crabs and a few flounder near the pier. Not a major event but worth checking out if you're in the area. Water temperature seems unusually warm.",
                location: locations[2],
                photoURLs: [],
                marineLifeTypes: Set([.crab, .flounder]),
                createdAt: Date().addingTimeInterval(-7200), // 2 hours ago
                likeCount: 23,
                commentCount: 5,
                isLikedByCurrentUser: true
            ),
            CommunityPost(
                id: "demo3",
                userId: "demoUser3",
                userName: "CoastalExplorer",
                title: "Stingray Sighting During Morning Jubilee",
                description: "Early morning jubilee brought in several stingrays along with the usual suspects. First time I've seen rays during a jubilee event! Also lots of eels and some small sharks.",
                location: locations[3],
                photoURLs: [],
                marineLifeTypes: Set([.ray, .eel, .other]),
                createdAt: Date().addingTimeInterval(-10800), // 3 hours ago
                likeCount: 67,
                commentCount: 18,
                isLikedByCurrentUser: false
            ),
            CommunityPost(
                id: "demo4",
                userId: "demoUser4",
                userName: "JubileeHunter",
                title: "Massive Shrimp Migration",
                description: "The shrimp are literally jumping out of the water! This is one of the largest shrimp jubilees I've seen in years. Bring your nets if you want to catch dinner!",
                location: locations[4],
                photoURLs: [],
                marineLifeTypes: Set([.shrimp]),
                createdAt: Date().addingTimeInterval(-14400), // 4 hours ago
                likeCount: 89,
                commentCount: 24,
                isLikedByCurrentUser: true
            ),
            CommunityPost(
                id: "demo5",
                userId: "demoUser5",
                userName: "MobileBayLocal",
                title: "Jubilee Conditions Developing",
                description: "Water is getting that glassy look and I'm seeing some crabs starting to move toward shore. Might be a good night to keep an eye on the bay. Wind is calm and tide is right.",
                location: locations[0],
                photoURLs: [],
                marineLifeTypes: Set([.crab]),
                createdAt: Date().addingTimeInterval(-21600), // 6 hours ago
                likeCount: 34,
                commentCount: 8,
                isLikedByCurrentUser: false
            )
        ]
        
        return posts
    }
    
    static func createDemoJubileeEvents() -> [JubileeEvent] {
        let locations = [
            CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            CLLocationCoordinate2D(latitude: 30.2672, longitude: -87.5503),
            CLLocationCoordinate2D(latitude: 30.3960, longitude: -87.6835)
        ]
        
        let events = [
            JubileeEvent(
                id: UUID(),
                startTime: Date().addingTimeInterval(-3600),
                endTime: nil,
                location: locations[0],
                intensity: .heavy,
                verificationStatus: .verified,
                reportCount: 15,
                reportedBy: "DemoUser1",
                metadata: JubileeMetadata(
                    windSpeed: 5.2,
                    windDirection: 180,
                    temperature: 78.5,
                    humidity: 85.0,
                    waterTemperature: 82.0,
                    dissolvedOxygen: 2.1,
                    salinity: 28.5,
                    tide: .low,
                    moonPhase: .full
                )
            ),
            JubileeEvent(
                id: UUID(),
                startTime: Date().addingTimeInterval(-7200),
                endTime: Date().addingTimeInterval(-3600),
                location: locations[1],
                intensity: .light,
                verificationStatus: .verified,
                reportCount: 8,
                reportedBy: "DemoUser2",
                metadata: JubileeMetadata(
                    windSpeed: 3.8,
                    windDirection: 210,
                    temperature: 76.0,
                    humidity: 82.0,
                    waterTemperature: 80.5,
                    dissolvedOxygen: 2.8,
                    salinity: 27.0,
                    tide: .rising,
                    moonPhase: .full
                )
            ),
            JubileeEvent(
                id: UUID(),
                startTime: Date().addingTimeInterval(-86400), // Yesterday
                endTime: Date().addingTimeInterval(-82800),
                location: locations[2],
                intensity: .moderate,
                verificationStatus: .userReported,
                reportCount: 5,
                reportedBy: "DemoUser3",
                metadata: JubileeMetadata(
                    windSpeed: 6.5,
                    windDirection: 165,
                    temperature: 75.0,
                    humidity: 78.0,
                    waterTemperature: 79.0,
                    dissolvedOxygen: 3.2,
                    salinity: 26.5,
                    tide: .high,
                    moonPhase: .lastQuarter
                )
            )
        ]
        
        return events
    }
}