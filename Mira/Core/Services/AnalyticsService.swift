import Foundation
import FirebaseAnalytics

/// Analytics service wrapper for Firebase Analytics
/// Provides a unified interface for tracking user events throughout the app
final class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {}
    
    /// Configure analytics - call this after Firebase.configure()
    func configure() {
        #if DEBUG
        // Disable analytics collection in debug builds
        AppLog.debug("AnalyticsService: Debug mode - Analytics disabled", category: .general)
        #else
        // In production, Analytics auto-configures with Firebase
        AppLog.info("AnalyticsService: Analytics configured", category: .general)
        #endif
    }
    
    // MARK: - Scanning Events
    
    /// Track when a product is scanned
    func trackProductScan(barcode: String, productName: String, source: String) {
        logEvent("scan_product", parameters: [
            "barcode": barcode,
            "product_name": String(productName.prefix(100)),
            "source": source
        ])
    }
    
    /// Track when a product lookup fails
    func trackScanFailed(barcode: String, reason: String) {
        logEvent("scan_failed", parameters: [
            "barcode": barcode,
            "reason": reason
        ])
    }
    
    // MARK: - Product Detail Events
    
    /// Track when a user views product details
    func trackViewProductDetails(barcode: String, productName: String) {
        logEvent("view_product_details", parameters: [
            "barcode": barcode,
            "product_name": String(productName.prefix(100))
        ])
    }
    
    /// Track when a user adds a product to favorites
    func trackAddFavorite(barcode: String, productName: String) {
        logEvent("add_favorite", parameters: [
            "barcode": barcode,
            "product_name": String(productName.prefix(100))
        ])
    }
    
    /// Track when a user removes a product from favorites
    func trackRemoveFavorite(barcode: String, productName: String) {
        logEvent("remove_favorite", parameters: [
            "barcode": barcode,
            "product_name": String(productName.prefix(100))
        ])
    }
    
    // MARK: - Navigation Events
    
    /// Track screen views
    func trackScreenView(_ screenName: String, screenClass: String? = nil) {
        logEvent("screen_view", parameters: [
            "screen_name": screenName,
            "screen_class": screenClass ?? screenName
        ])
    }
    
    // MARK: - Search & Filter Events
    
    /// Track search queries
    func trackSearch(query: String, resultCount: Int) {
        logEvent("search", parameters: [
            "search_term": query,
            "result_count": resultCount
        ])
    }
    
    /// Track filter usage
    func trackFilterApplied(filterType: String, filterValue: String) {
        logEvent("filter_applied", parameters: [
            "filter_type": filterType,
            "filter_value": filterValue
        ])
    }
    
    // MARK: - Settings Events
    
    /// Track when dietary restrictions are updated
    func trackDietaryRestrictionsUpdated(restrictions: [String]) {
        logEvent("dietary_restrictions_updated", parameters: [
            "restrictions": restrictions.joined(separator: ","),
            "count": restrictions.count
        ])
    }
    
    /// Track appearance settings changes
    func trackAppearanceChanged(colorScheme: String, textSize: String) {
        logEvent("appearance_changed", parameters: [
            "color_scheme": colorScheme,
            "text_size": textSize
        ])
    }
    
    /// Track when history is cleared
    func trackHistoryCleared() {
        logEvent("history_cleared", parameters: [:])
    }
    
    // MARK: - Comparison Events
    
    /// Track when products are compared
    func trackProductComparison(product1: String, product2: String) {
        logEvent("product_comparison", parameters: [
            "product_1": String(product1.prefix(100)),
            "product_2": String(product2.prefix(100))
        ])
    }
    
    // MARK: - User Properties
    
    /// Set the user's dietary restrictions as a user property
    func setUserDietaryRestrictions(_ restrictions: [String]) {
        setUserProperty(restrictions.joined(separator: ","), forName: "dietary_restrictions")
    }
    
    /// Set the user's preferred color scheme as a user property
    func setUserColorScheme(_ scheme: String) {
        setUserProperty(scheme, forName: "color_scheme")
    }
    
    // MARK: - Core Methods
    
    private func logEvent(_ name: String, parameters: [String: Any]) {
        #if DEBUG
        AppLog.debug("Analytics event: \(name) - \(parameters)", category: .general)
        #endif
        Analytics.logEvent(name, parameters: parameters)
    }
    
    private func setUserProperty(_ value: String?, forName name: String) {
        #if DEBUG
        AppLog.debug("Analytics user property: \(name) = \(value ?? "nil")", category: .general)
        #endif
        Analytics.setUserProperty(value, forName: name)
    }
}

// MARK: - Convenience Extensions

extension AnalyticsService {
    /// Standard event names for consistency
    enum EventName: String {
        case scanProduct = "scan_product"
        case scanFailed = "scan_failed"
        case viewProductDetails = "view_product_details"
        case addFavorite = "add_favorite"
        case removeFavorite = "remove_favorite"
        case screenView = "screen_view"
        case search = "search"
        case filterApplied = "filter_applied"
        case productComparison = "product_comparison"
        case historyCleared = "history_cleared"
    }
}
