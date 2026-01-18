import SwiftUI

/// Quick action bar that appears at the top of product detail
/// Provides instant decision + key actions for grocery store use
struct QuickScoreActionBar: View {
    let display: SimplifiedScoreDisplay
    let onCompare: () -> Void
    let onSeeDetails: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Score + Verdict
            HStack(spacing: 12) {
                // Large score circle
                ZStack {
                    Circle()
                        .fill(verdictColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Text("\(display.score)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(verdictColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(display.verdict.label.uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(verdictColor)
                        
                        Image(systemName: display.verdict.systemIcon)
                            .font(.system(size: 16))
                            .foregroundColor(verdictColor)
                    }
                    
                    Text(display.message)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Quick actions
            HStack(spacing: 12) {
                Button(action: onCompare) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 14))
                        Text("Compare")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button(action: onSeeDetails) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14))
                        Text("Details")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var verdictColor: Color {
        switch display.verdict {
        case .excellent:
            return Color.green
        case .good:
            return Color.green.opacity(0.7)
        case .okay:
            return Color.yellow
        case .fair:
            return Color.orange
        case .avoid:
            return Color.red
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        QuickScoreActionBar(
            display: SimplifiedScoreDisplay(
                score: 85,
                verdict: .excellent,
                topFactors: ["✓ Good protein", "✓ High fiber"],
                categoryContext: "Top 10% of yogurts"
            ),
            onCompare: {},
            onSeeDetails: {}
        )
        
        QuickScoreActionBar(
            display: SimplifiedScoreDisplay(
                score: 35,
                verdict: .avoid,
                topFactors: ["⚠️ High sugar", "⚠️ High sodium"],
                categoryContext: "Bottom 10% of cereals"
            ),
            onCompare: {},
            onSeeDetails: {}
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}










