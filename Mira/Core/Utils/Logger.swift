import Foundation
import os

enum LogCategory: String {
    case general
    case network
    case scanner
    case configuration
    case persistence
    case scoring
}

struct AppLog {
    private static let subsystem = "com.mira8.app"
    private static var cache = [LogCategory: Logger]()

    private static func logger(for category: LogCategory) -> Logger {
        if let existing = cache[category] {
            return existing
        }
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        cache[category] = logger
        return logger
    }

    static func debug(_ message: String, category: LogCategory = .general) {
        #if DEBUG
        logger(for: category).debug("\(message, privacy: .public)")
        #endif
    }

    static func info(_ message: String, category: LogCategory = .general) {
        #if DEBUG
        logger(for: category).info("\(message, privacy: .public)")
        #endif
    }

    static func warning(_ message: String, category: LogCategory = .general) {
        logger(for: category).warning("\(message, privacy: .public)")
    }

    static func error(_ message: String, category: LogCategory = .general) {
        logger(for: category).error("\(message, privacy: .public)")
    }
}
