import Foundation

// MARK: - Open Food Facts Service
actor OpenFoodFactsService {
    static let shared = OpenFoodFactsService()

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    // MARK: - Public Methods
    // Diagnostic test to validate image URLs from OFF and that images are fetchable
    func testImageFetch() async {
        let testBarcode = "5449000000996" // Coca-Cola
        let urlString = "\(Constants.API.openFoodFactsBaseURL)/product/\(testBarcode).json"

        AppLog.debug("🧪 Testing image fetch for barcode: \(testBarcode)", category: .network)
        AppLog.debug("🧪 URL: \(urlString)", category: .network)

        guard let url = URL(string: urlString) else {
            AppLog.warning("🧪 ❌ Invalid URL", category: .network)
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse {
                AppLog.debug("🧪 HTTP Status: \(httpResponse.statusCode)", category: .network)
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                AppLog.debug("🧪 Raw JSON Response (first 1000 chars):", category: .network)
                AppLog.debug(String(jsonString.prefix(1000)), category: .network)
            }

            let decoder = JSONDecoder()
            // Keep snake_case keys as-is for these test structs
            let apiResponse = try decoder.decode(OFFImageTestResponse.self, from: data)

            let productName = apiResponse.product.product_name ?? "nil"
            let imageUrl = apiResponse.product.image_url ?? "nil"
            let imageFrontUrl = apiResponse.product.image_front_url ?? "nil"
            let imageSmallUrl = apiResponse.product.image_small_url ?? "nil"
            AppLog.debug("🧪 Product name: \(productName)", category: .network)
            AppLog.debug("🧪 image_url: \(imageUrl)", category: .network)
            AppLog.debug("🧪 image_front_url: \(imageFrontUrl)", category: .network)
            AppLog.debug("🧪 image_small_url: \(imageSmallUrl)", category: .network)

            if let imageURLString = apiResponse.product.image_front_url ?? apiResponse.product.image_url,
               let imageURL = URL(string: imageURLString) {
                AppLog.debug("🧪 ✅ Valid image URL created: \(imageURL)", category: .network)

                let (imageData, imageResponse) = try await URLSession.shared.data(from: imageURL)
                if let httpResponse = imageResponse as? HTTPURLResponse {
                    AppLog.debug("🧪 Image HTTP Status: \(httpResponse.statusCode)", category: .network)
                    AppLog.debug("🧪 Image size: \(imageData.count) bytes", category: .network)
                }
            } else {
                AppLog.warning("🧪 ❌ Could not create valid image URL", category: .network)
            }

        } catch {
            AppLog.error("🧪 ❌ Error: \(error.localizedDescription)", category: .network)
        }
    }
    func searchProductByBarcode(_ barcode: String) async throws -> APIProduct {
        #if DEBUG
        AppLog.info("🖼️ Fetching product for barcode: \(barcode)", category: .network)
        #endif
        let endpoint = OpenFoodFactsEndpoint.productByBarcode(barcode: barcode)
        let data = try await apiClient.requestData(endpoint)

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            let preview = jsonString.count > 2000
                ? String(jsonString.prefix(2000)) + "… (truncated)"
                : jsonString
            AppLog.debug("🔍 OFF JSON Preview (<=2000 chars): \(preview)", category: .network)
        }
        #endif

        let response: OpenFoodFactsProductResponse = try JSONDecoder().decode(OpenFoodFactsProductResponse.self, from: data)

        guard response.status == 1, let raw = response.product else {
            throw NetworkError.productNotFound
        }

        #if DEBUG
        // Log raw image data from API for debugging purposes only.
        AppLog.debug("🖼️ Raw API Response:", category: .network)
        let imageUrl = raw.image_url ?? "nil"
        let imageFrontUrl = raw.image_front_url ?? "nil"
        let imageSmallUrl = raw.image_small_url ?? "nil"
        let selectedImageUrl = raw.selected_images?.front?.display?.en ?? "nil"
        let productName = raw.product_name ?? "nil"
        let brandOwner = raw.brand_owner ?? "nil"
        let brands = raw.brands ?? "nil"
        let categories = raw.categories ?? "nil"
        AppLog.debug("  - image_url: \(imageUrl)", category: .network)
        AppLog.debug("  - image_front_url: \(imageFrontUrl)", category: .network)
        AppLog.debug("  - image_small_url: \(imageSmallUrl)", category: .network)
        AppLog.debug("  - selected_images.front.display.en: \(selectedImageUrl)", category: .network)
        AppLog.debug("  - product_name: \(productName)", category: .network)
        AppLog.debug("  - brand_owner: \(brandOwner)", category: .network)
        AppLog.debug("  - brands: \(brands)", category: .network)
        AppLog.debug("  - categories: \(categories)", category: .network)
        let ingredientsPreview = raw.ingredients_text?.prefix(120) ?? "nil"
        AppLog.debug("  - ingredients_text preview: \(ingredientsPreview)", category: .network)
        #endif

        let product = try mapToProduct(raw)
        #if DEBUG
        let prodImageUrl = product.imageURL ?? "nil"
        let prodThumbUrl = product.thumbnailURL ?? "nil"
        AppLog.debug("🖼️ Product created with imageURL: \(prodImageUrl) | thumb: \(prodThumbUrl)", category: .network)
        #endif
        return product
    }

    func searchSimilarProducts(category: String, limit: Int = 20) async throws -> [APIProduct] {
        AppLog.debug("🌐 OFF: Search similar by category slug=\(category), limit=\(limit)", category: .network)
        let endpoint = OpenFoodFactsEndpoint.searchByCategory(category: category, limit: limit)
        let data = try await apiClient.requestData(endpoint)

        if let jsonString = String(data: data, encoding: .utf8) {
            let preview = String(jsonString.prefix(2000))
            AppLog.debug("📄 RAW SEARCH JSON (first 2000 chars): \(preview)", category: .network)
        }

        let response: OpenFoodFactsSearchResponse = try JSONDecoder().decode(OpenFoodFactsSearchResponse.self, from: data)
        let products = response.products ?? []
        AppLog.debug("🌐 OFF: Raw products returned: \(products.count)", category: .network)
        if let first = products.first {
            AppLog.debug("🔍 OFF Search Debug - first product raw:", category: .network)
            let code = first.code ?? "nil"
            let prodName = first.product_name ?? "nil"
            let prodNameEn = first.product_name_en ?? "nil"
            let genericName = first.generic_name ?? "nil"
            let brandsList = first.brands ?? "nil"
            let imageFront = first.image_front_url ?? "nil"
            AppLog.debug("   code: \(code)", category: .network)
            AppLog.debug("   product_name: \(prodName)", category: .network)
            AppLog.debug("   product_name_en: \(prodNameEn)", category: .network)
            AppLog.debug("   generic_name: \(genericName)", category: .network)
            AppLog.debug("   brands: \(brandsList)", category: .network)
            AppLog.debug("   image_front_url: \(imageFront)", category: .network)
            AppLog.debug("   categories_hierarchy: \(first.categories_hierarchy ?? [])", category: .network)
        }
        let mapped: [APIProduct] = products.compactMap { product in
            if let mapped = try? mapToProduct(product) {
                let mappedImageUrl = mapped.imageURL ?? "nil"
                let mappedThumbUrl = mapped.thumbnailURL ?? "nil"
                AppLog.debug("🌐 OFF: Mapped alt \(mapped.name) | img \(mappedImageUrl) thumb \(mappedThumbUrl) | cals \(mapped.nutritionalData.calories), protein \(mapped.nutritionalData.protein)", category: .network)
                return mapped
            }
            return nil
        }
        AppLog.debug("🌐 OFF: Mapped alternatives: \(mapped.count)", category: .network)
        return mapped
    }
}

// MARK: - Open Food Facts Endpoints
private enum OpenFoodFactsEndpoint: APIEndpoint {
    case productByBarcode(barcode: String)
    case searchByCategory(category: String, limit: Int)

    var baseURL: String {
        return Constants.API.openFoodFactsBaseURL
    }

    var path: String {
        switch self {
        case .productByBarcode(let barcode):
            return "/api/v2/product/\(barcode)"
        case .searchByCategory:
            return "/cgi/search.pl"
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .productByBarcode:
            return nil
        case .searchByCategory(let category, let limit):
            return [
                URLQueryItem(name: "action", value: "process"),
                URLQueryItem(name: "json", value: "1"),
                URLQueryItem(name: "page_size", value: "\(limit)"),
                URLQueryItem(name: "tagtype_0", value: "categories"),
                URLQueryItem(name: "tag_contains_0", value: "contains"),
                URLQueryItem(name: "tag_0", value: category),
                URLQueryItem(name: "sort_by", value: "popularity"),
                URLQueryItem(
                    name: "fields",
                    value: "product_name,product_name_en,generic_name,generic_name_en,brands,brand_owner,brand_owner_imported,categories,categories_hierarchy,_keywords,pnns_groups_2,ingredients_text,ingredients_text_en,nutriments,serving_size,serving_quantity,code,image_url,image_front_url,image_small_url,selected_images,nutriscore_grade,countries,countries_tags"
                )
            ]
        }
    }

    var headers: [String: String]? {
        return [
            "User-Agent": "Mira8-iOS/1.0"
        ]
    }
}

// MARK: - Open Food Facts Response Models
private struct OpenFoodFactsProductResponse: Codable {
    let code: String?
    let product: OpenFoodFactsProduct?
    let status: Int?
    let statusVerbose: String?

    enum CodingKeys: String, CodingKey {
        case code, product, status
        case statusVerbose = "status_verbose"
    }
}

private struct OpenFoodFactsSearchResponse: Codable {
    let count: Int?
    let page: Int?
    let pageCount: Int?
    let pageSize: Int?
    let products: [OpenFoodFactsProduct]?

    enum CodingKeys: String, CodingKey {
        case count, page
        case pageCount = "page_count"
        case pageSize = "page_size"
        case products
    }
}

private struct OpenFoodFactsProduct: Codable {
    let code: String?
    let product_name: String?
    let product_name_en: String?
    let generic_name: String?
    let generic_name_en: String?
    let brands: String?
    let brand_owner: String?
    let brand_owner_imported: String?
    let categories: String?
    let categories_hierarchy: [String]?
    let categories_tags: [String]?
    let _keywords: [String]?
    let pnns_groups_1: String?
    let pnns_groups_2: String?
    let ingredients_text: String?
    let ingredients_text_en: String?
    let nutriments: OpenFoodFactsNutriments?
    let serving_size: String?
    let serving_quantity: String?
    let image_url: String?
    let image_front_url: String?
    let image_small_url: String?
    let selected_images: SelectedImages?
    let nutriscore_grade: String?
    let ingredients: [Ingredient]?
    let countries: String?
    let countries_tags: [String]?
    let nova_group: Int?
    let nova_groups: String?
    let nova_groups_tags: [String]?

    enum CodingKeys: String, CodingKey {
        case code
        case product_name
        case product_name_en
        case generic_name
        case generic_name_en
        case brands
        case brand_owner
        case brand_owner_imported
        case categories
        case categories_hierarchy
        case categories_tags
        case _keywords
        case pnns_groups_1
        case pnns_groups_2
        case ingredients_text
        case ingredients_text_en
        case nutriments
        case serving_size
        case serving_quantity
        case image_url
        case image_front_url
        case image_small_url
        case selected_images
        case nutriscore_grade
        case ingredients
        case countries
        case countries_tags
        case nova_group
        case nova_groups
        case nova_groups_tags
    }

    struct SelectedImages: Codable {
        let front: FrontImage?

        struct FrontImage: Codable {
            let display: DisplayImage?

            struct DisplayImage: Codable {
                let en: String?
            }
        }
    }

    struct Ingredient: Codable {
        let id: String?
        let text: String?
        let rank: Int?
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        code = try container.decodeIfPresent(String.self, forKey: .code)
        product_name = try container.decodeIfPresent(String.self, forKey: .product_name)
        product_name_en = try container.decodeIfPresent(String.self, forKey: .product_name_en)
        generic_name = try container.decodeIfPresent(String.self, forKey: .generic_name)
        generic_name_en = try container.decodeIfPresent(String.self, forKey: .generic_name_en)
        brands = try container.decodeIfPresent(String.self, forKey: .brands)
        brand_owner = try container.decodeIfPresent(String.self, forKey: .brand_owner)
        brand_owner_imported = try container.decodeIfPresent(String.self, forKey: .brand_owner_imported)
        categories = try container.decodeIfPresent(String.self, forKey: .categories)
        categories_hierarchy = try container.decodeIfPresent([String].self, forKey: .categories_hierarchy)
        categories_tags = try container.decodeIfPresent([String].self, forKey: .categories_tags)
        _keywords = try container.decodeIfPresent([String].self, forKey: ._keywords)
        pnns_groups_1 = try container.decodeIfPresent(String.self, forKey: .pnns_groups_1)
        pnns_groups_2 = try container.decodeIfPresent(String.self, forKey: .pnns_groups_2)
        ingredients_text = try container.decodeIfPresent(String.self, forKey: .ingredients_text)
        ingredients_text_en = try container.decodeIfPresent(String.self, forKey: .ingredients_text_en)
        nutriments = try container.decodeIfPresent(OpenFoodFactsNutriments.self, forKey: .nutriments)
        serving_size = try container.decodeIfPresent(String.self, forKey: .serving_size)

        if let stringValue = try? container.decodeIfPresent(String.self, forKey: .serving_quantity) {
            serving_quantity = stringValue
        } else if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: .serving_quantity) {
            serving_quantity = String(doubleValue)
        } else if let intValue = try? container.decodeIfPresent(Int.self, forKey: .serving_quantity) {
            serving_quantity = String(intValue)
        } else {
            #if DEBUG
            let codeDescription = code ?? "unknown"
            AppLog.warning("⚠️ OFF serving_quantity decode failed for product \(codeDescription). Value was nil or of unexpected type.", category: .network)
            #endif
            serving_quantity = nil
        }

        image_url = try container.decodeIfPresent(String.self, forKey: .image_url)
        image_front_url = try container.decodeIfPresent(String.self, forKey: .image_front_url)
        image_small_url = try container.decodeIfPresent(String.self, forKey: .image_small_url)
        selected_images = try container.decodeIfPresent(SelectedImages.self, forKey: .selected_images)
        nutriscore_grade = try container.decodeIfPresent(String.self, forKey: .nutriscore_grade)
        ingredients = try container.decodeIfPresent([Ingredient].self, forKey: .ingredients)
        countries = try container.decodeIfPresent(String.self, forKey: .countries)
        countries_tags = try container.decodeIfPresent([String].self, forKey: .countries_tags)
        nova_group = try container.decodeIfPresent(Int.self, forKey: .nova_group)
        nova_groups = try container.decodeIfPresent(String.self, forKey: .nova_groups)
        nova_groups_tags = try container.decodeIfPresent([String].self, forKey: .nova_groups_tags)
    }
}

private struct OpenFoodFactsNutriments: Codable {
    let energy_100g: Double?
    let energy: Double?
    let energy_kcal_100g: Double?
    let energyKcal: Double?
    let proteins_100g: Double?
    let proteins: Double?
    let carbohydrates_100g: Double?
    let carbohydrates: Double?
    let fat_100g: Double?
    let fat: Double?
    let fiber_100g: Double?
    let fiber: Double?
    let sugars_100g: Double?
    let sugars: Double?
    let salt_100g: Double?
    let salt: Double?
    let sodium_100g: Double?
    let sodium: Double?
    let cholesterol_100g: Double?
    let cholesterol: Double?

    enum CodingKeys: String, CodingKey {
        case energy_100g = "energy_100g"
        case energy = "energy"
        case energy_kcal_100g = "energy-kcal_100g"
        case energyKcal = "energy-kcal"
        case proteins_100g
        case proteins
        case carbohydrates_100g
        case carbohydrates
        case fat_100g
        case fat
        case fiber_100g
        case fiber
        case sugars_100g
        case sugars
        case salt_100g
        case salt
        case sodium_100g
        case sodium
        case cholesterol_100g
        case cholesterol
    }
}

// MARK: - Mapping Extensions
private extension OpenFoodFactsService {
    func mapToProduct(_ offProduct: OpenFoodFactsProduct) throws -> APIProduct {
        let nutritionalData = mapNutritionalData(offProduct.nutriments)

        // Choose best image URL
        let bestImage = offProduct.bestImageURL
        let bestThumb = offProduct.bestThumbnailURL
        let bestImageStr = bestImage ?? "nil"
        let bestThumbStr = bestThumb ?? "nil"
        AppLog.debug("🖼️ OFF Picker -> image: \(bestImageStr), thumb: \(bestThumbStr)", category: .network)

        let name = preferredName(from: offProduct)
        AppLog.debug("🌐 OFF Name resolved: \(name)", category: .network)

        let brand = preferredBrand(from: offProduct)
        AppLog.debug("🌐 OFF Brand resolved: \(brand)", category: .network)

        var category = extractCategory(from: offProduct)
        let categorySlug = determineBestCategorySlug(from: offProduct)
        if let slug = categorySlug {
            category = formatCategoryName(slug)
        }
        AppLog.debug("🌐 OFF Category resolved: \(category)", category: .network)
        let categorySlugStr = categorySlug ?? "nil"
        AppLog.debug("🌐 OFF Category slug: \(categorySlugStr)", category: .network)

        let rawIngredients = offProduct.ingredients_text ?? offProduct.ingredients_text_en
        let parsedIngredients = parseIngredients(rawIngredients)
        let rawIngredientsStr = rawIngredients ?? "nil"
        AppLog.debug("🌿 OFF Ingredients text: \(rawIngredientsStr)", category: .network)
        AppLog.debug("🌿 OFF Parsed ingredients count: \(parsedIngredients.count)", category: .network)
        if !parsedIngredients.isEmpty {
            AppLog.debug("🌿 OFF Parsed sample: \(parsedIngredients.prefix(5))", category: .network)
        }

        // Derive processing level from NOVA group (preferred) or nil
        let processingLevel = ProcessingLevel.fromNOVA(offProduct.nova_group)
        if let novaGroup = offProduct.nova_group, let level = processingLevel {
            AppLog.debug("🔬 OFF NOVA group: \(novaGroup) → ProcessingLevel: \(level.displayName)", category: .network)
        } else {
            AppLog.debug("🔬 OFF NOVA group not available, processingLevel will be nil", category: .network)
        }

        // Use raw serving_size text as display string (e.g., "2 tbsp (30 g)")
        let servingSizeDisplay = offProduct.serving_size?.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayStr = servingSizeDisplay ?? "nil"
        AppLog.debug("🥄 OFF serving_size display: \(displayStr)", category: .network)

        return APIProduct(
            id: offProduct.code ?? UUID().uuidString,
            barcode: offProduct.code ?? "",
            name: name,
            brand: brand,
            category: category,
            categorySlug: categorySlug,
            ingredients: parsedIngredients,
            rawIngredientsText: rawIngredients,
            nutritionalData: nutritionalData,
            servingSize: extractServingSize(offProduct.serving_quantity),
            servingSizeUnit: extractServingSizeUnit(offProduct.serving_size),
            servingSizeDisplay: servingSizeDisplay,
            imageURL: bestImage,
            thumbnailURL: bestThumb,
            source: .openFoodFacts,
            countriesTags: offProduct.countries_tags,
            processingLevel: processingLevel
        )
    }

    func mapNutritionalData(_ nutriments: OpenFoodFactsNutriments?) -> NutritionalData {
        guard let nutriments = nutriments else {
            return NutritionalData()
        }

        var nutritionalData = NutritionalData()

        // Calories - prefer kcal over energy (kJ)
        nutritionalData.calories = nutriments.energy_kcal_100g
            ?? nutriments.energyKcal
            ?? ((nutriments.energy_100g ?? nutriments.energy).map { $0 / 4.184 })
            ?? 0

        // Macronutrients
        nutritionalData.protein = nutriments.proteins_100g ?? nutriments.proteins ?? 0
        nutritionalData.carbohydrates = nutriments.carbohydrates_100g ?? nutriments.carbohydrates ?? 0
        nutritionalData.fat = nutriments.fat_100g ?? nutriments.fat ?? 0
        nutritionalData.fiber = nutriments.fiber_100g ?? nutriments.fiber ?? 0
        nutritionalData.sugar = nutriments.sugars_100g ?? nutriments.sugars ?? 0

        // Sodium - convert from salt if sodium not available
        if let sodium = nutriments.sodium_100g ?? nutriments.sodium {
            // OFF sodium is typically in grams per 100g; keep as-is
            nutritionalData.sodium = sodium
        } else if let salt = nutriments.salt_100g ?? nutriments.salt {
            nutritionalData.sodium = salt * 0.4 // Salt to sodium conversion factor
        } else {
            nutritionalData.sodium = 0
        }

        if let cholesterolMg = nutriments.cholesterol_100g ?? nutriments.cholesterol {
            nutritionalData.cholesterol = cholesterolMg / 1000
        } else {
            nutritionalData.cholesterol = 0
        }

        return nutritionalData
    }

    func parseIngredients(_ ingredientsText: String?) -> [String] {
        IngredientAnalyzer.shared.parseIngredientList(ingredientsText)
    }

    func preferredBrand(from product: OpenFoodFactsProduct) -> String {
        AppLog.debug("🌐 Brand fields: owner=\(product.brand_owner ?? "nil"), imported=\(product.brand_owner_imported ?? "nil"), brands=\(product.brands ?? "nil")", category: .network)

        let candidates: [String?] = [
            product.brand_owner,
            product.brand_owner_imported,
            product.brands
        ]

        for candidate in candidates {
            if let raw = candidate?.trimmingCharacters(in: .whitespacesAndNewlines),
               let sanitized = sanitizedBrand(raw) {
                return sanitized
            }
        }

        return "Unknown"
    }

    func preferredName(from product: OpenFoodFactsProduct) -> String {
        let candidates: [String?] = [
            product.product_name,
            product.product_name_en,
            product.generic_name,
            product.generic_name_en
        ]

        AppLog.debug("🌐 Name candidates:", category: .network)
        for (index, candidate) in candidates.enumerated() {
            let trimmed = candidate?.trimmingCharacters(in: .whitespacesAndNewlines)
            let preview = trimmed ?? "nil"
            AppLog.debug("   [\(index)] -> \(preview)", category: .network)
            if let value = trimmed, !value.isEmpty {
                return value
            }
        }

        let fallbackBrand = [product.brand_owner, product.brand_owner_imported, product.brands]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap { sanitizedBrand($0) }
            .first

        let fallbackCategory = product.categories?
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })

        if let brand = fallbackBrand, let category = fallbackCategory {
            return "\(brand) \(category)"
        }

        if let brand = fallbackBrand {
            return brand
        }

        if let category = fallbackCategory {
            return category
        }

        return "Unknown Product"
    }

    func extractCategory(from product: OpenFoodFactsProduct) -> String {
        if let hierarchy = product.categories_hierarchy,
           let category = bestCategory(fromHierarchy: hierarchy) {
            return category
        }

        return extractCategory(fromList: product.categories)
    }

    func extractCategory(fromList categories: String?) -> String {
        guard let categories = categories else { return "Food" }

        let tokens = categories
            .components(separatedBy: ",")
            .compactMap { sanitizedCategoryToken($0) }

        if let specific = tokens.reversed().first(where: { !isGenericCategoryName($0) }) {
            return formatCategoryName(specific)
        }

        return tokens.last.map(formatCategoryName) ?? "Food"
    }

    func determineBestCategorySlug(from product: OpenFoodFactsProduct) -> String? {
        let nameCandidates = [product.product_name, product.generic_name, product.product_name_en, product.generic_name_en]
        if nameCandidates.compactMap({ $0?.lowercased() }).contains(where: { $0.contains("dressing") || $0.contains("vinaigrette") }) {
            return "salad-dressings"
        }

        if let keywords = product._keywords?.map({ $0.lowercased() }) {
            if keywords.contains(where: { $0.contains("dressing") || $0.contains("vinaigrette") }) {
                return "salad-dressings"
            }
        }

        if let hierarchy = product.categories_hierarchy {
            for entry in hierarchy.reversed() {
                if let slug = normalizeCategorySlug(entry) {
                    if slug.contains("salad-dressing") || slug.contains("vinaigrette") {
                        return slug
                    }
                    if !isGenericCategorySlug(slug) {
                        return slug
                    }
                }
            }
        }

        if let categories = product.categories {
            let tokens = categories
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            let normalizedTokens = tokens.map { $0.lowercased() }
            let preferred = ["salad dressings", "salad-dressings", "dressings", "vinaigrettes", "dressings and sauces", "dressings-and-sauces", "sauces"]

            for pref in preferred {
                let plain = pref.replacingOccurrences(of: "-", with: " ")
                if normalizedTokens.contains(where: { $0.contains(plain) }) {
                    let slug = pref.replacingOccurrences(of: " ", with: "-")
                    if !isGenericCategorySlug(slug) {
                        return slug
                    }
                }
            }

            for token in normalizedTokens.reversed() {
                if isGenericCategoryName(token) { continue }
                let slug = token
                    .replacingOccurrences(of: " ", with: "-")
                    .replacingOccurrences(of: "_", with: "-")
                if isGenericCategorySlug(slug) { continue }
                if !slug.isEmpty {
                    return slug
                }
            }
        }

        if let pnns = product.pnns_groups_2?.lowercased(), pnns.contains("dressing") {
            return "salad-dressings"
        }

        return "sauces"
    }

    func normalizeCategorySlug(_ raw: String) -> String? {
        var slug = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if slug.hasPrefix("en:") {
            slug.removeFirst(3)
        }
        slug = slug.replacingOccurrences(of: "_", with: "-")
        slug = slug.replacingOccurrences(of: " ", with: "-")
        return slug.isEmpty ? nil : slug
    }

    func bestCategory(fromHierarchy hierarchy: [String]) -> String? {
        for slug in hierarchy.reversed() {
            if isGenericCategorySlug(slug) { continue }
            let name = slug.components(separatedBy: ":").last ?? slug
            if let sanitized = sanitizedCategoryToken(name) {
                return formatCategoryName(sanitized)
            }
        }
        return nil
    }

    func sanitizedBrand(_ brand: String) -> String? {
        let cleaned = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        if cleaned.compare("Unknown", options: .caseInsensitive) == .orderedSame {
            return nil
        }
        return cleaned
    }

    func isGenericCategoryName(_ name: String) -> Bool {
        let normalized = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
        return genericCategoryTokens.contains(normalized)
    }

    func isGenericCategorySlug(_ slug: String) -> Bool {
        let normalized = slug
            .lowercased()
            .replacingOccurrences(of: "en:", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
        return genericCategoryTokens.contains(normalized)
    }

    func formatCategoryName(_ name: String) -> String {
        guard !name.isEmpty else { return "Food" }
        return name
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { substring in
                let lower = substring.lowercased()
                return lower.prefix(1).uppercased() + lower.dropFirst()
            }
            .joined(separator: " ")
    }

    func sanitizedCategoryToken(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var genericCategoryTokens: Set<String> {
        [
            "food",
            "foods",
            "product",
            "products",
            "grocery",
            "groceries",
            "beverage",
            "beverages",
            "condiments"
        ]
    }

    func extractServingSize(_ servingQuantity: String?) -> Double? {
        guard let servingQuantity = servingQuantity else { return nil }
        let sanitized = servingQuantity
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Double(sanitized) {
            return value
        }
        #if DEBUG
        AppLog.warning("⚠️ OFF serving_quantity value could not be parsed: \(servingQuantity)", category: .network)
        #endif
        return nil
    }

    func extractServingSizeUnit(_ servingSize: String?) -> String {
        guard let servingSize = servingSize else { return "g" }

        // Extract unit from serving size string
        let units = ["ml", "l", "g", "kg", "oz", "lb", "cup", "tbsp", "tsp"]

        for unit in units {
            if servingSize.lowercased().contains(unit) {
                return unit
            }
        }

        return "g" // Default to grams
    }
}

// MARK: - Image URL selection helpers
private extension OpenFoodFactsProduct {
    var bestName: String? {
        product_name ?? product_name_en ?? generic_name ?? generic_name_en
    }

    var bestImageURL: String? {
        if let frontURL = image_front_url, !frontURL.isEmpty {
            AppLog.debug("🖼️ Using image_front_url", category: .network)
            return frontURL
        }
        if let localizedURL = selected_images?.front?.display?.en, !localizedURL.isEmpty {
            AppLog.debug("🖼️ Using selected_images.front.display.en", category: .network)
            return localizedURL
        }
        if let genericURL = image_url, !genericURL.isEmpty {
            AppLog.debug("🖼️ Using image_url", category: .network)
            return genericURL
        }
        AppLog.debug("🖼️ No image URL found", category: .network)
        return nil
    }

    var bestThumbnailURL: String? {
        if let smallURL = image_small_url, !smallURL.isEmpty {
            return smallURL
        }
        return bestImageURL
    }
}

// MARK: - Test-only decoding structs for image diagnostics
private struct OFFImageTestResponse: Decodable {
    let status: Int?
    let product: OFFImageTestProduct
}

private struct OFFImageTestProduct: Decodable {
    let code: String?
    let product_name: String?
    let brands: String?
    let categories: String?

    let image_url: String?
    let image_front_url: String?
    let image_small_url: String?
    let image_thumb_url: String?

    let nutriments: OFFImageTestNutriments?
    let ingredients_text: String?
    let nova_group: Int?
}

private struct OFFImageTestNutriments: Decodable {
    let proteins_100g: Double?
    let fiber_100g: Double?
    let sugars_100g: Double?
    let sodium_100g: Double?
    let energy_kcal_100g: Double?
}
