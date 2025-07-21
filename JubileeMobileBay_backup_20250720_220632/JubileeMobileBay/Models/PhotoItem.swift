//
//  PhotoItem.swift
//  JubileeMobileBay
//
//  Model for photo selection and display
//

import Foundation
import UIKit

struct PhotoItem: Identifiable {
    let id: UUID
    var image: UIImage?
    var photoReference: PhotoReference?
    
    init(id: UUID = UUID()) {
        self.id = id
    }
}