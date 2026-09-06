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
    @Binding var centerOnCoordinate: CLLocationCoordinate2D?
    var onTap: (CLLocationCoordinate2D) -> Void
    var onAnnotationTap: (Pin) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tapGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(tapGesture)

        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress))
        longPressGesture.minimumPressDuration = 0.4
        longPressGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(longPressGesture)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        let existingAnnotations = uiView.annotations.compactMap { $0 as? PinAnnotation }
        let existingIds = Set(existingAnnotations.map { $0.pinId })
        let currentIds = Set(pins.map { $0.id })

        let toRemove = existingAnnotations.filter { !currentIds.contains($0.pinId) }
        if !toRemove.isEmpty {
            uiView.removeAnnotations(toRemove)
        }

        let idsToAdd = currentIds.subtracting(existingIds)
        let toAdd = pins.filter { idsToAdd.contains($0.id) }.map { pin -> PinAnnotation in
            let annotation = PinAnnotation()
            annotation.coordinate = pin.coordinate
            annotation.pinId = pin.id
            return annotation
        }
        if !toAdd.isEmpty {
            uiView.addAnnotations(toAdd)
        }

        // Refresh thumbnails for pins whose photo set changed in place (e.g. a
        // photo was just added to an existing pin - its id/annotation is unchanged).
        for annotation in existingAnnotations where currentIds.contains(annotation.pinId) {
            if let pin = pins.first(where: { $0.id == annotation.pinId }),
               let view = uiView.view(for: annotation) as? PhotoPinAnnotationView {
                view.configure(thumbnail: pin.images.first)
            }
        }

        if let center = centerOnCoordinate {
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            uiView.setRegion(region, animated: true)
            DispatchQueue.main.async { centerOnCoordinate = nil }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        @objc func handleTap(gestureRecognizer: UITapGestureRecognizer) {
            guard let mapView = gestureRecognizer.view as? MKMapView else { return }
            let location = gestureRecognizer.location(in: mapView)
            let tappedCoordinate = mapView.convert(location, toCoordinateFrom: mapView)
            parent.onTap(tappedCoordinate)
        }

        @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
            guard gestureRecognizer.state == .began,
                  let mapView = gestureRecognizer.view as? MKMapView else { return }
            let location = gestureRecognizer.location(in: mapView)
            let tappedCoordinate = mapView.convert(location, toCoordinateFrom: mapView)
            parent.onTap(tappedCoordinate)
        }

        // Let taps/long-presses that land on an existing pin's annotation view go
        // to MapKit's own selection (didSelect) instead of our custom gesture -
        // otherwise our recognizer swallows the touch before selection can happen.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var view = touch.view
            while let v = view {
                if v is MKAnnotationView { return false }
                view = v.superview
            }
            return true
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let pinAnnotation = annotation as? PinAnnotation else { return nil }

            let identifier = "PhotoPin"
            let view: PhotoPinAnnotationView
            if let dequeued = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? PhotoPinAnnotationView {
                dequeued.annotation = annotation
                view = dequeued
            } else {
                view = PhotoPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }

            let pin = parent.pins.first(where: { $0.id == pinAnnotation.pinId })
            view.configure(thumbnail: pin?.images.first)
            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? PinAnnotation,
                  let pin = parent.pins.first(where: { $0.id == annotation.pinId }) else {
                return
            }
            mapView.deselectAnnotation(annotation, animated: false)
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

/// A Snap Map-style circular photo thumbnail annotation.
final class PhotoPinAnnotationView: MKAnnotationView {
    private let imageView = UIImageView()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        frame = CGRect(x: 0, y: 0, width: 52, height: 52)
        centerOffset = CGPoint(x: 0, y: -frame.height / 2)
        canShowCallout = false

        imageView.frame = bounds.insetBy(dx: 3, dy: 3)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = imageView.frame.width / 2
        imageView.layer.borderWidth = 3
        addSubview(imageView)

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 3
        layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    func configure(thumbnail: UIImage?) {
        imageView.layer.borderColor = UIColor.systemBlue.cgColor
        if let thumbnail {
            imageView.image = thumbnail
            imageView.backgroundColor = .white
        } else {
            imageView.image = UIImage(systemName: "camera.fill")
            imageView.tintColor = .white
            imageView.backgroundColor = .systemBlue
        }
    }
}
