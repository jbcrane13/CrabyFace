//
//  MarineLifeType.swift
//  JubileeMobileBay
//
//  Marine life types commonly observed during jubilee events
//

import Foundation

enum MarineLifeType: String, CaseIterable, Identifiable, Codable {
    case crab = "Crab"
    case flounder = "Flounder"
    case shrimp = "Shrimp"
    case eel = "Eel"
    case ray = "Ray"
    case mullet = "Mullet"
    case seaTrout = "Sea Trout"
    case redfish = "Redfish"
    case bluefish = "Bluefish"
    case catfish = "Catfish"
    case other = "Other"
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue
    }
    
    var iconName: String {
        switch self {
        case .crab: return "🦀"
        case .flounder: return "🐟"
        case .shrimp: return "🦐"
        case .eel: return "🐍"
        case .ray: return "🪼"
        case .mullet: return "🐠"
        case .seaTrout: return "🐟"
        case .redfish: return "🐡"
        case .bluefish: return "🐟"
        case .catfish: return "🐋"
        case .other: return "🌊"
        }
    }
}