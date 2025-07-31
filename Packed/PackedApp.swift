import SwiftUI

@main
struct PackedApp: App {
    @StateObject private var savedLists = SavedLists()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(savedLists)
        }
    }
}
