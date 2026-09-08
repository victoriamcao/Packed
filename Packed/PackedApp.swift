import SwiftUI

@main
struct PackedApp: App {
    @StateObject private var savedLists = SavedLists()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(savedLists)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.preferredColorScheme)
        }
    }
}
