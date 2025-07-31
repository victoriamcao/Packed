//
//  MapView.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var pins: [Pin]
    var onTap: (CLLocationCoordinate2D) -> Void
    var onAnnotationTap: (Pin) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        mapView.addGestureRecognizer(tapGesture)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)

        for pin in pins {
            let annotation = PinAnnotation()
            annotation.coordinate = pin.coordinate
            annotation.title = "Tap to view photos"
            annotation.pinId = pin.id // Store the actual pin ID
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
            guard let mapView = gestureRecognizer.view as? MKMapView else { return }

            let location = gestureRecognizer.location(in: mapView)
            let tappedPoint = mapView.convert(location, toCoordinateFrom: mapView)

            for annotation in mapView.annotations {
                let annotationPoint = mapView.convert(annotation.coordinate, toPointTo: mapView)
                let distance = sqrt(pow(annotationPoint.x - location.x, 2) + pow(annotationPoint.y - location.y, 2))
                
                if distance < 44 {
                    return
                }
            }

            parent.onTap(tappedPoint)
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? PinAnnotation,
                  let pin = parent.pins.first(where: { $0.id == annotation.pinId }) else {
                return
            }
            
            parent.onAnnotationTap(pin)
        }
    }
}

class PinAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var title: String?
    var subtitle: String?
    var pinId: UUID = UUID()
}
