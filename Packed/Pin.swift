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
    /// Server-assigned id (Postgres UUID, as a string) once the pin exists
    /// in the map_pins table.
    let id: String
    let coordinate: CLLocationCoordinate2D
    @Published var images: [UIImage] = []
    /// Supabase Storage object paths, parallel to `images`.
    @Published var photoPaths: [String] = []

    init(id: String = UUID().uuidString, coordinate: CLLocationCoordinate2D, images: [UIImage] = [], photoPaths: [String] = []) {
        self.id = id
        self.coordinate = coordinate
        self.images = images
        self.photoPaths = photoPaths
    }

    static func == (lhs: Pin, rhs: Pin) -> Bool {
        lhs.id == rhs.id
    }
}
