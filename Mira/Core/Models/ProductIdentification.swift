import Foundation

/// Result of product identification from image analysis.
struct ProductIdentification: Identifiable, Equatable, Sendable {
    let id = UUID()
    let name: String
    let brand: String?
    let category: String?
    let confidence: Double
    let additionalDetails: [String: String]
    let identifiedAt: Date

    /// Whether the identification is confident enough to auto-search
    var isHighConfidence: Bool {
        confidence >= 0.8
    }

    /// Whether the identification needs user confirmation
    var needsConfirmation: Bool {
        confidence < 0.8 || brand == nil
    }

    init(
        name: String,
        brand: String? = nil,
        category: String? = nil,
        confidence: Double,
        additionalDetails: [String: String] = [:],
        identifiedAt: Date = Date()
    ) {
        self.name = name
        self.brand = brand
        self.category = category
        self.confidence = confidence
        self.additionalDetails = additionalDetails
        self.identifiedAt = identifiedAt
    }
}

/// Product match from Open Food Facts search
struct ProductMatch: Identifiable, Equatable, Sendable {
    let id: String
    let barcode: String
    let name: String
    let brand: String?
    let category: String?
    let thumbnailURL: String?
    let matchScore: Double

    /// How well this match corresponds to the identification
    var matchQuality: MatchQuality {
        switch matchScore {
        case 0.9...1.0: return .excellent
        case 0.7..<0.9: return .good
        case 0.5..<0.7: return .fair
        default: return .poor
        }
    }
}

/// Quality of a product match
enum MatchQuality: String {
    case excellent
    case good
    case fair
    case poor

    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "orange"
        case .poor: return "gray"
        }
    }
}

/// State of the image scanning process
enum ImageScanState: Equatable {
    case idle
    case capturing
    case processing
    case identifying
    case searching
    case matched([ProductMatch])
    case noMatches
    case error(ImageScanError)
}

/// Errors that can occur during image scanning
enum ImageScanError: LocalizedError, Equatable {
    case cameraUnavailable
    case captureFailed
    case imageProcessingFailed
    case identificationFailed
    case searchFailed
    case noProductDetected
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "Camera is not available on this device"
        case .captureFailed:
            return "Failed to capture image"
        case .imageProcessingFailed:
            return "Failed to process the image"
        case .identificationFailed:
            return "Could not identify the product"
        case .searchFailed:
            return "Failed to search for matching products"
        case .noProductDetected:
            return "No product detected in the image"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }

    var recoveryMessage: String {
        switch self {
        case .cameraUnavailable:
            return "Please ensure camera permissions are granted"
        case .captureFailed, .imageProcessingFailed:
            return "Try taking another photo with better lighting"
        case .identificationFailed, .noProductDetected:
            return "Make sure the product label is clearly visible"
        case .searchFailed, .apiError:
            return "Check your internet connection and try again"
        }
    }

    var iconName: String {
        switch self {
        case .cameraUnavailable:
            return "camera.fill"
        case .captureFailed, .imageProcessingFailed:
            return "photo.badge.exclamationmark"
        case .identificationFailed, .noProductDetected:
            return "eye.slash"
        case .searchFailed, .apiError:
            return "wifi.exclamationmark"
        }
    }
}

/// Vision API response from Claude
struct VisionIdentificationResponse: Codable {
    let productName: String?
    let brand: String?
    let category: String?
    let confidence: Double
    let reasoning: String?
    let alternativeNames: [String]?
    let isFood: Bool

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brand
        case category
        case confidence
        case reasoning
        case alternativeNames = "alternative_names"
        case isFood = "is_food"
    }

    // Custom decoder with defaults for required fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        productName = try container.decodeIfPresent(String.self, forKey: .productName)
        brand = try container.decodeIfPresent(String.self, forKey: .brand)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0.0
        reasoning = try container.decodeIfPresent(String.self, forKey: .reasoning)
        alternativeNames = try container.decodeIfPresent([String].self, forKey: .alternativeNames)
        isFood = try container.decodeIfPresent(Bool.self, forKey: .isFood) ?? false
    }
}

/// Configuration for image scanning
struct ImageScanConfiguration {
    let maxImageSize: Int
    let compressionQuality: CGFloat
    let maxSearchResults: Int
    let confidenceThreshold: Double

    static let `default` = ImageScanConfiguration(
        maxImageSize: 1024,
        compressionQuality: 0.7,
        maxSearchResults: 5,
        confidenceThreshold: 0.3  // Lowered from 0.5 to allow partial name matches
    )

    static let highQuality = ImageScanConfiguration(
        maxImageSize: 2048,
        compressionQuality: 0.85,
        maxSearchResults: 10,
        confidenceThreshold: 0.25
    )
}
