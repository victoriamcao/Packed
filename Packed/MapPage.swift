import SwiftUI
import MapKit
import Combine

struct MapPage: View {
    @EnvironmentObject var userData: UserData
    @StateObject private var locationManager = LocationManager()

    @State private var pins: [Pin] = []
    @State private var centerOnCoordinate: CLLocationCoordinate2D?
    @State private var hasCenteredOnUser = false

    // The coordinate a new photo will be attached to once picked.
    @State private var pendingCoordinate: CLLocationCoordinate2D?
    @State private var pickedPhoto: PickedPhoto?
    @State private var showingImagePicker = false
    @State private var showingConfirmImage = false
    @State private var selectedPinForPreview: Pin?
    @State private var isSavingPhoto = false
    @State private var errorMessage: String?
    @State private var showLoginPrompt = false

    // Set when the user picked a photo (via the global "+" button) that has no
    // GPS EXIF data and hasn't tapped a location for it yet.
    @State private var photoAwaitingPlacement: PickedPhoto?

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                MapView(
                    pins: $pins,
                    centerOnCoordinate: $centerOnCoordinate,
                    onTap: handleMapTap,
                    onAnnotationTap: { pin in
                        selectedPinForPreview = pin
                    }
                )
                .edgesIgnoringSafeArea(.all)

                if photoAwaitingPlacement != nil {
                    Text("Tap the map to place this photo")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                        .padding(.top, 16)
                }

                if isSavingPhoto {
                    Text("Saving photo...")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                        .padding(.top, 16)
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            guard requireLogin() else { return }
                            pendingCoordinate = nil
                            showingImagePicker = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                        .padding(.bottom, 60)
                    }
                }
            }

            BottomNavBar(current: .map)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(pickedPhoto: $pickedPhoto)
        }
        .sheet(isPresented: $showingConfirmImage) {
            if let photo = pickedPhoto {
                ZStack {
                    Color("appBackground").ignoresSafeArea()

                    VStack {
                        Text("Confirm your photo")
                            .font(.headline)
                            .padding()

                        Image(uiImage: photo.image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .padding()

                        HStack {
                            Button("Cancel") {
                                pickedPhoto = nil
                                pendingCoordinate = nil
                                showingConfirmImage = false
                            }
                            .padding()

                            Spacer()

                            Button("Confirm") {
                                showingConfirmImage = false
                                addPinWithPendingPhoto()
                            }
                            .padding()
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedPinForPreview) { pin in
            PhotoDetailView(pin: pin) {
                pendingCoordinate = pin.coordinate
                selectedPinForPreview = nil
                showingImagePicker = true
            }
        }
        .onChange(of: pickedPhoto) { _, newValue in
            guard let newValue else { return }
            showingImagePicker = false

            if pendingCoordinate != nil {
                // User already chose a location (tapped the map first).
                showingConfirmImage = true
            } else if let geotag = newValue.coordinate {
                // No location chosen yet, but the photo carries its own GPS EXIF - auto-place it.
                pendingCoordinate = geotag
                centerOnCoordinate = geotag
                showingConfirmImage = true
            } else {
                // No location chosen and no EXIF geotag - ask the user to tap the map.
                photoAwaitingPlacement = newValue
                pickedPhoto = nil
            }
        }
        .onAppear {
            locationManager.requestPermission()
            Task { await loadPins() }
        }
        .onChange(of: userData.isLoggedIn) { _, isLoggedIn in
            if isLoggedIn {
                Task { await loadPins() }
            } else {
                pins = []
            }
        }
        .onReceive(locationManager.$userLocation) { newValue in
            guard let newValue, !hasCenteredOnUser else { return }
            centerOnCoordinate = newValue
            hasCenteredOnUser = true
        }
        .alert("Log in required", isPresented: $showLoginPrompt) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Log in to save photos to the map.")
        }
        .alert("Couldn't save photo", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func requireLogin() -> Bool {
        guard userData.isLoggedIn else {
            showLoginPrompt = true
            return false
        }
        return true
    }

    private func loadPins() async {
        guard userData.isLoggedIn,
              let token = try? await userData.validAccessToken(),
              let uid = userData.currentUserId else { return }
        if let loaded = try? await PinStore.load(userId: uid, accessToken: token) {
            pins = loaded
        }
    }

    private func handleMapTap(_ coordinate: CLLocationCoordinate2D) {
        if let awaitingPhoto = photoAwaitingPlacement {
            guard requireLogin() else { return }
            pendingCoordinate = coordinate
            pickedPhoto = awaitingPhoto
            photoAwaitingPlacement = nil
            showingConfirmImage = true
            return
        }

        if let existingPin = pins.first(where: { isSameLocation($0.coordinate, coordinate) }) {
            selectedPinForPreview = existingPin
        } else {
            guard requireLogin() else { return }
            pendingCoordinate = coordinate
            showingImagePicker = true
        }
    }

    private func addPinWithPendingPhoto() {
        guard let coordinate = pendingCoordinate, let photo = pickedPhoto else { return }
        pickedPhoto = nil
        pendingCoordinate = nil

        Task {
            guard let token = try? await userData.validAccessToken(), let uid = userData.currentUserId else {
                showLoginPrompt = true
                return
            }

            isSavingPhoto = true
            do {
                if let index = pins.firstIndex(where: { isSameLocation($0.coordinate, coordinate) }) {
                    try await PinStore.addPhoto(photo.image, to: pins[index], userId: uid, accessToken: token)
                    // Pin is a class - mutating it in place doesn't change the
                    // [Pin] array's identity, so force a refresh of the map's
                    // annotation thumbnails.
                    pins = pins
                } else {
                    let newPin = try await PinStore.createPin(coordinate: coordinate, userId: uid, accessToken: token)
                    try await PinStore.addPhoto(photo.image, to: newPin, userId: uid, accessToken: token)
                    pins.append(newPin)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSavingPhoto = false
        }
    }

    private func isSameLocation(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Bool {
        abs(a.latitude - b.latitude) < 0.0005 && abs(a.longitude - b.longitude) < 0.0005
    }
}

private struct PhotoDetailView: View {
    @ObservedObject var pin: Pin
    @Environment(\.dismiss) var dismiss
    var onAddPhoto: () -> Void

    var body: some View {
        NavigationView {
            Group {
                if pin.images.isEmpty {
                    Text("No photos yet.")
                        .foregroundColor(.gray)
                } else {
                    TabView {
                        ForEach(pin.images.indices, id: \.self) { index in
                            Image(uiImage: pin.images[index])
                                .resizable()
                                .scaledToFit()
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: pin.images.count > 1 ? .always : .never))
                    .background(Color.black)
                }
            }
            .navigationTitle(pin.images.isEmpty ? "Photos" : "\(pin.images.count) Photo\(pin.images.count == 1 ? "" : "s")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: onAddPhoto) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    MapPage()
        .environmentObject(UserData())
}
