//
//  PinStore.swift
//  Packed
//
//  Persists map photo pins across app launches. Follows the same
//  convention as SavedLists/UserData in this app - a JSON index in
//  UserDefaults - with the actual photo bytes written to files in the
//  app's Documents directory (UserDefaults isn't meant for image blobs).
//

import Foundation
import CoreLocation
import UIKit

enum PinStore {
    private struct StoredPin: Codable {
        let id: UUID
        let latitude: Double
        let longitude: Double
        let imageFilenames: [String]
    }

    private static let indexKey = "mapPinsIndex"

    private static var photosDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PinPhotos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func load() -> [Pin] {
        guard let data = UserDefaults.standard.data(forKey: indexKey),
              let stored = try? JSONDecoder().decode([StoredPin].self, from: data) else {
            return []
        }

        return stored.map { entry in
            let images = entry.imageFilenames.compactMap { filename -> UIImage? in
                let url = photosDirectory.appendingPathComponent(filename)
                guard let data = try? Data(contentsOf: url) else { return nil }
                return UIImage(data: data)
            }
            return Pin(
                id: entry.id,
                coordinate: CLLocationCoordinate2D(latitude: entry.latitude, longitude: entry.longitude),
                images: images
            )
        }
    }

    static func save(_ pins: [Pin]) {
        var stored: [StoredPin] = []

        for pin in pins {
            var filenames: [String] = []
            for (index, image) in pin.images.enumerated() {
                let filename = "\(pin.id.uuidString)_\(index).jpg"
                let url = photosDirectory.appendingPathComponent(filename)
                // Only encode/write images we haven't already persisted - avoids
                // re-compressing (and slowly degrading) the same JPEG on every save.
                if !FileManager.default.fileExists(atPath: url.path),
                   let jpegData = image.jpegData(compressionQuality: 0.85) {
                    try? jpegData.write(to: url)
                }
                filenames.append(filename)
            }
            stored.append(StoredPin(
                id: pin.id,
                latitude: pin.coordinate.latitude,
                longitude: pin.coordinate.longitude,
                imageFilenames: filenames
            ))
        }

        if let data = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(data, forKey: indexKey)
        }
        cleanupOrphanedFiles(keeping: stored)
    }

    private static func cleanupOrphanedFiles(keeping stored: [StoredPin]) {
        let keepNames = Set(stored.flatMap { $0.imageFilenames })
        guard let files = try? FileManager.default.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: nil) else { return }
        for file in files where !keepNames.contains(file.lastPathComponent) {
            try? FileManager.default.removeItem(at: file)
        }
    }
}
