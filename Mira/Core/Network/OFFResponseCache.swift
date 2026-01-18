import Foundation

/// In-memory cache for Open Food Facts API responses
/// Prevents redundant API calls when enriching USDA data or re-viewing products
actor OFFResponseCache {
    static let shared = OFFResponseCache()
    
    private struct CacheEntry {
        let product: APIProduct
        let timestamp: Date
    }
    
    private var cache: [String: CacheEntry] = [:]
    
    /// Time-to-live for cached entries (5 minutes)
    private let ttl: TimeInterval = 300
    
    /// Maximum cache size to prevent memory bloat
    private let maxCacheSize = 50
    
    // MARK: - Public Methods
    
    /// Retrieve a cached product by barcode
    /// - Parameter barcode: The product barcode
    /// - Returns: The cached APIProduct if valid, nil if expired or not found
    func get(barcode: String) -> APIProduct? {
        guard let entry = cache[barcode] else {
            return nil
        }
        
        // Check if entry has expired
        if Date().timeIntervalSince(entry.timestamp) > ttl {
            cache.removeValue(forKey: barcode)
            AppLog.debug("🗂️ OFF cache expired for barcode: \(barcode)", category: .network)
            return nil
        }
        
        return entry.product
    }
    
    /// Store a product in the cache
    /// - Parameters:
    ///   - barcode: The product barcode
    ///   - product: The APIProduct to cache
    func set(barcode: String, product: APIProduct) {
        // Evict oldest entries if cache is full
        if cache.count >= maxCacheSize {
            evictOldestEntries(count: 10)
        }
        
        cache[barcode] = CacheEntry(product: product, timestamp: Date())
        AppLog.debug("🗂️ OFF cache stored for barcode: \(barcode)", category: .network)
    }
    
    /// Clear all cached entries
    func clear() {
        cache.removeAll()
        AppLog.debug("🗂️ OFF cache cleared", category: .network)
    }
    
    /// Get current cache size
    var count: Int {
        cache.count
    }
    
    // MARK: - Private Methods
    
    private func evictOldestEntries(count: Int) {
        let sorted = cache.sorted { $0.value.timestamp < $1.value.timestamp }
        let toRemove = sorted.prefix(count)
        
        for (key, _) in toRemove {
            cache.removeValue(forKey: key)
        }
        
        AppLog.debug("🗂️ OFF cache evicted \(toRemove.count) oldest entries", category: .network)
    }
}
