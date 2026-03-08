import Foundation

/// Service to provide product comparison functionality
final class ProductComparisonService {
    static let shared = ProductComparisonService()

    private init() {}

    /// Quick comparison between two scores to provide a simple verdict
    /// - Parameters:
    ///   - scoreA: The first product's score
    ///   - scoreB: The second product's score
    /// - Returns: A verdict string describing which is better
    func quickCompare(scoreA: Double, scoreB: Double) -> String {
        let difference = scoreB - scoreA

        if abs(difference) < 5 {
            return "Similar health scores"
        } else if difference > 0 {
            return "This is healthier (+\(Int(difference)) points)"
        } else {
            return "The other is healthier (\(Int(difference)) points)"
        }
    }
}
