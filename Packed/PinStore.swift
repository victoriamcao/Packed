//
//  PinStore.swift
//  Packed
//
//  Persists map photo pins to Supabase: pin coordinates + photo paths in
//  the map_pins table, actual photo bytes in the map-photos storage
//  bucket. Both are protected by row-level security scoped to the
//  logged-in user (see the setup SQL).
//

import Foundation
import CoreLocation
import UIKit

enum PinStoreError: LocalizedError {
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let message):
            return message
        }
    }
}

enum PinStore {
    private struct RemotePin: Codable {
        let id: String
        let latitude: Double
        let longitude: Double
        let photoPaths: [String]

        enum CodingKeys: String, CodingKey {
            case id, latitude, longitude
            case photoPaths = "photo_paths"
        }
    }

    static func load(userId: String, accessToken: String) async throws -> [Pin] {
        guard var components = URLComponents(string: "\(SupabaseConfig.projectURL)/rest/v1/map_pins") else {
            throw PinStoreError.requestFailed("Invalid URL.")
        }
        components.queryItems = [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "select", value: "*")
        ]
        guard let url = components.url else { throw PinStoreError.requestFailed("Invalid URL.") }

        var request = URLRequest(url: url)
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw PinStoreError.requestFailed("Couldn't load your map pins.")
        }
        let remotePins = try JSONDecoder().decode([RemotePin].self, from: data)

        // Fetch every photo in parallel (from the on-disk cache when we
        // already have it) instead of one at a time.
        let allPaths = Set(remotePins.flatMap(\.photoPaths))
        var photoData: [String: Data] = [:]
        await withTaskGroup(of: (String, Data?).self) { group in
            for path in allPaths {
                group.addTask {
                    (path, try? await photoBytes(path: path, accessToken: accessToken))
                }
            }
            for await (path, bytes) in group {
                if let bytes { photoData[path] = bytes }
            }
        }

        return remotePins.map { remote in
            // images/imagePaths stay parallel (only photos that actually
            // loaded); photoPaths stays the full server list.
            let loadedPaths = remote.photoPaths.filter { photoData[$0] != nil }
            var images: [UIImage] = []
            var imagePaths: [String] = []
            for path in loadedPaths {
                if let bytes = photoData[path], let image = PhotoCache.downsampledImage(from: bytes) {
                    images.append(image)
                    imagePaths.append(path)
                }
            }
            return Pin(
                id: remote.id,
                coordinate: CLLocationCoordinate2D(latitude: remote.latitude, longitude: remote.longitude),
                images: images,
                imagePaths: imagePaths,
                photoPaths: remote.photoPaths
            )
        }
    }

    /// Creates a new pin row at the given coordinate (no photos yet).
    static func createPin(coordinate: CLLocationCoordinate2D, userId: String, accessToken: String) async throws -> Pin {
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/rest/v1/map_pins") else {
            throw PinStoreError.requestFailed("Invalid URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "user_id": userId,
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "photo_paths": []
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw PinStoreError.requestFailed("Couldn't create the pin.")
        }
        let created = try JSONDecoder().decode([RemotePin].self, from: data)
        guard let first = created.first else {
            throw PinStoreError.requestFailed("Couldn't create the pin.")
        }
        return Pin(id: first.id, coordinate: coordinate)
    }

    /// Uploads a photo to Storage and appends it to the pin's photo list
    /// on the server. Returns the pin's new list of photo paths; the caller
    /// updates the Pin itself on the main actor.
    ///
    /// If saving the new path to the pin fails after the upload succeeded,
    /// the uploaded file is deleted again so it isn't orphaned in Storage.
    static func addPhoto(_ image: UIImage, to pin: Pin, userId: String, accessToken: String) async throws -> [String] {
        guard let jpegData = image.jpegData(compressionQuality: 0.85) else {
            throw PinStoreError.requestFailed("Couldn't process the photo.")
        }

        let existingPaths = pin.photoPaths
        let path = "\(userId)/\(pin.id)_\(UUID().uuidString).jpg"
        try await uploadPhoto(data: jpegData, path: path, accessToken: accessToken)

        let updatedPaths = existingPaths + [path]
        do {
            try await updatePhotoPaths(pinId: pin.id, photoPaths: updatedPaths, accessToken: accessToken)
        } catch {
            Log.map.error("Saving photo path failed, removing the uploaded file")
            await deletePhoto(path: path, accessToken: accessToken)
            throw error
        }
        PhotoCache.write(jpegData, for: path)
        return updatedPaths
    }

    /// Deletes the pin row first (so a failure never leaves a pin without
    /// its photos), then its photos from Storage and the local cache.
    static func deletePin(_ pin: Pin, accessToken: String) async throws {
        let photoPaths = pin.photoPaths
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/rest/v1/map_pins?id=eq.\(pin.id)") else {
            throw PinStoreError.requestFailed("Invalid URL.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw PinStoreError.requestFailed("Couldn't delete the pin.")
        }

        for path in photoPaths {
            await deletePhoto(path: path, accessToken: accessToken)
        }
    }

    /// Removes one photo from a pin. Returns the pin's remaining photo paths.
    static func removePhoto(path: String, from pin: Pin, accessToken: String) async throws -> [String] {
        let remaining = pin.photoPaths.filter { $0 != path }
        try await updatePhotoPaths(pinId: pin.id, photoPaths: remaining, accessToken: accessToken)
        await deletePhoto(path: path, accessToken: accessToken)
        return remaining
    }

    // MARK: - Storage

    private static func uploadPhoto(data: Data, path: String, accessToken: String) async throws {
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/storage/v1/object/map-photos/\(path)") else {
            throw PinStoreError.requestFailed("Invalid URL.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = data

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw PinStoreError.requestFailed("Couldn't upload the photo.")
        }
    }

    /// A photo's bytes, from the on-disk cache if we have them, otherwise
    /// downloaded (and then cached) - so reopening the map doesn't
    /// re-download every photo.
    private static func photoBytes(path: String, accessToken: String) async throws -> Data? {
        if let cached = PhotoCache.read(path) {
            return cached
        }
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/storage/v1/object/map-photos/\(path)") else {
            return nil
        }
        var request = URLRequest(url: url)
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return nil
        }
        PhotoCache.write(data, for: path)
        return data
    }

    private static func deletePhoto(path: String, accessToken: String) async {
        PhotoCache.remove(path)
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/storage/v1/object/map-photos/\(path)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: request)
    }

    private static func updatePhotoPaths(pinId: String, photoPaths: [String], accessToken: String) async throws {
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/rest/v1/map_pins?id=eq.\(pinId)") else {
            throw PinStoreError.requestFailed("Invalid URL.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["photo_paths": photoPaths])

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw PinStoreError.requestFailed("Couldn't update the pin.")
        }
    }
}
