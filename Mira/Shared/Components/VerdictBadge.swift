import SwiftUI

/// Reusable component that displays a verdict badge with emoji, label, and optional score
/// Supports multiple size variants for different contexts
struct VerdictBadge: View {
    enum SizeVariant {
        case large      // Score detail screens (score + verdict prominent)
        case medium     // Product list items (compact)
        case small      // Inline badges (minimal space)
        case compact    // Tiny indicators (tag-like)
    }

    let verdict: ScoreVerdict
    let score: Double?
    let size: SizeVariant

    init(
        verdict: ScoreVerdict,
        score: Double? = nil,
        size: SizeVariant = .medium
    ) {
        self.verdict = verdict
        self.score = score
        self.size = size
    }

    var body: some View {
        switch size {
        case .large:
            largeVariant
        case .medium:
            mediumVariant
        case .small:
            smallVariant
        case .compact:
            compactVariant
        }
    }

    // MARK: - Large Variant (Score detail screens)
    // Shows verdict prominently with optional score
    private var largeVariant: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Text(verdict.emoji)
                    .font(.system(size: 48))

                VStack(alignment: .leading, spacing: 4) {
                    Text(verdict.label.uppercased())
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(verdictColor)

                    if let score = score {
                        Text("\(Int(round(score)))/100")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .background(verdictColor.opacity(0.08))
            .cornerRadius(12)

            Text(verdict.message)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Medium Variant (Product list items)
    // Compact circular badge with verdict
    private var mediumVariant: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(verdictColor.opacity(0.12))
                    .frame(width: 80, height: 80)

                VStack(spacing: 4) {
                    Text(verdict.emoji)
                        .font(.system(size: 24))

                    Text(verdict.label)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(verdictColor)
                }
            }

            if let score = score {
                Text("\(Int(round(score)))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
    }

    // MARK: - Small Variant (Inline badges)
    // Horizontal pill badge
    private var smallVariant: some View {
        HStack(spacing: 6) {
            Text(verdict.emoji)
                .font(.system(size: 14))

            Text(verdict.label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(verdictColor)

            if let score = score {
                Text("\(Int(round(score)))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(verdictColor.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - Compact Variant (Tiny indicators)
    // Minimal tag-like appearance
    private var compactVariant: some View {
        HStack(spacing: 3) {
            Text(verdict.emoji)
                .font(.system(size: 11))

            Text(verdict.label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(verdictColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(verdictColor.opacity(0.12))
        .cornerRadius(12)
    }

    // MARK: - Colors
    private var verdictColor: Color {
        switch verdict {
        case .excellent:
            return .green
        case .good:
            return Color(red: 0.2, green: 0.8, blue: 0.2) // Light green
        case .okay:
            return .yellow
        case .fair:
            return .orange
        case .avoid:
            return .red
        }
    }
}

// MARK: - Previews
#Preview("Large Variant") {
    VStack(spacing: 20) {
        VerdictBadge(verdict: .excellent, score: 92, size: .large)
        VerdictBadge(verdict: .avoid, score: 28, size: .large)
    }
    .padding()
}

#Preview("Medium Variant") {
    HStack(spacing: 20) {
        VerdictBadge(verdict: .excellent, score: 92, size: .medium)
        VerdictBadge(verdict: .okay, score: 62, size: .medium)
        VerdictBadge(verdict: .avoid, score: 28, size: .medium)
    }
    .padding()
}

#Preview("Small Variant") {
    VStack(spacing: 12) {
        HStack(spacing: 8) {
            VerdictBadge(verdict: .excellent, score: 92, size: .small)
            VerdictBadge(verdict: .good, score: 78, size: .small)
            VerdictBadge(verdict: .fair, score: 45, size: .small)
        }

        HStack(spacing: 8) {
            VerdictBadge(verdict: .excellent, size: .small)
            VerdictBadge(verdict: .avoid, size: .small)
        }
    }
    .padding()
}

#Preview("Compact Variant") {
    HStack(spacing: 6) {
        VerdictBadge(verdict: .excellent, size: .compact)
        VerdictBadge(verdict: .good, size: .compact)
        VerdictBadge(verdict: .okay, size: .compact)
        VerdictBadge(verdict: .fair, size: .compact)
        VerdictBadge(verdict: .avoid, size: .compact)
    }
    .padding()
}
