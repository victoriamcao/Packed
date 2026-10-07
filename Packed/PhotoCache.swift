//
//  PhotoCache.swift
//  Packed
//
//  A small on-disk cache for map photos, keyed by their Supabase Storage
//  path. Photo paths are unique per upload, so a cached file never goes
//  stale. Lives in Caches, so iOS can clear it when space runs low.
//

import UIKit
import ImageIO

enum PhotoCache {
    private static var directory: URL? {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let dir = caches.appendingPathComponent("MapPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func fileURL(for path: String) -> URL? {
        directory?.appendingPathComponent(path.replacingOccurrences(of: "/", with: "_"))
    }

    static func read(_ path: String) -> Data? {
        guard let url = fileURL(for: path) else { return nil }
        return try? Data(contentsOf: url)
    }

    static func write(_ data: Data, for path: String) {
        guard let url = fileURL(for: path) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func remove(_ path: String) {
        guard let url = fileURL(for: path) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Clears every cached photo (used when logging out or deleting the account).
    static func removeAll() {
        guard let dir = directory else { return }
        try? FileManager.default.removeItem(at: dir)
    }

    /// Decodes image data at a capped size instead of full camera
    /// resolution, which keeps memory reasonable with lots of pins.
    static func downsampledImage(from data: Data) -> UIImage? {
        let maxPixelSize = 1600
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            return UIImage(data: data)
        }
        return UIImage(cgImage: cgImage)
    }
}
