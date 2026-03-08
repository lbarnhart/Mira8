import SwiftUI

/// Full-screen loading view shown while processing photo scan results
struct PhotoProcessingLoadingView: View {
    let state: ImageScanState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            Color.backgroundPrimary.ignoresSafeArea()

            // Content
            VStack(spacing: Spacing.xl) {
                Spacer()

                // Animated loading indicator
                loadingAnimation

                // Status message
                VStack(spacing: Spacing.sm) {
                    Text(statusTitle)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)

                    Text(statusMessage)
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }

                Spacer()
                Spacer()
            }
        }
    }

    // MARK: - Components

    private var loadingAnimation: some View {
        ZStack {
            // Outer rotating circle
            Circle()
                .stroke(Color.oceanTeal.opacity(0.2), lineWidth: 4)
                .frame(width: 80, height: 80)

            // Inner rotating arc
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        colors: [Color.oceanTeal, Color.oceanTeal.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .modifier(RotatingModifier())

            // Center icon
            Image(systemName: centerIcon)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.oceanTeal)
        }
    }

    private var centerIcon: String {
        switch state {
        case .processing, .identifying:
            return "eye.fill"
        case .searching:
            return "magnifyingglass"
        default:
            return "photo"
        }
    }

    private var statusTitle: String {
        switch state {
        case .processing, .identifying:
            return "Identifying Product"
        case .searching:
            return "Finding Match"
        case .matched:
            return "Match Found!"
        case .error:
            return "Processing Error"
        default:
            return "Processing Photo"
        }
    }

    private var statusMessage: String {
        switch state {
        case .processing, .identifying:
            return "Analyzing the image with AI..."
        case .searching:
            return "Searching our database for this product..."
        case .matched:
            return "Product identified successfully"
        case .error(let error):
            switch error {
            case .imageProcessingFailed, .captureFailed:
                return "Unable to process the image. Please try again."
            case .identificationFailed, .noProductDetected:
                return "Could not identify the product. Try a clearer photo."
            case .searchFailed:
                return "No matching products found in our database."
            case .apiError:
                return "Network connection issue. Please check your connection."
            case .cameraUnavailable:
                return "Camera is not available on this device."
            }
        default:
            return "Please wait..."
        }
    }
}

// MARK: - Rotating Modifier

private struct RotatingModifier: ViewModifier {
    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.0)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Preview

#Preview("Identifying") {
    PhotoProcessingLoadingView(state: .identifying)
}

#Preview("Searching") {
    PhotoProcessingLoadingView(state: .searching)
}

#Preview("Error") {
    PhotoProcessingLoadingView(state: .error(.noProductDetected))
}
