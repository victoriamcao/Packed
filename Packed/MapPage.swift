//
//  MapPage.swift
//  Packed
//
//  Created by Scholar on 7/29/25.
//
import SwiftUI
import MapKit

struct MapPage: View {
    @State private var pins: [Pin] = []
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var showingImagePicker = false
    @State private var pickedImage: UIImage?
    
    var body: some View {
        ZStack {
            MapView(pins: $pins, onTap: { coordinate in
                selectedCoordinate = coordinate
                showingImagePicker = true
            })
            .edgesIgnoringSafeArea(.all)
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: addPinWithImage) {
            ImagePicker(image: $pickedImage)
        }
    }
    
    private func addPinWithImage() {
        guard let coordinate = selectedCoordinate else { return }
        let pin = Pin(coordinate: coordinate, image: pickedImage)
        pins.append(pin)
        pickedImage = nil
    }
}


struct MapView: UIViewRepresentable {
    @Binding var pins: [Pin]
    var onTap: (CLLocationCoordinate2D) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(gestureRecognizer:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        for pin in pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate = pin.coordinate
            annotation.title = "Tap for image"
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
    }
}


#Preview {
    MapPage()
}

