//
//  ImagePicker.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//
//  Wraps PHPickerViewController (out-of-process, no photo-library
//  permission required) and also reads the picked photo's embedded GPS
//  EXIF location, if present, so a geotagged photo can be auto-placed
//  on the map without the user needing to tap a location first.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import ImageIO
import CoreLocation

struct PickedPhoto: Equatable {
    let image: UIImage
    let coordinate: CLLocationCoordinate2D?

    static func == (lhs: PickedPhoto, rhs: PickedPhoto) -> Bool {
        lhs.image === rhs.image
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var pickedPhoto: PickedPhoto?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else { return }

            provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, _ in
                guard let url, let data = try? Data(contentsOf: url), let image = UIImage(data: data) else { return }
                let coordinate = Self.extractGPSCoordinate(from: data)
                DispatchQueue.main.async {
                    self.parent.pickedPhoto = PickedPhoto(image: image, coordinate: coordinate)
                }
            }
        }

        private static func extractGPSCoordinate(from data: Data) -> CLLocationCoordinate2D? {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                  let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
                  var latitude = gps[kCGImagePropertyGPSLatitude] as? Double,
                  var longitude = gps[kCGImagePropertyGPSLongitude] as? Double else {
                return nil
            }
            if (gps[kCGImagePropertyGPSLatitudeRef] as? String) == "S" { latitude = -latitude }
            if (gps[kCGImagePropertyGPSLongitudeRef] as? String) == "W" { longitude = -longitude }
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}
