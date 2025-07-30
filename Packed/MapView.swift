//
//  MapView.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import Foundation
import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var pins: [Pin]
    var onTap: (CLLocationCoordinate2D) -> Void
    var onAnnotationTap: (Pin) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Allow zooming, scrolling etc. by default
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(gestureRecognizer:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        for pin in pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate = pin.coordinate
            annotation.title = "Tap to view image"
            uiView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        @objc func handleTap(gestureRecognizer: UITapGestureRecognizer) {
            let location = gestureRecognizer.location(in: gestureRecognizer.view)
            guard let mapView = gestureRecognizer.view as? MKMapView else { return }
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            parent.onTap(coordinate)
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation else { return }
            // Find the pin matching this coordinate
            if let pin = parent.pins.first(where: {
                abs($0.coordinate.latitude - annotation.coordinate.latitude) < 0.0001 &&
                abs($0.coordinate.longitude - annotation.coordinate.longitude) < 0.0001
            }) {
                parent.onAnnotationTap(pin)
            }
        }
    }
}
