import Foundation

enum PhotoScanSimulationScenario: String, Equatable {
    case singleMatch = "single"
    case multipleMatches = "multiple"
    case noMatches = "none"
    case error
}

struct AppLaunchConfiguration {
    static let current = AppLaunchConfiguration(arguments: ProcessInfo.processInfo.arguments)

    private enum Argument {
        static let uiTesting = "-ui-testing"
        static let resetState = "-reset-state"
        static let completeOnboarding = "-complete-onboarding"
        static let seedDemoData = "-seed-demo-data"
        static let selectedTab = "-selected-tab"
        static let simulateCameraDenied = "-simulate-camera-denied"
        static let simulateCameraAvailable = "-simulate-camera-available"
        static let simulateScannedBarcode = "-simulate-scanned-barcode"
        static let simulatePhotoResult = "-simulate-photo-result"
    }

    let arguments: [String]

    var isUITesting: Bool {
        arguments.contains(Argument.uiTesting)
    }

    var shouldResetState: Bool {
        arguments.contains(Argument.resetState)
    }

    var shouldCompleteOnboarding: Bool {
        arguments.contains(Argument.completeOnboarding)
    }

    var shouldSeedDemoData: Bool {
        arguments.contains(Argument.seedDemoData)
    }

    var shouldSimulateCameraDenied: Bool {
        isUITesting && arguments.contains(Argument.simulateCameraDenied)
    }

    var shouldSimulateCameraAvailable: Bool {
        isUITesting && arguments.contains(Argument.simulateCameraAvailable)
    }

    var simulatedScannedBarcode: String? {
        guard isUITesting,
              let index = arguments.firstIndex(of: Argument.simulateScannedBarcode),
              arguments.indices.contains(index + 1) else {
            return nil
        }

        let barcode = arguments[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
        return barcode.isEmpty ? nil : barcode
    }

    var simulatedPhotoScanScenario: PhotoScanSimulationScenario? {
        guard isUITesting,
              let index = arguments.firstIndex(of: Argument.simulatePhotoResult),
              arguments.indices.contains(index + 1) else {
            return nil
        }

        return PhotoScanSimulationScenario(rawValue: arguments[index + 1].lowercased())
    }

    var initialTab: Tab? {
        guard let index = arguments.firstIndex(of: Argument.selectedTab),
              arguments.indices.contains(index + 1) else {
            return nil
        }

        switch arguments[index + 1].lowercased() {
        case "scan":
            return .scan
        case "search":
            return .search
        case "insights":
            return .insights
        case "history":
            return .history
        case "list", "shoppinglist", "shopping-list":
            return .shoppingList
        case "profile":
            return .profile
        default:
            return nil
        }
    }

    func prepare() {
        guard isUITesting else { return }

        if shouldResetState {
            resetUserDefaults()
            try? CoreDataManager.shared.clearAllData()
        }

        if shouldCompleteOnboarding {
            configureCompletedOnboardingDefaults()
        }

        if shouldSeedDemoData {
            seedDemoData()
        }

        suppressIntroductoryEducation()
    }

    private func resetUserDefaults() {
        let defaults = UserDefaults.standard
        let keys = [
            Constants.UserDefaults.hasCompletedOnboarding,
            Constants.UserDefaults.selectedHealthFocus,
            Constants.UserDefaults.dietaryRestrictions,
            Constants.UserDefaults.lastSyncDate,
            Constants.UserDefaults.shoppingListItems,
            Constants.UserDefaults.hasSeenFirstScanEducation,
            Constants.UserDefaults.hasSeenBalanceBanner,
            Constants.UserDefaults.hasSeenInsightsUnlocked,
            Constants.UserDefaults.recentSearches,
            Constants.UserDefaults.appColorScheme,
            Constants.UserDefaults.appTextSize,
            Constants.UserDefaults.scanAnalytics
        ]

        keys.forEach(defaults.removeObject(forKey:))
    }

    private func configureCompletedOnboardingDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: Constants.UserDefaults.hasCompletedOnboarding)
        defaults.set(HealthFocus.generalWellness.rawValue, forKey: Constants.UserDefaults.selectedHealthFocus)
        defaults.set([], forKey: Constants.UserDefaults.dietaryRestrictions)
    }

    private func suppressIntroductoryEducation() {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: Constants.UserDefaults.hasSeenFirstScanEducation)
        defaults.set(true, forKey: Constants.UserDefaults.hasSeenBalanceBanner)
    }

    private func seedDemoData() {
        configureCompletedOnboardingDefaults()

        let now = Date()
        let seededProducts: [Product] = [
            Product(
                id: "ui-test-granola-1",
                barcode: "900000000001",
                name: "UI Test Granola",
                brand: "Mira Labs",
                category: "Breakfast",
                nutritionalData: NutritionalData(calories: 210, protein: 8, carbohydrates: 24, fat: 9, fiber: 5, sugar: 6, sodium: 0.120),
                ingredients: "Rolled oats, almonds, pumpkin seeds, maple syrup, sea salt",
                servingSize: "1 cup (55 g)",
                imageURL: nil,
                thumbnailURL: nil,
                lastScanned: now,
                nutriScore: "A"
            ),
            Product(
                id: "ui-test-yogurt-1",
                barcode: "900000000002",
                name: "UI Test Greek Yogurt",
                brand: "Mira Labs",
                category: "Dairy",
                nutritionalData: NutritionalData(calories: 130, protein: 15, carbohydrates: 8, fat: 3, fiber: 0, sugar: 7, sodium: 0.065),
                ingredients: "Cultured skim milk, live active cultures",
                servingSize: "1 container (150 g)",
                imageURL: nil,
                thumbnailURL: nil,
                lastScanned: now.addingTimeInterval(-86_400),
                nutriScore: "A"
            ),
            Product(
                id: "ui-test-soup-1",
                barcode: "900000000003",
                name: "UI Test Lentil Soup",
                brand: "Mira Pantry",
                category: "Soups",
                nutritionalData: NutritionalData(calories: 180, protein: 11, carbohydrates: 26, fat: 4, fiber: 7, sugar: 4, sodium: 0.480),
                ingredients: "Water, lentils, tomatoes, carrots, onions, olive oil, garlic, spices",
                servingSize: "1 bowl (245 g)",
                imageURL: nil,
                thumbnailURL: nil,
                lastScanned: now.addingTimeInterval(-172_800),
                nutriScore: "B"
            ),
            Product(
                id: "ui-test-crackers-1",
                barcode: "900000000004",
                name: "UI Test Seed Crackers",
                brand: "Mira Pantry",
                category: "Snacks",
                nutritionalData: NutritionalData(calories: 140, protein: 4, carbohydrates: 18, fat: 6, fiber: 4, sugar: 2, sodium: 0.160),
                ingredients: "Whole grain flour, flax seeds, sunflower seeds, olive oil, rosemary, sea salt",
                servingSize: "12 crackers (30 g)",
                imageURL: nil,
                thumbnailURL: nil,
                lastScanned: now.addingTimeInterval(-259_200),
                nutriScore: "B"
            ),
            Product(
                id: "ui-test-bar-1",
                barcode: "900000000005",
                name: "UI Test Protein Bar",
                brand: "Mira Fuel",
                category: "Bars",
                nutritionalData: NutritionalData(calories: 190, protein: 14, carbohydrates: 17, fat: 7, fiber: 6, sugar: 5, sodium: 0.150),
                ingredients: "Dates, peanuts, whey protein, cocoa, chicory root fiber, sea salt",
                servingSize: "1 bar (52 g)",
                imageURL: nil,
                thumbnailURL: nil,
                lastScanned: now.addingTimeInterval(-345_600),
                nutriScore: "B"
            )
        ]

        for product in seededProducts {
            try? CoreDataManager.shared.saveProduct(product)
            try? CoreDataManager.shared.saveScanHistory(product: product, healthFocus: HealthFocus.generalWellness.rawValue)
        }

        let seededShoppingList = [
            ShoppingListItem(
                barcode: seededProducts[0].barcode,
                productName: seededProducts[0].name,
                brand: seededProducts[0].brand,
                healthScore: 86,
                isChecked: false,
                addedDate: now,
                category: seededProducts[0].category
            )
        ]

        if let data = try? JSONEncoder().encode(seededShoppingList) {
            UserDefaults.standard.set(data, forKey: Constants.UserDefaults.shoppingListItems)
        }
    }
}
