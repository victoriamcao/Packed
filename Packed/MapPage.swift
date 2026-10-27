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
                        .accessibilityLabel("Add a photo")
                        .accessibilityHint("Pick a photo, then place it on the map")
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
        .fullScreenCover(item: $selectedPinForPreview) { pin in
            PhotoDetailView(
                pin: pin,
                onAddPhoto: {
                    pendingCoordinate = pin.coordinate
                    selectedPinForPreview = nil
                    showingImagePicker = true
                },
                onDeletePhoto: { path in
                    await deletePhoto(path: path, from: pin)
                },
                onDeletePin: {
                    await deletePin(pin)
                }
            )
        }
        .onChange(of: pickedPhoto) { _, newValue in
            guard let newValue else { return }
            showingImagePicker = false

            if pendingCoordinate != nil {
                // User already chose a location (tapped the map first).
                addPinWithPendingPhoto()
            } else if let geotag = newValue.coordinate {
                // No location chosen yet, but the photo carries its own GPS EXIF - auto-place it.
                pendingCoordinate = geotag
                centerOnCoordinate = geotag
                addPinWithPendingPhoto()
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
        .alert("Something went wrong", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .navigationBarBackButtonHidden(true)
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
        do {
            pins = try await PinStore.load(userId: uid, accessToken: token)
        } catch {
            Log.map.error("Loading pins failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't load your map photos. Check your connection and try again."
        }
    }

    private func handleMapTap(_ coordinate: CLLocationCoordinate2D) {
        if let awaitingPhoto = photoAwaitingPlacement {
            guard requireLogin() else { return }
            pendingCoordinate = coordinate
            pickedPhoto = awaitingPhoto
            photoAwaitingPlacement = nil
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
            defer { isSavingPhoto = false }

            if let index = pins.firstIndex(where: { isSameLocation($0.coordinate, coordinate) }) {
                let pin = pins[index]
                do {
                    let paths = try await PinStore.addPhoto(photo.image, to: pin, userId: uid, accessToken: token)
                    pin.photoPaths = paths
                    pin.images.append(photo.image)
                    if let newPath = paths.last { pin.imagePaths.append(newPath) }
                    // Pin is a class - mutating it in place doesn't change the
                    // [Pin] array's identity, so force a refresh of the map's
                    // annotation thumbnails.
                    pins = pins
                } catch {
                    errorMessage = error.localizedDescription
                }
                return
            }

            let newPin: Pin
            do {
                newPin = try await PinStore.createPin(coordinate: coordinate, userId: uid, accessToken: token)
            } catch {
                errorMessage = error.localizedDescription
                return
            }

            do {
                let paths = try await PinStore.addPhoto(photo.image, to: newPin, userId: uid, accessToken: token)
                newPin.photoPaths = paths
                newPin.images = [photo.image]
                newPin.imagePaths = paths
                pins.append(newPin)
            } catch {
                // The pin row exists but its photo didn't save - remove the
                // empty pin so it doesn't show up later as a photo-less pin.
                try? await PinStore.deletePin(newPin, accessToken: token)
                errorMessage = error.localizedDescription
            }
        }
    }

    private func deletePhoto(path: String, from pin: Pin) async {
        guard let token = try? await userData.validAccessToken() else { return }
        // Removing the last photo removes the pin itself.
        if pin.photoPaths.count <= 1 {
            await deletePin(pin)
            return
        }
        do {
            let remaining = try await PinStore.removePhoto(path: path, from: pin, accessToken: token)
            pin.photoPaths = remaining
            if let index = pin.imagePaths.firstIndex(of: path) {
                pin.imagePaths.remove(at: index)
                pin.images.remove(at: index)
            }
            pins = pins
        } catch {
            selectedPinForPreview = nil
            errorMessage = error.localizedDescription
        }
    }

    private func deletePin(_ pin: Pin) async {
        guard let token = try? await userData.validAccessToken() else { return }
        do {
            try await PinStore.deletePin(pin, accessToken: token)
            pins.removeAll { $0.id == pin.id }
            selectedPinForPreview = nil
        } catch {
            selectedPinForPreview = nil
            errorMessage = error.localizedDescription
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
    var onDeletePhoto: (String) async -> Void
    var onDeletePin: () async -> Void

    @State private var currentIndex = 0
    @State private var confirmingDeletePhoto = false
    @State private var confirmingDeletePin = false
    @State private var isDeleting = false

    var body: some View {
        NavigationStack {
            Group {
                if pin.images.isEmpty {
                    Text("No photos yet.")
                        .foregroundColor(.gray)
                } else {
                    TabView(selection: $currentIndex) {
                        ForEach(pin.images.indices, id: \.self) { index in
                            Image(uiImage: pin.images[index])
                                .resizable()
                                .scaledToFit()
                                .accessibilityLabel("Photo \(index + 1) of \(pin.images.count)")
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: pin.images.count > 1 ? .always : .never))
                    .background(Color.black)
                }
            }
            .overlay {
                if isDeleting {
                    ProgressView()
                }
            }
            .navigationTitle(pin.images.isEmpty ? "Photos" : "\(pin.images.count) Photo\(pin.images.count == 1 ? "" : "s")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu {
                        if !pin.images.isEmpty {
                            Button(role: .destructive) {
                                confirmingDeletePhoto = true
                            } label: {
                                Label("Delete This Photo", systemImage: "photo")
                            }
                        }
                        Button(role: .destructive) {
                            confirmingDeletePin = true
                        } label: {
                            Label("Delete Pin and All Photos", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("More options")
                    .disabled(isDeleting)

                    Button(action: onAddPhoto) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add a photo to this pin")
                    .disabled(isDeleting)
                }
            }
            .confirmationDialog("Delete this photo?", isPresented: $confirmingDeletePhoto, titleVisibility: .visible) {
                Button("Delete Photo", role: .destructive) {
                    guard pin.imagePaths.indices.contains(currentIndex) else { return }
                    let path = pin.imagePaths[currentIndex]
                    Task {
                        isDeleting = true
                        await onDeletePhoto(path)
                        currentIndex = max(0, min(currentIndex, pin.images.count - 1))
                        isDeleting = false
                    }
                }
            }
            .confirmationDialog("Delete this pin and all its photos?", isPresented: $confirmingDeletePin, titleVisibility: .visible) {
                Button("Delete Pin", role: .destructive) {
                    Task {
                        isDeleting = true
                        await onDeletePin()
                        isDeleting = false
                    }
                }
            } message: {
                Text("This can't be undone.")
            }
        }
    }
}

#Preview {
    MapPage()
        .environmentObject(UserData())
}
