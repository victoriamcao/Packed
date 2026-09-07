//
//  AppNavigator.swift
//  Packed
//
//  Shared navigation state so the bottom nav bar can jump to Home/Map/
//  Profile from any screen, not just from ContentView's own body. All
//  screens reached from ContentView push onto this single shared path.
//

import Foundation
import SwiftUI

enum AppDestination: Hashable {
    case survey
    case pastLists
    case map
    case profile
    case loginChoice
    case listPage(ListPageParams)
    case listDetail(SavedLists.PackingList)
    case login
    case signup
    case changePassword
    case apiKeySettings
}

struct ListPageParams: Hashable {
    var selectedType: String
    var selectedGender: String
    var selectedWeather: String
    var selectedLength: Int
    var destination: String
    var travelDate: Date
}

final class AppNavigator: ObservableObject {
    @Published var path = NavigationPath()

    /// Used by the bottom nav bar - always lands on one clean screen,
    /// regardless of how deep the current stack is.
    func goHome() {
        path = NavigationPath()
    }

    func go(to destination: AppDestination) {
        path = NavigationPath([destination])
    }

    /// Used for one-off forward pushes (e.g. Home -> Create Packing List)
    /// that should stay poppable back to where they came from.
    func push(_ destination: AppDestination) {
        path.append(destination)
    }

    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
