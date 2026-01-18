import SwiftUI

struct VerdictMixView: View {
    let items: [HistoryItem]
    
    private let verdictOrder = ["excellent", "good", "fair", "okay", "avoid"]
    
    var verdictCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for item in items {
            let healthScore = item.product.calculateScore()
            let verdict = healthScore.simplifiedDisplay.verdict.rawValue.lowercased()
            counts[verdict, default: 0] += 1
        }
        return counts
    }
    
    var totalProducts: Int {
        items.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Title
            Text("Total Scans")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            // Verdict list
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(verdictOrder, id: \.self) { verdict in
                    VerdictListItem(
                        verdict: verdict,
                        count: verdictCounts[verdict] ?? 0,
                        total: totalProducts
                    )
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
        .frame(maxWidth: .infinity)
    }
}

private struct VerdictListItem: View {
    let verdict: String
    let count: Int
    let total: Int
    
    private var percentage: Int {
        total > 0 ? Int((Double(count) / Double(total)) * 100) : 0
    }
    
    private var formattedVerdict: String {
        verdict.prefix(1).uppercased() + verdict.dropFirst()
    }
    
    private var circleColor: Color {
        switch verdict.lowercased() {
        case "excellent":
            return Color(red: 0.13, green: 0.48, blue: 0.27) // Dark/forest green
        case "good":
            return Color(red: 0.2, green: 0.7, blue: 0.4) // Light green (was excellent's color)
        case "fair":
            return Color(red: 1.0, green: 1.0, blue: 0.0) // Yellow
        case "okay":
            return Color(red: 1.0, green: 0.65, blue: 0.0) // Orange
        case "avoid":
            return Color(red: 1.0, green: 0.0, blue: 0.0) // Red
        default:
            return Color.gray
        }
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Text(formattedVerdict)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            HStack(spacing: Spacing.xs) {
                Text("\(count)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                Text("(\(percentage)%)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.textSecondary)
            }
            
            Circle()
                .fill(circleColor)
                .frame(width: 12, height: 12)
        }
        .padding(.vertical, Spacing.xs)
    }
}

#if DEBUG
struct VerdictMixView_Previews: PreviewProvider {
    static var previews: some View {
        VerdictMixView(items: HistoryItem.mockItems)
    }
}

extension HistoryItem {
    static let mockItems = [
        HistoryItem(product: Product.mock, scanDate: Date(), scanObjectID: nil),
        HistoryItem(product: Product.mock, scanDate: Date().addingTimeInterval(-86400), scanObjectID: nil),
        HistoryItem(product: Product.mock, scanDate: Date().addingTimeInterval(-172800), scanObjectID: nil),
    ]
}

extension Product {
    static let mock = Product(
        id: UUID().uuidString,
        barcode: "123456789",
        name: "Mock Product",
        brand: "Mock Brand",
        category: "Food",
        nutritionalData: NutritionalData(),
        ingredients: "Water, Sugar",
        servingSize: "100g",
        imageURL: nil,
        thumbnailURL: nil,
        lastScanned: Date(),
        nutriScore: nil
    )
}
#endif
