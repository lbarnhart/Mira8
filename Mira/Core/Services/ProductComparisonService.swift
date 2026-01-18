import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

/// Service to find healthier product alternatives using Firestore
final class ProductComparisonService {
    static let shared = ProductComparisonService()
    
    #if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
    #endif
    
    private init() {}

    /// Quick comparison between two scores to provide a simple verdict
    /// - Parameters:
    ///   - scoreA: The first product's score
    ///   - scoreB: The second product's score
    /// - Returns: A verdict string describing which is better
    func quickCompare(scoreA: Double, scoreB: Double) -> String {
        let difference = scoreB - scoreA

        if abs(difference) < 5 {
            return "Similar health scores"
        } else if difference > 0 {
            return "This is healthier (+\(Int(difference)) points)"
        } else {
            return "The other is healthier (\(Int(difference)) points)"
        }
    }

    /// Finds healthier alternatives for a given product within the same category.
    /// - Parameters:
    ///   - product: The product to compare against.
    ///   - limit: Maximum number of alternatives to return.
    /// - Returns: A list of healthier products.
    func findHealthierAlternatives(for product: ProductModel, limit: Int = 5) async -> [ProductModel] {
        // Ensure we have a category to compare against
        guard let categorySlug = product.categorySlug, !categorySlug.isEmpty else {
            return []
        }
        
        // Ensure the product has a valid health score to compare against
        let currentScore = product.healthScore
        
        #if canImport(FirebaseFirestore)
        do {
            // Logic: Same category, strictly higher health score, ordered by score descending
            let snapshot = try await db.collection("products")
                .whereField("categorySlug", isEqualTo: categorySlug)
                .whereField("healthScore", isGreaterThan: currentScore)
                .order(by: "healthScore", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            let alternatives = snapshot.documents.compactMap { doc -> ProductModel? in
                try? parseProduct(from: doc.data(), id: doc.documentID)
            }
            
            return alternatives
        } catch {
            AppLog.error("ProductComparisonService: Failed to fetch alternatives - \(error.localizedDescription)", category: .network)
            return []
        }
        #else
        return []
        #endif
    }
    
    // Helper to parse Firestore data back to ProductModel
    private func parseProduct(from data: [String: Any], id: String) throws -> ProductModel? {
        // Reuse CachedProduct parsing logic if possible, or replicate it
        guard let name = data["name"] as? String else { return nil }
        
        let cached = CachedProduct(
            barcode: id,
            name: name,
            brand: data["brand"] as? String,
            category: data["category"] as? String,
            categorySlug: data["categorySlug"] as? String,
            ingredients: (data["ingredients"] as? String)?.components(separatedBy: ", ") ?? [],
            rawIngredientsText: data["rawIngredientsText"] as? String,
            imageURL: data["imageURL"] as? String,
            thumbnailURL: data["thumbnailURL"] as? String,
            processingLevelRaw: data["processingLevel"] as? Int,
            nutriScore: data["nutriScore"] as? String,
            calories: data["calories"] as? Double ?? 0,
            protein: data["protein"] as? Double ?? 0,
            carbohydrates: data["carbohydrates"] as? Double ?? 0,
            fat: data["fat"] as? Double ?? 0,
            saturatedFat: data["saturatedFat"] as? Double ?? 0,
            fiber: data["fiber"] as? Double ?? 0,
            sugar: data["sugar"] as? Double ?? 0,
            sodium: data["sodium"] as? Double ?? 0,
            cholesterol: data["cholesterol"] as? Double ?? 0,
            servingSize: data["servingSize"] as? String ?? "100g"
        )
        
        // Inject the health score if it was stored
        var model = cached.toProductModel()
        if let score = data["healthScore"] as? Double {
            model.healthScore = score
        }
        
        return model
    }
}
