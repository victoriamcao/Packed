//
//  MapPage.swift
//  Packed
//
//  Created by Scholar on 7/29/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct Pin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct MapPage: View {
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    var body: some View {
        Map(position: $cameraPosition)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .onReceive(locationManager.$location) { location in
                if let location = location {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                }
            }
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    MapPage()
}
