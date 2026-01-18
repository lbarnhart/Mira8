import Foundation

/// Category-specific adjustments for relative scoring within product categories
/// Philosophy: Help consumers choose the BEST option within their shopping category
struct CategoryAdjustments {
    
    /// Get category-adjusted thresholds for more realistic scoring
    static func adjustedThresholds(for category: String?) -> CategoryThresholdProfile {
        guard let category = category?.lowercased() else {
            #if DEBUG
            print("⚠️ CategoryAdjustments: No category provided, using .standard")
            #endif
            return .standard
        }
        
        #if DEBUG
        print("🔍 CategoryAdjustments: Checking category '\(category)'")
        #endif
        
        // Condiments & Sauces - expected to be concentrated, used in small amounts
        // Check for both singular and plural forms
        if category.contains("sauce") || category.contains("salsa") || 
           category.contains("condiment") || category.contains("dressing") ||
           category.contains("marinade") || category.contains("ketchup") ||
           category.contains("mustard") || category.contains("relish") ||
           category.contains("dip") || category.contains("spread") {
            #if DEBUG
            print("✅ CategoryAdjustments: Matched .condiment")
            #endif
            return .condiment
        }
        
        // Snacks - compare within snack category
        if category.contains("snack") || category.contains("chip") || 
           category.contains("cracker") || category.contains("popcorn") {
            return .snack
        }
        
        // Beverages - already handled separately
        if category.contains("drink") || category.contains("beverage") || 
           category.contains("juice") || category.contains("soda") {
            return .beverage
        }
        
        // Desserts & Sweets - compare within indulgence category
        if category.contains("dessert") || category.contains("candy") || 
           category.contains("chocolate") || category.contains("cookie") ||
           category.contains("ice cream") || category.contains("cake") {
            return .dessert
        }
        
        // Breakfast Foods - different expectations
        if category.contains("cereal") || category.contains("granola") || 
           category.contains("breakfast") || category.contains("oatmeal") {
            return .breakfast
        }
        
        // Dairy - account for natural lactose, calcium content
        if category.contains("milk") || category.contains("yogurt") || 
           category.contains("cheese") {
            return .dairy
        }
        
        // Processed Meats - high protein, but also high sodium typically
        if category.contains("deli") || category.contains("bacon") || 
           category.contains("sausage") || category.contains("hot dog") {
            return .processedMeat
        }
        
        return .standard
    }
    
    /// Calculate serving-size adjusted penalty
    /// Condiments used in 15g servings shouldn't be penalized like 100g foods
    static func servingSizeMultiplier(for category: String?) -> Double {
        guard let category = category?.lowercased() else {
            return 1.0
        }
        
        // Typical serving sizes
        if category.contains("sauce") || category.contains("condiment") || 
           category.contains("dressing") || category.contains("salsa") {
            return 0.15  // Typical 15g serving vs 100g base
        }
        
        if category.contains("seasoning") || category.contains("spice") {
            return 0.05  // 5g typical serving
        }
        
        return 1.0  // Most foods evaluated at 100g
    }
}

/// Category-specific threshold profiles
enum CategoryThresholdProfile {
    case standard
    case condiment
    case snack
    case beverage
    case dessert
    case breakfast
    case dairy
    case processedMeat
    
    /// Adjusted sodium thresholds (mg per 100g)
    var sodiumThresholds: (baseline: Double, step: Double) {
        switch self {
        case .standard:
            return (90.0, 90.0)
        case .condiment:
            return (600.0, 200.0)  // Much more lenient - sauces are concentrated
        case .snack:
            return (250.0, 150.0)  // Snacks tend to be salty
        case .beverage:
            return (45.0, 45.0)    // Beverages should be low sodium
        case .dessert:
            return (150.0, 100.0)  // Desserts can have some sodium
        case .breakfast:
            return (200.0, 120.0)  // Cereals/granola often have sodium
        case .dairy:
            return (120.0, 80.0)   // Dairy has natural sodium
        case .processedMeat:
            return (800.0, 200.0)  // Processed meats are inherently high sodium
        }
    }
    
    /// Adjusted sugar thresholds (g per 100g)
    var sugarThresholds: (baseline: Double, step: Double) {
        switch self {
        case .standard:
            return (4.5, 4.5)
        case .condiment:
            return (8.0, 6.0)      // Sauces often have tomato/fruit sugar
        case .snack:
            return (6.0, 5.0)      // Some snacks have added sugar
        case .beverage:
            return (2.25, 2.25)    // Keep strict for beverages
        case .dessert:
            return (20.0, 10.0)    // Desserts expected to have sugar
        case .breakfast:
            return (10.0, 6.0)     // Cereals often have sugar
        case .dairy:
            return (8.0, 5.0)      // Natural lactose + potential added sugar
        case .processedMeat:
            return (3.0, 3.0)      // Shouldn't have much sugar
        }
    }
    
    /// Processing level tolerance
    var processingTolerance: Double {
        switch self {
        case .standard:
            return 1.0
        case .condiment, .snack, .dessert, .processedMeat:
            return 0.5  // More forgiving - these are expected to be processed
        case .beverage, .breakfast, .dairy:
            return 0.8  // Somewhat forgiving
        }
    }
    
    /// Guardrail adjustment - how strict are caps?
    var guardrailLeniency: GuardrailLeniency {
        switch self {
        case .standard:
            return .strict
        case .condiment, .dessert, .snack:
            return .moderate  // Allow tier 2-3 even with processed ingredients
        case .processedMeat:
            return .lenient   // Processed meats are inherently processed
        case .beverage, .breakfast, .dairy:
            return .strict    // Keep strict for these
        }
    }
    
    /// Display context message
    var contextMessage: String? {
        switch self {
        case .condiment:
            return "Condiments are concentrated - use 1-2 tablespoons per serving"
        case .dessert:
            return "Desserts are treats - enjoy in moderation"
        case .snack:
            return "Snacks are for occasional consumption"
        case .processedMeat:
            return "Processed meats - best enjoyed occasionally"
        default:
            return nil
        }
    }
}

/// How lenient should guardrails be for this category?
enum GuardrailLeniency {
    case strict      // Standard guardrail caps
    case moderate    // Raise caps by 1 tier (tier1 → tier2)
    case lenient     // Raise caps by 2 tiers (tier1 → tier3)
    
    func adjustTier(_ tier: GuardrailTier) -> GuardrailTier {
        switch self {
        case .strict:
            return tier
        case .moderate:
            // Raise by 1 tier
            switch tier {
            case .tier0: return .tier1
            case .tier1: return .tier2
            case .tier2: return .tier3
            case .tier3, .tier4: return .tier4
            }
        case .lenient:
            // Raise by 2 tiers
            switch tier {
            case .tier0: return .tier2
            case .tier1: return .tier3
            case .tier2, .tier3, .tier4: return .tier4
            }
        }
    }
}

