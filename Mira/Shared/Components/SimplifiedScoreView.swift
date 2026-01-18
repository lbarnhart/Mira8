import SwiftUI

/// Level 1 Display: Instant Nutriscore verdict for grocery store use
/// Shows the verdict and dietary restrictions only
/// Detailed custom score analysis available in expandable Advanced section
struct SimplifiedScoreView: View {
    let display: SimplifiedScoreDisplay
    let productName: String?
    let positiveFactors: [String]
    let negativeFactors: [String]

    var body: some View {
        VStack(spacing: 20) {
            // Verdict pill with color coding
            verdictPill
            
            // Descriptive message about the choice
            descriptiveMessage
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private var verdictPill: some View {
        HStack(spacing: 0) {
            Text(display.verdict.emoji)
                .font(.system(size: 24))
                .padding(.trailing, 12)
            
            Text(display.verdict.label.uppercased())
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(verdictColor)
        .cornerRadius(12)
    }
    
    private var descriptiveMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(display.message)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            if let context = display.categoryContext {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(context)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var verdictColor: Color {
        switch display.verdict {
        case .excellent:
            return Color(red: 0.15, green: 0.68, blue: 0.38)  // Green
        case .good:
            return Color(red: 0.95, green: 0.77, blue: 0.06)  // Golden/Yellow
        case .okay:
            return Color(red: 0.95, green: 0.77, blue: 0.06)  // Yellow
        case .fair:
            return Color(red: 1.0, green: 0.58, blue: 0.0)    // Orange
        case .avoid:
            return Color(red: 0.95, green: 0.26, blue: 0.21)  // Red
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SimplifiedScoreView(
            display: SimplifiedScoreDisplay(
                score: 85,
                verdict: .excellent,
                topFactors: [],
                categoryContext: nil
            ),
            productName: "Greek Yogurt",
            positiveFactors: [],
            negativeFactors: []
        )
        
        SimplifiedScoreView(
            display: SimplifiedScoreDisplay(
                score: 35,
                verdict: .avoid,
                topFactors: [],
                categoryContext: nil
            ),
            productName: "Sugar Cereal",
            positiveFactors: [],
            negativeFactors: []
        )
    }
    .padding()
}



