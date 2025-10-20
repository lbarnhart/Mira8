import SwiftUI

struct ScannerOverlayView: View {
    let isScanning: Bool
    let hasScannedProduct: Bool
    let errorMessage: String?
    let onDismissError: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            statusView
            Spacer()
            ScannerFrameView(isActive: isScanning && !hasScannedProduct)
            Spacer()
            InstructionTextView()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
        .allowsHitTesting(errorMessage != nil)
    }

    @ViewBuilder
    private var statusView: some View {
        if let message = errorMessage {
            ErrorMessageView(message: message, onDismiss: onDismissError)
                .transition(.opacity.animation(AnimationConstants.fade))
        } else if hasScannedProduct {
            ScannedIndicatorView()
                .transition(.opacity.animation(AnimationConstants.fade))
        } else {
            ScanningIndicatorView(isActive: isScanning)
                .transition(.opacity.animation(AnimationConstants.fade))
        }
    }
}
private struct ScannerFrameView: View {
    let isActive: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white, lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.15))
                )
                .frame(width: 280, height: 200)

            if isActive {
                ScanLineView(isActive: isActive)
            }
        }
    }
}
private struct ScanLineView: View {
    let isActive: Bool
    @State private var offsetRatio: CGFloat = -1

    private let frameWidth: CGFloat = 280
    private let frameHeight: CGFloat = 200

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, Color.green.opacity(0.7), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: frameWidth, height: 2)
            .offset(y: offset(for: frameHeight))
            .frame(width: frameWidth, height: frameHeight)
            .onAppear {
                startAnimation()
            }
            .onChange(of: isActive) { active in
                if active {
                    startAnimation()
                } else {
                    offsetRatio = -1
                }
            }
    }

    private func offset(for height: CGFloat) -> CGFloat {
        offsetRatio * (height / 2)
    }

    private func startAnimation() {
        guard isActive else { return }
        offsetRatio = -1
        withAnimation(AnimationConstants.scanLine) {
            offsetRatio = 1
        }
    }
}
private struct ScanningIndicatorView: View {
    let isActive: Bool
    @State private var scale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
                .scaleEffect(scale)
                .onAppear(perform: startPulse)
                .onChange(of: isActive) { newValue in
                    if newValue {
                        startPulse()
                    } else {
                        stopPulse()
                    }
                }

            Text("Scanning...")
                .font(.headline)
                .foregroundColor(.white)
        }
    }

    private func startPulse() {
        guard isActive else { return }
        scale = 1.0
        withAnimation(AnimationConstants.pulse) {
            scale = 1.25
        }
    }

    private func stopPulse() {
        withAnimation(AnimationConstants.fade) {
            scale = 1.0
        }
    }
}
private struct ScannedIndicatorView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)

            Text("Scanned!")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}
private struct ErrorMessageView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 8)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.footnote)
                    .padding(6)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(Color.red.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}
private struct InstructionTextView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Position the barcode within the frame")
                .font(.headline)
                .foregroundColor(.white)

            Text("The camera will automatically scan when a barcode is detected")
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 12)
    }
}
