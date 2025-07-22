//
//  MockDataService.swift
//  JubileeMobileBay
//
//  Mock data providers for development and demo purposes
//

import Foundation

// MARK: - Mock Weather API Service

final class MockWeatherAPIService: WeatherAPIProtocol {
    func fetchCurrentConditions() async throws -> WeatherConditions {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        return WeatherConditions(
            temperature: 78.5,
            humidity: 72.0,
            windSpeed: 8.5,
            windDirection: "SW",
            pressure: 1015.2,
            visibility: 10.0,
            uvIndex: 7,
            cloudCover: 25
        )
    }
    
    func fetchHourlyForecast(hours: Int) async throws -> [WeatherForecast] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let now = Date()
        var forecasts: [WeatherForecast] = []
        
        for hour in 0..<hours {
            let forecast = WeatherForecast(
                date: now.addingTimeInterval(Double(hour) * 3600),
                temperature: 78.0 + sin(Double(hour) * .pi / 12) * 5, // Varies between 73-83
                humidity: 70.0 + Double(hour % 6) * 2,
                windSpeed: 8.0 + Double(hour % 4),
                windDirection: ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][hour % 8],
                precipitationChance: hour < 12 ? 10 : 20,
                conditions: hour < 6 || hour > 18 ? "Clear" : "Partly Cloudy",
                icon: hour < 6 || hour > 18 ? "moon.stars" : "cloud.sun"
            )
            forecasts.append(forecast)
        }
        
        return forecasts
    }
    
    func fetchTideData() async throws -> [TideData] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let now = Date()
        return [
            TideData(
                time: now.addingTimeInterval(2 * 3600),
                height: 1.8,
                type: .high
            ),
            TideData(
                time: now.addingTimeInterval(8 * 3600),
                height: 0.3,
                type: .low
            ),
            TideData(
                time: now.addingTimeInterval(14 * 3600),
                height: 1.9,
                type: .high
            ),
            TideData(
                time: now.addingTimeInterval(20 * 3600),
                height: 0.2,
                type: .low
            )
        ]
    }
}

// MARK: - Mock Marine Data Service

final class MockMarineDataService: MarineDataProtocol {
    func fetchNearbyStations(latitude: Double, longitude: Double, radius: Double) async throws -> [MonitoringStation] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Return mock monitoring stations
        return [
            MonitoringStation(
                id: "MBLA1",
                name: "Mobile Bay - Meaher Park",
                latitude: 30.6954,
                longitude: -88.0399,
                type: .buoy,
                status: .active
            ),
            MonitoringStation(
                id: "MBLA2",
                name: "Mobile Bay - Fairhope Pier",
                latitude: 30.5280,
                longitude: -87.9341,
                type: .shore,
                status: .active
            ),
            MonitoringStation(
                id: "MBLA3",
                name: "Mobile Bay - Dauphin Island",
                latitude: 30.2500,
                longitude: -88.0753,
                type: .platform,
                status: .active
            )
        ]
    }
    
    func fetchCurrentConditions() async throws -> MarineConditions {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000)
        
        return MarineConditions(
            waterQuality: WaterQuality(
                temperature: 76.5,
                dissolvedOxygen: 3.2, // Low-ish for demo
                ph: 7.8,
                salinity: 32.5,
                turbidity: 12.0,
                chlorophyll: 2.5
            ),
            current: CurrentData(
                speed: 0.6,
                direction: 180,
                temperature: 76.0
            ),
            wave: WaveData(
                height: 1.5,
                period: 6.0,
                direction: 135
            ),
            timestamp: Date()
        )
    }
    
    func fetchHistoricalData(from startDate: Date, to endDate: Date) async throws -> [MarineConditions] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000)
        
        var conditions: [MarineConditions] = []
        var currentDate = startDate
        let calendar = Calendar.current
        
        while currentDate <= endDate {
            let dayOffset = calendar.dateComponents([.day], from: startDate, to: currentDate).day ?? 0
            
            // Create realistic oxygen decline pattern
            let baseOxygen = 5.0 - (Double(dayOffset) * 0.3)
            let oxygen = max(2.0, baseOxygen + sin(Double(dayOffset) * .pi / 3) * 0.5)
            
            let condition = MarineConditions(
                waterQuality: WaterQuality(
                    temperature: 75.0 + Double(dayOffset % 3),
                    dissolvedOxygen: oxygen,
                    ph: 7.8 + Double(dayOffset % 2) * 0.1,
                    salinity: 32.0 + Double(dayOffset % 4) * 0.5,
                    turbidity: 10.0 + Double(dayOffset % 5),
                    chlorophyll: 2.0 + Double(dayOffset % 3) * 0.5
                ),
                current: CurrentData(
                    speed: 0.5 + Double(dayOffset % 3) * 0.1,
                    direction: 180 + dayOffset * 10,
                    temperature: 75.0
                ),
                wave: WaveData(
                    height: 1.0 + Double(dayOffset % 4) * 0.5,
                    period: 5.0 + Double(dayOffset % 3),
                    direction: 90 + dayOffset * 15
                ),
                timestamp: currentDate
            )
            
            conditions.append(condition)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return conditions
    }
}

// MARK: - Mock CloudKit Service

extension CloudKitService {
    @MainActor
    static func createMockService() -> CloudKitService {
        let service = CloudKitService()
        // Service already has some mock functionality built in
        return service
    }
}

// MARK: - Development Data Provider

@MainActor
struct DevelopmentDataProvider {
    static let shared = DevelopmentDataProvider()
    
    let weatherAPI: WeatherAPIProtocol
    let marineAPI: MarineDataProtocol
    let cloudKitService: CloudKitService
    
    private init() {
        self.weatherAPI = MockWeatherAPIService()
        self.marineAPI = MockMarineDataService()
        self.cloudKitService = CloudKitService.createMockService()
    }
    
    var authService: AuthenticationService {
        AuthenticationService(cloudKitService: cloudKitService)
    }
    
    var predictionService: PredictionService {
        PredictionService(
            weatherAPI: weatherAPI,
            marineAPI: marineAPI
        )
    }
}