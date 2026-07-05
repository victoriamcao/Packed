//
//  WeatherService.swift
//  Packed
//
//  Fetches historical weather averages for a destination + travel date so the
//  packing list can recommend clothing based on the typical conditions there,
//  instead of relying only on a manually picked "weather" label.
//
//  Data source: Open-Meteo (https://open-meteo.com)
//    - Geocoding API: resolves a free-text place name to coordinates.
//    - Historical Weather (Archive) API: daily observed weather back to 1940.
//  Both are free, require no API key, and are updated continuously, which
//  makes them a good fit for computing "typical weather on this date" by
//  averaging the same calendar day across recent years.
//

import Foundation

/// A resolved location returned by the geocoding lookup.
struct GeocodedPlace: Equatable {
    let name: String
    let latitude: Double
    let longitude: Double
}

/// The historical average conditions for a destination on a given day of year,
/// computed from several years of observed daily data.
struct HistoricalWeatherSummary: Equatable {
    let locationName: String
    let month: Int
    let day: Int
    let averageHighC: Double
    let averageLowC: Double
    let averagePrecipitationMM: Double
    let averageSnowfallCM: Double
    let averageWindSpeedKMH: Double
    let yearsSampled: Int

    var averageHighF: Double { averageHighC * 9.0 / 5.0 + 32.0 }
    var averageLowF: Double { averageLowC * 9.0 / 5.0 + 32.0 }

    /// Buckets the averages into a broad condition so it can be blended with
    /// (or replace) the app's existing manual weather categories.
    var suggestedCondition: WeatherCondition {
        if averageSnowfallCM >= 0.5 {
            return .snowy
        }
        if averagePrecipitationMM >= 4.0 {
            return .rainy
        }
        if averageWindSpeedKMH >= 25.0 {
            return .windy
        }
        if averageHighC < 13.0 {
            return .cold
        }
        return .sunny
    }

    /// Short human-readable line to show the user what data drove the recommendation.
    var summaryText: String {
        let high = Int(averageHighF.rounded())
        let low = Int(averageLowF.rounded())
        return "\(locationName): historically \(low)°F–\(high)°F on this date (\(yearsSampled)-yr avg)"
    }
}

enum WeatherCondition: String {
    case sunny = "Sunny"
    case rainy = "Rainy"
    case cloudy = "Cloudy"
    case cold = "Cold"
    case windy = "Windy"
    case snowy = "Snowy"
}

enum WeatherServiceError: LocalizedError {
    case locationNotFound
    case noHistoricalData
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .locationNotFound:
            return "Couldn't find that destination."
        case .noHistoricalData:
            return "No historical weather data was available for that destination."
        case .invalidResponse:
            return "The weather service returned an unexpected response."
        }
    }
}

enum WeatherService {

    private static let geocodeEndpoint = "https://geocoding-api.open-meteo.com/v1/search"
    private static let archiveEndpoint = "https://archive-api.open-meteo.com/v1/archive"

    /// How many past years to sample when computing the historical average.
    /// 10 years is a reasonable trade-off between accuracy and request volume.
    private static let defaultYearsOfHistory = 10

    // MARK: - Public API

    /// Resolves a free-text destination (city, "City, Country", landmark, etc.)
    /// into coordinates using Open-Meteo's geocoding service.
    static func geocode(place: String) async throws -> GeocodedPlace {
        let trimmed = place.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw WeatherServiceError.locationNotFound }

        guard var components = URLComponents(string: geocodeEndpoint) else {
            throw WeatherServiceError.invalidResponse
        }
        components.queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "count", value: "1"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]
        guard let url = components.url else { throw WeatherServiceError.invalidResponse }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(GeocodeResponse.self, from: data)
        guard let first = decoded.results?.first else {
            throw WeatherServiceError.locationNotFound
        }

        return GeocodedPlace(name: first.name, latitude: first.latitude, longitude: first.longitude)
    }

    /// Computes the historical average weather for a destination on a given
    /// calendar date, by averaging observed data for that month/day across the
    /// past several years.
    static func fetchHistoricalAverage(
        destination: String,
        date: Date,
        yearsOfHistory: Int = defaultYearsOfHistory
    ) async throws -> HistoricalWeatherSummary {
        let place = try await geocode(place: destination)
        let calendar = Calendar(identifier: .gregorian)
        let comps = calendar.dateComponents([.month, .day], from: date)
        guard let month = comps.month, let day = comps.day else {
            throw WeatherServiceError.invalidResponse
        }
        return try await fetchHistoricalAverage(
            for: place,
            month: month,
            day: day,
            yearsOfHistory: yearsOfHistory
        )
    }

    /// Same as above, but for a location that has already been geocoded.
    static func fetchHistoricalAverage(
        for place: GeocodedPlace,
        month: Int,
        day: Int,
        yearsOfHistory: Int = defaultYearsOfHistory
    ) async throws -> HistoricalWeatherSummary {
        let calendar = Calendar(identifier: .gregorian)
        let currentYear = calendar.component(.year, from: Date())

        // Skip the current year: the archive API lags a few days behind real
        // time, so "this year" may not have data yet for the requested date.
        let years = (1...yearsOfHistory).map { currentYear - $0 }

        var readings: [DailyReading] = []
        try await withThrowingTaskGroup(of: DailyReading?.self) { group in
            for year in years {
                group.addTask {
                    try? await fetchDay(place: place, year: year, month: month, day: day)
                }
            }
            for try await reading in group {
                if let reading {
                    readings.append(reading)
                }
            }
        }

        guard !readings.isEmpty else { throw WeatherServiceError.noHistoricalData }

        let highs = readings.compactMap { $0.tempMaxC }
        let lows = readings.compactMap { $0.tempMinC }
        let precip = readings.compactMap { $0.precipitationMM }
        let snow = readings.compactMap { $0.snowfallCM }
        let wind = readings.compactMap { $0.windSpeedMaxKMH }

        guard !highs.isEmpty || !lows.isEmpty else { throw WeatherServiceError.noHistoricalData }

        return HistoricalWeatherSummary(
            locationName: place.name,
            month: month,
            day: day,
            averageHighC: highs.average,
            averageLowC: lows.average,
            averagePrecipitationMM: precip.average,
            averageSnowfallCM: snow.average,
            averageWindSpeedKMH: wind.average,
            yearsSampled: readings.count
        )
    }

    // MARK: - Networking helpers

    private struct DailyReading {
        let tempMaxC: Double?
        let tempMinC: Double?
        let precipitationMM: Double?
        let snowfallCM: Double?
        let windSpeedMaxKMH: Double?
    }

    private static func fetchDay(place: GeocodedPlace, year: Int, month: Int, day: Int) async throws -> DailyReading? {
        guard let dateString = isoDateString(year: year, month: month, day: day) else { return nil }

        guard var components = URLComponents(string: archiveEndpoint) else { return nil }
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(place.latitude)),
            URLQueryItem(name: "longitude", value: String(place.longitude)),
            URLQueryItem(name: "start_date", value: dateString),
            URLQueryItem(name: "end_date", value: dateString),
            URLQueryItem(
                name: "daily",
                value: "temperature_2m_max,temperature_2m_min,precipitation_sum,snowfall_sum,windspeed_10m_max"
            ),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        guard let url = components.url else { return nil }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(ArchiveResponse.self, from: data)
        guard let daily = decoded.daily, !daily.time.isEmpty else { return nil }

        return DailyReading(
            tempMaxC: daily.temperature_2m_max.first(where: { _ in true }).flatMap { $0 },
            tempMinC: daily.temperature_2m_min.first(where: { _ in true }).flatMap { $0 },
            precipitationMM: daily.precipitation_sum.first(where: { _ in true }).flatMap { $0 },
            snowfallCM: daily.snowfall_sum.first(where: { _ in true }).flatMap { $0 },
            windSpeedMaxKMH: daily.windspeed_10m_max.first(where: { _ in true }).flatMap { $0 }
        )
    }

    private static func isoDateString(year: Int, month: Int, day: Int) -> String? {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: comps) else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}

// MARK: - Response models

private struct GeocodeResponse: Decodable {
    struct Result: Decodable {
        let name: String
        let latitude: Double
        let longitude: Double
    }
    let results: [Result]?
}

private struct ArchiveResponse: Decodable {
    struct Daily: Decodable {
        let time: [String]
        let temperature_2m_max: [Double?]
        let temperature_2m_min: [Double?]
        let precipitation_sum: [Double?]
        let snowfall_sum: [Double?]
        let windspeed_10m_max: [Double?]
    }
    let daily: Daily?
}

private extension Array where Element == Double {
    var average: Double {
        isEmpty ? 0 : reduce(0, +) / Double(count)
    }
}
