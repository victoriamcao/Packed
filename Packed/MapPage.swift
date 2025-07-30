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
    
    @State private var showingConfirmImage = false
    @State private var selectedPinForPreview: Pin? = nil
    
    @State private var debugMessage = ""
    @State private var showDebug = false
    
    var body: some View {
        NavigationView {
            ZStack {
                MapView(pins: $pins, onTap: { coordinate in
                    debugMessage = "Tapped at: \(coordinate.latitude), \(coordinate.longitude)"
                    print(debugMessage) // Console logging
                    selectedCoordinate = coordinate
                    showingImagePicker = true
                }, onAnnotationTap: { pin in
                    debugMessage = "Annotation tapped for pin: \(pin.id)"
                    print(debugMessage) // Console logging
                    selectedPinForPreview = pin
                })
                .edgesIgnoringSafeArea(.all)
                
                // Debug overlay (optional - you can remove this later)
                if showDebug {
                    VStack {
                        Spacer()
                        Text(debugMessage)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding()
                    }
                }
                
                // Add pins counter in top corner
                VStack {
                    HStack {
                        Text("Pins: \(pins.count)")
                            .padding(8)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        Spacer()
                        Button("Debug") {
                            showDebug.toggle()
                        }
                        .padding(8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                    Spacer()
                }
            }
            .navigationTitle("Outfit Map")
            .navigationBarTitleDisplayMode(.inline)
        }
        // Pick an image when dropping pin
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $pickedImage)
        }
        // Confirm the image before adding pin
        .sheet(isPresented: $showingConfirmImage) {
            if let image = pickedImage {
                VStack(spacing: 20) {
                    Text("Confirm your photo")
                        .font(.headline)
                        .padding()
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .padding()
                    
                    if let coordinate = selectedCoordinate {
                        Text("Location: \(coordinate.latitude, specifier: "%.4f"), \(coordinate.longitude, specifier: "%.4f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 20) {
                        Button("Cancel") {
                            pickedImage = nil
                            selectedCoordinate = nil
                            showingConfirmImage = false
                        }
                        .foregroundStyle(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        
                        Button("Add Pin") {
                            addPinWithImage()
                        }
                        .foregroundStyle(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
        }
        // Preview pin image when tapped
        .sheet(item: $selectedPinForPreview) { pin in
            NavigationView {
                VStack {
                    if let image = pin.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                            .padding()
                    } else {
                        Text("No image available")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                    
                    Text("Added: \(pin.timestamp, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .navigationTitle("Outfit Pin")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button("Close") {
                    selectedPinForPreview = nil
                })
            }
        }
        // When image picked, show confirm sheet
        .onChange(of: pickedImage) { newValue in
            if newValue != nil {
                showingConfirmImage = true
                showingImagePicker = false
            }
        }
    }
    
    private func addPinWithImage() {
        guard let coordinate = selectedCoordinate, let image = pickedImage else {
            debugMessage = "Error: Missing coordinate or image"
            print(debugMessage)
            return
        }
        
        let newPin = Pin(coordinate: coordinate, image: image)
        pins.append(newPin)
        
        debugMessage = "Pin added successfully! Total pins: \(pins.count)"
        print(debugMessage)
        
        // Clean up
        pickedImage = nil
        selectedCoordinate = nil
        showingConfirmImage = false
    }
}

#Preview {
    MapPage()
}
