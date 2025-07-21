import Foundation

final class MarineDataService: MarineDataProtocol {
    private let urlSession: URLSessionProtocol
    private let apiKey: String
    private let baseURL = "https://api.marine.noaa.gov"
    
    // Mobile Bay primary station
    private let primaryStation = "mb0101"
    
    init(urlSession: URLSessionProtocol = URLSession.shared, apiKey: String = ProcessInfo.processInfo.environment["MARINE_API_KEY"] ?? "") {
        self.urlSession = urlSession
        self.apiKey = apiKey
    }
    
    func fetchCurrentConditions() async throws -> MarineConditions {
        let url = URL(string: "\(baseURL)/stations/\(primaryStation)/latest")!
        let request = URLRequest(url: url)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw MarineDataError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(MarineConditions.self, from: data)
        } catch is DecodingError {
            throw MarineDataError.decodingError
        } catch {
            throw MarineDataError.networkError
        }
    }
    
    func fetchHistoricalData(from startDate: Date, to endDate: Date) async throws -> [MarineConditions] {
        let dateFormatter = ISO8601DateFormatter()
        let startString = dateFormatter.string(from: startDate)
        let endString = dateFormatter.string(from: endDate)
        
        let url = URL(string: "\(baseURL)/stations/\(primaryStation)/data?start=\(startString)&end=\(endString)")!
        let request = URLRequest(url: url)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw MarineDataError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let container = try decoder.decode([String: [MarineConditions]].self, from: data)
            return container["data"] ?? []
        } catch is DecodingError {
            throw MarineDataError.decodingError
        } catch {
            throw MarineDataError.networkError
        }
    }
    
    func fetchNearbyStations(latitude: Double, longitude: Double, radius: Double) async throws -> [MonitoringStation] {
        let url = URL(string: "\(baseURL)/stations/nearby?lat=\(latitude)&lon=\(longitude)&radius=\(radius)")!
        let request = URLRequest(url: url)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw MarineDataError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            let container = try decoder.decode([String: [MonitoringStation]].self, from: data)
            return container["stations"] ?? []
        } catch is DecodingError {
            throw MarineDataError.decodingError
        } catch {
            throw MarineDataError.networkError
        }
    }
}