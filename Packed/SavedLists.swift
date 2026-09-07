import SwiftUI

/// A packing list item as stored in a saved list - just name + category,
/// since a saved list doesn't track packed/unpacked state.
struct SavedPackingItem: Codable, Hashable {
    var name: String
    var category: String
}

@MainActor
class SavedLists: ObservableObject {
    @Published var lists: [PackingList] = []
    @Published var errorMessage: String?

    struct PackingList: Identifiable, Codable, Hashable {
        let id: String
        var title: String
        var items: [SavedPackingItem]
        var tripType: String
        var duration: Int
        var member: String
        var createdAt: Date

        enum CodingKeys: String, CodingKey {
            case id, title, items
            case tripType = "trip_type"
            case duration, member
            case createdAt = "created_at"
        }
    }

    func loadFromStorage(userId: String, accessToken: String) async {
        guard var components = URLComponents(string: "\(SupabaseConfig.projectURL)/rest/v1/packing_lists") else { return }
        components.queryItems = [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        guard let url = components.url else { return }

        var request = URLRequest(url: url)
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            lists = try Self.decoder.decode([PackingList].self, from: data)
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't load your saved lists."
        }
    }

    @discardableResult
    func saveList(
        title: String,
        items: [SavedPackingItem],
        type: String,
        duration: Int,
        member: String,
        userId: String,
        accessToken: String
    ) async -> Bool {
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/rest/v1/packing_lists") else {
            errorMessage = "Couldn't save your list."
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "user_id": userId,
            "title": title,
            "items": items.map { ["name": $0.name, "category": $0.category] },
            "trip_type": type,
            "duration": duration,
            "member": member
        ])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                errorMessage = "Couldn't save your list."
                return false
            }
            if let inserted = try? Self.decoder.decode([PackingList].self, from: data), let first = inserted.first {
                lists.insert(first, at: 0)
            }
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Couldn't save your list."
            return false
        }
    }

    /// Persists edits made while reviewing a saved list (checking off or
    /// removing items) back to the server.
    @discardableResult
    func updateList(_ list: PackingList, items: [SavedPackingItem], accessToken: String) async -> Bool {
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/rest/v1/packing_lists?id=eq.\(list.id)") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "items": items.map { ["name": $0.name, "category": $0.category] }
        ])

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return false
            }
            if let index = lists.firstIndex(where: { $0.id == list.id }) {
                lists[index].items = items
            }
            return true
        } catch {
            return false
        }
    }

    func deleteList(_ list: PackingList, accessToken: String) async {
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/rest/v1/packing_lists?id=eq.\(list.id)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        _ = try? await URLSession.shared.data(for: request)
        lists.removeAll { $0.id == list.id }
    }

    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(decodePostgresTimestamp)
        return decoder
    }
}
