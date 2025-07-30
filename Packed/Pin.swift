//
//  Pin.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import Foundation
import MapKit
import UIKit

struct Pin: Identifiable, Equatable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var image: UIImage?
    
    static func == (lhs: Pin, rhs: Pin) -> Bool {
        lhs.id == rhs.id
    }
}
