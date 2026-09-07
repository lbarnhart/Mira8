import SwiftUI

enum ProductImageSize {
    case small
    case thumbnail
    case medium
    case large

    var dimension: CGFloat {
        switch self {
        case .small:
            return 40
        case .thumbnail:
            return 60
        case .medium:
            return 100
        case .large:
            return 200
        }
    }
}

struct AsyncProductImage: View {
    let url: String?
    let size: ProductImageSize
    var cornerRadius: CGFloat

    init(url: String?, size: ProductImageSize, cornerRadius: CGFloat = CornerRadius.card) {
        self.url = url
        self.size = size
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        let dimension = size.dimension

        ZStack {
            if let url, let remoteURL = URL(string: url) {
                AsyncImage(url: remoteURL, transaction: Transaction(animation: .easeInOut)) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .transition(.opacity)
                    case .failure(let error):
                        fallback
                            .onAppear {
                                AppLog.warning("Image load failed: \(error.localizedDescription)", category: .network)
                                AppLog.debug("Failed image URL: \(url)", category: .network)
                            }
                    @unknown default:
                        fallback
                    }
                }
            } else {
                fallback
                    .onAppear {
                        AppLog.debug("No URL provided for product image", category: .network)
                    }
            }
        }
        .frame(width: dimension, height: dimension)
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.textSubduedAccessible, lineWidth: 1)
        )
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.clear)

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primaryBlue))
        }
    }

    private var fallback: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.clear)

            Image(systemName: "leaf.fill")
                .imageScale(.medium)
                .foregroundColor(.deepForest)
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        AsyncProductImage(url: "https://static.openfoodfacts.org/images/products/737/628/064/5022/front_en.174.400.jpg", size: .large)
        AsyncProductImage(url: nil, size: .thumbnail, cornerRadius: CornerRadius.button)
        AsyncProductImage(url: nil, size: .small, cornerRadius: CornerRadius.button)
    }
    .padding()
    .background(Color.backgroundPrimary)
}
