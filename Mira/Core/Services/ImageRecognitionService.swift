import UIKit
import os
import Vision

/// Service for recognizing products from images using Claude Vision API.
/// Handles the full pipeline: image processing -> AI identification -> product search -> fuzzy matching.
/// Uses USDA as primary database (better US coverage) with Open Food Facts as fallback.
actor ImageRecognitionService {

    private let claudeService: ClaudeService
    private let usdaService: USDAService
    private let openFoodFactsService: OpenFoodFactsService
    private let logger = Logger(subsystem: "com.mira8.app", category: "ImageRecognition")
    private let configuration: ImageScanConfiguration

    init(
        claudeService: ClaudeService = .shared,
        usdaService: USDAService = .shared,
        openFoodFactsService: OpenFoodFactsService = OpenFoodFactsService(),
        configuration: ImageScanConfiguration = .default
    ) {
        self.claudeService = claudeService
        self.usdaService = usdaService
        self.openFoodFactsService = openFoodFactsService
        self.configuration = configuration
    }

    // MARK: - Main Recognition Pipeline

    /// Recognize a product from an image and find matching products in the database.
    /// - Parameter image: The product image to analyze
    /// - Returns: Array of matching products, sorted by match score
    func recognizeProduct(from image: UIImage) async throws -> [ProductMatch] {
        logger.info("Starting product recognition pipeline")

        // Step 1: Process image
        guard let imageData = ProductImageProcessor.processForRecognition(image, configuration: configuration) else {
            logger.error("Failed to process image")
            throw ImageScanError.imageProcessingFailed
        }

        logger.debug("Image processed: \(imageData.count / 1024)KB")

        // Step 2: Identify product using Claude when configured, otherwise on-device OCR.
        let identification = try await identifyProduct(imageData: imageData)

        logger.info("Identified product: \(identification.name) (confidence: \(identification.confidence))")

        // Step 3: Search for matching products
        let matches = try await searchAndMatchProducts(identification: identification)

        logger.info("Found \(matches.count) potential matches")

        return matches
    }

    /// Recognize a product from raw image data
    func recognizeProduct(fromData data: Data) async throws -> [ProductMatch] {
        guard let processedData = ProductImageProcessor.processFromData(data, configuration: configuration) else {
            throw ImageScanError.imageProcessingFailed
        }

        let identification = try await identifyProduct(imageData: processedData)
        return try await searchAndMatchProducts(identification: identification)
    }

    // MARK: - Product Identification

    private func identifyProduct(imageData: Data) async throws -> ProductIdentification {
        let isClaudeConfigured = await claudeService.isConfigured
        guard isClaudeConfigured else {
            logger.info("Claude is unavailable; using on-device product-label recognition")
            return try await identifyProductLocally(imageData: imageData)
        }

        let prompt = buildIdentificationPrompt()

        do {
            let response = try await claudeService.analyzeImage(
                imageData: imageData,
                prompt: prompt,
                systemPrompt: systemPrompt
            )

            return try parseIdentificationResponse(response)
        } catch {
            if error is CancellationError || Task.isCancelled {
                throw CancellationError()
            }

            logger.warning("Vision API failed; falling back to on-device recognition: \(error.localizedDescription)")
            return try await identifyProductLocally(imageData: imageData)
        }
    }

    private func identifyProductLocally(imageData: Data) async throws -> ProductIdentification {
        try await Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            guard let image = UIImage(data: imageData), let cgImage = image.cgImage else {
                throw ImageScanError.imageProcessingFailed
            }

            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            try Task.checkCancellation()

            let ignoredTerms = [
                "nutrition facts", "calories", "ingredients", "serving size",
                "distributed by", "manufactured by", "net weight", "net wt"
            ]

            let candidates = (request.results ?? [])
                .compactMap { $0.topCandidates(1).first }
                .filter { $0.confidence >= 0.35 }
                .map { $0.string.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { text in
                    let lowered = text.lowercased()
                    return text.count >= 3 && !ignoredTerms.contains(where: lowered.contains)
                }

            var uniqueLines: [String] = []
            var seen = Set<String>()
            for line in candidates {
                let key = line.lowercased()
                if seen.insert(key).inserted {
                    uniqueLines.append(line)
                }
            }

            let productLines = Array(uniqueLines.prefix(4))
            guard !productLines.isEmpty else {
                throw ImageScanError.noProductDetected
            }

            let productName = productLines.joined(separator: " ")
            let confidence = min(0.82, 0.45 + Double(productLines.count) * 0.09)

            return ProductIdentification(
                name: productName,
                brand: productLines.count > 1 ? productLines.first : nil,
                category: nil,
                confidence: confidence,
                additionalDetails: [
                    "reasoning": "Identified from text detected on the package on this device.",
                    "alternatives": productLines.dropFirst().joined(separator: ", ")
                ]
            )
        }.value
    }

    private var systemPrompt: String {
        """
        You are a product identification expert specializing in reading food packaging labels.
        Your task is to identify food products from images taken in grocery stores or kitchens.

        IMPORTANT: Be VERY liberal in identifying food - if you see ANY of these, it's food:
        - Cans (soup, beans, vegetables, fruit, etc.)
        - Boxes with nutrition labels
        - Bags of chips, snacks, or packaged foods
        - Bottles with beverages or sauces
        - Any packaging with food brand names
        - Any container showing food imagery (beans, vegetables, fruits, etc.)

        Even if the image is blurry, if it LOOKS like food packaging, mark it as food.
        """
    }

    private func buildIdentificationPrompt() -> String {
        """
        Analyze this image and identify the food product by reading the text on the packaging.

        Look for:
        - Brand name (e.g., "Bush's", "Mission", "Cheerios")
        - Product type (e.g., "Chickpeas", "Tortillas", "Cereal")
        - Descriptors (e.g., "Organic", "Low Sodium", "Whole Grain")
        - Any visible text on cans, boxes, bottles, or bags

        Even if some text is unclear, identify what you CAN read and set confidence accordingly.

        Respond in JSON format:
        {
          "product_name": "Full product name combining brand + type + descriptors (e.g., 'Bush's Organic Chickpeas')",
          "brand": "Brand name if visible, or null",
          "category": "Product category (e.g., canned beans, tortillas, snacks, cereal, beverages)",
          "confidence": 0.0 to 1.0 confidence score,
          "reasoning": "Brief explanation of what text you could read",
          "alternative_names": ["Other possible names or variations"],
          "is_food": true or false
        }

        Important:
        - If you can read ANY text suggesting a food product, set is_food to true
        - Set confidence based on how much text is readable (0.6+ if you can read brand OR product name)
        - If packaging shows food imagery (beans, vegetables, etc.), it's likely food
        - Be specific with product names: "Bush's Organic Chickpeas" not just "chickpeas"
        - Common food packaging includes: cans, boxes, bags, bottles, jars, pouches
        """
    }

    private func parseIdentificationResponse(_ response: String) throws -> ProductIdentification {
        // Log raw response for debugging
        logger.debug("Raw Claude Vision response: \(response)")

        // Extract JSON from response
        guard let jsonStart = response.firstIndex(of: "{"),
              let jsonEnd = response.lastIndex(of: "}") else {
            logger.error("No JSON found in response")
            throw ImageScanError.identificationFailed
        }

        let jsonString = String(response[jsonStart...jsonEnd])
        logger.debug("Extracted JSON: \(jsonString)")

        guard let data = jsonString.data(using: .utf8) else {
            logger.error("Failed to convert JSON string to data")
            throw ImageScanError.identificationFailed
        }

        let decoder = JSONDecoder()

        do {
            let visionResponse = try decoder.decode(VisionIdentificationResponse.self, from: data)
            logger.debug("Successfully decoded - isFood: \(visionResponse.isFood), productName: \(visionResponse.productName ?? "nil"), confidence: \(visionResponse.confidence)")

            // Continue with validation...
            return try validateAndCreateIdentification(from: visionResponse)
        } catch {
            logger.error("JSON decode error: \(error.localizedDescription)")
            logger.error("Failed JSON string: \(jsonString)")
            throw ImageScanError.identificationFailed
        }
    }

    private func validateAndCreateIdentification(from visionResponse: VisionIdentificationResponse) throws -> ProductIdentification {
        // Check if it's actually a food product
        guard visionResponse.isFood else {
            logger.info("Not a food product: \(visionResponse.reasoning ?? "No reason provided")")
            throw ImageScanError.noProductDetected
        }

        // Check if product name was identified
        guard let productName = visionResponse.productName, !productName.isEmpty else {
            logger.warning("No product name identified: \(visionResponse.reasoning ?? "Unknown reason")")
            throw ImageScanError.identificationFailed
        }

        // Log warning for low confidence but continue
        if visionResponse.confidence < configuration.confidenceThreshold {
            logger.warning("Low confidence identification: \(visionResponse.confidence)")
        }

        return ProductIdentification(
            name: productName,
            brand: visionResponse.brand,
            category: visionResponse.category,
            confidence: visionResponse.confidence,
            additionalDetails: [
                "reasoning": visionResponse.reasoning ?? "",
                "alternatives": visionResponse.alternativeNames?.joined(separator: ", ") ?? ""
            ]
        )
    }

    // MARK: - Product Search and Matching

    private func searchAndMatchProducts(identification: ProductIdentification) async throws -> [ProductMatch] {
        logger.info("🔍 Searching for matches: name=\"\(identification.name)\", brand=\"\(identification.brand ?? "nil")\"")
        var allMatches: [ProductMatch] = []

        // Build multiple search queries to maximize chances of finding the right product
        let searchQueries = buildSearchQueries(from: identification)
        logger.debug("📝 Search queries to try: \(searchQueries)")

        // STEP 1: Search USDA first (primary database for US products)
        logger.info("🇺🇸 Searching USDA (primary)...")
        for (index, query) in searchQueries.enumerated() {
            do {
                logger.debug("📡 USDA search attempt \(index + 1): \"\(query)\"")
                let searchResults = try await usdaService.searchByName(
                    name: query,
                    brand: identification.brand,
                    limit: configuration.maxSearchResults * 2
                )
                logger.info("📦 USDA: Received \(searchResults.count) results for query: \(query)")

                // Convert and score results
                let matches = scoreSearchResults(searchResults, identification: identification)

                // Log each match for debugging
                for match in matches.prefix(5) {
                    logger.debug("  - \(match.name) (brand: \(match.brand ?? "nil"), score: \(String(format: "%.3f", match.matchScore)))")
                }

                allMatches.append(contentsOf: matches)

                // If we found high-confidence matches, we can stop searching
                if matches.contains(where: { $0.matchScore >= 0.7 }) {
                    logger.info("⭐ Found high-confidence USDA match, stopping search")
                    break
                }
            } catch {
                try Task.checkCancellation()
                logger.warning("❌ USDA search failed for query \"\(query)\": \(error.localizedDescription)")
                continue
            }
        }

        // STEP 2: Fall back to Open Food Facts if USDA didn't find good matches
        let usdaBestScore = allMatches.max(by: { $0.matchScore < $1.matchScore })?.matchScore ?? 0
        if usdaBestScore < 0.6 {
            logger.info("🌍 USDA best score \(String(format: "%.2f", usdaBestScore)) < 0.6, trying Open Food Facts...")

            for (index, query) in searchQueries.enumerated() {
                do {
                    logger.debug("📡 OFF search attempt \(index + 1): \"\(query)\"")
                    let searchResults = try await openFoodFactsService.searchByName(
                        name: query,
                        brand: identification.brand,
                        limit: configuration.maxSearchResults * 2
                    )
                    logger.info("📦 OFF: Received \(searchResults.count) results for query: \(query)")

                    // Convert and score results
                    let matches = scoreSearchResults(searchResults, identification: identification)

                    // Log each match for debugging
                    for match in matches.prefix(5) {
                        logger.debug("  - \(match.name) (brand: \(match.brand ?? "nil"), score: \(String(format: "%.3f", match.matchScore)))")
                    }

                    allMatches.append(contentsOf: matches)

                    // If we found high-confidence matches, we can stop searching
                    if matches.contains(where: { $0.matchScore >= 0.7 }) {
                        logger.info("⭐ Found high-confidence OFF match, stopping search")
                        break
                    }
                } catch {
                    try Task.checkCancellation()
                    logger.warning("❌ OFF search failed for query \"\(query)\": \(error.localizedDescription)")
                    continue
                }
            }
        }

        // STEP 3: Try alternative names if we still haven't found good matches
        let bestMatchScore = allMatches.max(by: { $0.matchScore < $1.matchScore })?.matchScore ?? 0
        if bestMatchScore < 0.6,
           let alternatives = identification.additionalDetails["alternatives"],
           !alternatives.isEmpty {
            logger.info("🔄 Best score \(String(format: "%.2f", bestMatchScore)) < 0.6, trying alternative names: \(alternatives)")

            for altName in alternatives.components(separatedBy: ", ").prefix(2) {
                // Try USDA first for alternatives
                do {
                    logger.debug("  USDA trying: \(altName)")
                    let altResults = try await usdaService.searchByName(
                        name: altName,
                        brand: identification.brand,
                        limit: 5
                    )

                    let matches = scoreSearchResults(altResults, identification: identification)
                    logger.debug("  USDA found \(matches.count) matches for \(altName)")
                    allMatches.append(contentsOf: matches)

                    if matches.contains(where: { $0.matchScore >= 0.6 }) {
                        continue // Skip OFF for this alternative
                    }
                } catch {
                    try Task.checkCancellation()
                    logger.warning("  USDA alternative search failed for \(altName): \(error.localizedDescription)")
                }

                // Fall back to OFF for alternatives
                do {
                    logger.debug("  OFF trying: \(altName)")
                    let altResults = try await openFoodFactsService.searchByName(
                        name: altName,
                        brand: identification.brand,
                        limit: 5
                    )

                    let matches = scoreSearchResults(altResults, identification: identification)
                    logger.debug("  OFF found \(matches.count) matches for \(altName)")
                    allMatches.append(contentsOf: matches)
                } catch {
                    try Task.checkCancellation()
                    logger.warning("  OFF alternative search failed for \(altName): \(error.localizedDescription)")
                    continue
                }
            }
        }

        // Sort by score and deduplicate
        logger.debug("🎯 Total matches before filtering: \(allMatches.count)")
        let uniqueMatches = deduplicateMatches(allMatches)
        logger.debug("🎯 After deduplication: \(uniqueMatches.count)")

        let filteredMatches = uniqueMatches
            .filter { $0.matchScore >= configuration.confidenceThreshold }
        logger.debug("🎯 After confidence filter: \(filteredMatches.count)")

        let finalMatches = filteredMatches
            .sorted { $0.matchScore > $1.matchScore }
            .prefix(configuration.maxSearchResults)
            .map { $0 }

        logger.info("✅ Final result: \(finalMatches.count) matches")
        return finalMatches
    }

    /// Build multiple search queries from the identification to maximize chances of finding the right product
    private func buildSearchQueries(from identification: ProductIdentification) -> [String] {
        var queries: [String] = []
        let name = identification.name

        // Query 1: Full name as identified
        queries.append(name)

        // Query 2: Extract key product descriptors and search with those
        // This helps distinguish "100% Whole Grain" from "Stone-Ground White"
        let keyDescriptors = extractKeyDescriptors(from: name)
        if !keyDescriptors.isEmpty {
            // Try searching with descriptors + category
            if let category = identification.category {
                let descriptorQuery = (keyDescriptors + [category]).joined(separator: " ")
                if descriptorQuery != name {
                    queries.append(descriptorQuery)
                }
            }
        }

        // Query 3: If we have brand, try brand + simplified product type
        if let brand = identification.brand {
            let simplifiedName = simplifyProductName(name, removingBrand: brand)
            if simplifiedName != name {
                queries.append("\(brand) \(simplifiedName)")
            }
        }

        return queries.uniqued()
    }

    /// Extract key descriptive words that distinguish product variants
    private func extractKeyDescriptors(from name: String) -> [String] {
        let lowercaseName = name.lowercased()

        // Important descriptors that distinguish product variants
        let importantDescriptors: [(pattern: String, descriptor: String)] = [
            ("100%", "100%"),
            ("whole grain", "whole grain"),
            ("stone-ground", "stone-ground"),
            ("stone ground", "stone ground"),
            ("white", "white"),
            ("organic", "organic"),
            ("unbleached", "unbleached"),
            ("all-purpose", "all-purpose"),
            ("all purpose", "all purpose"),
            ("bread flour", "bread"),
            ("cake flour", "cake"),
            ("pastry flour", "pastry"),
            ("whole wheat", "whole wheat"),
            ("gluten-free", "gluten-free"),
            ("gluten free", "gluten free"),
            ("low sodium", "low sodium"),
            ("no salt", "no salt"),
            ("unsalted", "unsalted"),
            ("original", "original"),
            ("classic", "classic"),
            ("extra virgin", "extra virgin"),
            ("virgin", "virgin"),
            ("light", "light"),
            ("reduced fat", "reduced fat"),
            ("fat free", "fat free"),
            ("sugar free", "sugar free"),
            ("no sugar", "no sugar")
        ]

        var found: [String] = []
        for (pattern, descriptor) in importantDescriptors {
            if lowercaseName.contains(pattern) {
                found.append(descriptor)
            }
        }

        return found
    }

    /// Remove brand name and common filler words to get the core product type
    private func simplifyProductName(_ name: String, removingBrand brand: String) -> String {
        var simplified = name
            .replacingOccurrences(of: brand, with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove common filler words at the start
        let fillerPrefixes = ["organic", "natural", "premium", "artisan"]
        for filler in fillerPrefixes {
            if simplified.lowercased().hasPrefix(filler + " ") {
                simplified = String(simplified.dropFirst(filler.count + 1))
            }
        }

        return simplified.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func scoreSearchResults(
        _ results: [APIProduct],
        identification: ProductIdentification
    ) -> [ProductMatch] {
        results.map { product in
            let brandValue: String? = product.brand.isEmpty ? nil : product.brand
            let categoryValue: String? = product.category.isEmpty ? nil : product.category
            let score = ProductFuzzyMatcher.calculateMatchScore(
                identification: identification,
                candidateName: product.name,
                candidateBrand: brandValue,
                candidateCategory: categoryValue
            )

            // Log each score for debugging
            logger.debug("📊 Score: \(String(format: "%.2f", score)) for '\(product.name)' (cat: \(product.category)) vs '\(identification.name)' (cat: \(identification.category ?? "nil"))")

            return ProductMatch(
                id: product.barcode,
                barcode: product.barcode,
                name: product.name,
                brand: brandValue,
                category: product.category,
                thumbnailURL: product.thumbnailURL,
                matchScore: score
            )
        }
    }

    private func deduplicateMatches(_ matches: [ProductMatch]) -> [ProductMatch] {
        var seen = Set<String>()
        return matches.filter { match in
            if seen.contains(match.barcode) {
                return false
            }
            seen.insert(match.barcode)
            return true
        }
    }
}

// MARK: - Convenience Methods

extension ImageRecognitionService {

    /// Quick check if image is suitable for recognition
    func validateImage(_ image: UIImage) -> ImageValidationResult {
        ProductImageProcessor.validate(image)
    }

    /// Get just the identification without searching (for debugging/preview)
    func identifyOnly(from image: UIImage) async throws -> ProductIdentification {
        guard let imageData = ProductImageProcessor.processForRecognition(image, configuration: configuration) else {
            throw ImageScanError.imageProcessingFailed
        }

        return try await identifyProduct(imageData: imageData)
    }

    /// Search for product matches using an existing identification
    func searchMatches(for identification: ProductIdentification) async throws -> [ProductMatch] {
        return try await searchAndMatchProducts(identification: identification)
    }
}

// MARK: - Array Extension for Deduplication

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
