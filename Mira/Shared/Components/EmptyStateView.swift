import SwiftUI

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let actionButtonTitle: String?
    let action: (() -> Void)?

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        actionButtonTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.actionButtonTitle = actionButtonTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.textTertiary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)

                Text(subtitle)
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionButtonTitle = actionButtonTitle,
               let action = action {
                PrimaryButton(actionButtonTitle, style: .primary, action: action)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 20) {
        EmptyStateView(
            title: "No recent scans",
            subtitle: "Start by scanning your first product",
            systemImage: "tray"
        )

        EmptyStateView(
            title: "No products found",
            subtitle: "Try scanning a different barcode or check your internet connection",
            systemImage: "magnifyingglass",
            actionButtonTitle: "Try Again"
        ) {
            #if DEBUG
            print("Try again tapped")
            #endif
        }
    }
    .padding()
}
