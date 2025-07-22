//
//  DashboardStateCodable.swift
//  JubileeMobileBay
//
//  Codable conformance for Dashboard state types
//

import Foundation
import SwiftUI

// MARK: - DashboardTimeRange Codable

extension DashboardTimeRange: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case from
        case to
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "hour":
            self = .hour
        case "day":
            self = .day
        case "week":
            self = .week
        case "month":
            self = .month
        case "year":
            self = .year
        case "custom":
            let from = try container.decode(Date.self, forKey: .from)
            let to = try container.decode(Date.self, forKey: .to)
            self = .custom(from: from, to: to)
        default:
            self = .week // Default fallback
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .hour:
            try container.encode("hour", forKey: .type)
        case .day:
            try container.encode("day", forKey: .type)
        case .week:
            try container.encode("week", forKey: .type)
        case .month:
            try container.encode("month", forKey: .type)
        case .year:
            try container.encode("year", forKey: .type)
        case .custom(let from, let to):
            try container.encode("custom", forKey: .type)
            try container.encode(from, forKey: .from)
            try container.encode(to, forKey: .to)
        }
    }
}

// MARK: - FilterOption Codable

extension FilterOption: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case dataSource
        case chartType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "dataSource":
            let source = try container.decode(DataSource.self, forKey: .dataSource)
            self = .dataSource(source)
        case "chartType":
            let chartType = try container.decode(DashboardViewType.self, forKey: .chartType)
            self = .chartType(chartType)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown filter type"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .dataSource(let source):
            try container.encode("dataSource", forKey: .type)
            try container.encode(source, forKey: .dataSource)
        case .chartType(let chartType):
            try container.encode("chartType", forKey: .type)
            try container.encode(chartType, forKey: .chartType)
        }
    }
}

// MARK: - DashboardLayout Codable

extension DashboardLayout: Codable {}

// MARK: - DashboardViewType Codable

extension DashboardViewType: Codable {}