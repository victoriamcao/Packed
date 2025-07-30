//
//  Pin.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import Foundation
import MapKit
import SwiftUI

struct Pin: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var image: UIImage?
}
