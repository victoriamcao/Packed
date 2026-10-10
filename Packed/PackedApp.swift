import SwiftUI

@main
struct PackedApp: App {
    @StateObject private var themeManager = ThemeManager()

    init() {
        if !SupabaseConfig.isConfigured {
            Log.data.fault("Supabase isn't configured. Copy Config/SupabaseSecrets.example.plist to Packed/SupabaseSecrets.plist and fill it in.")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.preferredColorScheme)
        }
    }
}
