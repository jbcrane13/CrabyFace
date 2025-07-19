//
//  LocationAccuracy.swift
//  JubileeMobileBay
//
//  Created on 1/19/25.
//

import Foundation
import CoreLocation

enum LocationAccuracy {
    case best
    case navigation
    case kilometer
    case threeKilometers
    
    var clAccuracy: CLLocationAccuracy {
        switch self {
        case .best: 
            return kCLLocationAccuracyBest
        case .navigation: 
            return kCLLocationAccuracyBestForNavigation
        case .kilometer: 
            return kCLLocationAccuracyKilometer
        case .threeKilometers: 
            return kCLLocationAccuracyThreeKilometers
        }
    }
}