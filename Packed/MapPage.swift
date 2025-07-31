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
                        selectedPinForPreview = existingPin
                    } else {
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
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $pickedImage)
        }
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
        .fullScreenCover(item: $selectedPinForPreview) { pin in
            NavigationView {
                ScrollView {
                    VStack {
                        Text("Photos at Location")
                            .font(.headline)
                            .padding()

                        if pin.images.isEmpty {
                            Text("No photos yet.")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ForEach(pin.images.indices, id: \.self) { index in
                                Image(uiImage: pin.images[index])
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(10)
                                    .padding()
                            }
                        }

                        Button("Add Photo") {
                            selectedCoordinate = pin.coordinate
                            selectedPinForPreview = nil
                            showingImagePicker = true
                        }
                        .padding()

                        Spacer()
                    }
                    .navigationTitle("Photos")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                selectedPinForPreview = nil
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: pickedImage) { oldValue, newValue in
            if newValue != nil {
                showingConfirmImage = true
                showingImagePicker = false
            }
        }
    }

    private func addPinWithImage() {
        guard let coordinate = selectedCoordinate, let image = pickedImage else { return }

        // Find the pin by coordinate and add the image
        if let index = pins.firstIndex(where: {
            abs($0.coordinate.latitude - coordinate.latitude) < 0.0005 &&
            abs($0.coordinate.longitude - coordinate.longitude) < 0.0005
        }) {
            pins[index].images.append(image)
            
            // Automatically show the updated pin
            DispatchQueue.main.async {
                selectedPinForPreview = pins[index]
            }
        } else {
            // Create new pin with image
            let newPin = Pin(coordinate: coordinate, images: [image])
            pins.append(newPin)
            
            DispatchQueue.main.async {
                selectedPinForPreview = newPin
            }
        }

        pickedImage = nil
        selectedCoordinate = nil
    }
}

#Preview {
    MapPage()
}
