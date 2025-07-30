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
            let annotation = MKPointAnnotation()
            annotation.coordinate = pin.coordinate
            annotation.title = "Tap to view image"
            annotation.subtitle = pin.id.uuidString // Use UUID to match later
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

            // If user tapped on an existing annotation, ignore it
            let tappedAnnotations = mapView.annotations(in: mapView.visibleMapRect).filter { annotation in
                let coord = (annotation as? MKAnnotation)?.coordinate
                return coord != nil && abs(coord!.latitude - tappedPoint.latitude) < 0.0005 &&
                                      abs(coord!.longitude - tappedPoint.longitude) < 0.0005
            }

            guard tappedAnnotations.isEmpty else { return }

            parent.onTap(tappedPoint)
        }


        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation,
                  let idString = annotation.subtitle,
                  let pin = parent.pins.first(where: { $0.id.uuidString == idString }) else {
                return
            }
            parent.onAnnotationTap(pin)
        }
    }
}

