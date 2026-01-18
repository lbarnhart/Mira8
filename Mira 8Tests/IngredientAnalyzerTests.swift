import XCTest
@testable import Mira_8

final class IngredientAnalyzerTests: XCTestCase {
    
    // MARK: - Categorization Tests
    
    func testAnalyze_beneficialIngredient_returnsBeneficial() {
        // Given: A beneficial ingredient
        let ingredients = ["quinoa"]
        
        // When: Analyzing
        let results = IngredientAnalyzer.shared.analyze(ingredients: ingredients)
        
        // Then: Should be categorized as beneficial
        XCTAssertEqual(results.count, 1, "Should return one result")
        if let first = results.first {
            XCTAssertEqual(first.category, .beneficial, "Quinoa should be beneficial")
        }
    }
    
    func testAnalyze_neutralIngredient_returnsNeutral() {
        // Given: A neutral ingredient
        let ingredients = ["water"]
        
        // When: Analyzing
        let results = IngredientAnalyzer.shared.analyze(ingredients: ingredients)
        
        // Then: Should be categorized as neutral
        XCTAssertEqual(results.count, 1, "Should return one result")
        if let first = results.first {
            XCTAssertEqual(first.category, .neutral, "Water should be neutral")
        }
    }
    
    func testAnalyze_concerningIngredient_returnsConcerning() {
        // Given: A concerning ingredient
        let ingredients = ["high fructose corn syrup"]
        
        // When: Analyzing
        let results = IngredientAnalyzer.shared.analyze(ingredients: ingredients)
        
        // Then: Should be categorized as concerning
        XCTAssertEqual(results.count, 1, "Should return one result")
        if let first = results.first {
            XCTAssertEqual(first.category, .concerning, "High fructose corn syrup should be concerning")
        }
    }
    
    func testAnalyze_unknownIngredient_returnsUnknown() {
        // Given: An unknown/unusual ingredient
        let ingredients = ["xyzabc123unknown"]
        
        // When: Analyzing
        let results = IngredientAnalyzer.shared.analyze(ingredients: ingredients)
        
        // Then: Should be categorized as unknown
        XCTAssertEqual(results.count, 1, "Should return one result")
        if let first = results.first {
            XCTAssertEqual(first.category, .unknown, "Unknown ingredient should be categorized as unknown")
        }
    }
    
    // MARK: - Multiple Ingredients Tests
    
    func testAnalyze_multipleIngredients_returnsAllResults() {
        // Given: Multiple ingredients
        let ingredients = ["salt", "sugar", "water", "olive oil"]
        
        // When: Analyzing
        let results = IngredientAnalyzer.shared.analyze(ingredients: ingredients)
        
        // Then: Should return results for all ingredients
        XCTAssertEqual(results.count, 4, "Should return results for all ingredients")
    }
    
    func testAnalyze_emptyList_returnsEmptyResults() {
        // Given: Empty ingredient list
        let ingredients: [String] = []
        
        // When: Analyzing
        let results = IngredientAnalyzer.shared.analyze(ingredients: ingredients)
        
        // Then: Should return empty results
        XCTAssertTrue(results.isEmpty, "Should return empty results for empty input")
    }
    
    // MARK: - Parsing Tests
    
    func testParseIngredientList_standardFormat_correctlyParses() {
        // Given: Standard comma-separated ingredient text
        let text = "Water, Sugar, Salt, Natural Flavors"
        
        // When: Parsing
        let parsed = IngredientAnalyzer.shared.parseIngredientList(text)
        
        // Then: Should correctly split and trim
        XCTAssertEqual(parsed.count, 4, "Should parse 4 ingredients")
        XCTAssertTrue(parsed.contains("Water"), "Should contain Water")
        XCTAssertTrue(parsed.contains("Sugar"), "Should contain Sugar")
        XCTAssertTrue(parsed.contains("Salt"), "Should contain Salt")
    }
    
    func testParseIngredientList_withParentheses_handlesNested() {
        // Given: Ingredient with parenthetical content
        let text = "Wheat Flour (Contains: Wheat), Sugar, Salt"
        
        // When: Parsing
        let parsed = IngredientAnalyzer.shared.parseIngredientList(text)
        
        // Then: Should handle parentheses appropriately
        XCTAssertGreaterThanOrEqual(parsed.count, 3, "Should parse at least 3 ingredients")
    }
    
    func testParseIngredientList_withColons_handlesCorrectly() {
        // Given: Ingredient text with colons
        let text = "Contains: Milk, Soy. Ingredients: Water, Sugar"
        
        // When: Parsing
        let parsed = IngredientAnalyzer.shared.parseIngredientList(text)
        
        // Then: Should extract actual ingredients
        XCTAssertGreaterThan(parsed.count, 0, "Should parse some ingredients")
    }
    
    // MARK: - Case Sensitivity Tests
    
    func testAnalyze_caseInsensitive_matchesCorrectly() {
        // Given: Ingredients in different cases
        let lowerCase = IngredientAnalyzer.shared.analyze(ingredients: ["salt"])
        let upperCase = IngredientAnalyzer.shared.analyze(ingredients: ["SALT"])
        let mixedCase = IngredientAnalyzer.shared.analyze(ingredients: ["SaLt"])
        
        // Then: All should return the same category
        XCTAssertEqual(lowerCase.first?.category, upperCase.first?.category, "Case should not affect categorization")
        XCTAssertEqual(lowerCase.first?.category, mixedCase.first?.category, "Case should not affect categorization")
    }
    
    // MARK: - Whitespace Handling Tests
    
    func testAnalyze_withExtraWhitespace_handlesCorrectly() {
        // Given: Ingredients with extra whitespace
        let ingredients = ["  salt  ", "  sugar  "]
        
        // When: Analyzing
        let results = IngredientAnalyzer.shared.analyze(ingredients: ingredients)
        
        // Then: Should handle whitespace and still identify ingredients
        XCTAssertEqual(results.count, 2, "Should return 2 results despite whitespace")
    }
    
    // MARK: - Specific Ingredient Tests
    
    func testAnalyze_commonHealthyIngredients_categorizedCorrectly() {
        // Given: Common healthy ingredients
        let healthyIngredients = ["olive oil", "almonds", "spinach", "salmon", "blueberries"]
        
        // When: Analyzing
        let results = IngredientAnalyzer.shared.analyze(ingredients: healthyIngredients)
        
        // Then: Most should be beneficial
        let beneficialCount = results.filter { $0.category == .beneficial }.count
        XCTAssertGreaterThan(beneficialCount, 0, "Should identify some beneficial ingredients")
    }
    
    func testAnalyze_commonUnhealthyIngredients_categorizedCorrectly() {
        // Given: Common concerning ingredients
        let unhealthyIngredients = ["high fructose corn syrup", "partially hydrogenated oil", "artificial flavor"]
        
        // When: Analyzing
        let results = IngredientAnalyzer.shared.analyze(ingredients: unhealthyIngredients)
        
        // Then: Most should be concerning
        let concerningCount = results.filter { $0.category == .concerning }.count
        XCTAssertGreaterThan(concerningCount, 0, "Should identify some concerning ingredients")
    }
}
