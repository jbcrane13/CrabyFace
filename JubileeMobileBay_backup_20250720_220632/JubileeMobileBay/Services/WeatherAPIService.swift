import Foundation

final class WeatherAPIService: WeatherAPIProtocol {
    private let urlSession: URLSessionProtocol
    private let apiKey: String
    private let baseURL = "https://api.weather.com"
    private let tideBaseURL = "https://api.tides.com"
    
    // Mobile Bay coordinates
    private let defaultLatitude = 30.6954
    private let defaultLongitude = -88.0399
    
    init(urlSession: URLSessionProtocol = URLSession.shared, apiKey: String = ProcessInfo.processInfo.environment["WEATHER_API_KEY"] ?? "") {
        self.urlSession = urlSession
        self.apiKey = apiKey
    }
    
    func fetchCurrentConditions() async throws -> WeatherConditions {
        let url = URL(string: "\(baseURL)/current?lat=\(defaultLatitude)&lon=\(defaultLongitude)&units=imperial")!
        let request = URLRequest(url: url)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw WeatherAPIError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(WeatherConditions.self, from: data)
        } catch is DecodingError {
            throw WeatherAPIError.decodingError
        } catch {
            throw WeatherAPIError.networkError
        }
    }
    
    func fetchHourlyForecast(hours: Int) async throws -> [WeatherForecast] {
        let url = URL(string: "\(baseURL)/forecast/hourly?lat=\(defaultLatitude)&lon=\(defaultLongitude)&hours=\(hours)&units=imperial")!
        let request = URLRequest(url: url)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw WeatherAPIError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let container = try decoder.decode([String: [WeatherForecast]].self, from: data)
            return container["hourly"] ?? []
        } catch is DecodingError {
            throw WeatherAPIError.decodingError
        } catch {
            throw WeatherAPIError.networkError
        }
    }
    
    func fetchTideData() async throws -> [TideData] {
        let url = URL(string: "\(tideBaseURL)/tides?lat=\(defaultLatitude)&lon=\(defaultLongitude)&days=2")!
        let request = URLRequest(url: url)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw WeatherAPIError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let container = try decoder.decode([String: [TideData]].self, from: data)
            return container["tides"] ?? []
        } catch is DecodingError {
            throw WeatherAPIError.decodingError
        } catch {
            throw WeatherAPIError.networkError
        }
    }
}