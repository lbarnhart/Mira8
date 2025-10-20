import SwiftUI
import UIKit

struct InstacartAuthView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isAuthenticating = false
    @State private var errorMessage: String?

    var onConnected: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            header

            VStack(alignment: .leading, spacing: Spacing.sm) {
                benefitRow(icon: "cart", text: "Shop your local stores without leaving Mira")
                benefitRow(icon: "clock", text: "Save time with auto-filled carts and reorders")
                benefitRow(icon: "lock", text: "Secure OAuth flow direct with Instacart")
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.error)
                    .padding(.vertical, Spacing.xs)
            }

            Button {
                connectTapped()
            } label: {
                HStack {
                    if isAuthenticating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }

                    Text(isAuthenticating ? "Connecting…" : "Connect to Instacart")
                        .font(.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(hex: "0AAD0A"))
                .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(isAuthenticating)

            Button("Maybe Later") {
                dismiss()
            }
            .font(.bodyMedium)
            .foregroundColor(.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.md)
        }
        .padding(Spacing.xxl)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "leaf") // TODO: Replace with Instacart logo asset when available
                    .font(.title)
                    .foregroundColor(Color(hex: "0AAD0A"))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Connect Instacart")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Link your Instacart account to add products to your cart in seconds.")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(Color(hex: "0AAD0A"))
            Text(text)
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)
        }
    }

    private func connectTapped() {
        guard !isAuthenticating else { return }
        errorMessage = nil
        isAuthenticating = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        Task {
            do {
                let success = try await InstacartService.shared.authenticate()
                await MainActor.run {
                    isAuthenticating = false
                    if success {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        onConnected()
                        dismiss()
                    } else {
                        errorMessage = InstacartServiceError.authenticationFailed.errorDescription
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    }
                }
            } catch {
                await MainActor.run {
                    isAuthenticating = false
                    errorMessage = error.localizedDescription
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
}

#Preview {
    InstacartAuthView(onConnected: {})
}
