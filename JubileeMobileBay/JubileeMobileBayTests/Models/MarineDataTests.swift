import XCTest
@testable import JubileeMobileBay

final class MarineDataTests: XCTestCase {
    
    // MARK: - Water Quality Tests
    
    func test_waterQuality_initialization_shouldSetAllProperties() {
        // Given
        let temperature = 78.0
        let dissolvedOxygen = 1.8
        let ph = 7.5
        let salinity = 35.0
        let turbidity = 12.5
        let chlorophyll = 2.3
        
        // When
        let waterQuality = WaterQuality(
            temperature: temperature,
            dissolvedOxygen: dissolvedOxygen,
            ph: ph,
            salinity: salinity,
            turbidity: turbidity,
            chlorophyll: chlorophyll
        )
        
        // Then
        XCTAssertEqual(waterQuality.temperature, temperature)
        XCTAssertEqual(waterQuality.dissolvedOxygen, dissolvedOxygen)
        XCTAssertEqual(waterQuality.ph, ph)
        XCTAssertEqual(waterQuality.salinity, salinity)
        XCTAssertEqual(waterQuality.turbidity, turbidity)
        XCTAssertEqual(waterQuality.chlorophyll, chlorophyll)
    }
    
    func test_waterQuality_dissolvedOxygenStatus_shouldReturnCorrectStatus() {
        // Test critical level
        let criticalQuality = WaterQuality(
            temperature: 78,
            dissolvedOxygen: 1.5,
            ph: 7.5,
            salinity: 35,
            turbidity: 10,
            chlorophyll: 2
        )
        XCTAssertEqual(criticalQuality.dissolvedOxygenStatus, .critical)
        
        // Test low level
        let lowQuality = WaterQuality(
            temperature: 78,
            dissolvedOxygen: 2.5,
            ph: 7.5,
            salinity: 35,
            turbidity: 10,
            chlorophyll: 2
        )
        XCTAssertEqual(lowQuality.dissolvedOxygenStatus, .low)
        
        // Test normal level
        let normalQuality = WaterQuality(
            temperature: 78,
            dissolvedOxygen: 5.5,
            ph: 7.5,
            salinity: 35,
            turbidity: 10,
            chlorophyll: 2
        )
        XCTAssertEqual(normalQuality.dissolvedOxygenStatus, .normal)
    }
    
    func test_waterQuality_decodingFromJSON_shouldDecodeCorrectly() throws {
        // Given
        let json = """
        {
            "temperature": 76.5,
            "dissolvedOxygen": 2.1,
            "ph": 7.8,
            "salinity": 34.5,
            "turbidity": 15.0,
            "chlorophyll": 3.2
        }
        """.data(using: .utf8)!
        
        // When
        let waterQuality = try JSONDecoder().decode(WaterQuality.self, from: json)
        
        // Then
        XCTAssertEqual(waterQuality.temperature, 76.5)
        XCTAssertEqual(waterQuality.dissolvedOxygen, 2.1)
        XCTAssertEqual(waterQuality.ph, 7.8)
        XCTAssertEqual(waterQuality.salinity, 34.5)
        XCTAssertEqual(waterQuality.turbidity, 15.0)
        XCTAssertEqual(waterQuality.chlorophyll, 3.2)
    }
    
    // MARK: - Current Data Tests
    
    func test_currentData_initialization_shouldSetAllProperties() {
        // Given
        let speed = 0.5
        let direction = 180
        let temperature = 78.0
        
        // When
        let current = CurrentData(
            speed: speed,
            direction: direction,
            temperature: temperature
        )
        
        // Then
        XCTAssertEqual(current.speed, speed)
        XCTAssertEqual(current.direction, direction)
        XCTAssertEqual(current.temperature, temperature)
    }
    
    // MARK: - Wave Data Tests
    
    func test_waveData_initialization_shouldSetAllProperties() {
        // Given
        let height = 2.5
        let period = 8.0
        let direction = 90
        
        // When
        let wave = WaveData(
            height: height,
            period: period,
            direction: direction
        )
        
        // Then
        XCTAssertEqual(wave.height, height)
        XCTAssertEqual(wave.period, period)
        XCTAssertEqual(wave.direction, direction)
    }
    
    // MARK: - Marine Conditions Tests
    
    func test_marineConditions_initialization_shouldSetAllProperties() {
        // Given
        let waterQuality = WaterQuality(
            temperature: 78,
            dissolvedOxygen: 1.8,
            ph: 7.5,
            salinity: 35,
            turbidity: 10,
            chlorophyll: 2
        )
        let current = CurrentData(speed: 0.5, direction: 180, temperature: 78)
        let wave = WaveData(height: 2.5, period: 8, direction: 90)
        let timestamp = Date()
        
        // When
        let conditions = MarineConditions(
            waterQuality: waterQuality,
            current: current,
            wave: wave,
            timestamp: timestamp
        )
        
        // Then
        XCTAssertEqual(conditions.waterQuality, waterQuality)
        XCTAssertEqual(conditions.current, current)
        XCTAssertEqual(conditions.wave, wave)
        XCTAssertEqual(conditions.timestamp, timestamp)
    }
    
    // MARK: - Oxygen Status Tests
    
    func test_oxygenStatus_rawValues_shouldBeCorrect() {
        XCTAssertEqual(OxygenStatus.critical.rawValue, "critical")
        XCTAssertEqual(OxygenStatus.low.rawValue, "low")
        XCTAssertEqual(OxygenStatus.normal.rawValue, "normal")
    }
}