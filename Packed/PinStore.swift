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

        let (data, _) = try await URLSession.shared.data(for: request)
        let remotePins = try JSONDecoder().decode([RemotePin].self, from: data)

        var pins: [Pin] = []
        for remote in remotePins {
            var images: [UIImage] = []
            for path in remote.photoPaths {
                if let image = try? await downloadPhoto(path: path, accessToken: accessToken) {
                    images.append(image)
                }
            }
            pins.append(Pin(
                id: remote.id,
                coordinate: CLLocationCoordinate2D(latitude: remote.latitude, longitude: remote.longitude),
                images: images,
                photoPaths: remote.photoPaths
            ))
        }
        return pins
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

    /// Uploads a photo to Storage and appends it to the pin's photo list.
    static func addPhoto(_ image: UIImage, to pin: Pin, userId: String, accessToken: String) async throws {
        guard let jpegData = image.jpegData(compressionQuality: 0.85) else {
            throw PinStoreError.requestFailed("Couldn't process the photo.")
        }

        let path = "\(userId)/\(pin.id)_\(pin.photoPaths.count)_\(Int(Date().timeIntervalSince1970)).jpg"
        try await uploadPhoto(data: jpegData, path: path, accessToken: accessToken)

        let updatedPaths = pin.photoPaths + [path]
        try await updatePhotoPaths(pinId: pin.id, photoPaths: updatedPaths, accessToken: accessToken)

        pin.photoPaths = updatedPaths
        pin.images.append(image)
    }

    static func deletePin(_ pin: Pin, accessToken: String) async {
        for path in pin.photoPaths {
            await deletePhoto(path: path, accessToken: accessToken)
        }
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/rest/v1/map_pins?id=eq.\(pin.id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: request)
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

    private static func downloadPhoto(path: String, accessToken: String) async throws -> UIImage? {
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/storage/v1/object/map-photos/\(path)") else {
            return nil
        }
        var request = URLRequest(url: url)
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        return UIImage(data: data)
    }

    private static func deletePhoto(path: String, accessToken: String) async {
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
