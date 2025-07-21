import Foundation

struct JubileeMetadata: Codable, Equatable, Hashable {
    let windSpeed: Double
    let windDirection: Int
    let temperature: Double
    let humidity: Double
    let waterTemperature: Double
    let dissolvedOxygen: Double
    let salinity: Double
    let tide: TideState
    let moonPhase: MoonPhase
    
    init(
        windSpeed: Double,
        windDirection: Int,
        temperature: Double,
        humidity: Double,
        waterTemperature: Double,
        dissolvedOxygen: Double,
        salinity: Double,
        tide: TideState,
        moonPhase: MoonPhase
    ) {
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.temperature = temperature
        self.humidity = humidity
        self.waterTemperature = waterTemperature
        self.dissolvedOxygen = dissolvedOxygen
        self.salinity = salinity
        self.tide = tide
        self.moonPhase = moonPhase
    }
}