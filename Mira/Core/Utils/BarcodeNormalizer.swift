import Foundation

enum BarcodeNormalizer {
    /// Canonical lookup key for UPC/EAN/GTIN variants. Network requests should still use
    /// the originally scanned value because individual providers accept different lengths.
    static func lookupKey(for value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = trimmed.filter(\.isNumber)
        guard digits.count >= 8, digits.count <= 14 else { return trimmed }
        return String(repeating: "0", count: 14 - digits.count) + digits
    }
}
