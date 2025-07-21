import XCTest
@testable import JubileeMobileBay

final class WeatherAPIServiceTests: XCTestCase {
    var sut: WeatherAPIService!
    var mockURLSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        mockURLSession = MockURLSession()
        sut = WeatherAPIService(urlSession: mockURLSession)
    }
    
    override func tearDown() {
        sut = nil
        mockURLSession = nil
        super.tearDown()
    }
    
    // MARK: - Current Conditions Tests
    
    func test_fetchCurrentConditions_withValidResponse_shouldReturnWeatherConditions() async throws {
        // Given
        let expectedConditions = WeatherConditions(
            temperature: 78.5,
            humidity: 85.0,
            windSpeed: 3.0,
            windDirection: "E",
            pressure: 1013.25,
            visibility: 10.0,
            uvIndex: 8,
            cloudCover: 25
        )
        
        let responseData = try JSONEncoder().encode(expectedConditions)
        mockURLSession.mockData = responseData
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.weather.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let conditions = try await sut.fetchCurrentConditions()
        
        // Then
        XCTAssertEqual(conditions, expectedConditions)
        XCTAssertEqual(mockURLSession.lastRequest?.url?.absoluteString, "https://api.weather.com/current?lat=30.6954&lon=-88.0399&units=imperial")
    }
    
    func test_fetchCurrentConditions_withNetworkError_shouldThrowNetworkError() async {
        // Given
        mockURLSession.mockError = URLError(.notConnectedToInternet)
        
        // When/Then
        do {
            _ = try await sut.fetchCurrentConditions()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is WeatherAPIError)
            if let apiError = error as? WeatherAPIError {
                XCTAssertEqual(apiError, .networkError)
            }
        }
    }
    
    func test_fetchCurrentConditions_withInvalidResponse_shouldThrowInvalidResponse() async {
        // Given
        mockURLSession.mockData = Data()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.weather.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When/Then
        do {
            _ = try await sut.fetchCurrentConditions()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is WeatherAPIError)
            if let apiError = error as? WeatherAPIError {
                XCTAssertEqual(apiError, .invalidResponse)
            }
        }
    }
    
    // MARK: - Forecast Tests
    
    func test_fetchHourlyForecast_withValidResponse_shouldReturnForecasts() async throws {
        // Given
        let date1 = Date()
        let date2 = Date().addingTimeInterval(3600)
        let expectedForecasts = [
            WeatherForecast(
                date: date1,
                temperature: 82.0,
                humidity: 70.0,
                windSpeed: 8.0,
                windDirection: "SW",
                precipitationChance: 20,
                conditions: "Partly Cloudy",
                icon: "partly-cloudy"
            ),
            WeatherForecast(
                date: date2,
                temperature: 80.0,
                humidity: 75.0,
                windSpeed: 7.0,
                windDirection: "S",
                precipitationChance: 30,
                conditions: "Cloudy",
                icon: "cloudy"
            )
        ]
        
        let responseData = try JSONEncoder().encode(["hourly": expectedForecasts])
        mockURLSession.mockData = responseData
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.weather.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let forecasts = try await sut.fetchHourlyForecast(hours: 24)
        
        // Then
        XCTAssertEqual(forecasts.count, 2)
        XCTAssertEqual(forecasts, expectedForecasts)
        XCTAssertEqual(mockURLSession.lastRequest?.url?.absoluteString, "https://api.weather.com/forecast/hourly?lat=30.6954&lon=-88.0399&hours=24&units=imperial")
    }
    
    // MARK: - Tide Tests
    
    func test_fetchTideData_withValidResponse_shouldReturnTideData() async throws {
        // Given
        let date1 = Date()
        let date2 = Date().addingTimeInterval(21600) // 6 hours later
        let expectedTides = [
            TideData(time: date1, height: 5.2, type: .high),
            TideData(time: date2, height: 0.8, type: .low)
        ]
        
        let responseData = try JSONEncoder().encode(["tides": expectedTides])
        mockURLSession.mockData = responseData
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.weather.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let tides = try await sut.fetchTideData()
        
        // Then
        XCTAssertEqual(tides.count, 2)
        XCTAssertEqual(tides, expectedTides)
        XCTAssertEqual(mockURLSession.lastRequest?.url?.absoluteString, "https://api.tides.com/tides?lat=30.6954&lon=-88.0399&days=2")
    }
    
    func test_fetchTideData_withDecodingError_shouldThrowDecodingError() async {
        // Given
        mockURLSession.mockData = "invalid json".data(using: .utf8)
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.weather.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When/Then
        do {
            _ = try await sut.fetchTideData()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is WeatherAPIError)
            if let apiError = error as? WeatherAPIError {
                XCTAssertEqual(apiError, .decodingError)
            }
        }
    }
}

// MARK: - Mock URLSession

class MockURLSession: URLSessionProtocol {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var lastRequest: URLRequest?
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        
        if let error = mockError {
            throw error
        }
        
        guard let data = mockData,
              let response = mockResponse else {
            throw URLError(.badServerResponse)
        }
        
        return (data, response)
    }
}