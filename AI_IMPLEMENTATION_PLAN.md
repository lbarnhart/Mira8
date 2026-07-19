# Mira AI Feature Implementation Plan

> **Document Purpose**: This is the master planning document for incorporating AI into the Mira health app. It captures our strategic thinking, technical decisions, implementation progress, and serves as a reference for future development sessions.
>
> **Last Updated**: January 21, 2026

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Strategic Context](#strategic-context)
3. [Progress Tracker](#progress-tracker)
4. [Infrastructure Setup (Completed)](#infrastructure-setup-completed)
5. [Feature #1: LLM Ingredient Analysis](#feature-1-llm-powered-ingredient-analysis)
6. [Feature #2: Natural Language Product Search](#feature-2-natural-language-product-search)
7. [Feature #3: Smart Dietary Violation Detection](#feature-3-smart-dietary-violation-detection)
8. [Feature #4: Personalized Recommendations](#feature-4-personalized-recommendations)
9. [Feature #5: Product Image Recognition](#feature-5-product-image-recognition)
10. [Technical Reference](#technical-reference)
11. [Cost Projections](#cost-projections)
12. [Open Questions & Decisions](#open-questions--decisions)

---

## Executive Summary

### What We're Building
Mira is a health-focused grocery scanner app. We're adding AI capabilities to transform it from a "product evaluator" into a "personal health AI assistant."

### Why AI?
The current app uses rule-based systems (hardcoded ingredient databases, substring matching for allergens). AI will enable:
- **Smarter ingredient analysis** - Research-backed explanations for any ingredient
- **Better allergen detection** - Catch hidden dairy derivatives, cross-contamination warnings
- **Natural language search** - "Find me high-protein vegan snacks"
- **Personalized recommendations** - Based on user's scan history and nutritional gaps
- **Image recognition** - Identify products without barcodes

### Implementation Priority

| Rank | Feature | Why This Order | Status |
|------|---------|---------------|--------|
| 1 | LLM Ingredient Analysis | Lowest risk, immediate value, proves AI works | **Next Up** |
| 2 | Natural Language Search | Builds on #1, enables new user behavior | Planned |
| 3 | Smart Dietary Detection | Safety-critical, high user trust impact | Planned |
| 4 | Personalized Recommendations | Requires scan history, transforms app value | Planned |
| 5 | Product Image Recognition | Highest complexity, highest "wow factor" | Planned |

### Key Decision: Claude as AI Provider
We chose Anthropic's Claude API because:
- **Quality**: Best-in-class for nuanced health/nutrition information
- **Safety**: Strong content safety, important for health advice
- **Pricing**: Haiku model is cost-effective for high-volume features
- **Vision**: Built-in image analysis for future image recognition feature
- **Developer experience**: Clean API, good documentation

---

## Strategic Context

### Current App Architecture

Mira is a SwiftUI iOS app with:
- **Barcode scanning** via AVFoundation
- **Product data** from USDA API + Open Food Facts
- **Health scoring** via custom 5-pillar scoring pipeline (HealthScoringPipeline)
- **User preferences**: Health focus (gut health, weight loss, etc.) + dietary restrictions
- **Persistence**: CoreData for products, scan history, favorites

### Why These 5 Features?

After analyzing the codebase and user experience, we identified these features based on:

1. **User pain points**:
   - Unknown ingredients show as "Unknown" (no explanation)
   - Allergen detection misses derivatives (casein, whey, etc.)
   - No way to search for products matching criteria
   - Same recommendations for all users regardless of history
   - Can't scan products without visible barcodes

2. **Technical readiness**:
   - We have user health focus + dietary restrictions
   - We have scan history data
   - Existing scoring pipeline can incorporate AI insights
   - Architecture supports adding new services

3. **Business impact**:
   - Ingredient analysis = every scan becomes more valuable
   - Search = new engagement vector
   - Dietary detection = builds trust (safety)
   - Personalization = retention driver
   - Image recognition = differentiation

### Thought Process: Why This Implementation Order?

**Feature #1 (Ingredient Analysis) first because:**
- Simplest integration (add a service, call on tap)
- Immediate value (users see results on first use)
- Low risk (doesn't change core flows)
- Proves AI infrastructure works
- Teaches us about API costs, latency, prompt engineering

**Feature #2 (Search) second because:**
- Builds on #1's infrastructure
- Natural progression (analysis → discovery)
- Can soft-launch without replacing existing flows

**Feature #3 (Dietary Detection) third because:**
- Higher stakes (safety-critical)
- Needs proven infrastructure from #1-2
- More complex prompts, needs prompt engineering experience

**Feature #4 (Personalization) fourth because:**
- Requires accumulated scan history
- More complex data aggregation
- Changes core recommendation flow

**Feature #5 (Image Recognition) last because:**
- Highest complexity
- Vision API is more expensive
- Requires camera UI changes
- Can be a v2.0 differentiator

---

## Progress Tracker

### Completed Tasks ✅

- [x] **Strategic planning** - Analyzed codebase, identified 5 AI features, prioritized by value/complexity
- [x] **Anthropic account setup** - Created account at console.anthropic.com
- [x] **API key obtained** - Generated Claude API key
- [x] **Infrastructure: Configuration** - Added `ClaudeAPIKey` to AppConfiguration.swift
- [x] **Infrastructure: Constants** - Added `Constants.Claude` with API settings
- [x] **Infrastructure: API Endpoint** - Created ClaudeEndpoint.swift with request/response models
- [x] **Infrastructure: Service Wrapper** - Created ClaudeService.swift with caching
- [x] **Security: API key storage** - Moved key to Configuration.plist (gitignored)
- [x] **Security: .gitignore updated** - Configuration.plist properly excluded
- [x] **Infrastructure: USDA API Key** - Added `USDAAPIKey` to Configuration.plist (January 21, 2026)
- [x] **Bug Fix: Build Errors** - Fixed multiple build errors in scoring system (January 21, 2026)
- [x] **Bug Fix: History Score Mismatch** - Fixed score inconsistency between product detail and history views (January 21, 2026)

### In Progress 🔄

- [x] **Feature #1: Ingredient Analysis** - Core implementation complete (Week 1)
  - [x] Created `AIIngredientAnalysis.swift` model
  - [x] Created `IngredientAIService.swift` service
  - [x] Created `IngredientAIAnalysisSheet.swift` view
  - [x] Added "Get AI Analysis" button to ingredient detail sheet
  - [ ] Test on device with real API calls
  - [ ] Add error handling for edge cases
  - [ ] Polish UI and loading states

### Upcoming 📋

- [ ] Feature #2: Natural Language Search
- [ ] Feature #3: Smart Dietary Detection
- [ ] Feature #4: Personalized Recommendations
- [ ] Feature #5: Image Recognition

---

## Infrastructure Setup (Completed)

### Files Created/Modified

| File | Purpose | Status |
|------|---------|--------|
| `Mira/Core/Network/ClaudeEndpoint.swift` | API endpoint definition, request/response models | ✅ Created |
| `Mira/Core/Services/ClaudeService.swift` | Shared service for all Claude API calls | ✅ Created |
| `Mira/Core/Utils/Constants.swift` | Added `Constants.Claude` struct | ✅ Modified |
| `Mira/Core/Utils/AppConfiguration.swift` | Added `claudeAPIKey` property | ✅ Modified |
| `Mira/App/Configuration/Configuration.plist` | Stores actual API key (gitignored) | ✅ Created |
| `Mira/App/Configuration/Configuration.sample.plist` | Template for other developers | ✅ Modified |
| `.gitignore` | Added Configuration.plist path | ✅ Modified |

### ClaudeService API Reference

```swift
// Shared singleton
ClaudeService.shared

// Check if configured
if ClaudeService.shared.isConfigured { ... }

// Simple text completion
let response = try await ClaudeService.shared.complete(
    prompt: "What is carrageenan?",
    systemPrompt: "You are a nutrition expert.",
    model: .haiku,  // or .sonnet for complex tasks
    maxTokens: 1024,
    cacheKey: "optional_cache_key"  // enables 7-day response caching
)

// JSON completion (auto-parses response)
struct IngredientInfo: Codable {
    let safetyRating: String
    let explanation: String
}

let info: IngredientInfo = try await ClaudeService.shared.completeJSON(
    prompt: "Analyze maltodextrin. Return JSON with safetyRating and explanation.",
    systemPrompt: "You are a nutrition expert. Return valid JSON only.",
    cacheKey: "ingredient_maltodextrin"
)

// Image analysis (for Feature #5)
let description = try await ClaudeService.shared.analyzeImage(
    imageData: jpegData,
    prompt: "Identify the food product in this image.",
    systemPrompt: "You are a product identification expert."
)
```

### Configuration Setup Instructions

For developers setting up the project:

1. Copy the sample config:
   ```bash
   cp App/Configuration/Configuration.sample.plist Mira/Resources/Configuration.plist
   ```

2. Get an API key from [console.anthropic.com](https://console.anthropic.com)

3. Add your key to Configuration.plist:
   ```xml
   <key>ClaudeAPIKey</key>
   <string>&lt;CLAUDE_API_KEY&gt;</string>
   ```

4. Verify Configuration.plist is in .gitignore (it should be)

---

## Feature #1: LLM-Powered Ingredient Analysis

### Overview
Replace the hardcoded ingredient database with an LLM that provides real-time, research-backed ingredient safety assessments contextualized to the user's health focus.

### User Experience

**Current Flow:**
```
User sees ingredient "carrageenan" → App shows "Unknown" or generic "Additive"
```

**New Flow:**
```
User taps ingredient "carrageenan" →
  "Carrageenan is a seaweed-derived thickener. For gut health, some studies
   suggest it may cause inflammation in sensitive individuals. Consider
   alternatives if you have digestive issues."

   Safety: ⚠️ Caution
   Confidence: High
```

### Technical Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    ProductDetailView                             │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Ingredients Tab                                          │    │
│  │  • Water ℹ️                                              │    │
│  │  • Organic Cane Sugar ℹ️                                 │    │
│  │  • Carrageenan ℹ️  ← User taps                          │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                 IngredientAIService                              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ func analyzeIngredient(                                  │    │
│  │     name: String,                                        │    │
│  │     healthFocus: HealthFocus,                            │    │
│  │     dietaryRestrictions: [DietaryRestriction]            │    │
│  │ ) async -> IngredientAnalysis                            │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   ClaudeService (Haiku)                          │
│  System Prompt: "You are a nutrition expert..."                  │
│  User Prompt: "Analyze {ingredient} for someone focused on       │
│               {healthFocus} with restrictions: {restrictions}"   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              ClaudeResponseCache (in-memory, 7-day TTL)          │
│  Cache key: "{ingredient}_{healthFocus}" → reduces API costs     │
└─────────────────────────────────────────────────────────────────┘
```

### Data Models

```swift
// New file: Mira/Core/Models/IngredientAnalysis.swift

struct IngredientAnalysis: Codable {
    let ingredientName: String
    let healthFocus: String
    let safetyRating: SafetyRating      // safe, caution, avoid
    let summary: String                  // 1-2 sentence summary
    let detailedExplanation: String      // Full explanation
    let researchContext: String?         // "Studies suggest..."
    let relevantRestrictions: [String]   // Which dietary restrictions it affects
    let alternatives: [String]?          // Suggested alternatives
    let confidence: Double               // 0-1 confidence score

    enum SafetyRating: String, Codable {
        case safe = "safe"
        case caution = "caution"
        case avoid = "avoid"
    }
}
```

### Service Implementation

```swift
// New file: Mira/Core/Services/IngredientAIService.swift

import Foundation

actor IngredientAIService {
    static let shared = IngredientAIService()

    private let claudeService = ClaudeService.shared

    func analyzeIngredient(
        name: String,
        healthFocus: HealthFocus,
        dietaryRestrictions: [DietaryRestriction]
    ) async throws -> IngredientAnalysis {

        let cacheKey = "ingredient_\(name.lowercased())_\(healthFocus.rawValue)"

        let systemPrompt = """
        You are a nutrition scientist assistant for the Mira health app. Your role is to
        analyze food ingredients and provide accurate, research-backed assessments.

        Guidelines:
        - Be factual and cite research when available
        - Tailor advice to the user's specific health focus
        - Flag ingredients that conflict with dietary restrictions
        - Use accessible language (8th grade reading level)
        - Be balanced - don't fear-monger but don't dismiss legitimate concerns
        - If evidence is mixed or inconclusive, say so

        Response format (JSON only, no markdown):
        {
            "ingredientName": "the ingredient name",
            "healthFocus": "the health focus",
            "safetyRating": "safe" | "caution" | "avoid",
            "summary": "1-2 sentence summary",
            "detailedExplanation": "2-3 paragraph explanation",
            "researchContext": "What studies say (optional, can be null)",
            "relevantRestrictions": ["list of affected dietary restrictions"],
            "alternatives": ["healthier alternatives if applicable"],
            "confidence": 0.0-1.0
        }
        """

        let restrictionsList = dietaryRestrictions.map { $0.rawValue }.joined(separator: ", ")

        let userPrompt = """
        Analyze this ingredient: "\(name)"

        User's health focus: \(healthFocus.displayName)
        User's dietary restrictions: \(restrictionsList.isEmpty ? "None" : restrictionsList)

        Provide your analysis in the specified JSON format.
        """

        return try await claudeService.completeJSON(
            prompt: userPrompt,
            systemPrompt: systemPrompt,
            model: .haiku,
            cacheKey: cacheKey
        )
    }
}
```

### UI Integration

```swift
// Modify: Mira/Features/ProductDetail/Views/ProductIngredientsView.swift

// Add tap gesture to ingredient rows
struct IngredientRow: View {
    let ingredient: String
    @State private var showingAnalysis = false
    @State private var analysis: IngredientAnalysis?
    @State private var isLoading = false
    @State private var error: Error?

    @EnvironmentObject var userPreferences: UserPreferences

    var body: some View {
        Button(action: { showingAnalysis = true }) {
            HStack {
                Text(ingredient)
                Spacer()
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingAnalysis) {
            IngredientAnalysisSheet(
                ingredient: ingredient,
                analysis: analysis,
                isLoading: isLoading,
                error: error
            )
            .task {
                await loadAnalysis()
            }
        }
    }

    private func loadAnalysis() async {
        guard analysis == nil else { return }

        isLoading = true
        error = nil

        do {
            analysis = try await IngredientAIService.shared.analyzeIngredient(
                name: ingredient,
                healthFocus: userPreferences.healthFocus,
                dietaryRestrictions: userPreferences.dietaryRestrictions
            )
        } catch {
            self.error = error
        }

        isLoading = false
    }
}

// New file: Mira/Features/ProductDetail/Views/IngredientAnalysisSheet.swift

struct IngredientAnalysisSheet: View {
    let ingredient: String
    let analysis: IngredientAnalysis?
    let isLoading: Bool
    let error: Error?

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView("Analyzing ingredient...")
                        .padding(.top, 100)
                } else if let error = error {
                    ErrorView(error: error)
                } else if let analysis = analysis {
                    AnalysisContent(analysis: analysis)
                }
            }
            .navigationTitle(ingredient)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct AnalysisContent: View {
    let analysis: IngredientAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Safety badge
            SafetyBadge(rating: analysis.safetyRating)

            // Summary
            Text(analysis.summary)
                .font(.headline)

            // Detailed explanation
            Text(analysis.detailedExplanation)
                .font(.body)

            // Research context (if available)
            if let research = analysis.researchContext {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Research", systemImage: "book")
                        .font(.subheadline.bold())
                    Text(research)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Alternatives (if any)
            if let alternatives = analysis.alternatives, !alternatives.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Alternatives", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline.bold())
                    ForEach(alternatives, id: \.self) { alt in
                        Text("• \(alt)")
                            .font(.caption)
                    }
                }
            }

            // Confidence indicator
            ConfidenceIndicator(confidence: analysis.confidence)
        }
        .padding()
    }
}

struct SafetyBadge: View {
    let rating: IngredientAnalysis.SafetyRating

    var color: Color {
        switch rating {
        case .safe: return .green
        case .caution: return .orange
        case .avoid: return .red
        }
    }

    var icon: String {
        switch rating {
        case .safe: return "checkmark.circle.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .avoid: return "xmark.circle.fill"
        }
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(rating.rawValue.capitalized)
                .fontWeight(.semibold)
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}
```

### Implementation Checklist

**Week 1: Core Service**
- [ ] Create `IngredientAnalysis.swift` model
- [ ] Create `IngredientAIService.swift` service
- [ ] Test API calls with sample ingredients
- [ ] Verify caching works correctly
- [ ] Handle error cases (API down, rate limited, etc.)

**Week 2: UI Integration**
- [ ] Create `IngredientAnalysisSheet.swift`
- [ ] Modify `ProductIngredientsView.swift` to add tap targets
- [ ] Add loading states
- [ ] Add error handling UI
- [ ] Test on device

**Week 3: Polish & Testing**
- [ ] Add analytics tracking (ingredient taps, AI responses)
- [ ] Test with variety of ingredients (common, obscure, controversial)
- [ ] Tune prompts based on response quality
- [ ] Performance optimization
- [ ] Edge case handling (empty ingredients, special characters)

### Success Metrics
- Ingredient tap rate: >20% of users tap at least one ingredient
- User satisfaction: >4.0 rating on ingredient explanations (if we add feedback)
- API cost per user: <$0.05/month
- Response latency: <2 seconds average

### Cost Estimation

| Model | Cost per 1K tokens | Avg tokens/request | Cost per analysis |
|-------|-------------------|-------------------|-------------------|
| Claude Haiku | $0.00025 input, $0.00125 output | ~500 | ~$0.001 |
| Claude Sonnet | $0.003 input, $0.015 output | ~500 | ~$0.01 |

**Projected Monthly Costs (with caching):**
- 1,000 users × 10 scans × 3 ingredients = 30,000 analyses
- With 80% cache hit rate = 6,000 API calls
- Haiku: ~$6/month
- Sonnet: ~$60/month

**Decision: Use Haiku** - Sufficient quality for ingredient analysis, 10x cheaper

---

## Feature #2: Natural Language Product Search

### Overview
Allow users to search for products using natural language queries like "high protein vegan snacks under 200 calories" instead of category browsing.

### User Experience

**New Flow:**
```
User types: "gluten free breakfast cereals with low sugar"
           ↓
AI parses: { categories: ["cereals"], dietaryLabels: ["gluten-free"], sugarMax: 5 }
           ↓
App shows: Filtered results from Open Food Facts
           ranked by relevance to query + health score
```

### Technical Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     SearchView (New Tab)                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 🔍 "high protein vegan snacks"                          │    │
│  └─────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Suggested: "under 200 calories" "gluten free"           │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                 ProductSearchAIService                           │
│  1. Parse natural language → structured query (Claude)           │
│  2. Call Open Food Facts / USDA with filters                     │
│  3. Re-rank results by health score                              │
│  4. Return top 20 products                                       │
└─────────────────────────────────────────────────────────────────┘
```

### Data Models

```swift
struct ProductSearchQuery: Codable {
    let rawQuery: String
    let categories: [String]?
    let nutritionFilters: NutritionFilters?
    let dietaryLabels: [String]?
    let excludeIngredients: [String]?
    let sortBy: SortOption

    struct NutritionFilters: Codable {
        var caloriesMin: Double?
        var caloriesMax: Double?
        var proteinMin: Double?
        var proteinMax: Double?
        var sugarMax: Double?
        var fiberMin: Double?
        var sodiumMax: Double?
    }

    enum SortOption: String, Codable {
        case relevance
        case healthScore
        case proteinHighest
        case caloriesLowest
        case sugarLowest
    }
}
```

### Implementation Checklist

**Week 1: Query Parsing**
- [ ] Create `ProductSearchQuery` model
- [ ] Create `ProductSearchAIService` with Claude query parsing
- [ ] Define mapping: common terms → structured filters
- [ ] Add fallback for failed parsing (direct text search)

**Week 2: Search Integration**
- [ ] Extend `OpenFoodFactsService` with advanced filters
- [ ] Implement result scoring and ranking by health score
- [ ] Add search result caching

**Week 3: UI & Polish**
- [ ] Create `ProductSearchView`
- [ ] Add to tab bar (or as modal from home)
- [ ] Implement search history and suggestions
- [ ] Add voice search (iOS Speech framework) - stretch goal

### Success Metrics
- Search usage: >30% of users use search within first week
- Search success rate: >70% of searches return relevant results
- Conversion: >40% of searches lead to product detail view

---

## Feature #3: Smart Dietary Violation Detection

### Overview
Replace simple substring matching with AI-powered allergen and dietary violation detection that understands ingredient variations, hidden sources, and cross-contamination warnings.

### The Problem

**Current System Misses:**
```
"Contains milk" statement in allergen section (not in ingredients)
"Casein" (milk derivative) - not in substring list
"May contain traces of peanuts" - cross-contamination
"Natural flavors (contains dairy)" - hidden in parentheses
"Whey protein isolate" - milk-derived
```

### User Experience

**New Flow:**
```
User with "Dairy-Free" restriction scans product
           ↓
AI analyzes: Ingredients + Allergen statements + Manufacturing info
           ↓
Result:
  ⚠️ DAIRY DETECTED
  - "Casein" is a milk protein (line 5 of ingredients)
  - Allergen statement: "Contains milk"
  - Confidence: 98%

  ℹ️ CROSS-CONTAMINATION WARNING
  - "Manufactured in facility that processes milk"
  - Risk level: Low (separate equipment stated)
```

### Key Design Decision: Use Sonnet

This feature is **safety-critical**. A false negative (missing an allergen) could harm users. We'll use Claude Sonnet for higher accuracy despite the higher cost.

### Implementation Checklist

**Week 1: Core Detection Service**
- [ ] Create `DietaryViolationReport` model
- [ ] Create `DietaryViolationAIService`
- [ ] Build comprehensive derivative ingredient knowledge into prompts
- [ ] Implement confidence scoring

**Week 2: Integration & UI**
- [ ] Add violation check to product scan flow
- [ ] Create `DietaryViolationBanner` component
- [ ] Add detailed violation explanation sheet

**Week 3-4: Testing & Validation**
- [ ] Build test suite with known violating products
- [ ] A/B test against current substring matching
- [ ] Add user feedback mechanism ("Was this accurate?")
- [ ] Handle products with missing ingredient data

### Success Metrics
- Detection accuracy: >95% (vs current ~70%)
- False positive rate: <5%
- User trust: >90% report violations as accurate

---

## Feature #4: Personalized Recommendations

### Overview
Move beyond generic "healthier alternatives" to truly personalized recommendations based on user's scan history, nutritional gaps, and behavioral patterns.

### User Experience

**Current Flow:**
```
User scans chips → "Here are healthier chip alternatives" (same for all users)
```

**New Flow:**
```
User scans chips →
  "Based on your history, you're getting plenty of sodium but low on fiber.
   Try these high-fiber alternatives:"

   Also: "You've scanned this 3 times - want to add to favorites?"
```

### Prerequisites
- Accumulated scan history (already collected)
- User profile computation service (new)
- Integration with recommendation UI (modify existing)

### Implementation Checklist

**Week 1-2: User Profile Computation**
- [ ] Create `UserNutritionProfile` model
- [ ] Build profile computation from scan history
- [ ] Calculate nutritional gaps vs health focus goals

**Week 3: Recommendation Engine**
- [ ] Create `PersonalizedRecommendationService`
- [ ] Implement AI-powered ranking
- [ ] Build gap-filling search queries

**Week 4-5: UI Implementation**
- [ ] Create `WeeklyInsightsView`
- [ ] Modify alternatives section in ProductDetailView
- [ ] Add personalization indicators ("For your fiber goals")

**Week 6: Testing & Refinement**
- [ ] A/B test personalized vs generic recommendations
- [ ] Collect user feedback on relevance
- [ ] Tune recommendation algorithm

### Success Metrics
- Recommendation click-through: >25% (vs 10% for generic)
- User-reported relevance: >80% "helpful"
- Repeat engagement: Users check insights >2x/week

---

## Feature #5: Product Image Recognition

### Overview
Allow users to identify products by pointing their camera at packaging, shelf labels, or unpackaged items - no barcode required.

### User Experience

**New Flow:**
```
User points camera at product (no barcode visible)
           ↓
Camera captures image → Claude Vision identifies product
           ↓
"Is this: Cheerios Original (18oz)?"
  [Yes] [No, search manually]
           ↓
If yes → Show product detail with health score
```

### Technical Approach

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| **Claude Vision API** | Easy integration, high accuracy | Per-request cost (~$0.01) | ✅ Start here |
| **Apple Vision + CoreML** | On-device, fast, free | Requires training data | Future optimization |

### Implementation Checklist

**Week 1-2: Core Recognition Service**
- [ ] Create `ProductImageRecognitionService`
- [ ] Implement Claude Vision API integration (uses existing ClaudeService)
- [ ] Build image preprocessing pipeline (resize, compress)

**Week 3-4: Database Matching**
- [ ] Implement fuzzy product matching (identified product → database)
- [ ] Build disambiguation logic (multiple candidates)
- [ ] Handle edge cases (no match, low confidence)

**Week 5-6: UI Implementation**
- [ ] Add photo capture mode to scanner (toggle: Barcode / Photo)
- [ ] Create confirmation/disambiguation UI
- [ ] Add loading states and error handling

**Week 7-8: Testing & Optimization**
- [ ] Test with diverse product images
- [ ] Optimize image preprocessing for speed
- [ ] Consider offline fallback (local ML model) for v2

### Cost Considerations

| Usage | Images/Month | Cost/Image | Monthly Cost |
|-------|--------------|------------|--------------|
| Light | 5,000 | $0.01 | $50 |
| Medium | 20,000 | $0.01 | $200 |
| Heavy | 100,000 | $0.01 | $1,000 |

**Mitigation:** Implement usage limits (e.g., 10 photo scans/day free) and encourage barcode scanning when possible.

### Success Metrics
- Recognition accuracy: >85% correct identification
- User adoption: >20% of scans use photo mode
- Fallback rate: <30% need to revert to barcode

---

## Technical Reference

### API Configuration

```swift
// Constants.swift
struct Claude {
    static let baseURL = "https://api.anthropic.com"
    static let messagesPath = "/v1/messages"
    static let apiVersion = "2023-06-01"
    static var apiKey: String { AppConfiguration.shared.claudeAPIKey }
    static let defaultModel = "claude-3-5-haiku-20241022"  // Fast, cheap
    static let sonnetModel = "claude-sonnet-4-20250514"    // Accurate, for safety-critical
    static let requestTimeout: TimeInterval = 30.0
    static let maxTokensDefault = 1024
}
```

### Model Selection Guide

| Use Case | Model | Why |
|----------|-------|-----|
| Ingredient analysis | Haiku | High volume, simple task |
| Search query parsing | Haiku | Simple structured output |
| Dietary violation detection | Sonnet | Safety-critical, needs accuracy |
| Personalized recommendations | Sonnet | Complex reasoning |
| Image recognition | Sonnet | Vision capability required |

### Error Handling

```swift
enum ClaudeError: LocalizedError {
    case notConfigured      // API key missing
    case emptyResponse      // No content returned
    case invalidJSON        // Failed to parse JSON
    case decodingFailed     // Type mismatch
    case rateLimited        // Too many requests
    case serverError        // API error
}
```

### Caching Strategy

- **In-memory cache** in ClaudeService (7-day TTL)
- **Cache key format**: `{feature}_{parameters_hash}`
- **Cache eviction**: LRU when >500 entries
- **Future**: Consider CoreData for persistent caching

---

## Cost Projections

### Monthly Cost by Feature (at 10,000 active users)

| Feature | Model | Requests/User/Month | Cache Hit | API Calls | Cost |
|---------|-------|---------------------|-----------|-----------|------|
| Ingredient Analysis | Haiku | 30 | 80% | 60,000 | ~$60 |
| Search | Haiku | 10 | 50% | 50,000 | ~$50 |
| Dietary Detection | Sonnet | 30 | 90% | 30,000 | ~$300 |
| Recommendations | Sonnet | 5 | 70% | 15,000 | ~$150 |
| Image Recognition | Sonnet | 5 | 0% | 50,000 | ~$500 |

**Total estimated: ~$1,060/month at 10K users**

### Cost Optimization Strategies

1. **Aggressive caching** - Same ingredient + health focus = cached
2. **Model selection** - Haiku where possible, Sonnet only when needed
3. **Batch requests** - Analyze multiple ingredients in one call
4. **Usage limits** - Rate limit expensive features (image recognition)
5. **Prompt optimization** - Shorter prompts = fewer input tokens

---

## Open Questions & Decisions

### Resolved ✅

| Question | Decision | Rationale |
|----------|----------|-----------|
| Which AI provider? | Anthropic Claude | Quality, safety, vision support |
| Where to store API key? | Configuration.plist (gitignored) | Security best practice |
| Which model for ingredients? | Haiku | Cost-effective, sufficient quality |
| Which model for safety features? | Sonnet | Accuracy > cost for safety |

### Open Questions 🤔

| Question | Options | Notes |
|----------|---------|-------|
| Should ingredient analysis be automatic or tap-to-load? | Auto vs tap | Auto = higher cost, better UX |
| Add user feedback on AI responses? | Yes/No/Later | Helps improve prompts |
| How to handle AI downtime? | Fallback to rules vs show error | Need graceful degradation |
| Monetization of AI features? | Free vs premium vs usage-based | Business decision |

### Future Considerations 🔮

- **On-device ML** for image recognition (reduce API costs)
- **Fine-tuned model** if we have enough training data
- **Multi-language support** for international users
- **Voice input** for accessibility
- **Apple Intelligence integration** when available

---

## Implementation Roadmap Summary

```
COMPLETED:
├── Infrastructure setup (API client, configuration, security)

MONTH 1:
├── Week 1-2: Feature #1 (Ingredient Analysis) - Core service
├── Week 3-4: Feature #1 - UI integration & polish

MONTH 2:
├── Week 1-2: Feature #2 (Natural Language Search) - Query parsing
├── Week 3-4: Feature #2 - Search UI & integration

MONTH 3:
├── Week 1-2: Feature #3 (Smart Dietary Detection) - Core service
├── Week 3-4: Feature #3 - UI & validation testing

MONTH 4-5:
├── Week 1-2: Feature #4 (Personalized Recs) - User profile
├── Week 3-4: Feature #4 - Recommendation engine
├── Week 5-6: Feature #4 - Insights UI

MONTH 6-7:
├── Week 1-4: Feature #5 (Image Recognition) - Core service
├── Week 5-8: Feature #5 - UI & optimization
```

---

## Next Session Checklist

When resuming work on this project:

1. **Verify API key is working**: Build and run, check logs for Claude configuration warnings
2. **Review this document**: Check "Progress Tracker" and "Open Questions"
3. **Start Feature #1**: Begin with `IngredientAnalysis.swift` model
4. **Test incrementally**: Each service should work in isolation before UI integration

---

## Changelog

### January 21, 2026 - Bug Fixes & Infrastructure

This session focused on getting the app to build and fixing critical bugs discovered during testing.

#### Build Errors Fixed

Multiple build errors were discovered and resolved across the scoring system:

| File | Issue | Fix |
|------|-------|-----|
| `HealthScore.swift` | Missing closing brace in `ScoreColor.from(score:)` method | Added missing `}` |
| `Product.swift` | Missing `nutriScore` property in `APIProduct` | Added `nutriScore: String?` property |
| `Product.swift` | Missing `labelServingSize` in `ProductNutrition` | Added `labelServingSize: String?` property |
| `Product.swift` | Missing `fruitVegEstimate` in `ProductModel` | Added property and created `FruitVegEstimate` struct |
| `Product.swift` | Missing `isLikelyBeverage` computed property | Added computed property to `ProductModel` |
| `Product.swift` | Missing `NutrientAvailability` type | Created `OptionSet` with energy, sugar, saturatedFat, sodium, fiber, protein options |
| `Product.swift` | Missing `FruitVegLegumeNutEstimator` class | Created estimator class with `estimate(from:)` method |
| `TierMapper.swift` | Missing `ContributionGroupSummary` struct | Added struct definition |
| `TierMapper.swift` | `weightMultiplier` property not found | Changed to correct property name `weight` |
| `ScoringInputNormalizer.swift` | Missing `computeNutrientAvailability(from:)` method | Added method implementation |
| `IngredientAnalyzer.swift` | `IngredientMetadata` not accessible | Made struct `public`, added `IngredientMetadataSource` enum |
| `IngredientAnalyzer.swift` | Missing `hasMetadata(for:)` method | Added public method |
| `PillarEvaluator.swift` | `NutrientContribution` init parameter order wrong | Fixed parameter order |
| `HealthScoringPipeline.swift` | Missing `convertToComponentBreakdown` helper | Added helper function |
| `HealthFocusScorer.swift` | HealthScore initialization missing parameters | Updated to match new struct with all required parameters |
| `HealthFocusScorer.swift` | Missing `tierFromScore` helper | Added `tierFromScore(_ score: Double) -> ScoreTier` method |
| `ColorPalette.swift` | Missing color definitions | Added `warmCream`, `forestGreen`, `trafficLightGreen`, `trafficLightYellow`, `trafficLightRed` |
| `VerdictMixView.swift` | Mock data didn't match updated model | Updated mock data |
| `AppConfiguration.swift` | Non-exhaustive switch statement | Added missing cases |
| `ScannerViewModel.swift` | Missing `servingSize` parameter | Added parameter to function calls |
| `ComparisonPageView.swift` | Missing `healthFocus` parameter | Added parameter to function calls |
| `NutrientContribution` | Not conforming to `Identifiable` | Added `Identifiable` conformance with computed `id` |

#### Infrastructure: USDA API Key

**Problem**: Scanned products were returning "product not found" errors.

**Root Cause**: The `USDAAPIKey` was missing from `Configuration.plist`. The app's lookup flow is:
1. Try USDA FoodData Central API (requires API key)
2. Fallback to Open Food Facts (free, but less US product coverage)
3. Fallback to local catalog

Without the USDA API key, step 1 fails silently and falls back to Open Food Facts, which has limited US product coverage.

**Fix**:
- Added `USDAAPIKey` placeholder to `Configuration.plist`
- Added `USDAAPIKey` template to `Configuration.sample.plist`
- User obtained free API key from https://fdc.nal.usda.gov/api-key-signup.html

**Files Modified**:
- `Mira/App/Configuration/Configuration.plist` - Added USDAAPIKey entry
- `Mira/App/Configuration/Configuration.sample.plist` - Added USDAAPIKey template

#### Bug Fix: History Score Mismatch

**Problem**: A product (organic sea salt lime tortilla chips) showed score 22 in product detail view but 40 in history view.

**Root Cause**: Data normalization inconsistency between scan-time and history recalculation:

1. **Scanner saves per-serving nutritional data**: The `ScannerViewModel.makeProductModel()` scales API data (which is per-100g) to the actual serving size before saving to CoreData.

2. **History recalculates with wrong assumption**: The `Product+Scoring.swift` extension was hardcoding `servingSize: "100g"` when creating the `ProductModel` for scoring, but the stored data was already scaled to per-serving.

3. **Scoring thresholds expect per-100g data**: The scoring engine's thresholds are calibrated for per-100g nutritional values.

**Example**:
- Chips have 28g serving size with 140 calories per serving
- Scanner saves: 140 calories (per 28g serving)
- History recalculates treating 140 as per-100g → artificially low score (40)
- Correct would be: 140 × (100/28) = 500 calories per 100g → correct score (22)

**Fix**: Modified `Product+Scoring.swift` to normalize stored per-serving data back to per-100g before scoring:

```swift
// Extract serving size in grams (e.g., "28g", "1 oz (28g)", "2 tbsp (30 g)")
let servingGrams = extractServingGrams(from: servingSize) ?? 100.0
let normalizationFactor = servingGrams > 0 ? (100.0 / servingGrams) : 1.0

// Normalize per-serving data back to per-100g for scoring
let normalizedNutrition = NutritionalData(
    calories: nutritionalData.calories * normalizationFactor,
    protein: nutritionalData.protein * normalizationFactor,
    // ... etc
)
```

Added `extractServingGrams(from:)` helper that parses serving size strings:
- `"28g"` → 28.0
- `"1 oz (28g)"` → 28.0 (extracts grams from parentheses)
- `"2 tbsp (30 g)"` → 30.0 (handles spaces)
- `"240ml"` → 240.0 (for beverages, approximates 1ml ≈ 1g)
- `"1 oz"` → 28.35 (converts ounces to grams)

**Files Modified**:
- `Mira/Core/Models/Product+Scoring.swift` - Added normalization logic and `extractServingGrams(from:)` helper

**Testing**: After fix, rebuild app and either:
- Delete app and reinstall to clear cached data, or
- Delete affected products from history and re-scan

---

## UX Improvements: Competitive Positioning vs Yuka

### Strategic Overview

**Last Updated**: January 25, 2026

**Goal**: Make Mira demonstrably superior to Yuka by addressing Yuka's documented weaknesses while emphasizing Mira's unique AI-powered personalization.

**Competitive Analysis Source**: Comprehensive research of Yuka app reviews, user complaints, and feature comparisons documented in `/Users/laurenbarnhart/.claude/plans/effervescent-pondering-cake.md`

### Yuka's Key Weaknesses (Our Opportunities)

| Weakness | User Impact | Mira's Advantage |
|----------|-------------|------------------|
| No personalization | Same score for everyone | ✅ 5 health focuses, dynamic scoring |
| Creates food anxiety | Users report guilt/worry | ✅ Positive framing, educational approach |
| Oversimplified scores | Single number, no context | ✅ 5-pillar breakdown with explanations |
| Poor science | Labels MSG "hazardous" | ✅ Research-backed, nuanced |
| Penalizes healthy foods | Meat/cheese get unfair scores | ✅ Category-aware contextual messaging |
| Barcode-only | Can't scan without barcodes | ✅ Image recognition (in development) |
| No dietary filters | Can't filter for vegan/GF | ✅ AI-powered dietary detection |
| No insights | Just per-product scores | ✅ Weekly patterns, gaps, recommendations |

### Implementation Task List with Dependencies

#### Legend
- 🟢 No dependencies - Can start immediately
- 🟡 Has dependencies - Must wait for prerequisite tasks
- 🔵 Enhancement - Builds on existing feature
- ⚡ Quick Win - High impact, low effort (<5 hours)
- 🎯 High Impact - Critical differentiator vs Yuka

---

### Phase 1: Quick Wins (Week 1-2, ~30 hours)

These features can be implemented in parallel by different team members or sequentially as quick wins.

#### Task 1.1: Confidence Badges ⚡🎯
**Status**: Not Started
**Dependencies**: None 🟢
**Effort**: 2-3 hours
**Files**:
- Modify: `Mira/Shared/Components/ScoreGauge.swift`

**Subtasks**:
- [ ] Add `confidence: ConfidenceLevel` parameter to `ScoreGauge`
- [ ] Define `ConfidenceLevel` enum (high, medium, low)
- [ ] Add badge overlay to gauge view
- [ ] Update `ProductDetailViewModel` to calculate confidence based on data completeness
- [ ] Test with products having varying data completeness

**Acceptance Criteria**:
- High confidence (H) badge appears when all key nutrients present
- Medium (M) when some nutrients missing
- Low (L) when minimal data available
- Badge is color-coded and visually distinct

---

#### Task 1.2: Haptic Feedback ⚡
**Status**: Not Started
**Dependencies**: None 🟢
**Effort**: 2-3 hours
**Files**:
- Modify: `Mira/Features/Scanner/ViewModels/ScannerViewModel.swift`
- Modify: `Mira/Features/ProductDetail/ViewModels/ProductDetailViewModel.swift`

**Subtasks**:
- [ ] Create `HapticManager` utility class
- [ ] Add haptic on barcode detection (light impact)
- [ ] Add haptic on product found (success notification)
- [ ] Add haptic on score reveal (medium impact)
- [ ] Add haptic on excellent score 80+ (success notification)
- [ ] Add haptic on dietary violation (warning notification)
- [ ] Test on physical device

**Dependencies Unblocked**: None (independent feature)

---

#### Task 1.3: Score Animations ⚡
**Status**: Not Started
**Dependencies**: None 🟢
**Effort**: 3-4 hours
**Files**:
- Modify: `Mira/Shared/Components/ScoreGauge.swift`

**Subtasks**:
- [ ] Add loading state ("Analyzing..." with spinner)
- [ ] Implement animated count-up (0 → final score over 1 second)
- [ ] Add verdict text reveal animation
- [ ] Add confetti effect for scores 80+ (use SF Symbols or custom)
- [ ] Add spring animation to gauge fill
- [ ] Test performance on older devices

**Dependencies Unblocked**: None (independent feature)

---

#### Task 1.4: First-Scan Education Flow ⚡🎯
**Status**: Not Started
**Dependencies**: None 🟢
**Effort**: 3-4 hours
**Files**:
- Create: `Mira/Features/Scanner/Views/FirstScanEducationSheet.swift`
- Modify: `Mira/Features/Scanner/ViewModels/ScannerViewModel.swift`
- Modify: `Mira/Shared/AppState/AppState.swift` (add `hasSeenFirstScanEducation` flag)

**Subtasks**:
- [ ] Create `FirstScanEducationSheet` view with 2-3 pages
- [ ] Page 1: Show current product score
- [ ] Page 2: Show comparison slider (different health focuses)
- [ ] Page 3: Explain "Why different?" with focus-specific nutrients
- [ ] Add UserDefaults flag to show only once
- [ ] Add skip button
- [ ] Trigger after first successful scan
- [ ] Add analytics tracking

**Acceptance Criteria**:
- Sheet appears automatically after first scan
- Shows score comparison across all 5 health focuses
- Explains personalization clearly
- Only shows once per user
- Can be dismissed/skipped

**Dependencies Unblocked**: None (independent feature)

---

#### Task 1.5: Insights Unlocked Promotion ⚡🎯
**Status**: Not Started
**Dependencies**: Task 1.4 (uses similar sheet pattern) 🟡
**Effort**: 3-4 hours
**Files**:
- Create: `Mira/Features/Scanner/Views/InsightsUnlockedSheet.swift`
- Modify: `Mira/Features/Scanner/ViewModels/ScannerViewModel.swift`

**Subtasks**:
- [ ] Create `InsightsUnlockedSheet` view
- [ ] Add scan count tracking in `ScannerViewModel`
- [ ] Trigger sheet when scan count reaches 5
- [ ] Add "View My Insights" button → navigate to Insights tab
- [ ] Add "Later" button
- [ ] Add UserDefaults flag to show only once
- [ ] Include preview of what insights include

**Acceptance Criteria**:
- Sheet appears after exactly 5th scan
- Shows compelling preview of insights value
- "View My Insights" navigates to Insights tab
- Only shows once per user

**Dependencies Unblocked**: None

---

#### Task 1.6: Smart "Scan Again" Feature ⚡
**Status**: Not Started
**Dependencies**: None 🟢
**Effort**: 3-4 hours
**Files**:
- Create: `Mira/Features/Scanner/Views/DuplicateScanSheet.swift`
- Modify: `Mira/Features/Scanner/ViewModels/ScannerViewModel.swift`

**Subtasks**:
- [ ] Create `DuplicateScanSheet` view
- [ ] Check CoreData for existing scan by barcode
- [ ] Show previous scan date and score
- [ ] Add quick actions: View Details, Add to Favorites, Scan New
- [ ] Show tip if health focus hasn't changed
- [ ] Add setting to disable duplicate warnings

**Acceptance Criteria**:
- Detects duplicate scans within 30 days
- Shows previous scan context
- Provides quick actions
- Doesn't interrupt scanning flow (sheet, not alert)

**Dependencies Unblocked**: None

---

#### Task 1.7: "Why This Score?" Explainer Cards 🎯
**Status**: Not Started
**Dependencies**: None 🟢
**Effort**: 6-8 hours
**Files**:
- Create: `Mira/Features/ProductDetail/Views/Components/ExplainerCard.swift`
- Create: `Mira/Features/ProductDetail/Views/Components/ExplainerLibrary.swift`
- Modify: `Mira/Features/ProductDetail/Views/ScoreBreakdownView.swift`

**Subtasks**:
- [ ] Create `ExplainerCard` reusable component (sheet view)
- [ ] Create `ExplainerLibrary` with explanations for:
  - [ ] Macronutrients (what it measures, why it matters per health focus)
  - [ ] Micronutrients (vitamins/minerals importance)
  - [ ] Processing Level (NOVA groups explanation)
  - [ ] Ingredient Quality (clean label, derivatives)
  - [ ] Additives (harmful vs safe additives)
- [ ] Add tap gesture to each score component in `ScoreBreakdownView`
- [ ] Show health-focus-specific "Why it matters" text
- [ ] Add "Learn More" link to external resources
- [ ] Add close button

**Acceptance Criteria**:
- Each of 5 score components is tappable
- Explainer shows relevant information with examples
- Content adapts to user's health focus
- Easy to dismiss

**Dependencies Unblocked**: Foundation for Task 2.2c (What's Good Here section)

---

### Phase 2: Counter Yuka's Weaknesses (Week 3-5, ~45 hours)

#### Task 2.1: Dietary Filter Mode 🎯
**Status**: Not Started
**Dependencies**: None 🟢
**Effort**: 6-8 hours
**Files**:
- Create: `Mira/Features/Scanner/Views/FilterModeToggle.swift`
- Modify: `Mira/Features/Scanner/Views/LiveScannerView.swift`
- Modify: `Mira/Features/ProductDetail/ViewModels/ProductDetailViewModel.swift`

**Subtasks**:
- [ ] Add filter mode toggle in scanner top bar
- [ ] Add UserDefaults setting for filter mode preference
- [ ] Show active restrictions banner when filter enabled
- [ ] When non-compliant product scanned:
  - [ ] Show violation sheet (don't show full product detail)
  - [ ] List specific violations detected
  - [ ] Offer "See Alternatives" button
  - [ ] Offer "Scan Another" button
- [ ] Add setting to auto-enable filter mode based on restrictions
- [ ] Add haptic on violation detection

**Acceptance Criteria**:
- Toggle clearly visible in scanner UI
- Non-compliant products blocked from full view
- Violations clearly explained
- Alternatives offered
- Can be disabled quickly

**Dependencies Unblocked**: None

---

#### Task 2.2: Food Anxiety Reducer Features 🎯
**Status**: Not Started
**Dependencies**: Task 1.7 (Explainer Cards) 🟡
**Effort**: 8-10 hours

**Subtask 2.2a: Positive Framing in Scores**
**Files**:
- Modify: `Mira/Core/Models/ScoreVerdict.swift`

**Tasks**:
- [ ] Update verdict text for all tiers:
  - [ ] Excellent (85-100): Keep "Great choice!"
  - [ ] Good (70-84): "Solid option for your goals"
  - [ ] Okay (55-69): "Good choice! See alternatives for even better options"
  - [ ] Fair (40-54): "Okay in moderation. For better fits, check alternatives below"
  - [ ] Poor (0-39): "Not the best fit for your goals. Let's find a better match"
- [ ] Remove judgmental language ("Avoid", "Bad")
- [ ] Add context to messaging

**Subtask 2.2b: Balance Messaging Banner**
**Files**:
- Create: `Mira/Features/ProductDetail/Views/Components/BalanceBanner.swift`
- Modify: `Mira/Features/ProductDetail/Views/ProductDetailView.swift`

**Tasks**:
- [ ] Create `BalanceBanner` component
- [ ] Show at bottom of products scoring <60
- [ ] Include message: "No single food makes or breaks your health"
- [ ] Add "See Your Weekly Patterns" button → navigate to Insights
- [ ] Make dismissible with UserDefaults persistence

**Subtask 2.2c: "What's Good Here" Section**
**Files**:
- Modify: `Mira/Features/ProductDetail/Views/ProductDetailView.swift`
- Create: `Mira/Features/ProductDetail/Views/Components/PositivesSection.swift`

**Tasks**:
- [ ] Create `PositivesSection` component
- [ ] Add section before score breakdown for scores <60
- [ ] "✨ What's Good:" - list 2-3 positive attributes:
  - [ ] High in any nutrient (protein, fiber, vitamins)
  - [ ] Low in concerning nutrients
  - [ ] Minimal processing if applicable
  - [ ] No harmful additives
- [ ] "⚠️ Watch out for:" - list 1-2 main concerns
- [ ] Balance positive/negative (always show at least one positive)

**Acceptance Criteria**:
- Verdict text is encouraging, not shaming
- Low-scoring products show balance banner
- "What's Good" highlights positives even in low scores
- Users feel informed, not judged

**Dependencies Unblocked**: Foundation for context-aware messaging

---

#### Task 2.3: Context-Aware Messaging 🎯
**Status**: Not Started
**Dependencies**: Task 2.2 (Food Anxiety Reducers) 🟡
**Effort**: 6-8 hours
**Files**:
- Create: `Mira/Core/Scoring/CategoryContextProvider.swift`
- Modify: `Mira/Features/ProductDetail/ViewModels/ProductDetailViewModel.swift`

**Subtasks**:
- [ ] Create `CategoryContextProvider` class
- [ ] Define category-specific context messages:
  - [ ] Cheese: "Naturally higher in saturated fat, focus on protein/calcium"
  - [ ] Meat/Jerky: "Protein-to-calorie ratio is key metric"
  - [ ] Whole milk products: "Full-fat dairy has nutritional benefits"
  - [ ] Nuts: "High calories are from healthy fats"
  - [ ] Dark chocolate: "Higher fat content is heart-healthy"
  - [ ] Fermented foods: "Beneficial bacteria support gut health"
- [ ] Integrate context into product detail view
- [ ] Show context banner below product name
- [ ] Adjust scoring explanations to mention category context

**Acceptance Criteria**:
- Naturally high-fat foods aren't unfairly penalized
- Category context explains why certain nutrients are higher
- Messaging is scientifically accurate
- Cheese, meat, nuts show appropriate context

**Dependencies Unblocked**: None

---

#### Task 2.4: Comparison Mode Feature 🎯
**Status**: Not Started
**Dependencies**: None 🟢
**Effort**: 4-5 hours
**Files**:
- Create: `Mira/Features/ProductDetail/Views/ScoreComparisonSheet.swift`
- Modify: `Mira/Features/ProductDetail/ViewModels/ProductDetailViewModel.swift`

**Subtasks**:
- [ ] Create `ScoreComparisonSheet` view
- [ ] Add "Compare Focuses" button to product detail
- [ ] Calculate score for same product across all 5 health focuses
- [ ] Show scores in horizontal bar chart
- [ ] Add explanatory text for differences
- [ ] Highlight current user's health focus
- [ ] Cache calculated scores

**Acceptance Criteria**:
- Shows all 5 health focus scores side-by-side
- Clearly indicates user's current focus
- Explains why scores differ
- Performance is good (calculations cached)

**Dependencies Unblocked**: None

---

#### Task 2.5: Health Focus Onboarding Enhancement 🎯
**Status**: Not Started
**Dependencies**: Task 2.4 (Comparison Mode logic) 🟡
**Effort**: 5-6 hours
**Files**:
- Modify: `Mira/Features/Onboarding/Views/OnboardingView.swift`

**Subtasks**:
- [ ] Add interactive preview to health focus selection
- [ ] For each focus option, show:
  - [ ] Icon and name
  - [ ] Brief description
  - [ ] Example product with score preview
  - [ ] Comparison to what "others see" (different focus)
- [ ] Add sample products (e.g., Greek Yogurt, Avocado, Dark Chocolate)
- [ ] Calculate and show score difference
- [ ] Make selection feel impactful

**Acceptance Criteria**:
- Users see score impact before first scan
- Each focus has compelling example
- Comparison makes personalization tangible
- Selection process is engaging, not overwhelming

**Dependencies Unblocked**: None

---

#### Task 2.6: Alternative Suggestions Improvement 🔵
**Status**: Not Started
**Dependencies**: Task 2.2 (positive framing) 🟡
**Effort**: 4-5 hours
**Files**:
- Modify: `Mira/Features/ProductDetail/Views/Components/AlternativeProductCard.swift`

**Subtasks**:
- [ ] Redesign alternative card layout
- [ ] Add "✨ Why it's better:" section
- [ ] Show specific improvement reasons:
  - [ ] Higher fiber (Xg vs Yg)
  - [ ] Fewer additives (X vs Y)
  - [ ] Less processed
  - [ ] Better nutrient profile
- [ ] Calculate and cache improvement reasons
- [ ] Show up to 3 reasons per alternative

**Acceptance Criteria**:
- Each alternative clearly explains why it's better
- Reasons are specific with numbers
- Educational, not just prescriptive

**Dependencies Unblocked**: None

---

#### Task 2.7: Advanced Image Scanning Completion 🎯
**Status**: 40% complete (ViewModel exists)
**Dependencies**: Claude Vision API (already integrated) 🟢
**Effort**: 12-15 hours
**Files**:
- Complete: `Mira/Features/Scanner/Views/ImageScannerView.swift`
- Create: `Mira/Core/Services/ImageRecognitionService.swift`
- Create: `Mira/Features/Scanner/Views/ProductDisambiguationSheet.swift`
- Modify: `Mira/Features/Scanner/ViewModels/ScannerViewModel.swift`

**Subtasks**:
- [ ] Create `ImageScannerView` with camera capture UI
- [ ] Add mode toggle: Barcode / Photo
- [ ] Implement `ImageRecognitionService`:
  - [ ] Use Claude Vision API (via ClaudeService.analyzeImage)
  - [ ] Parse response for product name, brand, category
  - [ ] Return confidence score
- [ ] Implement fuzzy matching:
  - [ ] Search Open Food Facts by name + brand
  - [ ] Rank matches by similarity
  - [ ] Return top 3 matches
- [ ] Create `ProductDisambiguationSheet`:
  - [ ] Show multiple match options
  - [ ] Include product images if available
  - [ ] Add "None of these" option
- [ ] Handle edge cases:
  - [ ] No matches found → manual search
  - [ ] Low confidence → show warning
  - [ ] API error → graceful fallback
- [ ] Add loading states and animations
- [ ] Test with various product types

**Acceptance Criteria**:
- Photo mode works without barcode
- Correctly identifies products >85% accuracy
- Disambiguation UI is clear
- Fallback to manual search works
- Performance is acceptable (<3s total)

**Dependencies Unblocked**: Completes major differentiator vs Yuka

---

### Phase 3: Emphasize Existing Advantages (Week 6-8, ~30 hours)

#### Task 3.1: "Scan & Compare" Mode 🎯
**Status**: Not Started
**Dependencies**: None 🟢
**Effort**: 10-12 hours
**Files**:
- Create: `Mira/Features/Scanner/Views/ComparisonModeView.swift`
- Modify: `Mira/Features/Scanner/ViewModels/ScannerViewModel.swift`

**Subtasks**:
- [ ] Add "Compare Mode" toggle in scanner
- [ ] Track up to 3 scanned products in memory
- [ ] Create comparison table view:
  - [ ] Product images/names
  - [ ] Health scores
  - [ ] Key nutrients (protein, fiber, sugar, sodium)
  - [ ] Highlight best value in each column
- [ ] Add "Winner" indicator with explanation
- [ ] Add "Start Over" button
- [ ] Add "View Details" for each product
- [ ] Persist comparison list across app launches (optional)

**Acceptance Criteria**:
- Can compare 2-3 products side-by-side
- Clear visual indication of which is "best"
- Explanation of why winner wins
- Easy to start new comparison

**Dependencies Unblocked**: None

---

#### Task 3.2: Shopping List Integration 🎯
**Status**: Not Started
**Dependencies**: None 🟢
**Effort**: 8-10 hours
**Files**:
- Create: `Mira/Features/ShoppingList/ViewModels/ShoppingListViewModel.swift`
- Create: `Mira/Features/ShoppingList/Views/ShoppingListView.swift`
- Create: `Mira/Features/ShoppingList/Models/ShoppingListItem.swift`
- Modify: `Mira/ContentView.swift`
- Modify: `Mira/Features/ProductDetail/Views/ProductDetailView.swift`

**Subtasks**:
- [ ] Create `ShoppingListItem` model (CoreData entity)
- [ ] Create `ShoppingListViewModel` with CRUD operations
- [ ] Create `ShoppingListView`:
  - [ ] List items with checkboxes
  - [ ] Show score for each item
  - [ ] Show average list score
  - [ ] Add "Share List" functionality
  - [ ] Add "Clear Checked" button
- [ ] Add "Add to Shopping List" button in product detail
- [ ] Add 6th tab in `ContentView` (or place in Settings)
- [ ] Implement CoreData persistence
- [ ] Add notification for list reminders (optional)

**Acceptance Criteria**:
- Can add products to shopping list
- Can check off items
- Shows average health score of list
- Can share list as text
- Persists across app launches

**Dependencies Unblocked**: None

---

#### Task 3.3: Scan History Insights Enhancement 🔵
**Status**: Not Started
**Dependencies**: Insights feature (Feature #4, already implemented) 🟢
**Effort**: 4-5 hours
**Files**:
- Modify: `Mira/Features/History/Views/HistoryView.swift`
- Modify: `Mira/Core/Services/NutritionProfilerService.swift`

**Subtasks**:
- [ ] Add pattern detection to `NutritionProfilerService`:
  - [ ] Category frequency analysis
  - [ ] Nutrient trend detection (improving/declining)
- [ ] Create banner component for history view
- [ ] Show weekly pattern at top of history:
  - [ ] "You've scanned X% dairy products"
  - [ ] Tip based on pattern
  - [ ] Link to full insights
- [ ] Add filter chips: All, This Week, Favorites
- [ ] Add search bar for history

**Acceptance Criteria**:
- Pattern banner appears at top of history
- Provides actionable tip
- Links to full insights view
- Doesn't clutter main history list

**Dependencies Unblocked**: None

---

#### Task 3.4: Dark Mode Optimization
**Status**: Not Started
**Dependencies**: None 🟢
**Effort**: 3-4 hours
**Files**:
- Modify: `Mira/Shared/Theme/ColorPalette.swift`
- Audit all view files for color usage

**Subtasks**:
- [ ] Audit all colors for dark mode contrast
- [ ] Test score gauges in dark mode
- [ ] Test score breakdown cards
- [ ] Test sheets and modals
- [ ] Test text readability
- [ ] Fix any contrast issues
- [ ] Add dark mode screenshots to App Store listing

**Acceptance Criteria**:
- All text has >7:1 contrast ratio
- Colors look intentional, not just inverted
- No jarring transitions when switching modes
- All UI elements visible in both modes

**Dependencies Unblocked**: Polish complete

---

### Implementation Priority & Parallelization

#### Week 1: Quick Wins (Can Run in Parallel)
```
Developer A:
├── Task 1.1: Confidence Badges (2-3h)
├── Task 1.2: Haptic Feedback (2-3h)
└── Task 1.3: Score Animations (3-4h)
Total: ~8-10 hours

Developer B:
├── Task 1.4: First-Scan Education (3-4h)
├── Task 1.6: Smart Scan Again (3-4h)
└── Task 1.7: Explainer Cards (6-8h)
Total: ~12-16 hours
```

#### Week 2: Foundational Features
```
Developer A:
├── Task 1.5: Insights Unlocked (3-4h) [after 1.4]
└── Task 2.1: Dietary Filter Mode (6-8h)
Total: ~9-12 hours

Developer B:
├── Task 2.4: Comparison Mode (4-5h)
└── Task 2.5: Onboarding Enhancement (5-6h) [after 2.4]
Total: ~9-11 hours
```

#### Week 3-4: Food Anxiety & Context
```
Developer A:
├── Task 2.2: Food Anxiety Reducers (8-10h) [after 1.7]
└── Task 2.6: Alternative Improvements (4-5h) [after 2.2]
Total: ~12-15 hours

Developer B:
├── Task 2.3: Context-Aware Messaging (6-8h) [after 2.2]
└── Task 2.7: Image Scanning (12-15h)
Total: ~18-23 hours
```

#### Week 5-6: Advanced Features
```
Developer A:
└── Task 3.1: Scan & Compare Mode (10-12h)

Developer B:
└── Task 3.2: Shopping List Integration (8-10h)
```

#### Week 7-8: Polish
```
Anyone:
├── Task 3.3: History Insights Enhancement (4-5h)
├── Task 3.4: Dark Mode Optimization (3-4h)
└── Final testing, bug fixes, performance optimization
```

---

### Dependency Graph

```
Phase 1 (Quick Wins - All Independent):
┌─────────────────────────────────────────────┐
│ Task 1.1: Confidence Badges                 │ → No blockers
│ Task 1.2: Haptic Feedback                   │ → No blockers
│ Task 1.3: Score Animations                  │ → No blockers
│ Task 1.4: First-Scan Education              │ → No blockers
│ Task 1.6: Smart Scan Again                  │ → No blockers
│ Task 1.7: Explainer Cards                   │ → No blockers
└─────────────────────────────────────────────┘
            │
            ├──> Task 1.5: Insights Unlocked (uses sheet pattern from 1.4)
            │
            └──> Task 2.2: Food Anxiety Reducers (builds on explainer cards)

Phase 2 (Counter Yuka):
┌─────────────────────────────────────────────┐
│ Task 2.1: Dietary Filter Mode               │ → No blockers
│ Task 2.4: Comparison Mode                   │ → No blockers
│ Task 2.7: Image Scanning                    │ → No blockers
└─────────────────────────────────────────────┘
            │
            ├──> Task 2.2: Food Anxiety Reducers (after 1.7)
            │       │
            │       ├──> Task 2.3: Context-Aware Messaging
            │       └──> Task 2.6: Alternative Improvements
            │
            └──> Task 2.5: Onboarding Enhancement (uses comparison logic from 2.4)

Phase 3 (Advanced):
┌─────────────────────────────────────────────┐
│ Task 3.1: Scan & Compare Mode               │ → No blockers
│ Task 3.2: Shopping List Integration         │ → No blockers
│ Task 3.3: History Insights Enhancement      │ → No blockers (uses existing insights)
│ Task 3.4: Dark Mode Optimization            │ → No blockers
└─────────────────────────────────────────────┘
```

---

### Critical Path Analysis

**Longest dependency chain**:
```
Task 1.7 (Explainer Cards, 6-8h)
    ↓
Task 2.2 (Food Anxiety Reducers, 8-10h)
    ↓
Task 2.3 (Context-Aware Messaging, 6-8h)
    ↓
Task 2.6 (Alternative Improvements, 4-5h)

Total: 24-31 hours on critical path
```

**Recommendation**: Start Task 1.7 as soon as possible, as it blocks multiple high-impact features.

---

### Testing & Validation Plan

#### Unit Testing
- [ ] Confidence calculation logic
- [ ] Category context provider
- [ ] Scan duplicate detection
- [ ] Shopping list CRUD operations

#### Integration Testing
- [ ] First scan → education sheet flow
- [ ] 5th scan → insights unlocked flow
- [ ] Duplicate scan detection → quick actions
- [ ] Filter mode → violation detection → alternatives

#### User Acceptance Testing
- [ ] Conduct tests with 10 Yuka users
- [ ] Ask: "What makes Mira different from Yuka?"
- [ ] Target: 100% can articulate personalization advantage
- [ ] Target: 80%+ prefer Mira's approach
- [ ] Collect feedback on food anxiety reduction effectiveness

#### Performance Testing
- [ ] Score comparison calculations (<100ms)
- [ ] Image recognition end-to-end (<3s)
- [ ] Smooth animations (60fps)
- [ ] Memory usage acceptable

---

### Success Metrics

#### Feature Adoption
| Feature | Target Metric |
|---------|---------------|
| First-scan education | 80%+ completion rate |
| Confidence badges | Visible on 100% of products |
| Comparison mode | 30%+ of users view at least once |
| Filter mode | 50%+ of users with restrictions enable it |
| What's Good section | Reduces user anxiety (survey) |
| Image scanning | 20%+ of scans use photo mode |
| Shopping list | 15%+ of users create a list |

#### User Satisfaction
| Metric | Target |
|--------|--------|
| App Store rating | >4.5 stars |
| "Reduces food anxiety" survey | >70% agree |
| "More educational than Yuka" | >80% agree |
| "Personalization is valuable" | >90% agree |
| Feature request: "Make it like Yuka" | <5% |

#### Competitive Position
| Metric | Target |
|--------|--------|
| Head-to-head preference | >70% prefer Mira |
| "Mira vs Yuka" search ranking | Top 3 results |
| Social media mentions | 2x Yuka comparison posts/month |
| User referrals | 25%+ mention "better than Yuka" |

---

### Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Feature complexity overwhelms users | Medium | High | Gradual disclosure, onboarding, tooltips |
| Performance issues from calculations | Low | Medium | Cache aggressively, async operations |
| Users don't discover new features | High | High | Proactive prompts, onboarding highlights |
| Image scanning accuracy low | Medium | High | Fallback to manual search, show confidence |
| Too much positive framing seems dishonest | Low | Medium | Balance with clear warnings, maintain honesty |
| Development takes longer than estimated | Medium | Medium | Prioritize high-impact features first |
| iOS updates break features | Low | High | Automated testing, beta participation |

---

### Resource Requirements

#### Development Time
- **Single developer**: ~13-15 weeks full-time
- **Two developers**: ~7-8 weeks with parallelization
- **Three developers**: ~5-6 weeks with parallelization

#### Infrastructure
- **No additional infrastructure** - all features use existing backend
- **Claude API costs**: Already budgeted in existing AI features

#### Design Resources
- **UI mockups**: ~20 hours for new components
- **User testing facilitation**: ~10 hours
- **App Store assets**: ~5 hours (screenshots, marketing copy)

---

### Next Steps

1. **Review and approve** this implementation plan
2. **Prioritize** which phase to start with (recommend Phase 1 Quick Wins)
3. **Assign tasks** to developers
4. **Set up tracking** (Jira, Linear, or GitHub Projects)
5. **Schedule user testing** for feedback on early builds
6. **Begin implementation** with Task 1.1 or 1.7 (critical path)

---

*This UX improvement plan will be updated as features are implemented and user feedback is collected.*

---

*This document will be updated as implementation progresses.*
