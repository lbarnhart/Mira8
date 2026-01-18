import SwiftUI

/// Side-by-side product comparison view
/// Designed for grocery store aisle decision-making
struct ProductComparisonView: View {
    let comparison: ComparisonResult
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Winner announcement
                winnerSection
                
                // Score comparison
                scoreComparisonSection
                
                // Key differences
                if !comparison.keyDifferences.isEmpty {
                    keyDifferencesSection
                }
                
                // Recommendation
                recommendationSection
                
                // Detailed comparison button
                Button(action: {
                    // Navigate to detailed comparison
                }) {
                    HStack {
                        Image(systemName: "chart.bar.doc.horizontal")
                        Text("View Detailed Comparison")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Product Comparison")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var winnerSection: some View {
        VStack(spacing: 12) {
            if comparison.areEssentiallyEqual {
                // Show equality icon for identical products
                Image(systemName: "equal.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)

                Text("No Clear Winner")
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)
            } else {
                // Show trophy for winner
                Image(systemName: "trophy.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)

                Text(comparison.winner.name)
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)
            }

            Text(comparison.recommendation)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(comparison.areEssentiallyEqual ? Color.blue.opacity(0.1) : Color.yellow.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var scoreComparisonSection: some View {
        HStack(spacing: 16) {
            // Product A
            VStack(spacing: 12) {
                // Product Image
                if let imageURL = comparison.productA.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            Color.gray.opacity(0.3)
                                .frame(height: 120)
                                .cornerRadius(8)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 120)
                                .clipped()
                                .cornerRadius(8)
                        case .failure:
                            Color.gray.opacity(0.2)
                                .frame(height: 120)
                                .cornerRadius(8)
                        @unknown default:
                            Color.gray.opacity(0.2)
                                .frame(height: 120)
                                .cornerRadius(8)
                        }
                    }
                    .frame(height: 120)
                } else {
                    Color.gray.opacity(0.2)
                        .frame(height: 120)
                        .cornerRadius(8)
                }
                
                // Verdict pill
                verdictPill(verdict: comparison.scoreA.verdict, isWinner: !comparison.areEssentiallyEqual && comparison.scoreA.overall >= comparison.scoreB.overall)
                
                // Product name
                Text(comparison.productA.name)
                    .font(.system(size: 14, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                // Brand
                if let brand = comparison.productA.brand {
                    Text(brand)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // View details link
                Text("View details >")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color.cardBackground)
            .border(borderColor(isWinner: !comparison.areEssentiallyEqual && comparison.scoreA.overall >= comparison.scoreB.overall), width: 3)
            .cornerRadius(12)
            
            // Product B
            VStack(spacing: 12) {
                // Product Image
                if let imageURL = comparison.productB.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            Color.gray.opacity(0.3)
                                .frame(height: 120)
                                .cornerRadius(8)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 120)
                                .clipped()
                                .cornerRadius(8)
                        case .failure:
                            Color.gray.opacity(0.2)
                                .frame(height: 120)
                                .cornerRadius(8)
                        @unknown default:
                            Color.gray.opacity(0.2)
                                .frame(height: 120)
                                .cornerRadius(8)
                        }
                    }
                    .frame(height: 120)
                } else {
                    Color.gray.opacity(0.2)
                        .frame(height: 120)
                        .cornerRadius(8)
                }
                
                // Verdict pill
                verdictPill(verdict: comparison.scoreB.verdict, isWinner: !comparison.areEssentiallyEqual && comparison.scoreB.overall >= comparison.scoreA.overall)
                
                // Product name
                Text(comparison.productB.name)
                    .font(.system(size: 14, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                // Brand
                if let brand = comparison.productB.brand {
                    Text(brand)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // View details link
                Text("View details >")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color.cardBackground)
            .border(borderColor(isWinner: !comparison.areEssentiallyEqual && comparison.scoreB.overall >= comparison.scoreA.overall), width: 3)
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var keyDifferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Differences")
                .font(.system(size: 18, weight: .semibold))
            
            ForEach(comparison.keyDifferences, id: \.description) { factor in
                HStack(spacing: 12) {
                    Image(systemName: factor.isPositive ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(factor.isPositive ? .green : .red)
                        .font(.system(size: 20))
                    
                    Text(factor.description)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(factor.winner)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(6)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var recommendationSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Recommendation")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            
            Text(comparison.detailedRecommendation)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func verdictPill(verdict: ScoreVerdict, isWinner: Bool) -> some View {
        HStack(spacing: 6) {
            Text(verdict.emoji)
                .font(.system(size: 14))
            
            Text(verdict.label.uppercased())
                .font(.system(size: 12, weight: .bold))
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(.white)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(verdictColor(verdict))
        .cornerRadius(20)
    }
    
    private func verdictColor(_ verdict: ScoreVerdict) -> Color {
        switch verdict {
        case .excellent:
            return Color(red: 0.15, green: 0.68, blue: 0.38)  // Green
        case .good:
            return Color(red: 0.95, green: 0.77, blue: 0.06)  // Golden
        case .okay:
            return Color(red: 0.95, green: 0.77, blue: 0.06)  // Yellow
        case .fair:
            return Color(red: 1.0, green: 0.58, blue: 0.0)    // Orange
        case .avoid:
            return Color(red: 0.95, green: 0.26, blue: 0.21)  // Red
        }
    }
    
    private func borderColor(isWinner: Bool) -> Color {
        return isWinner ? Color(red: 0.95, green: 0.77, blue: 0.06) : Color.gray.opacity(0.3)
    }
}

#Preview {
    NavigationView {
        ProductComparisonView(
            comparison: ComparisonResult(
                productA: ProductModel.mockYogurt,
                productB: ProductModel.mockIceCream,
                scoreA: HealthScore.mock(score: 85),
                scoreB: HealthScore.mock(score: 45)
            )
        )
    }
}



