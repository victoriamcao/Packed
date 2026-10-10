//
//  Log.swift
//  Packed
//
//  Structured logging via os.Logger, so failures show up in Console.app
//  and in device logs (and sysdiagnoses) instead of vanishing silently.
//  Never log secrets, tokens, or user content here.
//

import OSLog

enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "Packed"

    static let auth = Logger(subsystem: subsystem, category: "auth")
    static let data = Logger(subsystem: subsystem, category: "data")
    static let map = Logger(subsystem: subsystem, category: "map")
    static let ai = Logger(subsystem: subsystem, category: "ai")
    static let weather = Logger(subsystem: subsystem, category: "weather")
}
