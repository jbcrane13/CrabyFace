import XCTest
@testable import JubileeMobileBay

final class MarineDataServiceTests: XCTestCase {
    var sut: MarineDataService!
    var mockURLSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        mockURLSession = MockURLSession()
        sut = MarineDataService(urlSession: mockURLSession)
    }
    
    override func tearDown() {
        sut = nil
        mockURLSession = nil
        super.tearDown()
    }
    
    // MARK: - Current Conditions Tests
    
    func test_fetchCurrentConditions_withValidResponse_shouldReturnMarineConditions() async throws {
        // Given
        let expectedConditions = MarineConditions(
            waterQuality: WaterQuality(
                temperature: 78.0,
                dissolvedOxygen: 1.8,
                ph: 7.5,
                salinity: 35.0,
                turbidity: 12.5,
                chlorophyll: 2.3
            ),
            current: CurrentData(
                speed: 0.5,
                direction: 180,
                temperature: 78.0
            ),
            wave: WaveData(
                height: 2.5,
                period: 8.0,
                direction: 90
            ),
            timestamp: Date()
        )
        
        let responseData = try JSONEncoder().encode(expectedConditions)
        mockURLSession.mockData = responseData
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.marine.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let conditions = try await sut.fetchCurrentConditions()
        
        // Then
        XCTAssertEqual(conditions.waterQuality, expectedConditions.waterQuality)
        XCTAssertEqual(conditions.current, expectedConditions.current)
        XCTAssertEqual(conditions.wave, expectedConditions.wave)
        XCTAssertEqual(mockURLSession.lastRequest?.url?.absoluteString, "https://api.marine.noaa.gov/stations/mb0101/latest")
    }
    
    func test_fetchCurrentConditions_withNetworkError_shouldThrowNetworkError() async {
        // Given
        mockURLSession.mockError = URLError(.notConnectedToInternet)
        
        // When/Then
        do {
            _ = try await sut.fetchCurrentConditions()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MarineDataError)
            if let apiError = error as? MarineDataError {
                XCTAssertEqual(apiError, .networkError)
            }
        }
    }
    
    // MARK: - Historical Data Tests
    
    func test_fetchHistoricalData_withValidResponse_shouldReturnHistoricalData() async throws {
        // Given
        let startDate = Date().addingTimeInterval(-86400) // 24 hours ago
        let endDate = Date()
        
        let expectedData = [
            MarineConditions(
                waterQuality: WaterQuality(
                    temperature: 76.0,
                    dissolvedOxygen: 2.0,
                    ph: 7.4,
                    salinity: 34.5,
                    turbidity: 10.0,
                    chlorophyll: 2.0
                ),
                current: CurrentData(speed: 0.4, direction: 170, temperature: 76.0),
                wave: WaveData(height: 2.0, period: 7.5, direction: 85),
                timestamp: startDate
            ),
            MarineConditions(
                waterQuality: WaterQuality(
                    temperature: 78.0,
                    dissolvedOxygen: 1.8,
                    ph: 7.5,
                    salinity: 35.0,
                    turbidity: 12.5,
                    chlorophyll: 2.3
                ),
                current: CurrentData(speed: 0.5, direction: 180, temperature: 78.0),
                wave: WaveData(height: 2.5, period: 8.0, direction: 90),
                timestamp: endDate
            )
        ]
        
        let responseData = try JSONEncoder().encode(["data": expectedData])
        mockURLSession.mockData = responseData
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.marine.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let historicalData = try await sut.fetchHistoricalData(from: startDate, to: endDate)
        
        // Then
        XCTAssertEqual(historicalData.count, 2)
        XCTAssertNotNil(mockURLSession.lastRequest?.url?.absoluteString.contains("start="))
        XCTAssertNotNil(mockURLSession.lastRequest?.url?.absoluteString.contains("end="))
    }
    
    // MARK: - Station Data Tests
    
    func test_fetchNearbyStations_withValidResponse_shouldReturnStations() async throws {
        // Given
        let expectedStations = [
            MonitoringStation(
                id: "mb0101",
                name: "Dauphin Island",
                latitude: 30.2500,
                longitude: -88.0750,
                type: .buoy,
                status: .active
            ),
            MonitoringStation(
                id: "mb0102",
                name: "Fort Morgan",
                latitude: 30.2280,
                longitude: -88.0197,
                type: .shore,
                status: .active
            )
        ]
        
        let responseData = try JSONEncoder().encode(["stations": expectedStations])
        mockURLSession.mockData = responseData
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.marine.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let stations = try await sut.fetchNearbyStations(latitude: 30.6954, longitude: -88.0399, radius: 50)
        
        // Then
        XCTAssertEqual(stations.count, 2)
        XCTAssertEqual(stations, expectedStations)
        XCTAssertNotNil(mockURLSession.lastRequest?.url?.absoluteString.contains("lat=30.6954"))
        XCTAssertNotNil(mockURLSession.lastRequest?.url?.absoluteString.contains("lon=-88.0399"))
        XCTAssertNotNil(mockURLSession.lastRequest?.url?.absoluteString.contains("radius=50"))
    }
    
    func test_fetchNearbyStations_withInvalidResponse_shouldThrowInvalidResponse() async {
        // Given
        mockURLSession.mockData = Data()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.marine.com")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When/Then
        do {
            _ = try await sut.fetchNearbyStations(latitude: 30.6954, longitude: -88.0399, radius: 50)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MarineDataError)
            if let apiError = error as? MarineDataError {
                XCTAssertEqual(apiError, .invalidResponse)
            }
        }
    }
}

// MARK: - Monitoring Station Model Tests

extension MarineDataServiceTests {
    func test_monitoringStation_initialization_shouldSetAllProperties() {
        // Given
        let id = "mb0101"
        let name = "Test Station"
        let latitude = 30.2500
        let longitude = -88.0750
        let type = StationType.buoy
        let status = StationStatus.active
        
        // When
        let station = MonitoringStation(
            id: id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            type: type,
            status: status
        )
        
        // Then
        XCTAssertEqual(station.id, id)
        XCTAssertEqual(station.name, name)
        XCTAssertEqual(station.latitude, latitude)
        XCTAssertEqual(station.longitude, longitude)
        XCTAssertEqual(station.type, type)
        XCTAssertEqual(station.status, status)
    }
    
    func test_stationType_rawValues_shouldBeCorrect() {
        XCTAssertEqual(StationType.buoy.rawValue, "buoy")
        XCTAssertEqual(StationType.shore.rawValue, "shore")
        XCTAssertEqual(StationType.platform.rawValue, "platform")
    }
    
    func test_stationStatus_rawValues_shouldBeCorrect() {
        XCTAssertEqual(StationStatus.active.rawValue, "active")
        XCTAssertEqual(StationStatus.maintenance.rawValue, "maintenance")
        XCTAssertEqual(StationStatus.offline.rawValue, "offline")
    }
}