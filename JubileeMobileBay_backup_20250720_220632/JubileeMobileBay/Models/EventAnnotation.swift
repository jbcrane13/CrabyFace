//
//  EventAnnotation.swift
//  JubileeMobileBay
//
//  Created on 1/19/25.
//

import Foundation

struct EventAnnotation: Identifiable {
    let id: UUID
    let event: JubileeEvent
    
    init(event: JubileeEvent) {
        self.id = event.id
        self.event = event
    }
}