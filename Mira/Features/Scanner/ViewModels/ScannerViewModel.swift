import Foundation
import UIKit
@preconcurrency import AVFoundation

@MainActor
final class ScannerViewModel: NSObject, ObservableObject {
    @Published var hasPermission = false
    @Published var isScanning = false
    @Published var lastScanResult: ScanResult?
    @Published var errorMessage: String?
    @Published var isTorchOn = false
    @Published var isLoading = false
    @Published var scannedProduct: ProductModel?
    @Published private(set) var captureSession: AVCaptureSession?
    @Published private(set) var isCameraSetup = false

    private let usdaService: USDAService
    private let openFoodFactsService: OpenFoodFactsService
    private let coreDataManager: CoreDataManager
    private var fetchTask: Task<Void, Never>?

    init(
        usdaService: USDAService = .shared,
        openFoodFactsService: OpenFoodFactsService = .shared,
        coreDataManager: CoreDataManager = .shared
    ) {
        self.usdaService = usdaService
        self.openFoodFactsService = openFoodFactsService
        self.coreDataManager = coreDataManager
        super.init()
        checkPermission()
    }

    deinit {
        fetchTask?.cancel()
    }

    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasPermission = true
            Task { [weak self] in
                await self?.setupCamera()
            }
        case .notDetermined:
            requestPermission()
        case .denied, .restricted:
            hasPermission = false
            teardownSession()
        @unknown default:
            hasPermission = false
            teardownSession()
        }
    }

    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                self.hasPermission = granted
                if granted {
                    Task { await self.setupCamera() }
                } else {
                    self.teardownSession()
                }
            }
        }
    }

    func setupCamera() async {
        if !hasPermission {
            checkPermission()
        }

        guard hasPermission else { return }

        guard !isCameraSetup else {
            if captureSession == nil {
                configureCaptureSession()
            } else if hasPermission && !isScanning {
                startScanning()
            }
            return
        }

        configureCaptureSession()
    }

    private func configureCaptureSession() {
        guard hasPermission else { return }

        let session = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showErrorMessage("Camera not available")
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            } else {
                showErrorMessage("Unable to add video input")
                return
            }
        } catch {
            showErrorMessage("Unable to access camera: \(error.localizedDescription)")
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                .ean8, .ean13, .pdf417, .upce, .code128, .code39, .qr
            ]
        } else {
            showErrorMessage("Unable to add metadata output")
            return
        }

        captureSession = session
        isCameraSetup = true
        startScanning()
    }

    private func teardownSession() {
        captureSession?.stopRunning()
        captureSession = nil
        isCameraSetup = false
        isScanning = false
        isTorchOn = false
    }

    func startScanning() {
        guard let session = captureSession, hasPermission, !isScanning else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }

        isScanning = true
    }

    func stopScanning() {
        captureSession?.stopRunning()
        isScanning = false
    }

    // MARK: - Torch Control
    var isTorchAvailable: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.hasTorch ?? false
    }

    func setTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
            isTorchOn = on
        } catch {
            showErrorMessage("Unable to control flashlight: \(error.localizedDescription)")
        }
    }

    func toggleTorch() {
        setTorch(!isTorchOn)
    }

    func resetScanner() {
        fetchTask?.cancel()
        fetchTask = nil
        stopScanning()
        scannedProduct = nil
        lastScanResult = nil
        errorMessage = nil
        isLoading = false
        if hasPermission {
            startScanning()
        }
    }

    private func lookupProduct(barcode: String, metadataType: AVMetadataObject.ObjectType) {
        guard !isLoading else { return }

        stopScanning()
        isLoading = true
        errorMessage = nil
        scannedProduct = nil

        let scanResult = ScanResult(
            barcode: barcode,
            type: ScanResultType(from: metadataType)
        )
        lastScanResult = scanResult

        fetchTask?.cancel()
        fetchTask = Task { [weak self] in
            await self?.fetchProductData(for: barcode)
        }
    }

    private func fetchProductData(for barcode: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        AppLog.debug("🔍 Attempting to fetch product for barcode: \(barcode)", category: .scanner)

        do {
            var productModel: ProductModel?
            var source = ""

            // Try USDA first
            do {
                let usdaProduct = try await usdaService.searchProductByBarcode(barcode)
                productModel = makeProductModel(from: usdaProduct)
                source = "USDA"
                AppLog.debug("✅ Product found in USDA", category: .scanner)
            } catch {
                AppLog.warning("⚠️ USDA failed: \(error.localizedDescription)", category: .scanner)
                AppLog.debug("🔄 Falling back to Open Food Facts...", category: .scanner)

                do {
                    let offProduct = try await openFoodFactsService.searchProductByBarcode(barcode)
                    productModel = makeProductModel(from: offProduct)
                    source = "Open Food Facts"
                    AppLog.debug("✅ Product found in Open Food Facts", category: .scanner)
                } catch {
                    AppLog.warning("⚠️ Open Food Facts failed: \(error.localizedDescription)", category: .scanner)
                    AppLog.debug("🔄 Checking local produce catalog...", category: .scanner)

                    // Try local catalog as final fallback
                    if let localItem = await LocalCatalogService.shared.product(for: barcode) {
                        let catalogProduct = await LocalCatalogService.shared.makeAPIProduct(from: localItem)
                        productModel = makeProductModel(from: catalogProduct)
                        source = "Local Catalog"
                        AppLog.debug("✅ Product found in local catalog", category: .scanner)
                    } else {
                        throw NetworkError.productNotFound
                    }
                }
            }

            guard var finalModel = productModel else {
                throw NetworkError.productNotFound
            }

            let needsImage = finalModel.imageURL?.isEmpty ?? true
            let needsIngredients = finalModel.ingredients.isEmpty

            if source == "USDA" && (needsImage || needsIngredients) {
                AppLog.debug("🖼️ USDA product missing \(needsImage ? "image" : "")\(needsImage && needsIngredients ? " and " : "")\(needsIngredients ? "ingredients" : "") – fetching from OFF...", category: .scanner)
                do {
                    let offProduct = try await openFoodFactsService.searchProductByBarcode(barcode)
                    let offModel = makeProductModel(from: offProduct)

                    if needsImage {
                        finalModel.imageURL = offModel.imageURL
                        finalModel.thumbnailURL = offModel.thumbnailURL ?? offModel.imageURL
                    }

                    if needsIngredients {
                        finalModel.ingredients = offModel.ingredients
                    }

                    AppLog.debug("🖼️ Enhanced USDA product with OFF data", category: .scanner)
                } catch {
                    AppLog.warning("⚠️ Could not fetch supplemental data from OFF: \(error.localizedDescription)", category: .scanner)
                }
            }

            AppLog.debug("📦 Final product source: \(source)", category: .scanner)
            AppLog.debug("📦 Has image: \(!(finalModel.imageURL?.isEmpty ?? true))", category: .scanner)
            AppLog.debug("📦 Ingredient count: \(finalModel.ingredients.count)", category: .scanner)

            await MainActor.run {
                scannedProduct = finalModel
                isLoading = false
            }

            AppLog.debug("📸 Scanned product: \(finalModel.name)", category: .scanner)
            persistScanIfNeeded(finalModel)
        } catch {
            AppLog.error("❌ Error fetching product: \(error.localizedDescription)", category: .scanner)
            await MainActor.run {
                errorMessage = resolvedErrorMessage(for: error)
                isLoading = false
            }
        }

        fetchTask = nil
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        isLoading = false
    }

    func dismissError() {
        resetScanner()
    }

    func refreshPermissionStatus() {
        checkPermission()
        if hasPermission {
            Task { await setupCamera() }
        } else {
            teardownSession()
        }
    }

    private func resolvedErrorMessage(for error: Error) -> String {
        let networkError = NetworkError.from(error)
        return networkError.errorDescription ?? "We couldn't find details for this barcode. Please try again."
    }

    private func makeProductModel(from apiProduct: APIProduct) -> ProductModel {
        // Align per-100g API data to the product's serving size for display
        // Use servingSizeDisplay if available (e.g., "2 tbsp (30 g)"), else fall back to "100g"
        let servingDisplay = apiProduct.servingSizeDisplay ?? "100g"
        let servingMultiplier = (apiProduct.servingSizeInGrams ?? 100) / 100
        let adjustedNutritionData = apiProduct.nutritionalData.scaled(by: servingMultiplier)
        let nutrition = ProductNutrition(
            calories: adjustedNutritionData.calories,
            protein: adjustedNutritionData.protein,
            carbohydrates: adjustedNutritionData.carbohydrates,
            fat: adjustedNutritionData.fat,
            fiber: adjustedNutritionData.fiber,
            sugar: adjustedNutritionData.sugar,
            sodium: adjustedNutritionData.sodium,
            cholesterol: adjustedNutritionData.cholesterol,
            servingSize: servingDisplay
        )

        // Prefer NOVA-derived processing level from APIProduct if available, else fall back to heuristic
        let processingLevel = apiProduct.processingLevel ?? ProcessingLevel.determine(for: apiProduct.ingredients)

        return ProductModel(
            id: UUID(),
            name: apiProduct.name,
            brand: apiProduct.brand,
            category: apiProduct.category,
            categorySlug: apiProduct.categorySlug,
            barcode: apiProduct.barcode,
            nutrition: nutrition,
            ingredients: apiProduct.ingredients,
            additives: [],
            processingLevel: processingLevel,
            dietaryFlags: [],
            imageURL: apiProduct.imageURL,
            thumbnailURL: apiProduct.thumbnailURL,
            healthScore: 0,
            createdAt: Date(),
            updatedAt: Date(),
            isCached: false,
            rawIngredientsText: apiProduct.rawIngredientsText
        )
    }

    private func persistScanIfNeeded(_ productModel: ProductModel) {
        let nutritionalData = NutritionalData(
            calories: productModel.nutrition.calories,
            protein: productModel.nutrition.protein,
            carbohydrates: productModel.nutrition.carbohydrates,
            fat: productModel.nutrition.fat,
            fiber: productModel.nutrition.fiber,
            sugar: productModel.nutrition.sugar,
            sodium: productModel.nutrition.sodium,
            cholesterol: productModel.nutrition.cholesterol
        )

        let product = Product(
            id: productModel.id.uuidString,
            barcode: productModel.barcode,
            name: productModel.name,
            brand: productModel.brand,
            category: productModel.category,
            nutritionalData: nutritionalData,
            ingredients: preferredIngredientsString(from: productModel),
            imageURL: productModel.imageURL,
            thumbnailURL: productModel.thumbnailURL ?? productModel.imageURL,
            lastScanned: Date()
        )

        let barcode = product.barcode

        AppLog.debug("📸 Saving to CoreData...", category: .scanner)

        Task.detached(priority: .utility) { [weak self, product, productModel, barcode] in
            let manager = CoreDataManager.shared

            do {
                // Determine user focus and restrictions for scoring
                let profile = try manager.fetchUserProfile()
                let focusString = profile?.healthFocus ?? "generalWellness"
                let focus = mapHealthFocus(from: focusString)
                let restrictions = mapRestrictions(from: profile?.dietaryRestrictions)

                // Compute health score from product model
                let healthScore = ScoringEngine.shared.calculateHealthScore(
                    for: productModel,
                    healthFocus: focus,
                    dietaryRestrictions: restrictions
                )
                let score = Int(healthScore.overall.rounded())

                AppLog.debug("📸 Attempting to save product: \(product.name)", category: .scanner)
                try manager.saveProduct(product)
                AppLog.debug("📸 Product saved successfully", category: .scanner)

                AppLog.debug("📸 Attempting to save scan history", category: .scanner)
                try manager.saveScanHistory(product: product, healthFocus: focusString)
                AppLog.debug("📸 Scan history saved successfully with score: \(score)", category: .scanner)
            } catch {
                AppLog.error("❌ Failed to persist scan for \(barcode): \(error.localizedDescription)", category: .scanner)
                await MainActor.run {
                    if let self {
                        self.errorMessage = "We saved the scan, but couldn't store it for history. Please try again later."
                    }
                }
            }
        }
    }

    // MARK: - End
}

// MARK: - Mapping helpers (fileprivate, non-actor isolated)
fileprivate func mapHealthFocus(from string: String) -> HealthFocus {
    switch string {
    case "gutHealth", "gut_health": return .gutHealth
    case "weightLoss", "weight_loss": return .weightLoss
    case "proteinFocus", "protein_focus": return .proteinFocus
    case "heartHealth", "heart_health": return .heartHealth
    case "generalWellness", "general_wellness": return .generalWellness
    default: return .generalWellness
    }
}

fileprivate func mapRestrictions(from stored: String?) -> [DietaryRestriction] {
    guard let stored, !stored.isEmpty else { return [] }
    let ids = stored.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    return ids.compactMap { id in
        switch id {
        case "vegan": return .vegan
        case "vegetarian": return .vegetarian
        case "glutenFree", "gluten_free": return .glutenFree
        case "dairyFree", "dairy_free": return .dairyFree
        case "nutFree", "nut_free": return .nutFree
        case "lowSodium", "low_sodium": return .lowSodium
        case "sugarFree", "sugar_free": return .sugarFree
        default: return nil
        }
    }
}

fileprivate func preferredIngredientsString(from product: ProductModel) -> String? {
    if let raw = product.rawIngredientsText?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
        return raw
    }
    let joined = product.ingredients.joined(separator: ", ")
    let trimmed = joined.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension ScannerViewModel: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let rawBarcode = readableObject.stringValue else {
            return
        }

        Task { @MainActor in
            guard self.scannedProduct == nil else { return }

            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            let cleanedBarcode = rawBarcode.trimmingCharacters(in: .whitespacesAndNewlines)
            AppLog.debug("📷 RAW BARCODE DETECTED: '\(rawBarcode)'", category: .scanner)
            AppLog.debug("📷 Cleaned barcode: '\(cleanedBarcode)' (length: \(cleanedBarcode.count))", category: .scanner)
            AppLog.debug("📷 Barcode type: \(readableObject.type.rawValue)", category: .scanner)

            guard !cleanedBarcode.isEmpty else {
                AppLog.debug("📷 Ignored empty barcode after trimming", category: .scanner)
                return
            }

            self.lookupProduct(barcode: cleanedBarcode, metadataType: readableObject.type)
        }
    }
}
