import Foundation

protocol WeatherAPIProtocol {
    func fetchCurrentConditions() async throws -> WeatherConditions
    func fetchHourlyForecast(hours: Int) async throws -> [WeatherForecast]
    func fetchTideData() async throws -> [TideData]
}

enum WeatherAPIError: Error, Equatable {
    case networkError
    case invalidResponse
    case decodingError
    case unauthorized
    case rateLimitExceeded
}