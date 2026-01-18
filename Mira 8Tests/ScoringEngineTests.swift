import XCTest
@testable import Mira_8

final class ScoringEngineTests: XCTestCase {
    
    // MARK: - Basic Scoring Tests
    
    func testCalculateHealthScore_withValidProduct_returnsScore() {
        // Given: A product with known nutritional values
        let product = createTestProduct(
            name: "Test Apple",
            sugar: 10.0,
            sodium: 1.0,
            fiber: 2.4,
            protein: 0.3,
            fat: 0.2,
            saturatedFat: 0.0
        )
        
        // When: Calculating the health score
        let score = ScoringEngine.shared.calculateHealthScore(
            for: product,
            dietaryRestrictions: []
        )
        
        // Then: Score should be within valid range (0-100)
        XCTAssertGreaterThanOrEqual(score.overall, 0, "Score should be at least 0")
        XCTAssertLessThanOrEqual(score.overall, 100, "Score should not exceed 100")
        XCTAssertNotNil(score.grade, "Score should have a grade")
        XCTAssertNotNil(score.verdict, "Score should have a verdict")
    }
    
    func testCalculateHealthScore_withHighSodium_returnsLowerScore() {
        // Given: Products with different sodium levels
        let lowSodiumProduct = createTestProduct(name: "Low Sodium", sodium: 10.0)
        let highSodiumProduct = createTestProduct(name: "High Sodium", sodium: 2000.0)
        
        // When: Calculating scores
        let lowSodiumScore = ScoringEngine.shared.calculateHealthScore(
            for: lowSodiumProduct,
            dietaryRestrictions: []
        )
        let highSodiumScore = ScoringEngine.shared.calculateHealthScore(
            for: highSodiumProduct,
            dietaryRestrictions: []
        )
        
        // Then: High sodium product should score lower
        XCTAssertGreaterThan(
            lowSodiumScore.overall,
            highSodiumScore.overall,
            "Low sodium product should score higher than high sodium product"
        )
    }
    
    func testCalculateHealthScore_withHighSugar_returnsLowerScore() {
        // Given: Products with different sugar levels
        let lowSugarProduct = createTestProduct(name: "Low Sugar", sugar: 2.0)
        let highSugarProduct = createTestProduct(name: "High Sugar", sugar: 50.0)
        
        // When: Calculating scores
        let lowSugarScore = ScoringEngine.shared.calculateHealthScore(
            for: lowSugarProduct,
            dietaryRestrictions: []
        )
        let highSugarScore = ScoringEngine.shared.calculateHealthScore(
            for: highSugarProduct,
            dietaryRestrictions: []
        )
        
        // Then: High sugar product should score lower
        XCTAssertGreaterThan(
            lowSugarScore.overall,
            highSugarScore.overall,
            "Low sugar product should score higher than high sugar product"
        )
    }
    
    func testCalculateHealthScore_withHighProtein_returnsHigherScore() {
        // Given: Products with different protein levels
        let lowProteinProduct = createTestProduct(name: "Low Protein", protein: 1.0)
        let highProteinProduct = createTestProduct(name: "High Protein", protein: 25.0)
        
        // When: Calculating scores
        let lowProteinScore = ScoringEngine.shared.calculateHealthScore(
            for: lowProteinProduct,
            dietaryRestrictions: []
        )
        let highProteinScore = ScoringEngine.shared.calculateHealthScore(
            for: highProteinProduct,
            dietaryRestrictions: []
        )
        
        // Then: High protein product should score higher
        XCTAssertGreaterThanOrEqual(
            highProteinScore.overall,
            lowProteinScore.overall,
            "High protein product should score at least as high as low protein product"
        )
    }
    
    func testCalculateHealthScore_withHighFiber_returnsHigherScore() {
        // Given: Products with different fiber levels
        let lowFiberProduct = createTestProduct(name: "Low Fiber", fiber: 0.5)
        let highFiberProduct = createTestProduct(name: "High Fiber", fiber: 10.0)
        
        // When: Calculating scores
        let lowFiberScore = ScoringEngine.shared.calculateHealthScore(
            for: lowFiberProduct,
            dietaryRestrictions: []
        )
        let highFiberScore = ScoringEngine.shared.calculateHealthScore(
            for: highFiberProduct,
            dietaryRestrictions: []
        )
        
        // Then: High fiber product should score higher
        XCTAssertGreaterThanOrEqual(
            highFiberScore.overall,
            lowFiberScore.overall,
            "High fiber product should score at least as high as low fiber product"
        )
    }
    
    // MARK: - Edge Case Tests
    
    func testCalculateHealthScore_withZeroNutrients_handlesGracefully() {
        // Given: A product with zero nutrients
        let product = createTestProduct(
            name: "Empty Product",
            sugar: 0, sodium: 0, fiber: 0, protein: 0, fat: 0, saturatedFat: 0
        )
        
        // When: Calculating the score
        let score = ScoringEngine.shared.calculateHealthScore(
            for: product,
            dietaryRestrictions: []
        )
        
        // Then: Should not crash and return valid score
        XCTAssertGreaterThanOrEqual(score.overall, 0)
        XCTAssertLessThanOrEqual(score.overall, 100)
    }
    
    func testCalculateHealthScore_withExtremeValues_clampsProperly() {
        // Given: A product with extreme nutrient values
        let product = createTestProduct(
            name: "Extreme Product",
            sugar: 999, sodium: 9999, fiber: 999, protein: 999, fat: 999, saturatedFat: 999
        )
        
        // When: Calculating the score
        let score = ScoringEngine.shared.calculateHealthScore(
            for: product,
            dietaryRestrictions: []
        )
        
        // Then: Score should still be in valid range
        XCTAssertGreaterThanOrEqual(score.overall, 0, "Score should be at least 0 even with extreme values")
        XCTAssertLessThanOrEqual(score.overall, 100, "Score should not exceed 100 even with extreme values")
    }
    
    // MARK: - Dietary Restriction Tests
    
    func testCheckDietaryViolations_withVeganAndMeat_returnsViolation() {
        // Given: A product with meat ingredients
        let ingredients = ["chicken", "salt", "pepper"]
        
        // When: Checking dietary violations
        let violations = ScoringEngine.shared.checkDietaryViolations(
            ingredients: ingredients,
            restrictions: [.vegan]
        )
        
        // Then: Should detect vegan violation
        XCTAssertTrue(violations.contains(.vegan), "Should detect vegan violation when meat is present")
    }
    
    func testCheckDietaryViolations_withVeganAndPlants_returnsNoViolation() {
        // Given: A product with only plant ingredients
        let ingredients = ["tomato", "basil", "olive oil", "salt"]
        
        // When: Checking dietary violations
        let violations = ScoringEngine.shared.checkDietaryViolations(
            ingredients: ingredients,
            restrictions: [.vegan]
        )
        
        // Then: Should not detect any violations
        XCTAssertFalse(violations.contains(.vegan), "Should not detect vegan violation for plant-only ingredients")
    }
    
    // MARK: - Helper Methods
    
    private func createTestProduct(
        name: String,
        sugar: Double = 5.0,
        sodium: Double = 100.0,
        fiber: Double = 2.0,
        protein: Double = 5.0,
        fat: Double = 3.0,
        saturatedFat: Double = 1.0
    ) -> ProductModel {
        let nutrition = ProductNutrition(
            calories: 100,
            protein: protein,
            carbohydrates: 20,
            fat: fat,
            saturatedFat: saturatedFat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            cholesterol: 0,
            servingSize: "100g",
            labelServingSize: nil
        )
        
        return ProductModel(
            id: UUID(),
            name: name,
            brand: "Test Brand",
            category: "Test Category",
            categorySlug: nil,
            barcode: "0000000000000",
            nutrition: nutrition,
            ingredients: [],
            additives: [],
            processingLevel: .minimal,
            dietaryFlags: [],
            imageURL: nil,
            thumbnailURL: nil,
            healthScore: 0,
            createdAt: Date(),
            updatedAt: Date(),
            isCached: false,
            rawIngredientsText: nil
        )
    }
}
