import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var scansThisMonth: Int = 0
    @State private var averageScore: Double?
    @State private var isLoadingStats = false
    @State private var statsError: String?
    @State private var showHealthFocusSettings = false
    @State private var showDietarySettings = false

    private let coreDataManager = CoreDataManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.sectionSpacing) {
                    healthFocusCard
                    restrictionsCard
                    statsCard
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.sectionSpacing)
            }
            .background(Color.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationDestination(isPresented: $showHealthFocusSettings) {
                HealthFocusSettingsView()
            }
            .navigationDestination(isPresented: $showDietarySettings) {
                DietaryRestrictionsSettingsView()
            }
            .task(loadStats)
            .onChange(of: showHealthFocusSettings) { newValue in
                if newValue == false {
                    Task { await loadStats() }
                }
            }
            .onChange(of: showDietarySettings) { newValue in
                if newValue == false {
                    Task { await loadStats() }
                }
            }
            .alert("Unable to load stats", isPresented: Binding(get: { statsError != nil }, set: { _ in statsError = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(statsError ?? "")
            }
        }
    }

    private var healthFocusCard: some View {
        let option = HealthFocusOption.option(for: appState.healthFocus) ?? HealthFocusOption.all.last!

        return Button {
            showHealthFocusSettings = true
        } label: {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Health Focus")
                    .font(.headline)
                    .foregroundColor(.textSecondary)

                HStack(spacing: Spacing.lg) {
                    ZStack {
                        if option.isSystemIcon {
                            Image(systemName: option.icon)
                                .font(.system(size: 32))
                                .foregroundColor(option.tint)
                        } else {
                            Image(option.icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 36, height: 36)
                        }
                    }
                    .frame(width: 64, height: 64)
                    .background(option.tint.opacity(0.15))
                    .cornerRadius(CornerRadius.button)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(option.title)
                            .font(.title3.bold())
                            .foregroundColor(.textPrimary)

                        Text(option.description)
                            .font(.body)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()
                }
            }
            .padding()
            .cardStyle(.standard)
        }
        .buttonStyle(.plain)
    }

    private var restrictionsCard: some View {
        Button {
            showDietarySettings = true
        } label: {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Dietary Restrictions")
                    .font(.headline)
                    .foregroundColor(.textSecondary)

                if appState.dietaryRestrictions.isEmpty {
                    Text("None")
                        .font(.body)
                        .foregroundColor(.textPrimary)
                        .padding(Spacing.sm)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(CornerRadius.button)
                } else {
                    FlexibleTagView(tags: Array(appState.dietaryRestrictions))
                }
            }
            .padding()
            .cardStyle(.standard)
        }
        .buttonStyle(.plain)
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Stats")
                    .font(.headline)
                    .foregroundColor(.textSecondary)
                Spacer()
                if isLoadingStats {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            HStack(alignment: .center, spacing: Spacing.sectionSpacing) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Scans this month")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    Text("\(scansThisMonth)")
                        .font(.title2.bold())
                        .foregroundColor(.textPrimary)
                }

                if let averageScore {
                    Spacer()
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Average score")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        Text("\(Int(averageScore))")
                            .font(.title2.bold())
                            .foregroundColor(Color.scoreColor(for: averageScore))
                    }
                }
            }
        }
        .padding()
        .cardStyle(.standard)
    }

    private func loadStats() async {
        await MainActor.run { isLoadingStats = true }
        do {
            let history = try coreDataManager.fetchScanHistory(limit: 0)
            let calendar = Calendar.current
            let now = Date()

            let monthCount = history.filter { entry in
                guard let date = entry.scanDate else { return false }
                return calendar.isDate(date, equalTo: now, toGranularity: .month) &&
                    calendar.isDate(date, equalTo: now, toGranularity: .year)
            }.count

            var dynamicScores: [Double] = []
            for entry in history {
                if let barcode = entry.productBarcode, let product = try? coreDataManager.fetchProduct(byBarcode: barcode) {
                    let score = product.calculateScore(for: appState.healthFocus).overall
                    dynamicScores.append(score)
                }
            }
            let average = dynamicScores.isEmpty ? nil : dynamicScores.reduce(0, +) / Double(dynamicScores.count)

            await MainActor.run {
                self.scansThisMonth = monthCount
                self.averageScore = average
                self.isLoadingStats = false
                self.statsError = nil
            }
        } catch {
            await MainActor.run {
                self.isLoadingStats = false
                self.statsError = error.localizedDescription
            }
        }
    }
}

private struct FlexibleTagView: View {
    let tags: [String]

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: Spacing.sm)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.sm) {
            ForEach(tags.sorted(), id: \.self) { tag in
                Text(formatted(tag))
                    .font(.caption.bold())
                    .foregroundColor(.primaryBlue)
                    .padding(.vertical, Spacing.xs)
                    .padding(.horizontal, Spacing.md)
                    .background(Color.primaryBlue.opacity(0.1))
                    .cornerRadius(CornerRadius.pill)
            }
        }
    }

    private func formatted(_ raw: String) -> String {
        raw.replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

#Preview {
    let appState = AppState()
    appState.updateOnboardingStatus(healthFocus: "gutHealth", restrictions: ["vegan", "glutenFree"], completed: true)
    return ProfileView()
        .environmentObject(appState)
}
