//
//  ThemeManager.swift
//  Packed
//
//  Persists the user's appearance preference (light/dark/system) and
//  exposes it as a ColorScheme? for .preferredColorScheme(_:) at the app
//  root - nil defers to the device's own light/dark setting, so "System"
//  keeps tracking it live as it changes.
//

import SwiftUI

enum AppColorScheme: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.righthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    private static let storageKey = "appColorSchemePreference"

    @Published var preference: AppColorScheme {
        didSet {
            UserDefaults.standard.set(preference.rawValue, forKey: Self.storageKey)
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: Self.storageKey)
        preference = saved.flatMap(AppColorScheme.init(rawValue:)) ?? .light
    }

    /// nil lets SwiftUI (and the OS) drive appearance from the device setting.
    var preferredColorScheme: ColorScheme? {
        switch preference {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
