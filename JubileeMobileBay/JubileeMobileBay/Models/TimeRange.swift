//
//  TimeRange.swift
//  JubileeMobileBay
//
//  Created on 1/19/25.
//

import Foundation

enum TimeRange: String, CaseIterable {
    case last6Hours = "Last 6 Hours"
    case last24Hours = "Last 24 Hours"
    case lastWeek = "Last Week"
    case all = "All"
    
    var timeInterval: TimeInterval? {
        switch self {
        case .last6Hours: return -6 * 3600
        case .last24Hours: return -24 * 3600
        case .lastWeek: return -7 * 24 * 3600
        case .all: return nil
        }
    }
}