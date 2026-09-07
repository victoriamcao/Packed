//
//  ClaudePackingListService.swift
//  Packed
//
//  Calls the Claude API (Anthropic Messages API) to generate a packing list
//  tailored to the trip's destination, dates, type, and weather context,
//  then maps the result into the app's existing PackingItem model.
//
//  Requires the user to supply their own Anthropic API key (see
//  APIKeyStore / ProfileView) - this app has no backend, so no key ships
//  in the binary. If no key is configured, or the request fails for any
//  reason, callers should fall back to ListItems.generatePackingList.
//

import Foundation

enum ClaudePackingListError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No Anthropic API key is configured."
        case .invalidResponse:
            return "The Claude API returned an unexpected response."
        case .requestFailed(let message):
            return message
        }
    }
}

enum ClaudePackingListService {

    private static let endpoint = "https://api.anthropic.com/v1/messages"
    private static let model = "claude-opus-5"
    private static let toolName = "record_packing_list"

    static func generatePackingList(
        destination: String,
        tripType: String,
        gender: String,
        travelDate: Date,
        lengthDays: Int,
        weather: HistoricalWeatherSummary?
    ) async throws -> [PackingItem] {
        guard let apiKey = APIKeyStore.load(), !apiKey.isEmpty else {
            throw ClaudePackingListError.missingAPIKey
        }

        guard let url = URL(string: endpoint) else {
            throw ClaudePackingListError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody(
            destination: destination,
            tripType: tripType,
            gender: gender,
            travelDate: travelDate,
            lengthDays: lengthDays,
            weather: weather
        ))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudePackingListError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ClaudePackingListError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = (json["error"] as? [String: Any])?["message"] as? String
            throw ClaudePackingListError.requestFailed(message ?? "Request failed with status \(httpResponse.statusCode).")
        }

        guard let content = json["content"] as? [[String: Any]],
              let toolUseBlock = content.first(where: { $0["type"] as? String == "tool_use" && $0["name"] as? String == toolName }),
              let input = toolUseBlock["input"] else {
            throw ClaudePackingListError.invalidResponse
        }

        let inputData = try JSONSerialization.data(withJSONObject: input)
        let payload = try JSONDecoder().decode(PackingListPayload.self, from: inputData)

        guard !payload.items.isEmpty else {
            throw ClaudePackingListError.invalidResponse
        }

        return payload.items.map { PackingItem(name: $0.name, category: $0.category) }
    }

    // MARK: - Request construction

    private static func requestBody(
        destination: String,
        tripType: String,
        gender: String,
        travelDate: Date,
        lengthDays: Int,
        weather: HistoricalWeatherSummary?
    ) -> [String: Any] {
        [
            "model": model,
            "max_tokens": 16000,
            "output_config": ["effort": "low"],
            "tools": [
                [
                    "name": toolName,
                    "description": "Records the generated packing list.",
                    "strict": true,
                    "input_schema": [
                        "type": "object",
                        "properties": [
                            "items": [
                                "type": "array",
                                "items": [
                                    "type": "object",
                                    "properties": [
                                        "name": ["type": "string", "description": "The packing list item, including a quantity in the name if more than one is needed (e.g. \"3 T-shirts\")."],
                                        "category": ["type": "string", "description": "A short category label grouping related items (e.g. Essentials, Clothing, Toiletries & Personal Items, Hiking Gear)."]
                                    ],
                                    "required": ["name", "category"],
                                    "additionalProperties": false
                                ]
                            ]
                        ],
                        "required": ["items"],
                        "additionalProperties": false
                    ]
                ]
            ],
            "tool_choice": ["type": "tool", "name": toolName],
            "messages": [
                ["role": "user", "content": prompt(
                    destination: destination,
                    tripType: tripType,
                    gender: gender,
                    travelDate: travelDate,
                    lengthDays: lengthDays,
                    weather: weather
                )]
            ]
        ]
    }

    private static func prompt(
        destination: String,
        tripType: String,
        gender: String,
        travelDate: Date,
        lengthDays: Int,
        weather: HistoricalWeatherSummary?
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let dateText = formatter.string(from: travelDate)

        var weatherLine = "Weather: unknown - use seasonally reasonable assumptions for the destination and date."
        if let weather {
            let source = weather.isForecast ? "forecast" : "historical average"
            weatherLine = "Weather (\(source)): high \(Int(weather.averageHighF.rounded()))°F, low \(Int(weather.averageLowF.rounded()))°F, "
                + "precipitation \(String(format: "%.1f", weather.averagePrecipitationMM))mm, "
                + "snowfall \(String(format: "%.1f", weather.averageSnowfallCM))cm, "
                + "wind \(String(format: "%.0f", weather.averageWindSpeedKMH))km/h. Overall conditions: \(weather.suggestedCondition.rawValue)."
        }

        return """
        Generate a complete, practical packing list for the trip described below.

        Destination: \(destination.isEmpty ? "Not specified" : destination)
        Trip type: \(tripType)
        Traveler: \(gender)
        Trip length: \(lengthDays) day(s)
        Travel date: \(dateText)
        \(weatherLine)

        Guidelines:
        - Scale clothing quantities sensibly to the trip length (include the quantity in the item name when more than one is needed).
        - Group items into clear categories such as Essentials, Clothing, Toiletries & Personal Items, and any trip-specific gear category appropriate to the trip type and weather.
        - Include practical essentials (documents, chargers, toiletries) as well as weather- and activity-appropriate items.
        - Do not include duplicate items.

        Call the \(toolName) tool with the full list.
        """
    }

    // MARK: - Response models

    private struct PackingListPayload: Decodable {
        struct Item: Decodable {
            let name: String
            let category: String
        }
        let items: [Item]
    }
}
