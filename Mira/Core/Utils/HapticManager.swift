import UIKit

/// Manages haptic feedback throughout the app
/// Provides consistent haptic patterns for different interaction types
final class HapticManager {
    static let shared = HapticManager()

    private init() {}

    // MARK: - Impact Feedback

    /// Light haptic for subtle interactions (e.g., barcode detected)
    func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium haptic for standard interactions (e.g., score revealed)
    func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy haptic for significant interactions
    func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    // MARK: - Notification Feedback

    /// Success haptic (e.g., product found, excellent score)
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Warning haptic (e.g., dietary violation detected)
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Error haptic
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback

    /// Selection changed haptic (e.g., tab switched, filter changed)
    func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // MARK: - Prepared Feedback (for sequences)

    /// Prepare impact generator for smoother haptics
    func prepareImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> UIImpactFeedbackGenerator {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        return generator
    }

    /// Prepare notification generator for smoother haptics
    func prepareNotification() -> UINotificationFeedbackGenerator {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        return generator
    }
}

// MARK: - Convenience Extensions

extension HapticManager {
    /// Barcode scan detected
    func barcodeDetected() {
        lightImpact()
    }

    /// Product successfully loaded
    func productLoaded(score: Double) {
        if score >= 80 {
            // Excellent score gets celebratory haptic
            success()
        } else {
            // Standard product load
            mediumImpact()
        }
    }

    /// Dietary violation detected
    func dietaryViolation() {
        warning()
    }

    /// Tab or filter changed
    func selectionMade() {
        selectionChanged()
    }

    /// User tapped to view more details
    func detailTapped() {
        lightImpact()
    }
}
