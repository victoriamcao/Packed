import SwiftUI
import MapKit

struct MapPage: View {
    @State private var pins: [Pin] = []
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var pickedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingConfirmImage = false
    @State private var selectedPinForPreview: Pin?

    var body: some View {
        ZStack {
            MapView(
                pins: $pins,
                onTap: { coordinate in
                    if let existingPin = pins.first(where: {
                        abs($0.coordinate.latitude - coordinate.latitude) < 0.0005 &&
                        abs($0.coordinate.longitude - coordinate.longitude) < 0.0005
                    }) {
                        // Show preview for existing pin
                        selectedPinForPreview = existingPin
                    } else {
                        // Create a new pin with empty images, add it to pins array so it has an ID
                        let newPin = Pin(coordinate: coordinate, images: [])
                        pins.append(newPin)
                        selectedPinForPreview = newPin
                    }
                },
                onAnnotationTap: { pin in
                    selectedPinForPreview = pin
                }
            )
            .edgesIgnoringSafeArea(.all)

            VStack {
                HStack {
                    Text("Pins: \(pins.count)")
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
        // Image picker sheet
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $pickedImage)
        }
        // Confirm image sheet
        .sheet(isPresented: $showingConfirmImage) {
            if let image = pickedImage {
                ZStack {
                    Color.white.ignoresSafeArea()

                    VStack {
                        Text("Confirm your photo")
                            .font(.headline)
                            .padding()

                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .padding()

                        HStack {
                            Button("Cancel") {
                                pickedImage = nil
                                showingConfirmImage = false
                            }
                            .padding()

                            Spacer()

                            Button("Confirm") {
                                addPinWithImage()
                                showingConfirmImage = false
                            }
                            .padding()
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        // Pin photo preview sheet
        .sheet(item: $selectedPinForPreview) { pin in
            ScrollView {
                VStack {
                    Text("Photos at Location")
                        .font(.headline)
                        .padding()

                    if pin.images.isEmpty {
                        Text("No photos yet.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(pin.images.indices, id: \.self) { index in
                            Image(uiImage: pin.images[index])
                                .resizable()
                                .scaledToFit()
                                .padding()
                        }
                    }

                    Button("Add Photo") {
                        selectedCoordinate = pin.coordinate
                        selectedPinForPreview = nil // Close preview before showing picker
                        showingImagePicker = true
                    }
                    .padding()
                }
            }
        }
        // When user picks an image, go to confirmation sheet
        .onChange(of: pickedImage) { newValue in
            if newValue != nil {
                showingConfirmImage = true
                showingImagePicker = false
            }
        }
    }

    private func addPinWithImage() {
        guard let coordinate = selectedCoordinate, let image = pickedImage else { return }

        if let index = pins.firstIndex(where: {
            abs($0.coordinate.latitude - coordinate.latitude) < 0.0005 &&
            abs($0.coordinate.longitude - coordinate.longitude) < 0.0005
        }) {
            pins[index].images.append(image)  // Append new image
            selectedPinForPreview = pins[index]
        } else {
            // Should not happen since new pins created on tap already
            let newPin = Pin(coordinate: coordinate, images: [image])
            pins.append(newPin)
            selectedPinForPreview = newPin
        }

        pickedImage = nil
        selectedCoordinate = nil
    }
}

#Preview {
    MapPage()
}
