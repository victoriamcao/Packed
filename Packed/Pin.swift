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
    /// Photos that loaded, in order.
    @Published var images: [UIImage] = []
    /// Storage paths parallel to `images` (same count and order).
    @Published var imagePaths: [String] = []
    /// Every Supabase Storage photo path saved on this pin, including any
    /// that failed to load this time.
    @Published var photoPaths: [String] = []

    // Only mutate a Pin's published properties from the main actor (the
    // map screen does this after PinStore calls return).
    init(
        id: String = UUID().uuidString,
        coordinate: CLLocationCoordinate2D,
        images: [UIImage] = [],
        imagePaths: [String] = [],
        photoPaths: [String] = []
    ) {
        self.id = id
        self.coordinate = coordinate
        self.images = images
        self.imagePaths = imagePaths
        self.photoPaths = photoPaths
    }

    static func == (lhs: Pin, rhs: Pin) -> Bool {
        lhs.id == rhs.id
    }
}
