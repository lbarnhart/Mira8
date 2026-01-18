import Foundation

#if canImport(FirebaseFunctions)
import FirebaseFunctions
#endif

/// Service to handle intelligent ingredient analysis using Firebase Cloud Functions (GenAI)
/// and local heuristics as fallback.
final class SmartIngredientService {
    static let shared = SmartIngredientService()
    
    #if canImport(FirebaseFunctions)
    private lazy var functions = Functions.functions()
    #endif
    
    private init() {}
    
    /// Analyzes a list of ingredients using AI to determine their health impact.
    /// - Parameter ingredients: List of ingredient names.
    /// - Returns: A map of ingredient name to its analysis.
    func analyzeIngredients(_ ingredients: [String]) async throws -> [String: IngredientMetadata] {
        // 1. Filter out ingredients we already know locally (optimization)
        let unknownIngredients = ingredients.filter { !IngredientAnalyzer.shared.hasMetadata(for: $0) }
        
        guard !unknownIngredients.isEmpty else {
            return [:]
        }
        
        // 2. Call Cloud Function for unknown ingredients
        #if canImport(FirebaseFunctions)
        do {
            let result = try await functions.httpsCallable("analyzeIngredients").call(["ingredients": unknownIngredients])
            
            guard let data = result.data as? [String: [String: Any]] else {
                throw SmartAnalysisError.invalidResponse
            }
            
            var analyses: [String: IngredientMetadata] = [:]
            
            for (name, info) in data {
                if let categoryStr = info["category"] as? String,
                   let category = IngredientCategory(rawValue: categoryStr),
                   let explanation = info["explanation"] as? String,
                   let displayName = info["displayName"] as? String {
                    
                    let metadata = IngredientMetadata(
                        displayName: displayName,
                        category: category,
                        explanation: explanation,
                        source: .aiVerified
                    )
                    analyses[name] = metadata
                }
            }
            return analyses
        } catch {
            AppLog.error("SmartIngredientService: AI analysis failed - \(error.localizedDescription)", category: .scoring)
            throw error
        }
        #else
        AppLog.warning("SmartIngredientService: FirebaseFunctions not available. Skipping AI analysis.", category: .scoring)
        return [:]
        #endif
    }
    
    /// Analyze a single unknown ingredient
    func analyzeIngredient(_ ingredient: String) async throws -> IngredientMetadata? {
        let result = try await analyzeIngredients([ingredient])
        return result[ingredient]
    }
    
    enum SmartAnalysisError: Error {
         case invalidResponse
    }
}
