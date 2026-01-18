import Foundation
import CoreData

/// Enhanced product caching layer for offline support
/// Provides cache-first lookup and prefetching capabilities
final class OfflineProductCache {
    static let shared = OfflineProductCache()
    
    private let coreDataManager: CoreDataManager
    private let networkMonitor: NetworkMonitor
    
    // Track when products were last fetched from network
    private var lastFetchDates: [String: Date] = [:]
    
    // Cache expiry (products older than this are considered stale but still usable offline)
    private let staleThreshold: TimeInterval = 7 * 24 * 60 * 60  // 7 days
    
    private init(
        coreDataManager: CoreDataManager = .shared,
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.coreDataManager = coreDataManager
        self.networkMonitor = networkMonitor
        loadFetchDates()
    }
    
    // MARK: - Cache-First Lookup
    
    /// Attempts to get a product, checking cache first if offline
    /// - Parameters:
    ///   - barcode: The product barcode
    ///   - forceNetwork: If true, always try network first even if cached
    /// - Returns: Tuple of (product, isFromCache)
    func getProduct(barcode: String, forceNetwork: Bool = false) async -> (product: Product?, isFromCache: Bool) {
        // If online and not forcing cache, let caller handle network fetch
        if networkMonitor.isConnected && !forceNetwork {
            return (nil, false)
        }
        
        // Try to get from local cache
        do {
            if let cachedProduct = try coreDataManager.fetchProduct(byBarcode: barcode) {
                AppLog.debug("OfflineProductCache: Found cached product for \(barcode)", category: .persistence)
                return (cachedProduct, true)
            }
        } catch {
            AppLog.warning("OfflineProductCache: Cache lookup failed - \(error.localizedDescription)", category: .persistence)
        }
        
        return (nil, false)
    }
    
    /// Check if a product exists in cache
    func hasCachedProduct(barcode: String) -> Bool {
        do {
            return try coreDataManager.fetchProduct(byBarcode: barcode) != nil
        } catch {
            return false
        }
    }
    
    /// Get the age of a cached product
    func getCacheAge(barcode: String) -> TimeInterval? {
        guard let fetchDate = lastFetchDates[barcode] else { return nil }
        return Date().timeIntervalSince(fetchDate)
    }
    
    /// Check if cached product is stale (older than threshold)
    func isStale(barcode: String) -> Bool {
        guard let age = getCacheAge(barcode: barcode) else { return true }
        return age > staleThreshold
    }
    
    // MARK: - Cache Management
    
    /// Save a product to cache after network fetch
    func cacheProduct(_ product: Product) {
        do {
            try coreDataManager.saveProduct(product)
            lastFetchDates[product.barcode] = Date()
            saveFetchDates()
            AppLog.debug("OfflineProductCache: Cached product \(product.barcode)", category: .persistence)
        } catch {
            AppLog.error("OfflineProductCache: Failed to cache product - \(error.localizedDescription)", category: .persistence)
        }
    }
    
    /// Get cache statistics
    func getCacheStats() -> CacheStats {
        var stats = CacheStats()
        
        // Count cached products from scan history
        do {
            let history = try coreDataManager.fetchScanHistory(limit: 10000)
            stats.totalProducts = history.count
            
            // Count stale products
            for scan in history {
                if let barcode = scan.productBarcode, isStale(barcode: barcode) {
                    stats.staleProducts += 1
                }
            }
        } catch {
            AppLog.warning("OfflineProductCache: Could not get cache stats", category: .persistence)
        }
        
        return stats
    }
    
    /// Clear all cached products (user-initiated)
    func clearCache() {
        do {
            try coreDataManager.clearScanHistory()
            lastFetchDates.removeAll()
            saveFetchDates()
            AppLog.info("OfflineProductCache: Cache cleared", category: .persistence)
        } catch {
            AppLog.error("OfflineProductCache: Failed to clear cache - \(error.localizedDescription)", category: .persistence)
        }
    }
    
    // MARK: - Prefetching
    
    /// Prefetch products for offline access (run on WiFi)
    /// - Parameter barcodes: List of barcodes to prefetch
    func prefetchProducts(barcodes: [String]) async {
        guard networkMonitor.hasFastConnection else {
            AppLog.debug("OfflineProductCache: Skipping prefetch - no fast connection", category: .persistence)
            return
        }
        
        let uncachedBarcodes = barcodes.filter { !hasCachedProduct(barcode: $0) }
        guard !uncachedBarcodes.isEmpty else { return }
        
        AppLog.info("OfflineProductCache: Prefetching \(uncachedBarcodes.count) products", category: .persistence)
        
        // Note: Actual API calls would go here
        // For now, just log intent - implementation depends on API batch support
    }
    
    // MARK: - Persistence for Fetch Dates
    
    private var fetchDatesURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("product_fetch_dates.json")
    }
    
    private func loadFetchDates() {
        guard FileManager.default.fileExists(atPath: fetchDatesURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: fetchDatesURL)
            let decoded = try JSONDecoder().decode([String: Date].self, from: data)
            lastFetchDates = decoded
        } catch {
            AppLog.warning("OfflineProductCache: Could not load fetch dates", category: .persistence)
        }
    }
    
    private func saveFetchDates() {
        do {
            let data = try JSONEncoder().encode(lastFetchDates)
            try data.write(to: fetchDatesURL)
        } catch {
            AppLog.warning("OfflineProductCache: Could not save fetch dates", category: .persistence)
        }
    }
}

// MARK: - Supporting Types

struct CacheStats {
    var totalProducts: Int = 0
    var staleProducts: Int = 0
    var cacheSizeBytes: Int64 = 0
    
    var freshProducts: Int {
        totalProducts - staleProducts
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: cacheSizeBytes, countStyle: .file)
    }
}

// MARK: - Offline Product Result

/// Represents a product lookup result with cache status
struct OfflineProductResult {
    let product: Product?
    let source: DataSource
    let fetchDate: Date?
    let isStale: Bool
    
    enum DataSource {
        case network
        case cache
        case notFound
    }
    
    var isAvailable: Bool {
        product != nil
    }
    
    var cacheAgeDescription: String? {
        guard let date = fetchDate else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
