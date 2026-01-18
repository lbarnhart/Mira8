import Foundation

protocol VersionedAsset {
    var metadata: AssetMetadata { get }
}

extension VersionedAsset {
    /// Stable identifier consumers can reference in logs and payloads (e.g., rule_id).
    var compositeIdentifier: String {
        "\(metadata.id)#\(metadata.version)"
    }
}

struct AssetMetadata: Codable, Equatable {
    let id: String
    let version: String
    let description: String
    let releasedAt: String?
    let checksum: String?
}

struct AdditiveLexiconAsset: Codable, VersionedAsset, Equatable {
    struct Entry: Codable, Equatable {
        let id: String
        let displayName: String
        let aliases: [String]
        let category: IngredientCategory
        let riskLevel: RiskLevel
        let tags: [String]
        let notes: String
        let references: [Reference]
    }

    struct Reference: Codable, Equatable {
        let label: String
        let url: String?
    }

    enum RiskLevel: String, Codable {
        case supportive
        case expected
        case elevated
    }

    let metadata: AssetMetadata
    let entries: [Entry]
}

struct ConversionTableAsset: Codable, VersionedAsset, Equatable {
    struct Conversion: Codable, Equatable {
        let id: String
        let fromUnit: String
        let toUnit: String
        let factor: Double
        let offset: Double?
        let precision: Int?
        let appliesTo: [String]
        let notes: String?
    }

    let metadata: AssetMetadata
    let conversions: [Conversion]
}

struct ThresholdAsset: Codable, VersionedAsset, Equatable {
    struct Threshold: Codable, Equatable {
        let id: String
        let kind: Kind
        let label: String
        let nutrient: String
        let unit: String
        let baseline: Double
        let step: Double
        let maxPoints: Int
        let weight: Double
        let guideline: String
        let citations: [String]
        let contexts: [Context]
    }

    enum Kind: String, Codable {
        case positive
        case negative
        case guardrail
    }

    struct Context: Codable, Equatable {
        let id: String
        let label: String
        let baseline: Double?
        let step: Double?
        let maxPoints: Int?
        let weight: Double?
        let notes: String?
    }

    let metadata: AssetMetadata
    let thresholds: [Threshold]
}

struct PrecedenceRulesAsset: Codable, VersionedAsset, Equatable {
    struct Rule: Codable, Equatable {
        let id: String
        let domain: String
        let description: String
        let stages: [Stage]
    }

    struct Stage: Codable, Equatable {
        let sequence: Int
        let id: String
        let label: String
        let outputs: [String]
        let notes: String
    }

    let metadata: AssetMetadata
    let rules: [Rule]
}

enum AssetLoaderError: Error, LocalizedError {
    case resourceNotFound(name: String)
    case decodingFailed(resource: String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .resourceNotFound(let name):
            return "Unable to locate scoring asset named \(name)."
        case .decodingFailed(let resource, let underlying):
            return "Failed to decode scoring asset \(resource): \(underlying.localizedDescription)"
        }
    }
}

enum AssetLoader {
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private static var bundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: BundleToken.self)
        #endif
    }

    static func lexiconAdditives() throws -> AdditiveLexiconAsset {
        try load(.lexiconAdditives, as: AdditiveLexiconAsset.self)
    }

    static func conversionTable() throws -> ConversionTableAsset {
        try load(.conversionTable, as: ConversionTableAsset.self)
    }

    static func thresholds() throws -> ThresholdAsset {
        try load(.thresholds, as: ThresholdAsset.self)
    }

    static func precedenceRules() throws -> PrecedenceRulesAsset {
        try load(.precedenceRules, as: PrecedenceRulesAsset.self)
    }

    private static func load<T: Decodable>(_ resource: AssetResource, as type: T.Type) throws -> T {
        let resourceName = resource.fileName
        guard let url = resourceURL(for: resource) else {
            AppLog.error("Missing scoring asset: \(resourceName)", category: .scoring)
            throw AssetLoaderError.resourceNotFound(name: resourceName)
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(type, from: data)
        } catch {
            AppLog.error("Failed decoding scoring asset \(resourceName): \(error)", category: .scoring)
            throw AssetLoaderError.decodingFailed(resource: resourceName, underlying: error)
        }
    }

    private enum AssetResource {
        case lexiconAdditives
        case conversionTable
        case thresholds
        case precedenceRules

        var fileName: String {
            switch self {
            case .lexiconAdditives:
                return "lexicon_additives_v1.1.1"
            case .conversionTable:
                return "conversion_table_v1.1.1"
            case .thresholds:
                return "thresholds_v1.1.1"
            case .precedenceRules:
                return "precedence_rules_v1.1.1"
            }
        }
    }

    private final class BundleToken {}

    private static func resourceURL(for resource: AssetResource) -> URL? {
        if let bundled = bundle.url(forResource: resource.fileName, withExtension: "json") {
            return bundled
        }

        #if DEBUG
        let fallback = fallbackAssetsDirectory
            .appendingPathComponent(resource.fileName)
            .appendingPathExtension("json")
        if FileManager.default.fileExists(atPath: fallback.path) {
            return fallback
        }
        #endif

        return nil
    }

    #if DEBUG
    private static let fallbackAssetsDirectory: URL = {
        let fileURL = URL(fileURLWithPath: #filePath)
        return fileURL
            .deletingLastPathComponent() // Utils
            .deletingLastPathComponent() // Core
            .appendingPathComponent("Scoring")
            .appendingPathComponent("Assets")
    }()
    #endif
}
