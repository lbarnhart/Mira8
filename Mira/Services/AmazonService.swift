import Foundation

protocol AmazonServicing {
    /// Attempts to build the best Amazon product link for the given metadata.
    /// Prefers UPC/GTIN when available, otherwise falls back to brand + name search.
    func generateProductLink(name: String, brand: String, barcode: String?) -> URL?

    /// Builds a general Amazon search URL with the provided query and tracking parameters.
    func searchProduct(query: String) -> URL
}

/// Lightweight Amazon helper that relies on deep links and affiliate tagging.
/// Upgrade path: integrate PA-API (requires signed requests) and map product ASINs.
struct AmazonService: AmazonServicing {
    static let shared = AmazonService()

    func generateProductLink(name: String, brand: String, barcode: String?) -> URL? {
        let trimmedBarcode = barcode?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let code = trimmedBarcode, !code.isEmpty {
            let barcodeURL = searchProduct(query: code)
            if validate(url: barcodeURL) {
                return barcodeURL
            }
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines)

        let compoundQuery: String
        if !trimmedBrand.isEmpty && !trimmedName.isEmpty {
            compoundQuery = "\(trimmedBrand) \(trimmedName)"
        } else if !trimmedName.isEmpty {
            compoundQuery = trimmedName
        } else if !trimmedBrand.isEmpty {
            compoundQuery = trimmedBrand
        } else if let code = trimmedBarcode, !code.isEmpty {
            compoundQuery = code
        } else {
            return nil
        }

        let searchURL = searchProduct(query: compoundQuery)
        return validate(url: searchURL) ? searchURL : nil
    }

    func searchProduct(query: String) -> URL {
        let encodedQuery = encode(query)
        var components = baseComponents()

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: Constants.Amazon.searchQueryKey, value: encodedQuery)
        ]

        if !Constants.Amazon.associateID.isEmpty {
            queryItems.append(URLQueryItem(name: Constants.Amazon.affiliateTagKey, value: Constants.Amazon.associateID))
        }

        queryItems.append(contentsOf: Constants.Amazon.trackingParameters)
        components.queryItems = queryItems

        return components.url ?? fallbackURL(for: encodedQuery)
    }

    // MARK: - Helpers

    private func baseComponents() -> URLComponents {
        var components = URLComponents(string: Constants.Amazon.baseURL) ?? URLComponents()
        components.path = Constants.Amazon.searchPath
        return components
    }

    private func encode(_ query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -")
        let sanitized = trimmed.unicodeScalars
            .filter { allowed.contains($0) }
            .map(String.init)
            .joined()
            .replacingOccurrences(of: " ", with: "+")
        return sanitized
    }

    private func fallbackURL(for encodedQuery: String) -> URL {
        let urlString = "\(Constants.Amazon.baseURL)\(Constants.Amazon.searchPath)?\(Constants.Amazon.searchQueryKey)=\(encodedQuery)"
        return URL(string: urlString) ?? URL(string: Constants.Amazon.baseURL)!
    }

    private func validate(url: URL) -> Bool {
        url.absoluteString.contains(Constants.Amazon.searchPath)
    }
}
