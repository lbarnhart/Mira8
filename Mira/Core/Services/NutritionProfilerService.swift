import Foundation
import os

/// Service that builds user nutrition profiles from scan history.
/// Calculates averages, identifies gaps, and detects consumption patterns.
actor NutritionProfilerService {

    private let logger = Logger(subsystem: "com.mira8.app", category: "NutritionProfiler")
    private let coreDataManager: CoreDataManager

    // Cache for profiles
    private var profileCache: [String: (profile: UserNutritionProfile, cachedAt: Date)] = [:]
    private let cacheTTL: TimeInterval = 3600 // 1 hour

    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }

    // MARK: - Public API

    /// Build a nutrition profile for the given period and health focus
    func buildProfile(
        period: AnalysisPeriod,
        healthFocus: HealthFocus
    ) async throws -> UserNutritionProfile {
        let cacheKey = "\(period.rawValue)_\(healthFocus.rawValue)"

        // Check cache
        if let cached = profileCache[cacheKey],
           Date().timeIntervalSince(cached.cachedAt) < cacheTTL {
            logger.debug("Returning cached profile for \(cacheKey)")
            return cached.profile
        }

        logger.info("Building nutrition profile for period: \(period.rawValue), focus: \(healthFocus.rawValue)")

        // Fetch scan history for the period
        let products = try await fetchProductsForPeriod(period)

        guard !products.isEmpty else {
            return emptyProfile(period: period, healthFocus: healthFocus)
        }

        // Calculate averages
        let averages = Self.calculateAverages(from: products)

        // Calculate gaps based on health focus targets
        let targets = HealthFocusTargets.targets(for: healthFocus)
        let gaps = targets.calculateGaps(from: averages)

        // Detect consumption patterns
        let patterns = detectPatterns(from: products)

        let profile = UserNutritionProfile(
            period: period,
            healthFocus: healthFocus,
            scanCount: products.count,
            averages: averages,
            gaps: gaps,
            patterns: patterns,
            generatedAt: Date()
        )

        // Cache the profile
        profileCache[cacheKey] = (profile, Date())

        logger.info("Built profile with \(products.count) products, \(gaps.count) gaps, \(patterns.count) patterns")

        return profile
    }

    /// Invalidate cached profiles (call after new scans)
    func invalidateCache() {
        profileCache.removeAll()
        logger.debug("Profile cache invalidated")
    }

    // MARK: - Data Fetching

    private func fetchProductsForPeriod(_ period: AnalysisPeriod) async throws -> [Product] {
        let startDate = Calendar.current.date(byAdding: .day, value: -period.days, to: Date()) ?? Date()

        // Fetch scan history from CoreData
        let historyEntities = try coreDataManager.fetchScanHistory(limit: 0) // 0 = no limit

        // Filter by date and convert to products
        let products = historyEntities
            .filter { entity in
                guard let scanDate = entity.scanDate else { return false }
                return scanDate >= startDate
            }
            .compactMap { entity -> Product? in
                entity.product?.toProduct()
            }

        // Remove duplicates (keep most recent scan of each product)
        var seenBarcodes = Set<String>()
        let uniqueProducts = products.filter { product in
            if seenBarcodes.contains(product.barcode) {
                return false
            }
            seenBarcodes.insert(product.barcode)
            return true
        }

        return uniqueProducts
    }

    // MARK: - Calculations

    /// Returns per-product averages in the units exposed by `NutritionAverages`.
    /// `NutritionalData.sodium` is stored in grams, while insights and their
    /// health-focus thresholds use milligrams.
    static func calculateAverages(from products: [Product]) -> NutritionAverages {
        guard !products.isEmpty else { return .zero }

        let count = Double(products.count)

        let totalCalories = products.reduce(0.0) { $0 + $1.nutritionalData.calories }
        let totalProtein = products.reduce(0.0) { $0 + $1.nutritionalData.protein }
        let totalCarbs = products.reduce(0.0) { $0 + $1.nutritionalData.carbohydrates }
        let totalFat = products.reduce(0.0) { $0 + $1.nutritionalData.fat }
        let totalFiber = products.reduce(0.0) { $0 + $1.nutritionalData.fiber }
        let totalSugar = products.reduce(0.0) { $0 + $1.nutritionalData.sugar }
        let totalSodiumMilligrams = products.reduce(0.0) {
            $0 + $1.nutritionalData.sodiumMilligrams
        }
        let totalSatFat = products.reduce(0.0) { $0 + $1.nutritionalData.saturatedFat }

        return NutritionAverages(
            calories: totalCalories / count,
            protein: totalProtein / count,
            carbohydrates: totalCarbs / count,
            fat: totalFat / count,
            fiber: totalFiber / count,
            sugar: totalSugar / count,
            sodium: totalSodiumMilligrams / count,
            saturatedFat: totalSatFat / count
        )
    }

    // MARK: - Pattern Detection

    private func detectPatterns(from products: [Product]) -> [ConsumptionPattern] {
        var patterns: [ConsumptionPattern] = []

        // Category distribution
        let categoryPatterns = detectCategoryPatterns(from: products)
        patterns.append(contentsOf: categoryPatterns)

        // Nutritional consistency
        if let consistencyPattern = detectConsistencyPattern(from: products) {
            patterns.append(consistencyPattern)
        }

        return patterns
    }

    private func detectCategoryPatterns(from products: [Product]) -> [ConsumptionPattern] {
        var patterns: [ConsumptionPattern] = []

        // Count categories (filter out empty/undefined)
        var categoryCounts: [String: Int] = [:]
        for product in products {
            if let category = product.category?.lowercased() {
                let trimmed = category.trimmingCharacters(in: .whitespacesAndNewlines)
                // Skip empty, undefined, or unknown categories
                guard !trimmed.isEmpty, trimmed != "undefined", trimmed != "unknown" else { continue }
                let normalizedCategory = normalizeCategory(trimmed)
                categoryCounts[normalizedCategory, default: 0] += 1
            }
        }

        let total = products.count
        guard total > 0 else { return patterns }

        // Find high/low categories
        for (category, count) in categoryCounts {
            let percentage = Double(count) / Double(total) * 100

            if percentage > 30 {
                patterns.append(ConsumptionPattern(
                    type: .highCategory,
                    description: "\(category.capitalized) products make up \(Int(percentage))% of your scans",
                    confidence: min(0.9, percentage / 100 + 0.5)
                ))
            }
        }

        // Check for category diversity (or lack thereof)
        if categoryCounts.count < 3 && total >= 5 {
            patterns.append(ConsumptionPattern(
                type: .lowCategory,
                description: "Limited variety - only \(categoryCounts.count) product categories scanned",
                confidence: 0.8
            ))
        }

        return patterns
    }

    private func detectConsistencyPattern(from products: [Product]) -> ConsumptionPattern? {
        guard products.count >= 5 else { return nil }

        // Calculate standard deviation of key nutrients
        let proteins = products.map { $0.nutritionalData.protein }
        let fibers = products.map { $0.nutritionalData.fiber }
        let sugars = products.map { $0.nutritionalData.sugar }

        let proteinCV = coefficientOfVariation(proteins)
        let fiberCV = coefficientOfVariation(fibers)
        let sugarCV = coefficientOfVariation(sugars)

        let averageCV = (proteinCV + fiberCV + sugarCV) / 3

        if averageCV < 0.3 {
            return ConsumptionPattern(
                type: .consistent,
                description: "Your food choices show consistent nutritional values",
                confidence: 0.85
            )
        } else if averageCV > 0.7 {
            return ConsumptionPattern(
                type: .variable,
                description: "Your food choices vary significantly in nutritional content",
                confidence: 0.75
            )
        }

        return nil
    }

    // MARK: - Helpers

    private func normalizeCategory(_ category: String) -> String {
        // Map similar categories together
        let normalized = category.lowercased()

        if normalized.contains("snack") {
            return "snacks"
        } else if normalized.contains("beverage") || normalized.contains("drink") {
            return "beverages"
        } else if normalized.contains("cereal") || normalized.contains("breakfast") {
            return "breakfast"
        } else if normalized.contains("dairy") || normalized.contains("milk") || normalized.contains("cheese") {
            return "dairy"
        } else if normalized.contains("meat") || normalized.contains("protein") {
            return "proteins"
        } else if normalized.contains("bread") || normalized.contains("bakery") {
            return "bakery"
        } else if normalized.contains("vegetable") || normalized.contains("produce") {
            return "produce"
        }

        return normalized
    }

    private func coefficientOfVariation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }

        let mean = values.reduce(0, +) / Double(values.count)
        guard mean > 0 else { return 0 }

        let squaredDiffs = values.map { pow($0 - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(values.count)
        let stdDev = sqrt(variance)

        return stdDev / mean
    }

    private func emptyProfile(period: AnalysisPeriod, healthFocus: HealthFocus) -> UserNutritionProfile {
        UserNutritionProfile(
            period: period,
            healthFocus: healthFocus,
            scanCount: 0,
            averages: .zero,
            gaps: [],
            patterns: [],
            generatedAt: Date()
        )
    }
}
