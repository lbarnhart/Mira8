import SwiftUI

// MARK: - Empty State Component
struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionButton: EmptyStateAction?

    init(
        icon: String,
        title: String,
        message: String,
        actionButton: EmptyStateAction? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionButton = actionButton
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            contentView

            if let actionButton = actionButton {
                PrimaryButton(
                    actionButton.title,
                    style: actionButton.style,
                    icon: actionButton.icon,
                    action: actionButton.action
                )
                .padding(.horizontal, Spacing.xl)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var contentView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: Size.iconXL, weight: .light))
                .foregroundColor(.textTertiary)

            Text(title)
                .headlineSmallStyle()
                .foregroundColor(.textSecondary)

            Text(message)
                .bodyMediumStyle()
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)
        }
    }
}

// MARK: - Empty State Action
struct EmptyStateAction {
    let title: String
    let style: MiraButtonStyle
    let icon: String?
    let action: () -> Void

    init(
        title: String,
        style: MiraButtonStyle = .primary,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.action = action
    }
}

// MARK: - Empty State Variants
extension EmptyState {
    // MARK: - No Search Results
    static func noSearchResults(searchTerm: String) -> EmptyState {
        EmptyState(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "Try adjusting your search or filters"
        )
    }

    // MARK: - No History
    static func noHistory(onScanAction: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: "clock",
            title: "No Scanned Products",
            message: "Products you scan will appear here",
            actionButton: EmptyStateAction(
                title: "Scan Your First Product",
                style: .primary,
                icon: "barcode.viewfinder",
                action: onScanAction
            )
        )
    }

    // MARK: - No Favorites
    static func noFavorites() -> EmptyState {
        EmptyState(
            icon: "heart",
            title: "No Favorites Yet",
            message: "Tap the heart icon on products you love to save them here"
        )
    }

    // MARK: - Network Error
    static func networkError(onRetryAction: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: "wifi.slash",
            title: "Connection Error",
            message: "Please check your internet connection and try again",
            actionButton: EmptyStateAction(
                title: "Try Again",
                style: .secondary,
                icon: "arrow.clockwise",
                action: onRetryAction
            )
        )
    }

    // MARK: - Server Error
    static func serverError(onRetryAction: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: "exclamationmark.triangle",
            title: "Something Went Wrong",
            message: "We're having trouble loading your data. Please try again in a moment.",
            actionButton: EmptyStateAction(
                title: "Retry",
                style: .secondary,
                icon: "arrow.clockwise",
                action: onRetryAction
            )
        )
    }

    // MARK: - Permission Denied
    static func cameraPermissionDenied(onSettingsAction: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: "camera.fill",
            title: "Camera Access Required",
            message: "Please allow camera access in Settings to scan barcodes",
            actionButton: EmptyStateAction(
                title: "Open Settings",
                style: .primary,
                icon: "gearshape",
                action: onSettingsAction
            )
        )
    }

    // MARK: - Loading State
    static func loading(message: String = "Loading...") -> EmptyState {
        EmptyState(
            icon: "hourglass",
            title: message,
            message: "Please wait while we fetch your data"
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: Spacing.xxl) {
        EmptyState.noHistory {
            #if DEBUG
            print("Scan tapped")
            #endif
        }
        .frame(height: 300)
        .standardCard()

        EmptyState.networkError {
            #if DEBUG
            print("Retry tapped")
            #endif
        }
        .frame(height: 300)
        .standardCard()
    }
    .padding()
}
