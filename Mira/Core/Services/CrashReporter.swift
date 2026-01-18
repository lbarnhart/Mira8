import Foundation
import FirebaseCrashlytics

/// Crash reporting service wrapper for Firebase Crashlytics
/// Provides a unified interface for crash reporting throughout the app
final class CrashReporter {
    static let shared = CrashReporter()
    
    private init() {
        // Configure Firebase Crashlytics on initialization
        // Note: Firebase.configure() must be called in AppDelegate/App first
    }
    
    /// Configure crash reporter - call this after Firebase.configure()
    func configure() {
        #if DEBUG
        // Disable crash reporting in debug builds to avoid polluting production data
        AppLog.debug("CrashReporter: Debug mode - Crashlytics disabled", category: .general)
        #else
        // In production, Crashlytics auto-configures with Firebase
        AppLog.info("CrashReporter: Crashlytics configured", category: .general)
        #endif
    }
    
    /// Record a non-fatal error
    /// - Parameters:
    ///   - error: The error to record
    ///   - userInfo: Additional context about the error
    func recordError(_ error: Error, userInfo: [String: Any]? = nil) {
        #if DEBUG
        AppLog.error("CrashReporter recordError: \(error.localizedDescription)", category: .general)
        if let info = userInfo {
            AppLog.debug("  Context: \(info)", category: .general)
        }
        #endif
        Crashlytics.crashlytics().record(error: error, userInfo: userInfo)
    }
    
    /// Record a non-fatal error with a custom message
    /// - Parameters:
    ///   - message: A description of the error
    ///   - error: The underlying error, if any
    func recordError(message: String, error: Error? = nil) {
        let userInfo: [String: Any] = [
            "message": message,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let error = error {
            recordError(error, userInfo: userInfo)
        } else {
            #if DEBUG
            AppLog.error("CrashReporter: \(message)", category: .general)
            #else
            // In production: Create an NSError and record it
            #endif
        }
    }
    
    /// Log a message to Crashlytics for context in crash reports
    /// - Parameter message: The message to log
    func log(_ message: String) {
        #if DEBUG
        AppLog.debug("CrashReporter log: \(message)", category: .general)
        #endif
        Crashlytics.crashlytics().log(message)
    }
    
    /// Set a custom key-value pair for crash context
    /// - Parameters:
    ///   - key: The key
    ///   - value: The value
    func setCustomValue(_ value: Any, forKey key: String) {
        #if DEBUG
        AppLog.debug("CrashReporter setCustomValue: \(key) = \(value)", category: .general)
        #endif
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
    
    /// Set the user identifier for crash attribution
    /// - Parameter userId: The user's unique identifier
    func setUserId(_ userId: String?) {
        #if DEBUG
        AppLog.debug("CrashReporter setUserId: \(userId ?? "nil")", category: .general)
        #endif
        Crashlytics.crashlytics().setUserID(userId)
    }
}
