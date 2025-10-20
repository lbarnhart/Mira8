import SwiftUI

// MARK: - Product Card Component
struct ProductCard: View {
    let product: ProductCardData
    let style: ProductCardStyle
    let onTap: () -> Void
    let onFavoriteToggle: (() -> Void)?

    init(
        product: ProductCardData,
        style: ProductCardStyle = .standard,
        onTap: @escaping () -> Void,
        onFavoriteToggle: (() -> Void)? = nil
    ) {
        self.product = product
        self.style = style
        self.onTap = onTap
        self.onFavoriteToggle = onFavoriteToggle
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: style.spacing) {
                leadingContent
                productInfo
                Spacer()
                trailingContent
            }
            .padding(style.padding)
        }
        .buttonStyle(.plain)
        .cardStyle(style.cardStyle)
    }

    @ViewBuilder
    private var leadingContent: some View {
        switch style {
        case .standard, .compact:
            ScoreRing(
                score: product.healthScore,
                size: style.scoreSize
            )

        case .detailed:
            VStack(spacing: Spacing.xs) {
                ScoreRing(
                    score: product.healthScore,
                    size: style.scoreSize
                )

                if let processingLevel = product.processingLevel {
                    ProcessingLevelBadge(level: processingLevel)
                }
            }

        case .minimal:
            Circle()
                .fill(Color.scoreColor(for: product.healthScore))
                .frame(width: style.scoreSize, height: style.scoreSize)
        }
    }

    private var productInfo: some View {
        VStack(alignment: .leading, spacing: style.contentSpacing) {
            // Product name
            Text(product.name)
                .font(style.titleFont)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(style.titleLineLimit)

            // Brand
            Text(product.brand)
                .font(style.subtitleFont)
                .foregroundColor(.textSecondary)
                .lineLimit(1)

            // Additional info based on style
            if style.showAdditionalInfo {
                additionalInfo
            }
        }
    }

    @ViewBuilder
    private var additionalInfo: some View {
        switch style {
        case .detailed:
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if let scannedAt = product.scannedAt {
                    Text(scannedAt.formatted(.relative(presentation: .named)))
                        .font(style.captionFont)
                        .foregroundColor(.textTertiary)
                }

                if let category = product.category {
                    Text(category)
                        .font(style.captionFont)
                        .foregroundColor(.textTertiary)
                }
            }

        case .standard:
            if let scannedAt = product.scannedAt {
                Text(scannedAt.formatted(.relative(presentation: .named)))
                    .font(style.captionFont)
                    .foregroundColor(.textTertiary)
            }

        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var trailingContent: some View {
        VStack(spacing: Spacing.sm) {
            // Favorite button
            if let onFavoriteToggle = onFavoriteToggle {
                Button(action: onFavoriteToggle) {
                    Image(systemName: product.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(product.isFavorite ? .error : .textTertiary)
                        .font(.system(size: style.favoriteIconSize))
                }
                .buttonStyle(.plain)
            }

            // Additional trailing content
            if style.showTrailingInfo {
                trailingInfo
            }
        }
    }

    @ViewBuilder
    private var trailingInfo: some View {
        switch style {
        case .detailed:
            VStack(spacing: Spacing.xs) {
                if let calories = product.calories {
                    VStack(spacing: 2) {
                        Text("\(Int(calories))")
                            .captionLargeStyle()
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)

                        Text("cal")
                            .captionSmallStyle()
                            .foregroundColor(.textTertiary)
                    }
                }
            }

        default:
            EmptyView()
        }
    }
}

// MARK: - Product Card Data
struct ProductCardData {
    let id: String
    let name: String
    let brand: String
    let healthScore: Double
    let isFavorite: Bool
    let scannedAt: Date?
    let category: String?
    let processingLevel: ProcessingLevel?
    let calories: Double?

    init(
        id: String,
        name: String,
        brand: String,
        healthScore: Double,
        isFavorite: Bool = false,
        scannedAt: Date? = nil,
        category: String? = nil,
        processingLevel: ProcessingLevel? = nil,
        calories: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.healthScore = healthScore
        self.isFavorite = isFavorite
        self.scannedAt = scannedAt
        self.category = category
        self.processingLevel = processingLevel
        self.calories = calories
    }
}

// MARK: - Product Card Style
enum ProductCardStyle {
    case minimal
    case compact
    case standard
    case detailed

    var cardStyle: CardStyle {
        switch self {
        case .minimal:
            return .minimal
        case .compact, .standard:
            return .standard
        case .detailed:
            return .elevated
        }
    }

    var spacing: CGFloat {
        switch self {
        case .minimal, .compact:
            return Spacing.sm
        case .standard, .detailed:
            return Spacing.md
        }
    }

    var padding: CGFloat {
        switch self {
        case .minimal:
            return Spacing.sm
        case .compact:
            return Spacing.md
        case .standard, .detailed:
            return Spacing.md
        }
    }

    var contentSpacing: CGFloat {
        switch self {
        case .minimal, .compact:
            return Spacing.xs
        case .standard, .detailed:
            return Spacing.xs
        }
    }

    var scoreSize: CGFloat {
        switch self {
        case .minimal:
            return 12
        case .compact:
            return 40
        case .standard:
            return 50
        case .detailed:
            return 60
        }
    }

    var titleFont: Font {
        switch self {
        case .minimal, .compact:
            return .bodyMedium
        case .standard:
            return .bodyLarge
        case .detailed:
            return .titleSmall
        }
    }

    var subtitleFont: Font {
        switch self {
        case .minimal:
            return .captionSmall
        case .compact, .standard, .detailed:
            return .captionMedium
        }
    }

    var captionFont: Font {
        return .captionSmall
    }

    var titleLineLimit: Int {
        switch self {
        case .minimal:
            return 1
        case .compact, .standard:
            return 2
        case .detailed:
            return 3
        }
    }

    var favoriteIconSize: CGFloat {
        switch self {
        case .minimal:
            return 12
        case .compact, .standard:
            return 16
        case .detailed:
            return 18
        }
    }

    var showAdditionalInfo: Bool {
        switch self {
        case .minimal, .compact:
            return false
        case .standard, .detailed:
            return true
        }
    }

    var showTrailingInfo: Bool {
        switch self {
        case .detailed:
            return true
        default:
            return false
        }
    }
}

// MARK: - Processing Level Badge
struct ProcessingLevelBadge: View {
    let level: ProcessingLevel

    var body: some View {
        Text(level.shortName)
            .font(.system(size: 8, weight: .medium))
            .foregroundColor(.textOnDark)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(level.color)
            .cornerRadius(4)
    }
}

// MARK: - Processing Level Extension
extension ProcessingLevel {
    var shortName: String {
        switch self {
        case .minimal:
            return "MIN"
        case .processed:
            return "PROC"
        case .ultraProcessed:
            return "ULTRA"
        case .unknown:
            return "?"
        }
    }

    var color: Color {
        switch self {
        case .minimal:
            return .success
        case .processed:
            return .warning
        case .ultraProcessed:
            return .error
        case .unknown:
            return .textTertiary
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            let sampleProduct = ProductCardData(
                id: "1",
                name: "Organic Granola Cereal with Nuts and Berries",
                brand: "Nature's Best",
                healthScore: 85,
                isFavorite: true,
                scannedAt: Date().addingTimeInterval(-3600),
                category: "Breakfast",
                processingLevel: .minimal,
                calories: 320
            )

            ProductCard(
                product: sampleProduct,
                style: .minimal,
                onTap: {
                    #if DEBUG
                    print("Tapped")
                    #endif
                }
            )

            ProductCard(
                product: sampleProduct,
                style: .standard,
                onTap: {
                    #if DEBUG
                    print("Tapped")
                    #endif
                },
                onFavoriteToggle: {
                    #if DEBUG
                    print("Favorite toggled")
                    #endif
                }
            )

            ProductCard(
                product: sampleProduct,
                style: .detailed,
                onTap: {
                    #if DEBUG
                    print("Tapped")
                    #endif
                },
                onFavoriteToggle: {
                    #if DEBUG
                    print("Favorite toggled")
                    #endif
                }
            )
        }
        .padding()
    }
}
