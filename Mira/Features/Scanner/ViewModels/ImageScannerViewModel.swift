import SwiftUI
import AVFoundation
import os

/// ViewModel for image-based product scanning.
/// Handles camera capture, image recognition, and product matching.
@MainActor
final class ImageScannerViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var state: ImageScanState = .idle
    @Published private(set) var capturedImage: UIImage?
    @Published private(set) var identification: ProductIdentification?
    @Published private(set) var matches: [ProductMatch] = []
    @Published var selectedMatch: ProductMatch?
    @Published var showDisambiguation = false

    // MARK: - Dependencies

    private let recognitionService: ImageRecognitionService
    private let logger = Logger(subsystem: "com.mira8.app", category: "ImageScannerViewModel")

    // MARK: - Initialization

    init(recognitionService: ImageRecognitionService? = nil) {
        self.recognitionService = recognitionService ?? ImageRecognitionService()
    }

    // MARK: - Camera Access

    func checkCameraPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Image Capture

    func processImage(_ image: UIImage) async {
        guard state != .processing && state != .identifying && state != .searching else {
            logger.warning("Already processing, ignoring new image")
            return
        }

        capturedImage = image
        state = .processing

        // Validate image
        let validation = await validateImage(image)
        switch validation {
        case .invalid(let reason):
            state = .error(.imageProcessingFailed)
            logger.warning("Image validation failed: \(reason)")
            return
        case .warning(let reason):
            logger.info("Image warning: \(reason)")
        case .valid:
            break
        }

        // Run recognition pipeline
        await recognizeProduct(from: image)
    }

    func processImageData(_ data: Data) async {
        guard let image = UIImage(data: data) else {
            state = .error(.imageProcessingFailed)
            return
        }

        await processImage(image)
    }

    // MARK: - Recognition Pipeline

    private func recognizeProduct(from image: UIImage) async {
        logger.info("🔄 Starting recognition pipeline")
        state = .identifying

        do {
            // Get identification first (for UI feedback)
            logger.info("📸 Step 1: Identifying product...")
            let ident = try await recognitionService.identifyOnly(from: image)
            identification = ident
            logger.info("✅ Step 1 complete: \(ident.name) (confidence: \(ident.confidence))")

            state = .searching
            logger.info("🔍 Step 2: Searching for matches...")

            // Then search for matches using the identification we already have
            let productMatches = try await recognitionService.searchMatches(for: ident)
            matches = productMatches
            logger.info("✅ Step 2 complete: Found \(productMatches.count) matches")

            if productMatches.isEmpty {
                logger.warning("❌ No matches found in database")
                state = .noMatches
            } else if productMatches.count == 1 {
                // Single match - auto-select
                logger.info("🎯 Single match: \(productMatches[0].name) (score: \(productMatches[0].matchScore))")
                selectedMatch = productMatches[0]
                state = .matched(productMatches)
            } else {
                // Multiple matches - show disambiguation
                logger.info("🔀 Multiple matches (\(productMatches.count)), showing disambiguation")
                state = .matched(productMatches)
                showDisambiguation = true
            }

            logger.info("Recognition complete: \(productMatches.count) matches")
        } catch let error as ImageScanError {
            state = .error(error)
            logger.error("❌ Recognition failed with ImageScanError: \(error.localizedDescription)")
        } catch {
            state = .error(.identificationFailed)
            logger.error("❌ Recognition failed with unexpected error: \(error.localizedDescription)")
        }
    }

    // MARK: - Match Selection

    func selectMatch(_ match: ProductMatch) {
        selectedMatch = match
        showDisambiguation = false
        logger.info("Selected match: \(match.name) (barcode: \(match.barcode))")
    }

    func confirmMatch() -> String? {
        guard let match = selectedMatch else { return nil }
        return match.barcode
    }

    // MARK: - Retry / Reset

    func retry() {
        guard let image = capturedImage else {
            reset()
            return
        }

        Task {
            await recognizeProduct(from: image)
        }
    }

    func retryWithNewImage() {
        reset()
    }

    func reset() {
        state = .idle
        capturedImage = nil
        identification = nil
        matches = []
        selectedMatch = nil
        showDisambiguation = false
    }

    // MARK: - Helpers

    private func validateImage(_ image: UIImage) async -> ImageValidationResult {
        ProductImageProcessor.validate(image)
    }

    // MARK: - Computed Properties

    var isProcessing: Bool {
        switch state {
        case .processing, .identifying, .searching:
            return true
        default:
            return false
        }
    }

    var hasError: Bool {
        if case .error = state {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .error(let error) = state {
            return error.errorDescription
        }
        return nil
    }

    var recoveryMessage: String? {
        if case .error(let error) = state {
            return error.recoveryMessage
        }
        return nil
    }

    var statusMessage: String {
        switch state {
        case .idle:
            return "Point camera at a product"
        case .capturing:
            return "Hold steady..."
        case .processing:
            return "Processing image..."
        case .identifying:
            return "Identifying product..."
        case .searching:
            if let name = identification?.name {
                return "Searching for \"\(name)\"..."
            }
            return "Searching..."
        case .matched(let matches):
            if matches.count == 1 {
                return "Product found!"
            }
            return "Found \(matches.count) possible matches"
        case .noMatches:
            return "No matching products found"
        case .error:
            return "Something went wrong"
        }
    }
}

// MARK: - Preview Helper

extension ImageScannerViewModel {
    static var preview: ImageScannerViewModel {
        let vm = ImageScannerViewModel()
        vm.identification = ProductIdentification(
            name: "Cheerios Original",
            brand: "General Mills",
            category: "Cereal",
            confidence: 0.92
        )
        vm.matches = [
            ProductMatch(
                id: "1",
                barcode: "016000275287",
                name: "Cheerios Original",
                brand: "General Mills",
                category: "Cereals",
                thumbnailURL: nil,
                matchScore: 0.95
            ),
            ProductMatch(
                id: "2",
                barcode: "016000487932",
                name: "Cheerios Honey Nut",
                brand: "General Mills",
                category: "Cereals",
                thumbnailURL: nil,
                matchScore: 0.72
            )
        ]
        vm.state = .matched(vm.matches)
        return vm
    }
}
