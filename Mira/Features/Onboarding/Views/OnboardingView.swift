import SwiftUI

struct OnboardingView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var currentPage = 0

    private let totalPages = 3

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.top, Spacing.xxxl)

            TabView(selection: $currentPage) {
                WelcomeView()
                    .tag(0)

                HealthFocusSelectionView(
                    selectedFocus: $viewModel.selectedHealthFocus,
                    onSelection: viewModel.selectHealthFocus
                )
                .tag(1)

                DietaryRestrictionsView(
                    selectedRestrictions: $viewModel.selectedRestrictions,
                    onToggle: viewModel.toggleRestriction,
                    onSkip: viewModel.skipRestrictions
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            footer
                .padding(Spacing.screenPadding)
                .padding(.bottom, Spacing.xxxl)
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .alert("Something went wrong", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "We couldn't save your preferences. Please try again.")
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            ProgressDots(currentIndex: currentPage, total: totalPages)

            Spacer()

            Button("Skip") {
                viewModel.skipOnboarding(appState: appState)
            }
            .font(.body.weight(.semibold))
            .foregroundColor(.textSecondary)
        }
    }

    private var footer: some View {
        VStack(spacing: Spacing.md) {
            PrimaryButton(buttonTitle, isFullWidth: true, isEnabled: isPrimaryEnabled) {
                handlePrimaryAction()
            }

            if currentPage == 2 {
                Text("You can update these preferences anytime in Settings.")
                    .font(.footnote)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var buttonTitle: String {
        currentPage == totalPages - 1 ? "Done" : "Next"
    }

    private var isPrimaryEnabled: Bool {
        if currentPage == 1 {
            return viewModel.selectedHealthFocus != nil
        }
        return true
    }

    private func handlePrimaryAction() {
        if currentPage < totalPages - 1 {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentPage += 1
            }
        } else {
            viewModel.completeOnboarding(appState: appState)
        }
    }
}

private struct ProgressDots: View {
    let currentIndex: Int
    let total: Int

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? Color.primaryBlue : Color.primaryBlue.opacity(0.2))
                    .frame(width: index == currentIndex ? 32 : 12, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: currentIndex)
            }
        }
    }
}

#Preview {
    OnboardingView(appState: AppState())
}
