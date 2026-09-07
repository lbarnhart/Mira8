import Foundation
import os

enum LogCategory: String, CaseIterable {
    case general
    case network
    case scanner
    case configuration
    case persistence
    case scoring
}

struct AppLog {
    private static let subsystem = "com.mira8.app"
    private static let cache = Dictionary(
        uniqueKeysWithValues: LogCategory.allCases.map {
            ($0, Logger(subsystem: subsystem, category: $0.rawValue))
        }
    )

    private static func logger(for category: LogCategory) -> Logger {
        cache[category] ?? Logger(subsystem: subsystem, category: category.rawValue)
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
        logger(for: category).warning("\(message, privacy: .private)")
    }

    static func error(_ message: String, category: LogCategory = .general) {
        logger(for: category).error("\(message, privacy: .private)")
    }
}
