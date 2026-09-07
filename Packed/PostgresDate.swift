//
//  PostgresDate.swift
//  Packed
//
//  Supabase/PostgREST timestamps come back with fractional seconds
//  (e.g. "2026-09-06T12:34:56.789012+00:00"), which Foundation's plain
//  .iso8601 JSONDecoder strategy can't parse. This tries with fractional
//  seconds first, then falls back to whole seconds.
//

import Foundation

func decodePostgresTimestamp(from decoder: Decoder) throws -> Date {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)

    let withFractional = ISO8601DateFormatter()
    withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = withFractional.date(from: string) {
        return date
    }

    let withoutFractional = ISO8601DateFormatter()
    withoutFractional.formatOptions = [.withInternetDateTime]
    if let date = withoutFractional.date(from: string) {
        return date
    }

    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date format: \(string)")
}
