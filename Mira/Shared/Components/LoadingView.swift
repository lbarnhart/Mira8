import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .primaryBlue))

            Text("Loading...")
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

struct LoadingViewWithMessage: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .primaryBlue))

            Text(message)
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingView()
        LoadingViewWithMessage(message: "Analyzing product nutritional data...")
    }
    .padding()
}