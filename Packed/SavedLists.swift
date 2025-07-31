//
//  SavedLists.swift
//  Packed
//
//  Created by Scholar on 7/29/25.
//

import SwiftUI

class SavedLists: ObservableObject {
    @Published var lists: [PackingList] = []
    
    struct PackingList: Identifiable, Codable {
        let id = UUID()
        var title: String
        var items: [String]
        var tripType: String
        var duration: Int
        var member: String
        var createdAt = Date()
    }
    
    func saveList(title: String, items: [String], type: String, duration: Int, member: String) {
        let newList = PackingList(
            title: title,
            items: items,
            tripType: type,
            duration: duration,
            member: member
        )
        lists.append(newList)
        saveToStorage()
    }
    
    func deleteList(at indexSet: IndexSet) {
        lists.remove(atOffsets: indexSet)
        saveToStorage()
    }
    
    private func saveToStorage() {
        if let encoded = try? JSONEncoder().encode(lists) {
            UserDefaults.standard.set(encoded, forKey: "savedPackingLists")
        }
    }
    
    func loadFromStorage() {
        if let data = UserDefaults.standard.data(forKey: "savedPackingLists"),
           let decoded = try? JSONDecoder().decode([PackingList].self, from: data) {
            lists = decoded
        }
    }
}
