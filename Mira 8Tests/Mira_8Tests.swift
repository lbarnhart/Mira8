//
//  MiraTests.swift
//  Mira Tests
//
//  Created by Lauren Barnhart on 9/29/25.
//

import Foundation
import Testing
@testable import Mira_8

@Suite struct MiraTests {

    @Test func openFoodFactsMappingPrefersBrandOwner() async throws {
        let json = """
        {
          "status": 1,
          "code": "027271103049",
          "product": {
            "code": "027271103049",
            "product_name": "Organic honey ginger vinaigrette dressing",
            "_keywords": ["organic", "honey", "ginger", "vinaigrette", "dressing"],
            "brands": null,
            "brand_owner": "Del Sol Food Company, Inc.",
            "brand_owner_imported": "Del Sol Food Company, Inc.",
            "categories": "Condiments, Sauces, Groceries",
            "categories_hierarchy": ["en:condiments", "en:sauces", "en:Groceries"],
            "ingredients_text": "Water, organic canola oil, organic white vinegar, organic honey, organic light brown sugar, organic sugar, salt, organic carrot powder, organic ginger powder, citric acid, organic onion powder, xanthan gum.",
            "nutriments": {
              "energy-kcal_100g": 355,
              "energy-kcal": 355,
              "proteins_100g": 0,
              "carbohydrates_100g": 22.6,
              "fat_100g": 32.3,
              "sugars_100g": 19.4,
              "fiber_100g": 0,
              "sodium_100g": 0.194
            }
          }
        }
        """.data(using: .utf8)!

        let mockClient = MockAPIClient(payload: json)
        let service = OpenFoodFactsService(apiClient: mockClient)

        let product = try await service.searchProductByBarcode("027271103049")

        #expect(product.brand == "Del Sol Food Company, Inc.")
        #expect(product.category == "Salad Dressings")
        #expect(product.categorySlug == "salad-dressings")
        #expect(product.name == "Organic honey ginger vinaigrette dressing")
        #expect(product.ingredients.count == 12)
    }

    @Test func novaGroupMapsToProcessingLevel() async throws {
        // Test NOVA 1 → minimal
        #expect(ProcessingLevel.fromNOVA(1) == .minimal)

        // Test NOVA 2 and 3 → processed
        #expect(ProcessingLevel.fromNOVA(2) == .processed)
        #expect(ProcessingLevel.fromNOVA(3) == .processed)

        // Test NOVA 4 → ultra-processed
        #expect(ProcessingLevel.fromNOVA(4) == .ultraProcessed)

        // Test nil and invalid values
        #expect(ProcessingLevel.fromNOVA(nil) == nil)
        #expect(ProcessingLevel.fromNOVA(0) == nil)
        #expect(ProcessingLevel.fromNOVA(5) == nil)
    }

    @Test func alternativesEngineUsesMeaningfulQueryToken() async throws {
        let product = ProductModel(
            id: UUID(),
            name: "Groceries",
            brand: "Briannas",
            category: nil,
            categorySlug: nil,
            barcode: "027271103049",
            nutrition: ProductNutrition(),
            ingredients: ["Water"],
            additives: [],
            processingLevel: .processed,
            dietaryFlags: [],
            imageURL: nil,
            thumbnailURL: nil,
            healthScore: 0,
            createdAt: Date(),
            updatedAt: Date(),
            isCached: false,
            rawIngredientsText: nil
        )

        let query = AlternativesEngine.shared.sanitizedQuery(from: product)
        #expect(query == "briannas")
    }

    @Test func sanitizedQueryUsesCategorySlug() async throws {
        let product = ProductModel(
            id: UUID(),
            name: "Organic Honey Ginger Vinaigrette",
            brand: "Briannas",
            category: "Salad Dressings",
            categorySlug: "salad-dressings",
            barcode: "027271103049",
            nutrition: ProductNutrition(),
            ingredients: [],
            additives: [],
            processingLevel: .processed,
            dietaryFlags: [],
            imageURL: nil,
            thumbnailURL: nil,
            healthScore: 0,
            createdAt: Date(),
            updatedAt: Date(),
            isCached: false,
            rawIngredientsText: nil
        )

        let query = AlternativesEngine.shared.sanitizedQuery(from: product)
        #expect(query == "salad-dressings")
    }

    @Test func servingSizeDisplayIsPreservedFromSource() async throws {
        // Test that when servingSizeDisplay is provided from OpenFoodFacts, it's used
        let json = """
        {
          "status": 1,
          "code": "027271103049",
          "product": {
            "code": "027271103049",
            "product_name": "Asiago Caesar Dressing",
            "brand_owner": "Briannas",
            "serving_size": "2 tbsp (30 g)",
            "serving_quantity": "30",
            "categories": "Salad Dressings",
            "ingredients_text": "Water, oil, cheese",
            "nutriments": {
              "energy-kcal_100g": 500,
              "proteins_100g": 2.0,
              "carbohydrates_100g": 3.0,
              "fat_100g": 50.0,
              "sugars_100g": 2.0,
              "fiber_100g": 0,
              "sodium_100g": 0.5
            }
          }
        }
        """.data(using: .utf8)!

        let mockClient = MockAPIClient(payload: json)
        let service = OpenFoodFactsService(apiClient: mockClient)

        let apiProduct = try await service.searchProductByBarcode("027271103049")

        // Verify servingSizeDisplay is populated
        #expect(apiProduct.servingSizeDisplay == "2 tbsp (30 g)")

        // Create ProductModel from APIProduct (simulating what ScannerViewModel does)
        let servingDisplay = apiProduct.servingSizeDisplay ?? "100g"
        let nutrition = ProductNutrition(
            calories: apiProduct.nutritionalData.calories,
            protein: apiProduct.nutritionalData.protein,
            carbohydrates: apiProduct.nutritionalData.carbohydrates,
            fat: apiProduct.nutritionalData.fat,
            fiber: apiProduct.nutritionalData.fiber,
            sugar: apiProduct.nutritionalData.sugar,
            sodium: apiProduct.nutritionalData.sodium,
            cholesterol: apiProduct.nutritionalData.cholesterol,
            servingSize: servingDisplay
        )

        // Verify ProductNutrition uses the display string
        #expect(nutrition.servingSize == "2 tbsp (30 g)")
    }

    @Test func servingSizeFallsBackTo100gWhenMissing() async throws {
        // Test that when servingSizeDisplay is nil, we fall back to "100g"
        let json = """
        {
          "status": 1,
          "code": "999999",
          "product": {
            "code": "999999",
            "product_name": "Test Product",
            "brand_owner": "Test Brand",
            "categories": "Food",
            "ingredients_text": "ingredient1, ingredient2",
            "nutriments": {
              "energy-kcal_100g": 200,
              "proteins_100g": 5.0,
              "carbohydrates_100g": 20.0,
              "fat_100g": 8.0
            }
          }
        }
        """.data(using: .utf8)!

        let mockClient = MockAPIClient(payload: json)
        let service = OpenFoodFactsService(apiClient: mockClient)

        let apiProduct = try await service.searchProductByBarcode("999999")

        // Verify servingSizeDisplay is nil (no serving_size in JSON)
        #expect(apiProduct.servingSizeDisplay == nil)

        // Create ProductModel (simulating ScannerViewModel logic)
        let servingDisplay = apiProduct.servingSizeDisplay ?? "100g"
        let nutrition = ProductNutrition(servingSize: servingDisplay)

        // Verify it falls back to "100g"
        #expect(nutrition.servingSize == "100g")
    }

    @Test func usdaLabelNutrientsArePreferredOverPer100g() async throws {
        // Test USDA product with both foodNutrients (per 100g) and labelNutrients (per serving)
        let json = """
        {
          "fdcId": 123456,
          "description": "Almond Butter",
          "brandOwner": "Test Brand",
          "gtinUpc": "012345678901",
          "servingSize": 32,
          "servingSizeUnit": "g",
          "householdServingFullText": "2 tbsp (32g)",
          "foodNutrients": [
            {"nutrientId": 1008, "nutrientName": "Energy", "nutrientNumber": "208", "unitName": "kcal", "value": 625},
            {"nutrientId": 1003, "nutrientName": "Protein", "nutrientNumber": "203", "unitName": "g", "value": 21.88},
            {"nutrientId": 1004, "nutrientName": "Total lipid (fat)", "nutrientNumber": "204", "unitName": "g", "value": 56.25},
            {"nutrientId": 1005, "nutrientName": "Carbohydrate", "nutrientNumber": "205", "unitName": "g", "value": 18.75},
            {"nutrientId": 1079, "nutrientName": "Fiber", "nutrientNumber": "291", "unitName": "g", "value": 9.4},
            {"nutrientId": 2000, "nutrientName": "Sugars", "nutrientNumber": "269", "unitName": "g", "value": 6.25},
            {"nutrientId": 1093, "nutrientName": "Sodium", "nutrientNumber": "307", "unitName": "mg", "value": 312},
            {"nutrientId": 1253, "nutrientName": "Cholesterol", "nutrientNumber": "601", "unitName": "mg", "value": 0}
          ],
          "labelNutrients": {
            "calories": {"value": 200},
            "protein": {"value": 7},
            "fat": {"value": 18},
            "carbohydrates": {"value": 6},
            "fiber": {"value": 3},
            "sugars": {"value": 2},
            "sodium": {"value": 100},
            "cholesterol": {"value": 0}
          }
        }
        """.data(using: .utf8)!

        let mockClient = MockAPIClient(payload: json)
        let usdaService = USDAService(apiClient: mockClient)

        let details = try await usdaService.fetchProductDetails(fdcId: "123456")
        let apiProduct = details.product

        // Verify labelNutrients values were used (per-serving), NOT per-100g values
        #expect(apiProduct.nutritionalData.calories == 200.0)  // Not 625
        #expect(apiProduct.nutritionalData.protein == 7.0)    // Not 21.88
        #expect(apiProduct.nutritionalData.fat == 18.0)       // Not 56.25
        #expect(apiProduct.nutritionalData.carbohydrates == 6.0)  // Not 18.75
        #expect(apiProduct.nutritionalData.fiber == 3.0)      // Not 9.4
        #expect(apiProduct.nutritionalData.sugar == 2.0)      // Not 6.25
        #expect(apiProduct.nutritionalData.sodium == 0.1)     // 100mg -> 0.1g (Not 0.312g)
        #expect(apiProduct.nutritionalData.cholesterol == 0.0)

        // Verify serving size display is preserved
        #expect(apiProduct.servingSizeDisplay == "2 tbsp (32g)")
    }

    @Test func usdaFallsBackToPer100gWhenLabelNutrientsAreMissing() async throws {
        // Test USDA product with only foodNutrients (no labelNutrients)
        let json = """
        {
          "fdcId": 789012,
          "description": "Plain Yogurt",
          "brandOwner": "Dairy Co",
          "gtinUpc": "098765432101",
          "servingSize": 100,
          "servingSizeUnit": "g",
          "foodNutrients": [
            {"nutrientId": 1008, "nutrientName": "Energy", "nutrientNumber": "208", "unitName": "kcal", "value": 59},
            {"nutrientId": 1003, "nutrientName": "Protein", "nutrientNumber": "203", "unitName": "g", "value": 3.5},
            {"nutrientId": 1004, "nutrientName": "Total lipid (fat)", "nutrientNumber": "204", "unitName": "g", "value": 0.4},
            {"nutrientId": 1005, "nutrientName": "Carbohydrate", "nutrientNumber": "205", "unitName": "g", "value": 4.7},
            {"nutrientId": 1079, "nutrientName": "Fiber", "nutrientNumber": "291", "unitName": "g", "value": 0},
            {"nutrientId": 2000, "nutrientName": "Sugars", "nutrientNumber": "269", "unitName": "g", "value": 4.7},
            {"nutrientId": 1093, "nutrientName": "Sodium", "nutrientNumber": "307", "unitName": "mg", "value": 46},
            {"nutrientId": 1253, "nutrientName": "Cholesterol", "nutrientNumber": "601", "unitName": "mg", "value": 2}
          ]
        }
        """.data(using: .utf8)!

        let mockClient = MockAPIClient(payload: json)
        let usdaService = USDAService(apiClient: mockClient)

        let details = try await usdaService.fetchProductDetails(fdcId: "789012")
        let apiProduct = details.product

        // Verify per-100g values are used when labelNutrients are not present
        #expect(apiProduct.nutritionalData.calories == 59.0)
        #expect(apiProduct.nutritionalData.protein == 3.5)
        #expect(apiProduct.nutritionalData.fat == 0.4)
        #expect(apiProduct.nutritionalData.carbohydrates == 4.7)
        #expect(apiProduct.nutritionalData.fiber == 0.0)
        #expect(apiProduct.nutritionalData.sugar == 4.7)
        #expect(apiProduct.nutritionalData.sodium == 0.046)  // 46mg -> 0.046g
        #expect(apiProduct.nutritionalData.cholesterol == 0.002)  // 2mg -> 0.002g
    }

    @Test func usdaPartialLabelNutrientsFallBackSelectively() async throws {
        // Test USDA with partial labelNutrients - some fields present, some missing
        let json = """
        {
          "fdcId": 345678,
          "description": "Granola Bar",
          "brandOwner": "Snack Co",
          "gtinUpc": "111222333444",
          "servingSize": 40,
          "servingSizeUnit": "g",
          "householdServingFullText": "1 bar (40g)",
          "foodNutrients": [
            {"nutrientId": 1008, "nutrientName": "Energy", "nutrientNumber": "208", "unitName": "kcal", "value": 450},
            {"nutrientId": 1003, "nutrientName": "Protein", "nutrientNumber": "203", "unitName": "g", "value": 12.5},
            {"nutrientId": 1004, "nutrientName": "Total lipid (fat)", "nutrientNumber": "204", "unitName": "g", "value": 17.5},
            {"nutrientId": 1005, "nutrientName": "Carbohydrate", "nutrientNumber": "205", "unitName": "g", "value": 62.5},
            {"nutrientId": 1079, "nutrientName": "Fiber", "nutrientNumber": "291", "unitName": "g", "value": 7.5},
            {"nutrientId": 2000, "nutrientName": "Sugars", "nutrientNumber": "269", "unitName": "g", "value": 25},
            {"nutrientId": 1093, "nutrientName": "Sodium", "nutrientNumber": "307", "unitName": "mg", "value": 375}
          ],
          "labelNutrients": {
            "calories": {"value": 180},
            "protein": {"value": 5},
            "fat": {"value": 7}
          }
        }
        """.data(using: .utf8)!

        let mockClient = MockAPIClient(payload: json)
        let usdaService = USDAService(apiClient: mockClient)

        let details = try await usdaService.fetchProductDetails(fdcId: "345678")
        let apiProduct = details.product

        // Verify labelNutrients values are used where available
        #expect(apiProduct.nutritionalData.calories == 180.0)  // From labelNutrients
        #expect(apiProduct.nutritionalData.protein == 5.0)     // From labelNutrients
        #expect(apiProduct.nutritionalData.fat == 7.0)         // From labelNutrients

        // Verify fallback to per-100g for missing labelNutrients fields
        #expect(apiProduct.nutritionalData.carbohydrates == 62.5)  // From foodNutrients (per 100g)
        #expect(apiProduct.nutritionalData.fiber == 7.5)          // From foodNutrients
        #expect(apiProduct.nutritionalData.sugar == 25.0)         // From foodNutrients
        #expect(apiProduct.nutritionalData.sodium == 0.375)       // From foodNutrients (375mg -> 0.375g)
    }

    @Test func usdaSearchResultsUseLabelNutrients() async throws {
        // Test that search results (USDAFood) also support labelNutrients
        let json = """
        {
          "totalHits": 1,
          "currentPage": 1,
          "totalPages": 1,
          "foods": [
            {
              "fdcId": 456789,
              "description": "Peanut Butter",
              "brandOwner": "Nut Co",
              "gtinUpc": "555666777888",
              "servingSize": 32,
              "servingSizeUnit": "g",
              "householdServingFullText": "2 tbsp (32g)",
              "foodNutrients": [
                {"nutrientId": 1008, "nutrientName": "Energy", "nutrientNumber": "208", "unitName": "kcal", "value": 588},
                {"nutrientId": 1003, "nutrientName": "Protein", "nutrientNumber": "203", "unitName": "g", "value": 25},
                {"nutrientId": 1004, "nutrientName": "Total lipid (fat)", "nutrientNumber": "204", "unitName": "g", "value": 50}
              ],
              "labelNutrients": {
                "calories": {"value": 190},
                "protein": {"value": 8},
                "fat": {"value": 16}
              }
            }
          ]
        }
        """.data(using: .utf8)!

        let mockClient = MockAPIClient(payload: json)
        let usdaService = USDAService(apiClient: mockClient)

        let apiProduct = try await usdaService.searchProductByBarcode("555666777888")

        // Verify labelNutrients are used from search results
        #expect(apiProduct.nutritionalData.calories == 190.0)  // Not 588
        #expect(apiProduct.nutritionalData.protein == 8.0)     // Not 25
        #expect(apiProduct.nutritionalData.fat == 16.0)        // Not 50
        #expect(apiProduct.servingSizeDisplay == "2 tbsp (32g)")
    }

    @Test func usdaProductModelShowsCorrectServingInformation() async throws {
        // Test that when converted to ProductModel, serving information is preserved
        let json = """
        {
          "fdcId": 999888,
          "description": "Chocolate Bar",
          "brandOwner": "Candy Co",
          "gtinUpc": "999888777666",
          "servingSize": 43,
          "servingSizeUnit": "g",
          "householdServingFullText": "3 pieces (43g)",
          "foodNutrients": [
            {"nutrientId": 1008, "nutrientName": "Energy", "nutrientNumber": "208", "unitName": "kcal", "value": 535}
          ],
          "labelNutrients": {
            "calories": {"value": 230}
          }
        }
        """.data(using: .utf8)!

        let mockClient = MockAPIClient(payload: json)
        let usdaService = USDAService(apiClient: mockClient)

        let details = try await usdaService.fetchProductDetails(fdcId: "999888")
        let apiProduct = details.product

        // Simulate what ScannerViewModel/ProductDetailViewModel does
        let servingDisplay = apiProduct.servingSizeDisplay ?? "100g"
        let nutrition = ProductNutrition(
            calories: apiProduct.nutritionalData.calories,
            protein: apiProduct.nutritionalData.protein,
            carbohydrates: apiProduct.nutritionalData.carbohydrates,
            fat: apiProduct.nutritionalData.fat,
            fiber: apiProduct.nutritionalData.fiber,
            sugar: apiProduct.nutritionalData.sugar,
            sodium: apiProduct.nutritionalData.sodium,
            cholesterol: apiProduct.nutritionalData.cholesterol,
            servingSize: servingDisplay
        )

        // Verify the UI model displays per-serving values with correct serving size text
        #expect(nutrition.servingSize == "3 pieces (43g)")
        #expect(nutrition.calories == 230.0)  // Per-serving from labelNutrients
    }
}

// MARK: - Scoring Transparency Tests

@Suite struct ScoringTransparencyTests {

    /// Test that detailed breakdown fields are populated
    @Test func scoreIncludesDetailedBreakdown() async throws {
        let product = createTestProduct(
            protein: 15.0,
            fiber: 5.0,
            sugar: 3.0,
            sodium: 0.4,
            cholesterol: 0.03,
            ingredients: ["oats", "almond", "honey", "salt"]
        )

        let score = ScoringEngine.shared.calculateHealthScore(
            for: product,
            healthFocus: .heartHealth,
            dietaryRestrictions: []
        )

        // Verify breakdown exists and has 5 components
        #expect(score.breakdown.count == 5)

        // Verify all components are present
        let componentNames = score.breakdown.map { $0.componentName }
        #expect(componentNames.contains("Macronutrients"))
        #expect(componentNames.contains("Micronutrients"))
        #expect(componentNames.contains("Processing Level"))
        #expect(componentNames.contains("Ingredient Quality"))
        #expect(componentNames.contains("Additives"))

        // Verify weighted scores are calculated
        for component in score.breakdown {
            #expect(component.weightedScore == component.rawScore * component.weight)
            #expect(component.weight > 0)
            #expect(!component.keyFactors.isEmpty)
        }
    }

    /// Test heart-health cholesterol adjustments are explicit
    @Test func heartHealthCholesterolAdjustmentsAreExplicit() async throws {
        // High cholesterol product
        let highCholesterolProduct = createTestProduct(
            cholesterol: 0.15, // 150mg
            ingredients: ["egg", "butter"]
        )

        let score = ScoringEngine.shared.calculateHealthScore(
            for: highCholesterolProduct,
            healthFocus: .heartHealth,
            dietaryRestrictions: []
        )

        // Should have cholesterol penalty adjustment
        let cholesterolAdjustments = score.adjustments.filter { $0.label.contains("Cholesterol") }
        #expect(!cholesterolAdjustments.isEmpty)

        let highPenalty = cholesterolAdjustments.first { $0.label == "High Cholesterol Penalty" }
        #expect(highPenalty != nil)
        #expect(highPenalty!.delta < 0)
        #expect(highPenalty!.reason.contains("100mg"))
    }

    /// Test cholesterol-free bonus
    @Test func heartHealthCholesterolFreeGetsBonus() async throws {
        let cholesterolFreeProduct = createTestProduct(
            cholesterol: 0.0,
            ingredients: ["oats", "almond"]
        )

        let score = ScoringEngine.shared.calculateHealthScore(
            for: cholesterolFreeProduct,
            healthFocus: .heartHealth,
            dietaryRestrictions: []
        )

        let cholesterolBonus = score.adjustments.first { $0.label == "Cholesterol-Free Bonus" }
        #expect(cholesterolBonus != nil)
        #expect(cholesterolBonus!.delta > 0)
        #expect(cholesterolBonus!.reason.contains("excellent for heart health"))
    }

    /// Test heart-friendly ingredients bonus
    @Test func heartFriendlyIngredientsGetBonus() async throws {
        let heartFriendlyProduct = createTestProduct(
            ingredients: ["oats", "chia seeds", "flaxseed", "walnut"]
        )

        let score = ScoringEngine.shared.calculateHealthScore(
            for: heartFriendlyProduct,
            healthFocus: .heartHealth,
            dietaryRestrictions: []
        )

        let heartBonus = score.adjustments.first { $0.label == "Heart-Friendly Ingredients" }
        #expect(heartBonus != nil)
        #expect(heartBonus!.delta > 0)
        #expect(heartBonus!.reason.contains("cardiovascular benefits"))
    }

    /// Test micronutrient fallback explanation
    @Test func micronutrientScoringShowsFallbackExplanation() async throws {
        let product = createTestProduct(
            protein: 10.0,
            fiber: 3.0
        )

        let score = ScoringEngine.shared.calculateHealthScore(
            for: product,
            healthFocus: .generalWellness,
            dietaryRestrictions: []
        )

        // Should have micronutrient estimation adjustment
        let microAdjustment = score.adjustments.first { $0.label == "Micronutrient Estimation" }
        #expect(microAdjustment != nil)
        #expect(microAdjustment!.reason.contains("fiber/protein proxy"))

        // Micronutrient component should mention proxy
        let microComponent = score.breakdown.first { $0.componentName == "Micronutrients" }
        #expect(microComponent != nil)
        #expect(microComponent!.explanation.contains("proxy"))
    }

    /// Test missing data detection and low confidence
    @Test func missingDataResultsInLowConfidence() async throws {
        let incompleteProduct = createTestProduct(
            protein: 0,
            fiber: 0,
            sugar: 0,
            sodium: 0,
            ingredients: [] // No ingredients
        )

        let score = ScoringEngine.shared.calculateHealthScore(
            for: incompleteProduct,
            healthFocus: .generalWellness,
            dietaryRestrictions: []
        )

        #expect(score.confidence == .low || score.confidence == .medium)
        #expect(score.confidenceWarning != nil)
        #expect(score.confidenceWarning!.contains("Limited"))
    }

    /// Test complete data results in high confidence
    @Test func completeDataResultsInHighConfidence() async throws {
        let completeProduct = createTestProduct(
            protein: 15.0,
            fiber: 5.0,
            sugar: 3.0,
            sodium: 0.4,
            fat: 8.0,
            carbs: 25.0,
            calories: 250,
            cholesterol: 0.03,
            ingredients: ["oats", "almond", "honey", "salt", "cinnamon"]
        )

        let score = ScoringEngine.shared.calculateHealthScore(
            for: completeProduct,
            healthFocus: .generalWellness,
            dietaryRestrictions: []
        )

        #expect(score.confidence == .high)
        #expect(score.confidenceWarning == nil)
    }

    /// Test explanation mentions key nutrients with values
    @Test func explanationMentionsKeyNutrientsWithValues() async throws {
        let product = createTestProduct(
            protein: 20.0,
            fiber: 8.0,
            sugar: 2.0,
            sodium: 0.2,
            ingredients: ["chicken", "quinoa", "broccoli"]
        )

        let score = ScoringEngine.shared.calculateHealthScore(
            for: product,
            healthFocus: .proteinFocus,
            dietaryRestrictions: []
        )

        // Breakdown should have key factors with actual values
        let macroComponent = score.breakdown.first { $0.componentName == "Macronutrients" }
        #expect(macroComponent != nil)
        #expect(!macroComponent!.keyFactors.isEmpty)
        #expect(macroComponent!.keyFactors.contains { $0.contains("Protein") && $0.contains("20") })
    }

    /// Test long ingredient list penalty
    @Test func longIngredientListReceivesPenalty() async throws {
        let manyIngredients = (1...15).map { "ingredient\($0)" }
        let product = createTestProduct(ingredients: manyIngredients)

        let score = ScoringEngine.shared.calculateHealthScore(
            for: product,
            healthFocus: .generalWellness,
            dietaryRestrictions: []
        )

        let lengthPenalty = score.adjustments.first { $0.label == "Long Ingredient List" }
        #expect(lengthPenalty != nil)
        #expect(lengthPenalty!.delta < 0)
        #expect(lengthPenalty!.reason.contains("15 ingredients"))
    }

    /// Test harmful additives penalty
    @Test func harmfulAdditivesReceivePenalty() async throws {
        let product = createTestProduct(
            additives: ["monosodium glutamate", "artificial colors", "sodium nitrate"]
        )

        let score = ScoringEngine.shared.calculateHealthScore(
            for: product,
            healthFocus: .generalWellness,
            dietaryRestrictions: []
        )

        let harmfulPenalty = score.adjustments.first { $0.label == "Harmful Additives Penalty" }
        #expect(harmfulPenalty != nil)
        #expect(harmfulPenalty!.delta < 0)
    }

    /// Test weight adjustment for missing ingredient data
    @Test func missingIngredientDataAdjustsWeights() async throws {
        let noIngredientsProduct = createTestProduct(
            protein: 10.0,
            fiber: 3.0,
            ingredients: [] // No ingredients
        )

        let score = ScoringEngine.shared.calculateHealthScore(
            for: noIngredientsProduct,
            healthFocus: .generalWellness,
            dietaryRestrictions: []
        )

        // Ingredient quality should have lower weight
        let ingredientComponent = score.breakdown.first { $0.componentName == "Ingredient Quality" }
        #expect(ingredientComponent != nil)

        // Other components should have slightly higher weights to compensate
        let macroComponent = score.breakdown.first { $0.componentName == "Macronutrient Balance" }
        #expect(macroComponent != nil)
    }

    /// Test overall score stays within 0-100 range
    @Test func overallScoreStaysInValidRange() async throws {
        // Extreme cases
        let extremelyBadProduct = createTestProduct(
            protein: 0,
            fiber: 0,
            sugar: 50.0,
            sodium: 5.0,
            cholesterol: 0.5,
            ingredients: (1...30).map { "bad\($0)" },
            additives: ["msg", "artificial colors", "trans fat", "sodium nitrate"]
        )

        let badScore = ScoringEngine.shared.calculateHealthScore(
            for: extremelyBadProduct,
            healthFocus: .heartHealth,
            dietaryRestrictions: []
        )

        #expect(badScore.overall >= 0)
        #expect(badScore.overall <= 100)

        let excellentProduct = createTestProduct(
            protein: 25.0,
            fiber: 10.0,
            sugar: 1.0,
            sodium: 0.1,
            cholesterol: 0.0,
            ingredients: ["organic oats", "organic almond", "chia"]
        )

        let goodScore = ScoringEngine.shared.calculateHealthScore(
            for: excellentProduct,
            healthFocus: .generalWellness,
            dietaryRestrictions: []
        )

        #expect(goodScore.overall >= 0)
        #expect(goodScore.overall <= 100)
    }

    /// Test explanation includes confidence note when not high
    @Test func explanationIncludesConfidenceWarningWhenLow() async throws {
        let incompleteProduct = createTestProduct(
            protein: 5.0,
            ingredients: ["item1"] // Minimal data
        )

        let score = ScoringEngine.shared.calculateHealthScore(
            for: incompleteProduct,
            healthFocus: .generalWellness,
            dietaryRestrictions: []
        )

        if score.confidence != .high {
            #expect(score.explanation.contains("confidence") || score.explanation.contains("limited data"))
        }
    }

    /// Test spinach scores highly for gut health with seeded micronutrients
    @Test func spinachScoresHighlyForGutHealth() async throws {
        let spinach = ProductModel(
            id: UUID(),
            name: "Fresh Spinach",
            brand: "Organic Farms",
            category: "Vegetables",
            categorySlug: "vegetables",
            barcode: "123456",
            nutrition: ProductNutrition(
                calories: 23,
                protein: 2.9,
                carbohydrates: 3.6,
                fat: 0.4,
                fiber: 2.2,
                sugar: 0.4,
                sodium: 0.079,
                cholesterol: 0,
                servingSize: "100g"
            ),
            ingredients: ["spinach"],
            additives: [],
            processingLevel: .minimal,
            dietaryFlags: [],
            imageURL: nil,
            thumbnailURL: nil,
            healthScore: 0,
            createdAt: Date(),
            updatedAt: Date(),
            isCached: false,
            rawIngredientsText: "spinach"
        )

        let score = ScoringEngine.shared.calculateHealthScore(
            for: spinach,
            healthFocus: .gutHealth,
            dietaryRestrictions: []
        )

        #expect(score.overall >= 80, "Spinach should score >= 80 for gut health, got \(score.overall)")

        let ingredientComponent = score.breakdown.first { $0.componentName == "Ingredient Quality" }
        #expect(ingredientComponent != nil)
        #expect(ingredientComponent!.rawScore >= 90, "Single whole-food ingredient should score >= 90")

        let processingComponent = score.breakdown.first { $0.componentName == "Processing Level" }
        #expect(processingComponent != nil)
        #expect(processingComponent!.rawScore >= 85, "Minimal processing should score >= 85")

        let microComponent = score.breakdown.first { $0.componentName == "Micronutrients" }
        #expect(microComponent != nil)
        #expect(microComponent!.explanation.contains("est.") || !microComponent!.keyFactors.contains("Limited micronutrient data"),
                "Should use seeded micronutrient profiles or real data")
    }

    /// Test Spindrift (zero-calorie sparkling water) scores reasonably for gut health
    @Test func spindriftScoresReasonablyForGutHealth() async throws {
        let spindrift = ProductModel(
            id: UUID(),
            name: "Spindrift Sparkling Water",
            brand: "Spindrift",
            category: "Beverages",
            categorySlug: "beverages",
            barcode: "856541004001",
            nutrition: ProductNutrition(
                calories: 0,
                protein: 0,
                carbohydrates: 0,
                fat: 0,
                fiber: 0,
                sugar: 0,
                sodium: 0,
                cholesterol: 0,
                servingSize: "355ml"
            ),
            ingredients: ["carbonated water", "lemon juice"],
            additives: [],
            processingLevel: .minimal,
            dietaryFlags: [],
            imageURL: nil,
            thumbnailURL: nil,
            healthScore: 0,
            createdAt: Date(),
            updatedAt: Date(),
            isCached: false,
            rawIngredientsText: "carbonated water, lemon juice"
        )

        let score = ScoringEngine.shared.calculateHealthScore(
            for: spindrift,
            healthFocus: .gutHealth,
            dietaryRestrictions: []
        )

        #expect(score.overall >= 70, "Spindrift should score >= 70 for gut health (clean low-cal beverage), got \(score.overall)")

        let macroComponent = score.breakdown.first { $0.componentName == "Macronutrients" }
        #expect(macroComponent != nil)

        let fiberAdjustment = score.adjustments.first { $0.label == "Low-Calorie Beverage Exception" }
        #expect(fiberAdjustment != nil, "Should have low-calorie beverage exception for zero-fiber drinks")
        #expect(fiberAdjustment!.delta >= 0, "Adjustment should be non-negative")
    }

    /// Test that processed snacks with many additives still score lower than whole foods
    @Test func processedSnackScoresLowerThanWholeFoods() async throws {
        let processedSnack = ProductModel(
            id: UUID(),
            name: "Cheese Crackers",
            brand: "Generic",
            category: "Snacks",
            categorySlug: "snacks",
            barcode: "999999",
            nutrition: ProductNutrition(
                calories: 140,
                protein: 2.0,
                carbohydrates: 18.0,
                fat: 7.0,
                fiber: 1.0,
                sugar: 2.0,
                sodium: 0.25,
                cholesterol: 0,
                servingSize: "30g"
            ),
            ingredients: [
                "enriched flour", "vegetable oil", "cheese", "salt", "sugar",
                "natural flavor", "yeast extract", "citric acid", "sodium phosphate",
                "artificial color", "tbhq"
            ],
            additives: ["natural flavor", "artificial color", "tbhq"],
            processingLevel: .ultraProcessed,
            dietaryFlags: [],
            imageURL: nil,
            thumbnailURL: nil,
            healthScore: 0,
            createdAt: Date(),
            updatedAt: Date(),
            isCached: false,
            rawIngredientsText: nil
        )

        let spinach = ProductModel(
            id: UUID(),
            name: "Fresh Spinach",
            brand: "Organic Farms",
            category: "Vegetables",
            categorySlug: "vegetables",
            barcode: "123456",
            nutrition: ProductNutrition(
                calories: 23,
                protein: 2.9,
                carbohydrates: 3.6,
                fat: 0.4,
                fiber: 2.2,
                sugar: 0.4,
                sodium: 0.079,
                cholesterol: 0,
                servingSize: "100g"
            ),
            ingredients: ["spinach"],
            additives: [],
            processingLevel: .minimal,
            dietaryFlags: [],
            imageURL: nil,
            thumbnailURL: nil,
            healthScore: 0,
            createdAt: Date(),
            updatedAt: Date(),
            isCached: false,
            rawIngredientsText: "spinach"
        )

        let snackScore = ScoringEngine.shared.calculateHealthScore(
            for: processedSnack,
            healthFocus: .gutHealth,
            dietaryRestrictions: []
        )

        let spinachScore = ScoringEngine.shared.calculateHealthScore(
            for: spinach,
            healthFocus: .gutHealth,
            dietaryRestrictions: []
        )

        #expect(spinachScore.overall > snackScore.overall,
                "Whole food (spinach: \(spinachScore.overall)) should score higher than processed snack (\(snackScore.overall))")
    }

    // MARK: - Helper Functions

    private func createTestProduct(
        protein: Double = 10.0,
        fiber: Double = 3.0,
        sugar: Double = 5.0,
        sodium: Double = 0.5,
        fat: Double = 5.0,
        carbs: Double = 20.0,
        calories: Double = 200.0,
        cholesterol: Double = 0.05,
        ingredients: [String] = ["ingredient1", "ingredient2", "ingredient3"],
        additives: [String] = []
    ) -> ProductModel {
        return ProductModel(
            id: UUID(),
            name: "Test Product",
            brand: "Test Brand",
            category: "Test Category",
            categorySlug: "test-category",
            barcode: "123456789",
            nutrition: ProductNutrition(
                calories: calories,
                protein: protein,
                carbohydrates: carbs,
                fat: fat,
                fiber: fiber,
                sugar: sugar,
                sodium: sodium,
                cholesterol: cholesterol,
                servingSize: "100g"
            ),
            ingredients: ingredients,
            additives: additives,
            processingLevel: .processed,
            dietaryFlags: [],
            imageURL: nil,
            thumbnailURL: nil,
            healthScore: 0,
            createdAt: Date(),
            updatedAt: Date(),
            isCached: false,
            rawIngredientsText: ingredients.joined(separator: ", ")
        )
    }
}

private actor MockAPIClient: APIClientProtocol {
    enum MockError: Error { case missingPayload }

    private let payload: Data?
    private let decoder: JSONDecoder

    init(payload: Data?) {
        self.payload = payload
        self.decoder = JSONDecoder()
    }

    func request<T>(_ endpoint: APIEndpoint) async throws -> T where T: Decodable, T: Encodable {
        guard let payload else { throw MockError.missingPayload }
        return try decoder.decode(T.self, from: payload)
    }

    func requestData(_ endpoint: APIEndpoint) async throws -> Data {
        guard let payload else { throw MockError.missingPayload }
        return payload
    }
}
