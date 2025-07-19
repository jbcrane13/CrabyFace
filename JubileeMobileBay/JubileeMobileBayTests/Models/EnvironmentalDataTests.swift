import XCTest
import CoreLocation
@testable import JubileeMobileBay

final class EnvironmentalDataTests: XCTestCase {
    
    // MARK: - Model Tests
    
    func test_environmentalData_initialization_shouldSetAllProperties() {
        // Given
        let id = UUID()
        let timestamp = Date()
        let location = CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399)
        let temperature = 75.5
        let humidity = 82.0
        let pressure = 1013.25
        let windSpeed = 12.5
        let windDirection = 225
        let waterTemperature = 78.0
        let dissolvedOxygen = 2.8
        let salinity = 28.5
        let ph = 7.8
        let turbidity = 15.0
        let dataSource = DataSource.noaa
        
        // When
        let data = EnvironmentalData(
            id: id,
            timestamp: timestamp,
            location: location,
            temperature: temperature,
            humidity: humidity,
            pressure: pressure,
            windSpeed: windSpeed,
            windDirection: windDirection,
            waterTemperature: waterTemperature,
            dissolvedOxygen: dissolvedOxygen,
            salinity: salinity,
            ph: ph,
            turbidity: turbidity,
            dataSource: dataSource
        )
        
        // Then
        XCTAssertEqual(data.id, id)
        XCTAssertEqual(data.timestamp, timestamp)
        XCTAssertEqual(data.location.latitude, location.latitude)
        XCTAssertEqual(data.location.longitude, location.longitude)
        XCTAssertEqual(data.temperature, temperature)
        XCTAssertEqual(data.humidity, humidity)
        XCTAssertEqual(data.pressure, pressure)
        XCTAssertEqual(data.windSpeed, windSpeed)
        XCTAssertEqual(data.windDirection, windDirection)
        XCTAssertEqual(data.waterTemperature, waterTemperature)
        XCTAssertEqual(data.dissolvedOxygen, dissolvedOxygen)
        XCTAssertEqual(data.salinity, salinity)
        XCTAssertEqual(data.ph, ph)
        XCTAssertEqual(data.turbidity, turbidity)
        XCTAssertEqual(data.dataSource, dataSource)
    }
    
    func test_environmentalData_optionalProperties_shouldHandleNilValues() {
        // Given
        let data = EnvironmentalData(
            id: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            temperature: 75.0,
            humidity: 80.0,
            pressure: nil,
            windSpeed: 10.0,
            windDirection: 180,
            waterTemperature: nil,
            dissolvedOxygen: nil,
            salinity: nil,
            ph: nil,
            turbidity: nil,
            dataSource: .openWeatherMap
        )
        
        // When & Then
        XCTAssertNil(data.pressure)
        XCTAssertNil(data.waterTemperature)
        XCTAssertNil(data.dissolvedOxygen)
        XCTAssertNil(data.salinity)
        XCTAssertNil(data.ph)
        XCTAssertNil(data.turbidity)
    }
    
    // MARK: - Validation Tests
    
    func test_environmentalData_validation_shouldFailForInvalidTemperature() {
        // Given
        let data = EnvironmentalData(
            id: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            temperature: 150.0, // Invalid temperature (too high)
            humidity: 80.0,
            pressure: 1013.0,
            windSpeed: 10.0,
            windDirection: 180,
            waterTemperature: nil,
            dissolvedOxygen: nil,
            salinity: nil,
            ph: nil,
            turbidity: nil,
            dataSource: .noaa
        )
        
        // When & Then
        XCTAssertFalse(data.isValid)
    }
    
    func test_environmentalData_validation_shouldFailForInvalidHumidity() {
        // Given
        let data = EnvironmentalData(
            id: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            temperature: 75.0,
            humidity: 120.0, // Invalid humidity (> 100%)
            pressure: 1013.0,
            windSpeed: 10.0,
            windDirection: 180,
            waterTemperature: nil,
            dissolvedOxygen: nil,
            salinity: nil,
            ph: nil,
            turbidity: nil,
            dataSource: .noaa
        )
        
        // When & Then
        XCTAssertFalse(data.isValid)
    }
    
    func test_environmentalData_validation_shouldFailForInvalidWindDirection() {
        // Given
        let data = EnvironmentalData(
            id: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            temperature: 75.0,
            humidity: 80.0,
            pressure: 1013.0,
            windSpeed: 10.0,
            windDirection: 400, // Invalid wind direction (> 360)
            waterTemperature: nil,
            dissolvedOxygen: nil,
            salinity: nil,
            ph: nil,
            turbidity: nil,
            dataSource: .noaa
        )
        
        // When & Then
        XCTAssertFalse(data.isValid)
    }
    
    func test_environmentalData_validation_shouldFailForInvalidPH() {
        // Given
        let data = EnvironmentalData(
            id: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            temperature: 75.0,
            humidity: 80.0,
            pressure: 1013.0,
            windSpeed: 10.0,
            windDirection: 180,
            waterTemperature: 78.0,
            dissolvedOxygen: 3.0,
            salinity: 30.0,
            ph: 15.0, // Invalid pH (> 14)
            turbidity: 10.0,
            dataSource: .noaa
        )
        
        // When & Then
        XCTAssertFalse(data.isValid)
    }
    
    func test_environmentalData_validation_shouldPassForValidData() {
        // Given
        let data = EnvironmentalData(
            id: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            temperature: 75.0,
            humidity: 80.0,
            pressure: 1013.25,
            windSpeed: 12.5,
            windDirection: 225,
            waterTemperature: 78.0,
            dissolvedOxygen: 2.8,
            salinity: 28.5,
            ph: 7.8,
            turbidity: 15.0,
            dataSource: .noaa
        )
        
        // When & Then
        XCTAssertTrue(data.isValid)
    }
    
    // MARK: - Calculated Properties Tests
    
    func test_environmentalData_windSpeedInKnots_shouldConvertCorrectly() {
        // Given
        let data = EnvironmentalData(
            id: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            temperature: 75.0,
            humidity: 80.0,
            pressure: 1013.0,
            windSpeed: 10.0, // mph
            windDirection: 180,
            waterTemperature: nil,
            dissolvedOxygen: nil,
            salinity: nil,
            ph: nil,
            turbidity: nil,
            dataSource: .noaa
        )
        
        // When
        let knots = data.windSpeedInKnots
        
        // Then
        XCTAssertEqual(knots, 8.69, accuracy: 0.01)
    }
    
    func test_environmentalData_temperatureInCelsius_shouldConvertCorrectly() {
        // Given
        let data = EnvironmentalData(
            id: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            temperature: 77.0, // Fahrenheit
            humidity: 80.0,
            pressure: 1013.0,
            windSpeed: 10.0,
            windDirection: 180,
            waterTemperature: nil,
            dissolvedOxygen: nil,
            salinity: nil,
            ph: nil,
            turbidity: nil,
            dataSource: .noaa
        )
        
        // When
        let celsius = data.temperatureInCelsius
        
        // Then
        XCTAssertEqual(celsius, 25.0, accuracy: 0.1)
    }
    
    // MARK: - Equatable Tests
    
    func test_environmentalData_equatable_shouldBeEqualWhenIDsMatch() {
        // Given
        let id = UUID()
        let data1 = EnvironmentalData(
            id: id,
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            temperature: 75.0,
            humidity: 80.0,
            pressure: 1013.0,
            windSpeed: 10.0,
            windDirection: 180,
            waterTemperature: nil,
            dissolvedOxygen: nil,
            salinity: nil,
            ph: nil,
            turbidity: nil,
            dataSource: .noaa
        )
        
        let data2 = EnvironmentalData(
            id: id,
            timestamp: Date().addingTimeInterval(100),
            location: CLLocationCoordinate2D(latitude: 31.0, longitude: -89.0),
            temperature: 80.0,
            humidity: 85.0,
            pressure: 1015.0,
            windSpeed: 15.0,
            windDirection: 270,
            waterTemperature: 80.0,
            dissolvedOxygen: 3.0,
            salinity: 32.0,
            ph: 8.0,
            turbidity: 20.0,
            dataSource: .openWeatherMap
        )
        
        // When & Then
        XCTAssertEqual(data1, data2)
    }
}

// MARK: - Mock Extensions

extension EnvironmentalData {
    static var mock: EnvironmentalData {
        EnvironmentalData(
            id: UUID(),
            timestamp: Date(),
            location: CLLocationCoordinate2D(latitude: 30.6954, longitude: -88.0399),
            temperature: 75.0,
            humidity: 80.0,
            pressure: 1013.25,
            windSpeed: 12.5,
            windDirection: 225,
            waterTemperature: 78.0,
            dissolvedOxygen: 2.8,
            salinity: 28.5,
            ph: 7.8,
            turbidity: 15.0,
            dataSource: .noaa
        )
    }
}