# Mira Refactor Plan: Becoming a Better Yuka

## Overview
Phased plan to fix architectural issues, eliminate redundancies, and polish the app. Each phase is self-contained and shippable. Phases are ordered by dependency — later phases build on earlier ones.

---

## Phase 1: Foundation Cleanup (No Behavioral Changes)
*Goal: Eliminate code duplication and type mismatches without changing any behavior.*

### 1A. Consolidate `mapHealthFocus` into a single utility
**8 duplicate implementations → 1**

Create `HealthFocus.init(from string: String)` on the enum itself.

**Files to change:**
- `Mira/Core/Models/Product.swift` — add `init(from:)` to `HealthFocus` enum
- `Mira/Core/Models/Product+Scoring.swift:101-110` — delete local `mapHealthFocus`, use enum init
- `Mira/Features/Scanner/ViewModels/ScannerViewModel.swift:545-553` — delete, use enum init
- `Mira/Features/Scanner/Views/ScannerContentView.swift:614-622` — delete, use enum init
- `Mira/Features/ProductDetail/Views/ProductDetailView.swift:342-350` — delete, use enum init
- `Mira/Features/History/ViewModels/HistoryViewModel.swift:210-218` — delete, use enum init
- `Mira/Features/Settings/Views/SettingsView.swift:223-233` — delete, use enum init
- `Mira/Features/Search/Views/NLSearchView.swift:507-515` — delete, use enum init
- `Mira/Features/Insights/ViewModels/InsightsViewModel.swift:48-56` — delete, use enum init

### 1B. Consolidate `DietaryRestriction` string conversions
**3 duplicate conversion methods → 1**

Ensure `DietaryRestriction.init(from: String)` (already in `DietaryAnalysisResult.swift:73-88`) is the single source. Delete duplicates.

**Files to change:**
- `Mira/Features/Scanner/ViewModels/ScannerViewModel.swift:556-570` — delete `mapRestrictions`, use enum init
- `Mira/Features/Scanner/Views/ScannerContentView.swift:610-611` — use enum init
- `Mira/Core/Database/CoreDataManager.swift:305` — use enum rawValues consistently

### 1C. Migrate deprecated `NavigationView` → `NavigationStack`
**15 deprecated usages → 0**

**Files to change:**
- `Mira/Shared/Components/ProductComparisonView.swift:305`
- `Mira/Features/Home/Views/HomeView.swift:10, 178`
- `Mira/Features/Settings/Views/SettingsView.swift:25, 331, 401, 563`
- `Mira/Features/ProductDetail/Views/ScoreComparisonSheet.swift:21`
- `Mira/Features/Scanner/Views/InsightsUnlockedSheet.swift:9`
- `Mira/Features/ProductDetail/Views/IngredientsAnalysisView.swift:407`
- `Mira/Features/ProductDetail/Views/WhyThisScoreView.swift:23`
- `Mira/Features/Scanner/Views/DuplicateScanSheet.swift:14`
- `Mira/Features/Scanner/Views/NonCompliantProductSheet.swift:12`
- `Mira/Features/Scanner/Views/ComparisonModeView.swift:11`
- `Mira/Features/Scanner/Views/FirstScanEducationSheet.swift:23`

### 1D. Fix hardcoded tab navigation
**3 magic numbers → typed enum**

Add a `Tab` enum to `AppState` or `ContentView`.

**Files to change:**
- `Mira/Shared/AppState/AppState.swift` — add `enum Tab: Int, CaseIterable` with cases for scan/search/insights/history/list/profile
- `Mira/ContentView.swift` — use `Tab` enum for tab selection
- `Mira/Features/ProductDetail/Views/ProductDetailView.swift:219` — `appState.selectedTab = Tab.history.rawValue` (or better, change selectedTab to `Tab` type)
- `Mira/Features/Scanner/Views/ScannerContentView.swift:98` — same
- `Mira/Features/ShoppingList/Views/ShoppingListView.swift:87` — same

---

## Phase 2: Scoring System Migration
*Goal: Activate the superior HealthScoringPipeline, remove the old HealthFocusScorer.*

### 2A. Wire HealthScoringPipeline into ScoringEngine
The new pipeline has zero call sites. The only change point is `ScoringEngine.swift:69`.

**Files to change:**
- `Mira/Core/Scoring/ScoringEngine.swift:69` — replace `healthFocusScorer.calculateScore(...)` with `HealthScoringPipeline` call
- Ensure `HealthScore` output format matches what the 34 consuming files expect (it already does — both systems produce `HealthScore`)

### 2B. Fix scoring bugs before activation
- `Mira/Core/Scoring/ScoringSpec/GuardrailEngine.swift` — add sodium unit validation (check if value is already in mg vs g)
- `Mira/Core/Scoring/ScoringSpec/HealthScoringPipeline.swift:96-99` — fix NutriScore fallback (don't default to `.fair`, use score-based verdict)
- `Mira/Core/Models/HealthScore.swift` — remove legacy `var focus: HealthFocus { .generalWellness }` computed property
- `Mira/Core/Scoring/ScoringSpec/PillarEvaluator.swift` — add confidence metadata when pillars are dropped due to missing data

### 2C. Consolidate verdict systems
**4 systems → 1 primary (`ScoreVerdict`) with NutriScore as supplementary display**

- `ScoreVerdict` — keep as primary (excellent/good/okay/fair/poor)
- `ScoreGrade` — keep for display only (A+, A, B+, etc.), derive from ScoreVerdict
- `ScoreTier` — remove, replace with ScoreVerdict everywhere
- `NutriScoreVerdict` — keep as read-only external reference, never override Mira's own verdict

**Files to change:**
- `Mira/Core/Models/HealthScore.swift` — remove `tier: ScoreTier`, keep `verdict` and `grade`
- `Mira/Core/Scoring/ScoringSpec/TierMapper.swift` — output ScoreVerdict directly
- All 34 HealthScore consumers — audit for `tier` usage, replace with `verdict`

### 2D. Delete old scoring system
After 2A-2C are stable and tested:
- Delete `Mira/Core/Scoring/HealthFocusScorer.swift`
- Remove HealthFocusScorer from `ScoringEngine.swift` init
- Remove all 7 direct HealthFocusScorer instantiation sites:
  - `AlternativeProductCard.swift:174, 221`
  - `PositivesSection.swift:204`
  - `ScoreComparisonSheet.swift:162`
  - `DuplicateScanSheet.swift:157`
  - `FirstScanEducationSheet.swift:305, 358`
- Route all of these through `ScoringEngine.shared.calculateHealthScore()` instead
- Update tests in `Mira 8Tests/ScoringEngineTests.swift`

---

## Phase 3: Data Model Consolidation
*Goal: Single nutrition struct, proper Core Data schema, no binary blobs.*

### 3A. Merge `ProductNutrition` into `NutritionalData`
**2 nearly-identical structs → 1**

Keep `NutritionalData` (it's already used in API layer and Core Data). Add any fields from `ProductNutrition` that `NutritionalData` is missing.

**Files to change:**
- `Mira/Core/Models/Product.swift` — delete `ProductNutrition` struct, update `ProductModel` to use `NutritionalData`
- `Mira/Core/Network/ProductModelConverter.swift:14-24` — convert directly to `NutritionalData` (no more `ProductNutrition`)
- `Mira/Core/Models/CachedProduct.swift:28-42` — convert to `NutritionalData`
- All files referencing `ProductNutrition` — update to `NutritionalData`

### 3B. Refactor Core Data nutrition storage
**Binary blob → individual attributes**

Add individual nutrient attributes to `ProductEntity` in the Core Data model.

**Files to change:**
- `Mira/Core/Database/Mira8.xcdatamodeld/Mira8.xcdatamodel/contents` — add attributes: calories, protein, fat, saturatedFat, carbohydrates, sugar, fiber, sodium (all Double, optional)
- `Mira/Core/Database/ProductEntity+Extensions.swift` — update `toProduct()` and `fromProduct()` to use individual fields instead of binary blob
- `Mira/Core/Database/CoreDataManager.swift:346-354` — remove `encodeNutritionalData`/`decodeNutritionalData`
- Add lightweight Core Data migration for existing users

### 3C. Add unique constraint on barcode
- `Mira/Core/Database/Mira8.xcdatamodeld/Mira8.xcdatamodel/contents` — add uniqueness constraint on `ProductEntity.barcode`
- `Mira/Core/Database/CoreDataManager.swift` — add merge policy for constraint conflicts (`NSMergeByPropertyObjectTrumpMergePolicy`)

### 3D. Fix dietary restrictions storage
**Comma-separated string → proper array storage**

- `Mira/Core/Database/Mira8.xcdatamodeld/Mira8.xcdatamodel/contents` — change `UserProfileEntity.dietaryRestrictions` to Transformable with `[String]` transformer, or store as JSON Data
- `Mira/Core/Database/CoreDataManager.swift` — update read/write to use array instead of comma-split

---

## Phase 4: View Decomposition & UI Cleanup
*Goal: Break up massive views, extract shared components, remove duplication.*

### 4A. Extract SettingsView sheets (627 lines → ~150 each)
- Create `Mira/Features/Settings/Views/HealthProfileSheet.swift`
- Create `Mira/Features/Settings/Views/DietaryRestrictionsSheet.swift`
- Create `Mira/Features/Settings/Views/MoreSettingsSheet.swift`
- Create `Mira/Features/Settings/Views/AboutSheet.swift`
- Slim `SettingsView.swift` to ~150 lines (shell with sheet bindings)

### 4B. Extract InsightsView cards (607 lines → ~100 each)
- Create `Mira/Features/Insights/Views/WeeklySummaryCard.swift`
- Create `Mira/Features/Insights/Views/HealthScoreCard.swift`
- Create `Mira/Features/Insights/Views/HighlightsSection.swift`
- Create `Mira/Features/Insights/Views/NutritionGapsSection.swift`
- Create `Mira/Features/Insights/Views/RecommendationsSection.swift`
- Create `Mira/Features/Insights/Views/PatternsSection.swift`
- Create `Mira/Features/Insights/Views/NutrientAveragesSection.swift`
- Slim `InsightsView.swift` to ~120 lines

### 4C. Extract ShoppingListView components (408 lines → ~100 each)
- Create `Mira/Features/ShoppingList/Views/ShoppingListStatsCard.swift`
- Create `Mira/Features/ShoppingList/Views/ShoppingListItemRow.swift`
- Create `Mira/Features/ShoppingList/Views/ScoreDistributionBadge.swift`

### 4D. Consolidate shared state components
**4 loading views, 4 empty states, 3 error views → 1 each**

- Audit `Mira/Shared/Components/EmptyState.swift` and `EmptyStateView.swift` — merge into one
- Create `Mira/Shared/Components/ErrorStateView.swift` — unified error display
- Update `Mira/Shared/Components/LoadingView.swift` — add variants (skeleton, spinner, text)
- Replace all inline loading/empty/error views in InsightsView, NLSearchView, DietaryRestrictionsSectionView, IngredientAIAnalysisSheet

### 4E. Move CoreData access out of views
**12 files with direct CoreData → 0**

Move all `CoreDataManager.shared` and `PersistenceController.shared.container.viewContext` usage from views into their corresponding ViewModels.

**Views to fix:**
- `ProfileView.swift:12` → use a ProfileViewModel
- `HealthFocusSettingsView.swift:11` → pass through ProfileViewModel
- `DietaryRestrictionsSettingsView.swift:11` → pass through ProfileViewModel
- `ProductDetailView.swift:253, 275` → move favorites logic to ProductDetailViewModel
- `HistoryView.swift:89, 118` → move favorites toggle to HistoryViewModel

---

## Phase 5: Service Architecture Improvements
*Goal: Better testability, reduce coupling, fix network inefficiencies.*

### 5A. Add concurrent API searches
- `Mira/Core/Services/ImageRecognitionService.swift` — use `async let` to search USDA and OFF concurrently instead of sequentially
- `Mira/Core/Scoring/AlternativesEngine.swift` — parallelize candidate scoring

### 5B. Add request deduplication
- `Mira/Core/Network/APIClient.swift` — add in-flight request tracking (dictionary of `URL: Task<Data, Error>`) to prevent duplicate concurrent requests for the same barcode

### 5C. Split ImageRecognitionService responsibilities
- Keep `ImageRecognitionService` for orchestration only
- Extract `ProductImageProcessor` (already exists) for image prep
- Extract product search logic into a `ProductSearchService` that both barcode and image paths can share
- Extract fuzzy matching into `ProductFuzzyMatcher` (already exists, ensure it's used consistently)

### 5D. Add cache coherence
- Create a `CacheCoordinator` that invalidates across all cache tiers when a product is refreshed
- Add stale-while-revalidate: serve cached data immediately, refresh in background if stale

### 5E. Improve error handling
Replace silent failures with explicit user-facing states:
- `Mira/Core/Utils/AppConfiguration.swift` — throw on missing API key instead of returning empty string
- `Mira/Core/Database/ProductEntity+Extensions.swift` — log and surface decoding failures
- `Mira/Core/Scoring/ScoringEngine.swift` — return `.insufficientData` verdict instead of guessing when critical nutrients missing

---

## Phase 6: Feature Gaps (vs Yuka)
*Goal: Add the missing features that would make Mira clearly superior.*

### 6A. Eco/Sustainability Score
- Add `ecoScore` field to product models
- Pull Eco-Score data from Open Food Facts (they provide it)
- Display alongside health score in ProductDetailView
- Add eco filter to search

### 6B. Full Allergen Tracking with Severity
- Expand `DietaryRestriction` enum to include all major allergens (tree nuts, peanuts, shellfish, eggs, soy, wheat, fish, sesame)
- Add severity levels (intolerance vs allergy vs preference)
- Show allergen warnings prominently in scan results
- Add allergen section to onboarding

### 6C. Robust Offline Mode
- Implement `OfflineProductCache.prefetchProducts()` (currently stub)
- Cache last 100 scanned products with full data
- Enable local-only scoring when offline
- Show clear offline indicator in UI

### 6D. Nutrition Goal Tracking
- Add daily macro targets to user profile
- Track cumulative nutrition from scanned products
- Show progress toward daily goals in Insights
- Add "log this product" action after scanning

---

## Phase Summary

| Phase | Effort | Risk | Behavioral Change |
|-------|--------|------|-------------------|
| 1: Foundation Cleanup | Low | Low | None — pure refactor |
| 2: Scoring Migration | Medium | Medium | Scores may change slightly |
| 3: Data Model Consolidation | Medium | Medium | Requires Core Data migration |
| 4: View Decomposition | Low | Low | None — pure refactor |
| 5: Service Architecture | Medium | Low | Performance improvements |
| 6: Feature Gaps | High | Low | New user-facing features |

Phases 1 and 4 can run in parallel. Phase 2 depends on 1A. Phase 3 is independent. Phase 5 is independent. Phase 6 depends on all prior phases being stable.
