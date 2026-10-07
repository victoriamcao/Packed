//
//  SupabaseConfig.swift
//  Packed
//
//  Reads the Supabase project URL and anon key from SupabaseSecrets.plist,
//  which lives next to this file but is git-ignored so your project's
//  details stay out of the public repo.
//
//  Setup: copy Config/SupabaseSecrets.example.plist to
//  Packed/SupabaseSecrets.plist and fill in the two values from your
//  Supabase dashboard (Project Settings -> API).
//

import Foundation

enum SupabaseConfig {
    private static let values: [String: String] = {
        guard let url = Bundle.main.url(forResource: "SupabaseSecrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] else {
            return [:]
        }
        return plist
    }()

    static let projectURL = values["SUPABASE_URL"] ?? "https://YOUR_PROJECT_REF.supabase.co"
    static let anonKey = values["SUPABASE_ANON_KEY"] ?? "YOUR_ANON_PUBLIC_KEY"

    /// False until SupabaseSecrets.plist exists with real values.
    static var isConfigured: Bool {
        !projectURL.contains("YOUR_PROJECT_REF") && !anonKey.hasPrefix("YOUR_")
    }
}
