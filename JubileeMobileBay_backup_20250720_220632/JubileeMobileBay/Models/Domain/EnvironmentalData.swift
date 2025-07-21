import Foundation
import CoreLocation

struct EnvironmentalData: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    let timestamp: Date
    let location: CLLocationCoordinate2D
    let temperature: Double                 // Fahrenheit
    let humidity: Double                   // Percentage (0-100)
    let pressure: Double?                  // Millibars
    let windSpeed: Double                  // Miles per hour
    let windDirection: Int                 // Degrees (0-360)
    let waterTemperature: Double?          // Fahrenheit
    let dissolvedOxygen: Double?           // mg/L
    let salinity: Double?                  // Parts per thousand
    let ph: Double?                        // pH scale (0-14)
    let turbidity: Double?                 // NTU (Nephelometric Turbidity Units)
    let dataSource: DataSource
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        location: CLLocationCoordinate2D,
        temperature: Double,
        humidity: Double,
        pressure: Double? = nil,
        windSpeed: Double,
        windDirection: Int,
        waterTemperature: Double? = nil,
        dissolvedOxygen: Double? = nil,
        salinity: Double? = nil,
        ph: Double? = nil,
        turbidity: Double? = nil,
        dataSource: DataSource
    ) {
        self.id = id
        self.timestamp = timestamp
        self.location = location
        self.temperature = temperature
        self.humidity = humidity
        self.pressure = pressure
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.waterTemperature = waterTemperature
        self.dissolvedOxygen = dissolvedOxygen
        self.salinity = salinity
        self.ph = ph
        self.turbidity = turbidity
        self.dataSource = dataSource
    }
    
    // MARK: - Calculated Properties
    
    var windSpeedInKnots: Double {
        windSpeed * 0.868976 // Convert mph to knots
    }
    
    var temperatureInCelsius: Double {
        (temperature - 32) * 5/9
    }
    
    var waterTemperatureInCelsius: Double? {
        guard let waterTemp = waterTemperature else { return nil }
        return (waterTemp - 32) * 5/9
    }
    
    var isValid: Bool {
        // Validate temperature range (-100°F to 150°F)
        guard temperature >= -100 && temperature <= 150 else { return false }
        
        // Validate humidity (0-100%)
        guard humidity >= 0 && humidity <= 100 else { return false }
        
        // Validate wind direction (0-360 degrees)
        guard windDirection >= 0 && windDirection <= 360 else { return false }
        
        // Validate wind speed (0-300 mph)
        guard windSpeed >= 0 && windSpeed <= 300 else { return false }
        
        // Validate optional parameters if present
        if let pressure = pressure {
            guard pressure >= 800 && pressure <= 1100 else { return false }
        }
        
        if let ph = ph {
            guard ph >= 0 && ph <= 14 else { return false }
        }
        
        if let waterTemp = waterTemperature {
            guard waterTemp >= 32 && waterTemp <= 120 else { return false }
        }
        
        if let dissolved = dissolvedOxygen {
            guard dissolved >= 0 && dissolved <= 20 else { return false }
        }
        
        if let sal = salinity {
            guard sal >= 0 && sal <= 50 else { return false }
        }
        
        if let turb = turbidity {
            guard turb >= 0 && turb <= 1000 else { return false }
        }
        
        // Validate coordinates
        guard CLLocationCoordinate2DIsValid(location) else { return false }
        
        return true
    }
    
    // MARK: - Equatable
    
    static func == (lhs: EnvironmentalData, rhs: EnvironmentalData) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case latitude
        case longitude
        case temperature
        case humidity
        case pressure
        case windSpeed
        case windDirection
        case waterTemperature
        case dissolvedOxygen
        case salinity
        case ph
        case turbidity
        case dataSource
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        temperature = try container.decode(Double.self, forKey: .temperature)
        humidity = try container.decode(Double.self, forKey: .humidity)
        pressure = try container.decodeIfPresent(Double.self, forKey: .pressure)
        windSpeed = try container.decode(Double.self, forKey: .windSpeed)
        windDirection = try container.decode(Int.self, forKey: .windDirection)
        waterTemperature = try container.decodeIfPresent(Double.self, forKey: .waterTemperature)
        dissolvedOxygen = try container.decodeIfPresent(Double.self, forKey: .dissolvedOxygen)
        salinity = try container.decodeIfPresent(Double.self, forKey: .salinity)
        ph = try container.decodeIfPresent(Double.self, forKey: .ph)
        turbidity = try container.decodeIfPresent(Double.self, forKey: .turbidity)
        dataSource = try container.decode(DataSource.self, forKey: .dataSource)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(location.latitude, forKey: .latitude)
        try container.encode(location.longitude, forKey: .longitude)
        try container.encode(temperature, forKey: .temperature)
        try container.encode(humidity, forKey: .humidity)
        try container.encodeIfPresent(pressure, forKey: .pressure)
        try container.encode(windSpeed, forKey: .windSpeed)
        try container.encode(windDirection, forKey: .windDirection)
        try container.encodeIfPresent(waterTemperature, forKey: .waterTemperature)
        try container.encodeIfPresent(dissolvedOxygen, forKey: .dissolvedOxygen)
        try container.encodeIfPresent(salinity, forKey: .salinity)
        try container.encodeIfPresent(ph, forKey: .ph)
        try container.encodeIfPresent(turbidity, forKey: .turbidity)
        try container.encode(dataSource, forKey: .dataSource)
    }
}