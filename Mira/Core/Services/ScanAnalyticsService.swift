import Foundation

/// Tracks success/failure rates for product scanning (barcode and image-based).
/// Helps understand which data sources work best for US products.
actor ScanAnalyticsService {
    static let shared = ScanAnalyticsService()

    private let userDefaults = UserDefaults.standard
    private let analyticsKey = Constants.UserDefaults.scanAnalytics

    // MARK: - Analytics Models

    struct ScanEvent: Codable {
        let timestamp: Date
        let scanType: ScanType
        let source: DataSource
        let outcome: Outcome
        let productName: String?
        let brand: String?
        let matchScore: Double?

        enum ScanType: String, Codable {
            case barcode
            case image
        }

        enum DataSource: String, Codable {
            case usda
            case openFoodFacts
            case localCatalog
            case notFound
        }

        enum Outcome: String, Codable {
            case success
            case fallback  // Primary failed, fallback succeeded
            case failure   // All sources failed
        }
    }

    struct AnalyticsSummary: Codable {
        let totalScans: Int
        let barcodeScans: ScanTypeSummary
        let imageScans: ScanTypeSummary
        let periodStart: Date
        let periodEnd: Date

        struct ScanTypeSummary: Codable {
            let total: Int
            let successRate: Double
            let usdaSuccessCount: Int
            let offSuccessCount: Int
            let localCatalogSuccessCount: Int
            let failureCount: Int
        }
    }

    // MARK: - Event Tracking

    /// Track a barcode scan event
    func trackBarcodeScan(
        source: ScanEvent.DataSource,
        outcome: ScanEvent.Outcome,
        productName: String? = nil,
        brand: String? = nil
    ) async {
        let event = ScanEvent(
            timestamp: Date(),
            scanType: .barcode,
            source: source,
            outcome: outcome,
            productName: productName,
            brand: brand,
            matchScore: nil
        )
        await saveEvent(event)

        AppLog.info("📊 Analytics: Barcode scan - source=\(source.rawValue), outcome=\(outcome.rawValue)", category: .scanner)
    }

    /// Track an image scan event
    func trackImageScan(
        source: ScanEvent.DataSource,
        outcome: ScanEvent.Outcome,
        productName: String? = nil,
        brand: String? = nil,
        matchScore: Double? = nil
    ) async {
        let event = ScanEvent(
            timestamp: Date(),
            scanType: .image,
            source: source,
            outcome: outcome,
            productName: productName,
            brand: brand,
            matchScore: matchScore
        )
        await saveEvent(event)

        AppLog.info("📊 Analytics: Image scan - source=\(source.rawValue), outcome=\(outcome.rawValue), score=\(matchScore.map { String(format: "%.2f", $0) } ?? "nil")", category: .scanner)
    }

    // MARK: - Analytics Summary

    /// Get analytics summary for the last N days
    func getSummary(days: Int = 30) async -> AnalyticsSummary {
        let events = await loadEvents()
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let recentEvents = events.filter { $0.timestamp >= cutoffDate }

        let barcodeEvents = recentEvents.filter { $0.scanType == .barcode }
        let imageEvents = recentEvents.filter { $0.scanType == .image }

        return AnalyticsSummary(
            totalScans: recentEvents.count,
            barcodeScans: summarize(barcodeEvents),
            imageScans: summarize(imageEvents),
            periodStart: cutoffDate,
            periodEnd: Date()
        )
    }

    /// Get detailed event log for debugging
    func getRecentEvents(limit: Int = 50) async -> [ScanEvent] {
        let events = await loadEvents()
        return Array(events.suffix(limit))
    }

    /// Clear all analytics data
    func clearAnalytics() async {
        userDefaults.removeObject(forKey: analyticsKey)
        AppLog.info("📊 Analytics: Cleared all data", category: .scanner)
    }

    // MARK: - Logging for Console

    /// Print analytics summary to console (for debugging)
    func logSummary() async {
        let summary = await getSummary(days: 30)

        AppLog.info("""
        📊 ===== SCAN ANALYTICS (Last 30 Days) =====
        Total Scans: \(summary.totalScans)

        BARCODE SCANS:
          Total: \(summary.barcodeScans.total)
          Success Rate: \(String(format: "%.1f%%", summary.barcodeScans.successRate * 100))
          USDA Success: \(summary.barcodeScans.usdaSuccessCount)
          OFF Success: \(summary.barcodeScans.offSuccessCount)
          Local Catalog: \(summary.barcodeScans.localCatalogSuccessCount)
          Failures: \(summary.barcodeScans.failureCount)

        IMAGE SCANS:
          Total: \(summary.imageScans.total)
          Success Rate: \(String(format: "%.1f%%", summary.imageScans.successRate * 100))
          USDA Success: \(summary.imageScans.usdaSuccessCount)
          OFF Success: \(summary.imageScans.offSuccessCount)
          Failures: \(summary.imageScans.failureCount)
        ============================================
        """, category: .scanner)
    }

    // MARK: - Private Helpers

    private func saveEvent(_ event: ScanEvent) async {
        var events = await loadEvents()
        events.append(event)

        // Keep only last 1000 events to prevent unbounded growth
        if events.count > 1000 {
            events = Array(events.suffix(1000))
        }

        if let data = try? JSONEncoder().encode(events) {
            userDefaults.set(data, forKey: analyticsKey)
        }
    }

    private func loadEvents() async -> [ScanEvent] {
        guard let data = userDefaults.data(forKey: analyticsKey),
              let events = try? JSONDecoder().decode([ScanEvent].self, from: data) else {
            return []
        }
        return events
    }

    private func summarize(_ events: [ScanEvent]) -> AnalyticsSummary.ScanTypeSummary {
        let total = events.count
        guard total > 0 else {
            return AnalyticsSummary.ScanTypeSummary(
                total: 0,
                successRate: 0,
                usdaSuccessCount: 0,
                offSuccessCount: 0,
                localCatalogSuccessCount: 0,
                failureCount: 0
            )
        }

        let successes = events.filter { $0.outcome == .success || $0.outcome == .fallback }
        let usdaSuccesses = events.filter { $0.source == .usda && $0.outcome == .success }
        let offSuccesses = events.filter { $0.source == .openFoodFacts && ($0.outcome == .success || $0.outcome == .fallback) }
        let localSuccesses = events.filter { $0.source == .localCatalog && ($0.outcome == .success || $0.outcome == .fallback) }
        let failures = events.filter { $0.outcome == .failure }

        return AnalyticsSummary.ScanTypeSummary(
            total: total,
            successRate: Double(successes.count) / Double(total),
            usdaSuccessCount: usdaSuccesses.count,
            offSuccessCount: offSuccesses.count,
            localCatalogSuccessCount: localSuccesses.count,
            failureCount: failures.count
        )
    }
}
