import SwiftUI

class SavedLists: ObservableObject {
    @Published var lists: [[String]] = []
}
