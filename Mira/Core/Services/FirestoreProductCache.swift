
import Foundation

// Check if Firestore is available
#if canImport(FirebaseFirestore)
import FirebaseCore
import FirebaseFirestore

/// Shared product cache using Firebase Firestore
/// Products scanned by any user become available to all users instantly
final class FirestoreProductCache {
    static let shared = FirestoreProductCache()
    
    private var db: Firestore?
    private let collectionName = "products"
    
    private init() {
        configureFirebase()
    }
    
    /// Configure Firebase if not already configured
    private func configureFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            AppLog.info("FirestoreProductCache: Firebase configured", category: .persistence)
        }
        db = Firestore.firestore()
    }
    
    // MARK: - Product Lookup
    
    /// Fetch a product from the shared Firestore cache
    /// - Parameter barcode: The product barcode
    /// - Returns: The cached product, or nil if not found
    func getProduct(barcode: String) async -> CachedProduct? {
        guard let db = db else {
            AppLog.warning("FirestoreProductCache: Firestore not initialized", category: .persistence)
            return nil
        }
        
        do {
            let document = try await db.collection(collectionName).document(barcode).getDocument()
            
            guard document.exists, let data = document.data() else {
                AppLog.debug("FirestoreProductCache: No cached product for \(barcode)", category: .persistence)
                return nil
            }
            
            let product = try parseCachedProduct(from: data, barcode: barcode)
            AppLog.debug("FirestoreProductCache: Found cached product: \(product.name)", category: .persistence)
            return product
            
        } catch {
            AppLog.warning("FirestoreProductCache: Failed to fetch \(barcode) - \(error.localizedDescription)", category: .persistence)
            return nil
        }
    }
    
    /// Check if a product exists in the shared cache (fast check without full fetch)
    func hasProduct(barcode: String) async -> Bool {
        guard let db = db else { return false }
        
        do {
            let document = try await db.collection(collectionName).document(barcode).getDocument()
            return document.exists
        } catch {
            return false
        }
    }
    
    // MARK: - Product Caching
    
    func cacheProduct(_ product: ProductModel) async {
        guard let db = db else { return }
        
        let data: [String: Any] = [
            "name": product.name,
            "brand": product.brand ?? "",
            "category": product.category ?? "",
            "categorySlug": product.categorySlug ?? "",
            "ingredients": product.ingredients.joined(separator: ", "),
            "rawIngredientsText": product.rawIngredientsText ?? "",
            "imageURL": product.imageURL ?? "",
            "thumbnailURL": product.thumbnailURL ?? "",
            "processingLevel": product.processingLevel.rawValue,
            "nutriScore": product.nutriScore ?? "",
            "healthScore": product.healthScore,
            "calories": product.nutrition.calories,
            "protein": product.nutrition.protein,
            "carbohydrates": product.nutrition.carbohydrates,
            "fat": product.nutrition.fat,
            "saturatedFat": product.nutrition.saturatedFat,
            "fiber": product.nutrition.fiber,
            "sugar": product.nutrition.sugar,
            "sodium": product.nutrition.sodium,
            "cholesterol": product.nutrition.cholesterol,
            "servingSize": product.nutrition.servingSize,
            "cachedAt": FieldValue.serverTimestamp(),
            "scanCount": FieldValue.increment(Int64(1))
        ]
        
        do {
            try await db.collection(collectionName).document(product.barcode).setData(data, merge: true)
            AppLog.info("FirestoreProductCache: Cached product \(product.barcode)", category: .persistence)
        } catch {
            AppLog.warning("FirestoreProductCache: Failed to cache \(product.barcode) - \(error.localizedDescription)", category: .persistence)
        }
    }
    
    private func parseCachedProduct(from data: [String: Any], barcode: String) throws -> CachedProduct {
        guard let name = data["name"] as? String, !name.isEmpty else {
            throw CacheError.invalidData
        }
        
        return CachedProduct(
            barcode: barcode,
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
    }
    
    enum CacheError: Error {
        case invalidData
    }
}

#else
// Fallback stub if Firestore is not available
final class FirestoreProductCache {
    static let shared = FirestoreProductCache()
    private init() {
        AppLog.warning("FirestoreProductCache: Missing FirebaseFirestore dependency. Shared caching disabled.", category: .persistence)
    }
    func getProduct(barcode: String) async -> CachedProduct? { return nil }
    func hasProduct(barcode: String) async -> Bool { return false }
    func cacheProduct(_ product: ProductModel) async {}
}
#endif


