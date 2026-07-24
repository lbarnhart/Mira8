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

    /// Whether to show the duplicate scan sheet
    @Published var showDuplicateScan = false

    /// Information about the previous scan (for duplicate detection)
    @Published var previousScanDate: Date?
    @Published var previousScanScore: Double?

    private let usdaService: USDAService
    private let openFoodFactsService: OpenFoodFactsService
    private let coreDataManager: CoreDataManager
    private let recommendationService: PersonalizedRecommendationService
    private let analyticsService: ScanAnalyticsService
    private let launchConfiguration: AppLaunchConfiguration
    private var fetchTask: Task<Void, Never>?
    private var lookupGeneration = UUID()

    init(
        usdaService: USDAService = .shared,
        openFoodFactsService: OpenFoodFactsService = .shared,
        coreDataManager: CoreDataManager = .shared,
        recommendationService: PersonalizedRecommendationService = PersonalizedRecommendationService(),
        analyticsService: ScanAnalyticsService = .shared,
        launchConfiguration: AppLaunchConfiguration = .current
    ) {
        self.usdaService = usdaService
        self.openFoodFactsService = openFoodFactsService
        self.coreDataManager = coreDataManager
        self.recommendationService = recommendationService
        self.analyticsService = analyticsService
        self.launchConfiguration = launchConfiguration
        super.init()
        if launchConfiguration.shouldSimulateCameraDenied {
            hasPermission = false
        } else if launchConfiguration.shouldSimulateCameraAvailable
                    || launchConfiguration.simulatedScannedBarcode != nil {
            hasPermission = true
        } else {
            checkPermission()
        }
    }

    deinit {
        fetchTask?.cancel()
    }

    private func checkPermission() {
        guard !launchConfiguration.shouldSimulateCameraDenied else {
            hasPermission = false
            teardownSession()
            return
        }

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
        guard !launchConfiguration.shouldSimulateCameraAvailable,
              launchConfiguration.simulatedScannedBarcode == nil else { return }

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
        lookupGeneration = UUID()
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

        let generation = UUID()
        lookupGeneration = generation
        fetchTask?.cancel()
        fetchTask = Task { [weak self] in
            await self?.fetchProductData(for: barcode, generation: generation)
        }
    }

    private func fetchProductData(for barcode: String, generation: UUID) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        AppLog.debug("🔍 Attempting to fetch product for barcode: \(barcode)", category: .scanner)

        do {
            var productModel: ProductModel?
            var source = ""

            // Prefer exact local and Open Food Facts lookups. USDA is a fallback because it
            // requires a key and its search endpoint must be filtered to an exact GTIN.
            if let localItem = await LocalCatalogService.shared.product(for: barcode) {
                try Task.checkCancellation()
                let catalogProduct = await LocalCatalogService.shared.makeAPIProduct(from: localItem)
                productModel = makeProductModel(from: catalogProduct)
                source = "Local Catalog"
                AppLog.debug("✅ Product found in local catalog", category: .scanner)
            } else if let essentialProduct = await EssentialsDatabase.shared.getProductIfAvailable(barcode: barcode) {
                try Task.checkCancellation()
                productModel = makeProductModel(from: essentialProduct)
                source = "Local Catalog"
                AppLog.debug("✅ Product found in offline essentials catalog", category: .scanner)
            } else {
                do {
                    let offProduct = try await openFoodFactsService.searchProductByBarcode(barcode)
                    try Task.checkCancellation()
                    productModel = makeProductModel(from: offProduct)
                    source = "Open Food Facts"
                    AppLog.debug("✅ Product found in Open Food Facts", category: .scanner)
                } catch {
                    try Task.checkCancellation()
                    AppLog.warning("⚠️ Open Food Facts failed: \(error.localizedDescription)", category: .scanner)
                    AppLog.debug("🔄 Falling back to USDA...", category: .scanner)

                    let usdaProduct = try await usdaService.searchProductByBarcode(barcode)
                    try Task.checkCancellation()
                    productModel = makeProductModel(from: usdaProduct)
                    source = "USDA"
                    AppLog.debug("✅ Product found in USDA", category: .scanner)
                }
            }

            guard let finalModel = productModel else {
                throw NetworkError.productNotFound
            }
            try Task.checkCancellation()

            AppLog.debug("📦 Final product source: \(source)", category: .scanner)
            AppLog.debug("📦 Has image: \(!(finalModel.imageURL?.isEmpty ?? true))", category: .scanner)
            AppLog.debug("📦 Ingredient count: \(finalModel.ingredients.count)", category: .scanner)

            // Check for duplicate scan before showing product
            let isDuplicate = checkForRecentScan(barcode: barcode)
            guard lookupGeneration == generation else { return }

            await MainActor.run {
                scannedProduct = finalModel
                isLoading = false

                // Show duplicate scan sheet if this was scanned recently
                if isDuplicate {
                    showDuplicateScan = true
                }

                // Haptic feedback for successful product load
                HapticManager.shared.mediumImpact()
            }

            AppLog.debug("📸 Scanned product: \(finalModel.name)", category: .scanner)
            try Task.checkCancellation()
            guard lookupGeneration == generation else { return }
            persistScanIfNeeded(finalModel)

            // Track analytics
            let analyticsSource: ScanAnalyticsService.ScanEvent.DataSource = {
                switch source {
                case "USDA": return .usda
                case "Open Food Facts": return .openFoodFacts
                case "Local Catalog": return .localCatalog
                default: return .usda
                }
            }()
            let outcome: ScanAnalyticsService.ScanEvent.Outcome = source == "USDA" ? .success : .fallback
            await analyticsService.trackBarcodeScan(
                source: analyticsSource,
                outcome: outcome,
                productName: finalModel.name,
                brand: finalModel.brand
            )
        } catch is CancellationError {
            return
        } catch {
            guard lookupGeneration == generation else { return }
            AppLog.error("❌ Error fetching product: \(error.localizedDescription)", category: .scanner)

            // Track failure
            await analyticsService.trackBarcodeScan(
                source: .notFound,
                outcome: .failure,
                productName: nil,
                brand: nil
            )

            await MainActor.run {
                errorMessage = resolvedErrorMessage(for: error)
                isLoading = false
            }
        }

        if lookupGeneration == generation {
            fetchTask = nil
        }
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        isLoading = false
    }

    func dismissError() {
        resetScanner()
    }

    func refreshPermissionStatus() {
        guard !launchConfiguration.shouldSimulateCameraDenied else {
            hasPermission = false
            return
        }
        guard !launchConfiguration.shouldSimulateCameraAvailable,
              launchConfiguration.simulatedScannedBarcode == nil else {
            hasPermission = true
            simulateConfiguredScanIfNeeded()
            return
        }

        checkPermission()
        if hasPermission {
            Task { await setupCamera() }
        } else {
            teardownSession()
        }
    }

    func simulateConfiguredScanIfNeeded() {
        guard launchConfiguration.isUITesting,
              let barcode = launchConfiguration.simulatedScannedBarcode,
              scannedProduct == nil else {
            return
        }

        do {
            guard let storedProduct = try coreDataManager.fetchProduct(byBarcode: barcode) else {
                showErrorMessage("UI test product was not seeded for barcode \(barcode).")
                return
            }

            lastScanResult = ScanResult(barcode: barcode, type: .ean13)
            scannedProduct = storedProduct.toProductModel()
            isLoading = false
        } catch {
            showErrorMessage("Unable to load the UI test product: \(error.localizedDescription)")
        }
    }

    private func resolvedErrorMessage(for error: Error) -> String {
        let networkError = NetworkError.from(error)
        return networkError.errorDescription ?? "We couldn't find details for this barcode. Please try again."
    }

    private func makeProductModel(from apiProduct: APIProduct) -> ProductModel {
        let adjustedNutritionData = apiProduct.nutritionalDataForDisplayedServing
        let nutrition = ProductNutrition(
            from: adjustedNutritionData,
            servingSize: apiProduct.servingSizeLabelForDisplay
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
            rawIngredientsText: apiProduct.rawIngredientsText,
            dataSource: apiProduct.source
        )
    }

    /// Checks if this product was scanned recently (within last 7 days)
    /// Returns true if it's a duplicate scan
    private func checkForRecentScan(barcode: String) -> Bool {
        do {
            guard let product = try coreDataManager.fetchProduct(byBarcode: barcode),
                  let lastScanned = product.lastScanned else {
                return false
            }

            // Check if scanned within last 7 days
            let daysSinceLastScan = Calendar.current.dateComponents([.day], from: lastScanned, to: Date()).day ?? 0

            if daysSinceLastScan <= 7 {
                previousScanDate = lastScanned
                // Score will be calculated in the sheet
                previousScanScore = nil

                AppLog.debug("🔄 Duplicate scan detected: last scanned \(daysSinceLastScan) days ago", category: .scanner)
                return true
            }

            return false
        } catch {
            AppLog.warning("⚠️ Could not check for recent scan: \(error.localizedDescription)", category: .scanner)
            return false
        }
    }

    private func persistScanIfNeeded(_ productModel: ProductModel) {
        let nutritionalData = productModel.nutrition.nutritionData

        let product = Product(
            id: productModel.id.uuidString,
            barcode: productModel.barcode,
            name: productModel.name,
            brand: productModel.brand,
            category: productModel.category,
            nutritionalData: nutritionalData,
            ingredients: preferredIngredientsString(from: productModel),
            servingSize: productModel.nutrition.servingSize,
            imageURL: productModel.imageURL,
            thumbnailURL: productModel.thumbnailURL ?? productModel.imageURL,
            lastScanned: Date(),
            dataSource: productModel.dataSource
        )

        let barcode = product.barcode

        AppLog.debug("📸 Saving to CoreData...", category: .scanner)

        Task.detached(priority: .utility) { [weak self, product, productModel, barcode] in
            let manager = CoreDataManager.shared

            do {
                // Determine user focus and restrictions for scoring
                let profile = try manager.fetchUserProfile()
                let focusString = profile?.healthFocus ?? "generalWellness"
                let focus = HealthFocus(fromStored: focusString)
                let restrictions = DietaryRestriction.fromCommaSeparated(profile?.dietaryRestrictions)

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

                // Invalidate insights cache so new scan is reflected
                await self?.recommendationService.invalidateCache()
                AppLog.debug("📸 Insights cache invalidated", category: .scanner)
            } catch {
                AppLog.error("❌ Failed to persist scan for \(barcode): \(error.localizedDescription)", category: .scanner)
                await self?.showErrorMessage(
                    "We found the product, but couldn't save it to your history. Please try again later."
                )
            }
        }
    }

    // MARK: - End
}

// MARK: - Mapping helpers (fileprivate, non-actor isolated)


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

            // Haptic feedback for barcode detection
            HapticManager.shared.barcodeDetected()

            let cleanedBarcode = rawBarcode.trimmingCharacters(in: .whitespacesAndNewlines)
            AppLog.debug("📷 RAW BARCODE DETECTED: '\(rawBarcode)'", category: .scanner)
            AppLog.debug("📷 Cleaned barcode: '\(cleanedBarcode)' (length: \(cleanedBarcode.count))", category: .scanner)
            AppLog.debug("📷 Barcode type: \(readableObject.type.rawValue)", category: .scanner)

            guard !cleanedBarcode.isEmpty else {
                AppLog.debug("📷 Ignored empty barcode after trimming", category: .scanner)
                return
            }

            // Filter out QR codes - only accept product barcodes
            let validBarcodeTypes: [AVMetadataObject.ObjectType] = [
                .ean13,
                .ean8,
                .upce,
                .code128
            ]

            guard validBarcodeTypes.contains(readableObject.type) else {
                AppLog.debug("📷 Ignored non-product barcode type: \(readableObject.type.rawValue)", category: .scanner)
                return
            }

            self.lookupProduct(barcode: cleanedBarcode, metadataType: readableObject.type)
        }
    }
}
