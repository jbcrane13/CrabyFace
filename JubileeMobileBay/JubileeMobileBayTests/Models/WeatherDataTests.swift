import XCTest
@testable import JubileeMobileBay

final class WeatherDataTests: XCTestCase {
    
    // MARK: - Current Conditions Tests
    
    func test_weatherConditions_initialization_shouldSetAllProperties() {
        // Given
        let temperature = 78.5
        let humidity = 85.0
        let windSpeed = 3.0
        let windDirection = "E"
        let pressure = 1013.25
        let visibility = 10.0
        let uvIndex = 8
        let cloudCover = 25
        
        // When
        let conditions = WeatherConditions(
            temperature: temperature,
            humidity: humidity,
            windSpeed: windSpeed,
            windDirection: windDirection,
            pressure: pressure,
            visibility: visibility,
            uvIndex: uvIndex,
            cloudCover: cloudCover
        )
        
        // Then
        XCTAssertEqual(conditions.temperature, temperature)
        XCTAssertEqual(conditions.humidity, humidity)
        XCTAssertEqual(conditions.windSpeed, windSpeed)
        XCTAssertEqual(conditions.windDirection, windDirection)
        XCTAssertEqual(conditions.pressure, pressure)
        XCTAssertEqual(conditions.visibility, visibility)
        XCTAssertEqual(conditions.uvIndex, uvIndex)
        XCTAssertEqual(conditions.cloudCover, cloudCover)
    }
    
    func test_weatherConditions_decodingFromJSON_shouldDecodeCorrectly() throws {
        // Given
        let json = """
        {
            "temperature": 75.2,
            "humidity": 80.5,
            "windSpeed": 5.5,
            "windDirection": "NE",
            "pressure": 1015.0,
            "visibility": 12.0,
            "uvIndex": 6,
            "cloudCover": 40
        }
        """.data(using: .utf8)!
        
        // When
        let conditions = try JSONDecoder().decode(WeatherConditions.self, from: json)
        
        // Then
        XCTAssertEqual(conditions.temperature, 75.2)
        XCTAssertEqual(conditions.humidity, 80.5)
        XCTAssertEqual(conditions.windSpeed, 5.5)
        XCTAssertEqual(conditions.windDirection, "NE")
        XCTAssertEqual(conditions.pressure, 1015.0)
        XCTAssertEqual(conditions.visibility, 12.0)
        XCTAssertEqual(conditions.uvIndex, 6)
        XCTAssertEqual(conditions.cloudCover, 40)
    }
    
    // MARK: - Forecast Tests
    
    func test_weatherForecast_initialization_shouldSetAllProperties() {
        // Given
        let date = Date()
        let temperature = 82.0
        let humidity = 70.0
        let windSpeed = 8.0
        let windDirection = "SW"
        let precipitationChance = 20
        let conditions = "Partly Cloudy"
        let icon = "partly-cloudy"
        
        // When
        let forecast = WeatherForecast(
            date: date,
            temperature: temperature,
            humidity: humidity,
            windSpeed: windSpeed,
            windDirection: windDirection,
            precipitationChance: precipitationChance,
            conditions: conditions,
            icon: icon
        )
        
        // Then
        XCTAssertEqual(forecast.date, date)
        XCTAssertEqual(forecast.temperature, temperature)
        XCTAssertEqual(forecast.humidity, humidity)
        XCTAssertEqual(forecast.windSpeed, windSpeed)
        XCTAssertEqual(forecast.windDirection, windDirection)
        XCTAssertEqual(forecast.precipitationChance, precipitationChance)
        XCTAssertEqual(forecast.conditions, conditions)
        XCTAssertEqual(forecast.icon, icon)
    }
    
    // MARK: - Tide Tests
    
    func test_tideData_initialization_shouldSetAllProperties() {
        // Given
        let time = Date()
        let height = 5.2
        let type = TideType.high
        
        // When
        let tide = TideData(time: time, height: height, type: type)
        
        // Then
        XCTAssertEqual(tide.time, time)
        XCTAssertEqual(tide.height, height)
        XCTAssertEqual(tide.type, type)
    }
    
    func test_tideType_rawValues_shouldBeCorrect() {
        XCTAssertEqual(TideType.high.rawValue, "high")
        XCTAssertEqual(TideType.low.rawValue, "low")
    }
}