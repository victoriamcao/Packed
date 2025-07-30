//
//  Pin.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import Foundation
import MapKit
import UIKit
import Combine

class Pin: Identifiable, ObservableObject, Equatable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    @Published var images: [UIImage] = []

    init(coordinate: CLLocationCoordinate2D, images: [UIImage] = []) {
        self.coordinate = coordinate
        self.images = images
    }

    static func == (lhs: Pin, rhs: Pin) -> Bool {
        lhs.id == rhs.id
    }
}

