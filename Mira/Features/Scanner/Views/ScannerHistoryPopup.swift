import SwiftUI

/// Quick-access popup showing last 3 scanned products in the scanner view
struct ScannerHistoryPopup: View {
    let recentScans: [Product]
    let onProductTap: (Product) -> Void
    
    var body: some View {
        if !recentScans.isEmpty {
            VStack(spacing: Spacing.sm) {
                Text("Recent Scans")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.7))
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(recentScans) { product in
                            RecentScanPill(product: product) {
                                onProductTap(product)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color.black.opacity(0.6))
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            )
            .padding(.horizontal, Spacing.md)
        }
    }
}

private struct RecentScanPill: View {
    let product: Product
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                // Product thumbnail
                AsyncProductImage(
                    url: product.thumbnailURL ?? product.imageURL,
                    size: .small,
                    cornerRadius: CornerRadius.sm
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.name)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let brand = product.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

/// Barcode confirmation overlay shown briefly after scanning
struct BarcodeConfirmationOverlay: View {
    let barcode: String
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.white)
            
            Text(barcode)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .foregroundColor(.white)
            
            Text("Barcode detected")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.primaryBlue.opacity(0.9))
        )
    }
}

#Preview("Recent Scans Popup") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Spacer()
            ScannerHistoryPopup(
                recentScans: [],
                onProductTap: { _ in }
            )
        }
    }
}

#Preview("Barcode Confirmation") {
    ZStack {
        Color.black.ignoresSafeArea()
        BarcodeConfirmationOverlay(barcode: "0123456789012")
    }
}
