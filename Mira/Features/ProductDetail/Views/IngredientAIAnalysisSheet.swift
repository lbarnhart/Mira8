import SwiftUI

/// Error types for ingredient analysis
enum IngredientAnalysisError: LocalizedError, Equatable {
    case offline
    case rateLimited
    case apiUnavailable
    case decodingFailed
    case unknown(String)

    static func == (lhs: IngredientAnalysisError, rhs: IngredientAnalysisError) -> Bool {
        switch (lhs, rhs) {
        case (.offline, .offline),
             (.rateLimited, .rateLimited),
             (.apiUnavailable, .apiUnavailable),
             (.decodingFailed, .decodingFailed):
            return true
        case (.unknown(let lhsMsg), .unknown(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .offline:
            return "No internet connection"
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        case .apiUnavailable:
            return "AI service is temporarily unavailable"
        case .decodingFailed:
            return "Unable to process the response"
        case .unknown(let message):
            return message
        }
    }

    var recoveryMessage: String {
        switch self {
        case .offline:
            return "Check your connection and try again"
        case .rateLimited:
            return "Wait a few seconds before retrying"
        case .apiUnavailable:
            return "The service may be experiencing high demand"
        case .decodingFailed:
            return "Try again - this is usually temporary"
        case .unknown:
            return "An unexpected error occurred"
        }
    }

    var iconName: String {
        switch self {
        case .offline: return "wifi.slash"
        case .rateLimited: return "clock.badge.exclamationmark"
        case .apiUnavailable: return "server.rack"
        case .decodingFailed: return "doc.questionmark"
        case .unknown: return "exclamationmark.triangle"
        }
    }

    var canRetry: Bool {
        switch self {
        case .rateLimited: return true
        case .offline: return true
        case .apiUnavailable: return true
        case .decodingFailed: return true
        case .unknown: return true
        }
    }

    static func from(_ error: Error) -> IngredientAnalysisError {
        let nsError = error as NSError

        // Check for network-related errors
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorDataNotAllowed:
                return .offline
            default:
                break
            }
        }

        // Check for HTTP status codes in the error
        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            if underlyingError.code == 429 {
                return .rateLimited
            }
            if underlyingError.code >= 500 && underlyingError.code < 600 {
                return .apiUnavailable
            }
        }

        // Check error description for common patterns
        let description = error.localizedDescription.lowercased()
        if description.contains("rate limit") || description.contains("429") {
            return .rateLimited
        }
        if description.contains("decode") || description.contains("json") {
            return .decodingFailed
        }
        if description.contains("offline") || description.contains("internet") {
            return .offline
        }

        return .unknown(error.localizedDescription)
    }
}

/// Sheet that displays AI-powered ingredient analysis.
/// Shows loading state, analysis results, or error state.
struct IngredientAIAnalysisSheet: View {
    let ingredientName: String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    @State private var analysis: AIIngredientAnalysis?
    @State private var isLoading = false
    @State private var analysisError: IngredientAnalysisError?
    @State private var retryCount = 0
    @State private var isRetrying = false

    private let maxRetries = 3
    private let baseRetryDelay: TimeInterval = 1.0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if isLoading {
                        loadingSkeletonView
                    } else if let error = analysisError {
                        errorView(error: error)
                    } else if let analysis = analysis {
                        analysisContent(analysis)
                    }
                }
                .padding(Spacing.lg)
            }
            .navigationTitle(ingredientName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            await loadAnalysis()
        }
    }

    // MARK: - Loading Skeleton View

    private var loadingSkeletonView: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Status indicator
            HStack(spacing: Spacing.sm) {
                ProgressView()
                    .scaleEffect(0.8)
                Text(isRetrying ? "Retrying... (attempt \(retryCount + 1))" : "Analyzing \(ingredientName)...")
                    .font(.callout)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, Spacing.sm)

            // Safety badge skeleton
            SkeletonView()
                .frame(width: 140, height: 44)
                .cornerRadius(CornerRadius.md)

            // Summary skeleton
            VStack(alignment: .leading, spacing: Spacing.xs) {
                SkeletonView()
                    .frame(height: 20)
                SkeletonView()
                    .frame(width: 200, height: 20)
            }

            // Details section skeleton
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.xs) {
                    SkeletonView()
                        .frame(width: 20, height: 20)
                        .cornerRadius(4)
                    SkeletonView()
                        .frame(width: 60, height: 16)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    SkeletonView().frame(height: 14)
                    SkeletonView().frame(height: 14)
                    SkeletonView().frame(height: 14)
                    SkeletonView().frame(width: 250, height: 14)
                }
            }
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(CornerRadius.md)

            // Research section skeleton
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.xs) {
                    SkeletonView()
                        .frame(width: 20, height: 20)
                        .cornerRadius(4)
                    SkeletonView()
                        .frame(width: 70, height: 16)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    SkeletonView().frame(height: 14)
                    SkeletonView().frame(height: 14)
                    SkeletonView().frame(width: 180, height: 14)
                }
            }
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(CornerRadius.md)

            // Confidence indicator skeleton
            HStack(spacing: Spacing.sm) {
                SkeletonView()
                    .frame(width: 80, height: 12)
                SkeletonView()
                    .frame(width: 80, height: 8)
                    .cornerRadius(4)
                SkeletonView()
                    .frame(width: 30, height: 12)
            }
        }
    }

    // MARK: - Error View

    private func errorView(error: IngredientAnalysisError) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: error.iconName)
                .font(.system(size: 40))
                .foregroundColor(error == .rateLimited ? .yellow : .orange)

            Text("Unable to analyze ingredient")
                .font(.headline)

            Text(error.errorDescription ?? "Unknown error")
                .font(.callout)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            Text(error.recoveryMessage)
                .font(.caption)
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if retryCount > 0 {
                Text("Attempted \(retryCount) time\(retryCount == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
            }

            if error.canRetry {
                Button {
                    Task { await retryAnalysis() }
                } label: {
                    Label("Try Again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .padding(.top, Spacing.sm)
                .disabled(isRetrying)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Analysis Content

    @ViewBuilder
    private func analysisContent(_ analysis: AIIngredientAnalysis) -> some View {
        // Safety Rating Badge
        safetyBadge(rating: analysis.safetyRating)

        // Summary
        Text(analysis.summary)
            .font(.headline)
            .foregroundColor(.textPrimary)

        // Detailed Explanation
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Details", icon: "doc.text")
            Text(analysis.detailedExplanation)
                .font(.body)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)

        // Research Context
        if let research = analysis.researchContext, !research.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                sectionHeader("Research", icon: "book")
                Text(research)
                    .font(.callout)
                    .foregroundColor(.textSecondary)
            }
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(CornerRadius.md)
        }

        // Dietary Restrictions Warning
        if !analysis.relevantRestrictions.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                sectionHeader("Dietary Note", icon: "exclamationmark.circle")
                Text("May affect: \(analysis.relevantRestrictions.joined(separator: ", "))")
                    .font(.callout)
                    .foregroundColor(.orange)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(CornerRadius.md)
        }

        // Alternatives
        if let alternatives = analysis.alternatives, !alternatives.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                sectionHeader("Alternatives", icon: "arrow.triangle.2.circlepath")
                ForEach(alternatives, id: \.self) { alt in
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "leaf")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(alt)
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(CornerRadius.md)
        }

        // Confidence Indicator
        confidenceIndicator(confidence: analysis.confidence)

        // Disclaimer
        Text("This analysis is AI-generated and for informational purposes only. Always consult healthcare professionals for medical advice.")
            .font(.caption2)
            .foregroundColor(.textTertiary)
            .padding(.top, Spacing.sm)
    }

    // MARK: - Components

    private func safetyBadge(rating: AIIngredientAnalysis.SafetyRating) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: rating.iconName)
                .font(.title2)
            Text(rating.displayName)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .foregroundColor(colorForRating(rating))
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(colorForRating(rating).opacity(0.12))
        .cornerRadius(CornerRadius.md)
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(.primaryBlue)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    private func confidenceIndicator(confidence: Double) -> some View {
        HStack(spacing: Spacing.sm) {
            Text("Confidence:")
                .font(.caption)
                .foregroundColor(.textTertiary)

            ProgressView(value: confidence, total: 1.0)
                .tint(confidence >= 0.7 ? .green : confidence >= 0.4 ? .orange : .red)
                .frame(width: 80)

            Text("\(Int(confidence * 100))%")
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
    }

    private func colorForRating(_ rating: AIIngredientAnalysis.SafetyRating) -> Color {
        switch rating {
        case .safe: return .green
        case .caution: return .orange
        case .avoid: return .red
        }
    }

    // MARK: - Data Loading

    private func loadAnalysis() async {
        guard analysis == nil else { return }

        isLoading = true
        analysisError = nil
        retryCount = 0

        await performAnalysisWithRetry()
    }

    private func retryAnalysis() async {
        isLoading = true
        isRetrying = true
        analysisError = nil

        await performAnalysisWithRetry()

        isRetrying = false
    }

    private func performAnalysisWithRetry() async {
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                analysis = try await IngredientAIService.shared.analyzeIngredient(
                    name: ingredientName,
                    healthFocus: appState.healthFocus,
                    dietaryRestrictions: appState.dietaryRestrictions
                )
                isLoading = false
                return
            } catch {
                lastError = error
                retryCount = attempt + 1

                let typedError = IngredientAnalysisError.from(error)

                // Don't retry on rate limiting - let user decide
                if case .rateLimited = typedError {
                    analysisError = typedError
                    isLoading = false
                    return
                }

                // If not the last attempt, wait before retrying
                if attempt < maxRetries - 1 {
                    let delay = baseRetryDelay * pow(2.0, Double(attempt))
                    let jitter = Double.random(in: 0...0.3) * delay
                    try? await Task.sleep(nanoseconds: UInt64((delay + jitter) * 1_000_000_000))
                }
            }
        }

        // All retries exhausted
        if let error = lastError {
            analysisError = IngredientAnalysisError.from(error)
        }
        isLoading = false
    }
}

// MARK: - Skeleton View Component

/// Animated placeholder view for loading states
struct SkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray.opacity(0.2),
                        Color.gray.opacity(0.35),
                        Color.gray.opacity(0.2)
                    ]),
                    startPoint: isAnimating ? .trailing : .leading,
                    endPoint: isAnimating ? .leading : .trailing
                )
            )
            .onAppear {
                withAnimation(
                    Animation
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}

#Preview {
    IngredientAIAnalysisSheet(ingredientName: "Carrageenan")
        .environmentObject(AppState.shared)
}
