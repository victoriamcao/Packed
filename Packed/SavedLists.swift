import SwiftUI

/// A packing list item as stored in a saved list's `items` JSON column.
/// `id` and `isPacked` were added later, so older rows without them still
/// decode (see the Decodable extension below).
struct SavedPackingItem: Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var category: String
    var isPacked: Bool = false

    init(id: UUID = UUID(), name: String, category: String, isPacked: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.isPacked = isPacked
    }

    init(_ item: PackingItem) {
        self.init(id: item.id, name: item.name, category: item.category, isPacked: item.isPacked)
    }

    var packingItem: PackingItem {
        PackingItem(id: id, name: name, isPacked: isPacked, category: category)
    }

    /// The shape written to the `items` JSON column.
    var jsonObject: [String: Any] {
        ["id": id.uuidString, "name": name, "category": category, "isPacked": isPacked]
    }

    enum CodingKeys: String, CodingKey {
        case id, name, category, isPacked
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(String.self, forKey: .category)
        isPacked = try container.decodeIfPresent(Bool.self, forKey: .isPacked) ?? false
    }
}

@MainActor
class SavedLists: ObservableObject {
    @Published var lists: [PackingList] = []
    @Published var errorMessage: String?
    /// True once a load has finished at least once (success or failure),
    /// so screens can tell "still loading" apart from "really empty".
    @Published var hasLoaded = false

    /// One in-flight update per list, so rapid edits are sent to the
    /// server in order and an older request can't overwrite a newer one.
    private var updateChains: [String: Task<Bool, Never>] = [:]

    struct PackingList: Identifiable, Codable, Hashable {
        let id: String
        var title: String
        var items: [SavedPackingItem]
        var tripType: String
        var duration: Int
        var member: String
        var createdAt: Date
        /// Raw "yyyy-MM-dd" from Postgres's `date` column - kept as a plain
        /// string since it has no time component, unlike createdAt, so it
        /// can't share that field's timestamp decoding strategy.
        var travelDateString: String? = nil
        /// The owner's user id. Lists shared with you have someone else's id here.
        var userId: String? = nil

        enum CodingKeys: String, CodingKey {
            case id, title, items
            case tripType = "trip_type"
            case duration, member
            case createdAt = "created_at"
            case travelDateString = "travel_date"
            case userId = "user_id"
        }

        /// The trip's travel date, parsed from travelDateString using the
        /// device's local calendar (a travel date is a plain calendar day
        /// with no meaningful time zone of its own).
        var travelDate: Date? {
            guard let travelDateString else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter.date(from: travelDateString)
        }

        /// Lists with no owner id (older previews) count as yours.
        func isOwned(by userId: String?) -> Bool {
            guard let owner = self.userId, let userId else { return true }
            return owner == userId
        }
    }

    private static func dateOnlyString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    private static func makeRequest(_ path: String, method: String = "GET", accessToken: String) -> URLRequest? {
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/rest/v1/\(path)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    private static func isSuccess(_ response: URLResponse) -> Bool {
        guard let http = response as? HTTPURLResponse else { return false }
        return (200..<300).contains(http.statusCode)
    }

    // MARK: - Load

    func loadFromStorage(userId: String, accessToken: String) async {
        defer { hasLoaded = true }

        // Lists shared with this user (empty if sharing isn't set up on the backend yet).
        let sharedIds = await Self.fetchSharedListIds(userId: userId, accessToken: accessToken)

        var filter = "user_id.eq.\(userId)"
        if !sharedIds.isEmpty {
            filter += ",id.in.(\(sharedIds.joined(separator: ",")))"
        }

        guard var components = URLComponents(string: "\(SupabaseConfig.projectURL)/rest/v1/packing_lists") else { return }
        components.queryItems = [
            URLQueryItem(name: "or", value: "(\(filter))"),
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        guard let url = components.url else { return }

        var request = URLRequest(url: url)
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard Self.isSuccess(response) else {
                Log.data.error("Loading lists failed with a non-2xx response")
                errorMessage = "Couldn't load your saved lists."
                return
            }
            lists = try Self.decoder.decode([PackingList].self, from: data)
            errorMessage = nil
        } catch {
            Log.data.error("Loading lists failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't load your saved lists. Check your connection and try again."
        }
    }

    private static func fetchSharedListIds(userId: String, accessToken: String) async -> [String] {
        guard let request = makeRequest("list_shares?user_id=eq.\(userId)&select=list_id", accessToken: accessToken) else { return [] }
        struct Row: Decodable { let list_id: String }
        guard let result = try? await URLSession.shared.data(for: request),
              isSuccess(result.1),
              let rows = try? JSONDecoder().decode([Row].self, from: result.0) else {
            return []
        }
        return rows.map(\.list_id)
    }

    // MARK: - Save / update / delete

    @discardableResult
    func saveList(
        title: String,
        items: [SavedPackingItem],
        type: String,
        duration: Int,
        member: String,
        travelDate: Date,
        userId: String,
        accessToken: String
    ) async -> Bool {
        guard var request = Self.makeRequest("packing_lists", method: "POST", accessToken: accessToken) else {
            errorMessage = "Couldn't save your list."
            return false
        }
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "user_id": userId,
            "title": title,
            "items": items.map(\.jsonObject),
            "trip_type": type,
            "duration": duration,
            "member": member,
            "travel_date": Self.dateOnlyString(travelDate)
        ])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard Self.isSuccess(response) else {
                Log.data.error("Saving a list failed with a non-2xx response")
                errorMessage = "Couldn't save your list."
                return false
            }
            if let inserted = try? Self.decoder.decode([PackingList].self, from: data), let first = inserted.first {
                lists.insert(first, at: 0)
            }
            errorMessage = nil
            return true
        } catch {
            Log.data.error("Saving a list failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't save your list. Check your connection and try again."
            return false
        }
    }

    /// Persists edits made while reviewing a saved list (checking off,
    /// removing, reordering items). Updates to the same list are queued so
    /// they reach the server in the order they were made.
    @discardableResult
    func updateList(_ list: PackingList, items: [SavedPackingItem], userId: String?, accessToken: String) async -> Bool {
        let previous = updateChains[list.id]
        let task = Task { () -> Bool in
            _ = await previous?.value
            return await self.performUpdate(list, items: items, userId: userId, accessToken: accessToken)
        }
        updateChains[list.id] = task
        return await task.value
    }

    private func performUpdate(_ list: PackingList, items: [SavedPackingItem], userId: String?, accessToken: String) async -> Bool {
        let itemsJSON = items.map(\.jsonObject)
        var request: URLRequest?

        if list.isOwned(by: userId) {
            request = Self.makeRequest("packing_lists?id=eq.\(list.id)", method: "PATCH", accessToken: accessToken)
            // Ask for the updated row back - PostgREST answers 2xx even when
            // row-level security matched zero rows, so an empty array means
            // nothing was actually saved.
            request?.setValue("return=representation", forHTTPHeaderField: "Prefer")
            request?.httpBody = try? JSONSerialization.data(withJSONObject: ["items": itemsJSON])
        } else {
            request = Self.makeRequest("rpc/update_shared_list_items", method: "POST", accessToken: accessToken)
            request?.httpBody = try? JSONSerialization.data(withJSONObject: [
                "p_list_id": list.id,
                "p_items": itemsJSON
            ])
        }
        guard let request else { return false }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard Self.isSuccess(response) else {
                Log.data.error("Updating a list failed with a non-2xx response")
                return false
            }
            if list.isOwned(by: userId),
               let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
               json.isEmpty {
                Log.data.error("Updating a list matched no rows")
                return false
            }
            if let index = lists.firstIndex(where: { $0.id == list.id }) {
                lists[index].items = items
            }
            return true
        } catch {
            Log.data.error("Updating a list failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// Deletes a list you own. Only removes it locally once the server
    /// confirms, so a failed delete doesn't make the list vanish and then
    /// reappear on the next load.
    @discardableResult
    func deleteList(_ list: PackingList, accessToken: String) async -> Bool {
        guard let request = Self.makeRequest("packing_lists?id=eq.\(list.id)", method: "DELETE", accessToken: accessToken) else {
            return false
        }
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard Self.isSuccess(response) else {
                errorMessage = "Couldn't delete \"\(list.title)\"."
                return false
            }
            lists.removeAll { $0.id == list.id }
            return true
        } catch {
            errorMessage = "Couldn't delete \"\(list.title)\". Check your connection and try again."
            return false
        }
    }

    // MARK: - Sharing

    struct ShareMember: Decodable, Identifiable, Hashable {
        let username: String
        let name: String?
        var id: String { username }
    }

    /// Removes a list someone shared with you from your own saved lists
    /// (the owner's copy is untouched).
    @discardableResult
    func leaveSharedList(_ list: PackingList, accessToken: String) async -> Bool {
        guard var request = Self.makeRequest("rpc/leave_shared_list", method: "POST", accessToken: accessToken) else { return false }
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["p_list_id": list.id])
        guard let result = try? await URLSession.shared.data(for: request), Self.isSuccess(result.1) else {
            errorMessage = "Couldn't remove \"\(list.title)\"."
            return false
        }
        lists.removeAll { $0.id == list.id }
        return true
    }

    static func shareMembers(listId: String, accessToken: String) async throws -> [ShareMember] {
        guard var request = makeRequest("rpc/list_share_members", method: "POST", accessToken: accessToken) else { return [] }
        request.httpBody = try JSONSerialization.data(withJSONObject: ["p_list_id": listId])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard isSuccess(response) else { throw SharingError.from(data) }
        return try JSONDecoder().decode([ShareMember].self, from: data)
    }

    static func share(listId: String, withUsername username: String, accessToken: String) async throws {
        guard var request = makeRequest("rpc/share_list", method: "POST", accessToken: accessToken) else { return }
        request.httpBody = try JSONSerialization.data(withJSONObject: ["p_list_id": listId, "p_username": username])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard isSuccess(response) else { throw SharingError.from(data) }
    }

    static func unshare(listId: String, username: String, accessToken: String) async throws {
        guard var request = makeRequest("rpc/unshare_list", method: "POST", accessToken: accessToken) else { return }
        request.httpBody = try JSONSerialization.data(withJSONObject: ["p_list_id": listId, "p_username": username])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard isSuccess(response) else { throw SharingError.from(data) }
    }

    enum SharingError: LocalizedError {
        case server(String)

        var errorDescription: String? {
            switch self {
            case .server(let message): return message
            }
        }

        /// The SQL functions raise readable messages ("No user with that
        /// username"), which PostgREST returns in the `message` field.
        static func from(_ data: Data) -> SharingError {
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            return .server((json?["message"] as? String) ?? "Something went wrong. Try again.")
        }
    }

    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { try decodePostgresTimestamp(from: $0) }
        return decoder
    }
}
