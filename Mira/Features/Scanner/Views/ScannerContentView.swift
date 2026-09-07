import SwiftUI
import UIKit
import Combine

struct ScannerContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ScannerViewModel()
    @State private var showProductDetail = false
    @State private var showInsightsUnlocked = false
    // Smart default: enable filter mode if user has dietary restrictions
    @State private var isFilterModeEnabled: Bool
    @State private var showNonCompliantAlert = false
    @State private var currentViolations: [DietaryAnalysisResult] = []
    @State private var showComparisonMode = false
    @State private var isComparisonModeActive = false
    @State private var showSettings = false
    @StateObject private var comparisonViewModel = ComparisonModeViewModel()

    let onScanComplete: (ScanResult) -> Void

    init(onScanComplete: @escaping (ScanResult) -> Void = { _ in }) {
        self.onScanComplete = onScanComplete
        // Initialize filter mode based on whether user has dietary restrictions
        _isFilterModeEnabled = State(initialValue: false) // Will be set in onAppear
    }

    var body: some View {
        mainContent
            .task {
                await viewModel.setupCamera()
                viewModel.simulateConfiguredScanIfNeeded()
            }
            .onAppear {
                viewModel.startScanning()
            }
            .onDisappear {
                viewModel.stopScanning()
            }
            .onChange(of: scenePhase, perform: handleScenePhaseChange)
            .onReceive(viewModel.$scannedProduct, perform: handleScannedProduct)
            .onReceive(viewModel.$lastScanResult.compactMap { $0 }) { result in
                onScanComplete(result)
            }
    }

    private var mainContent: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.hasPermission {
                scannerBody
            } else {
                permissionView
            }

            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .sheet(isPresented: $showProductDetail, onDismiss: {
            viewModel.resetScanner()
        }) {
            productDetailSheet
        }
        .sheet(isPresented: $viewModel.showDuplicateScan, onDismiss: {
            viewModel.resetScanner()
        }) {
            if let product = viewModel.scannedProduct,
               let previousDate = viewModel.previousScanDate {
                let healthFocus = UserDefaults.standard.string(
                    forKey: Constants.UserDefaults.selectedHealthFocus
                ) ?? HealthFocus.generalWellness.rawValue
                DuplicateScanSheet(
                    product: product,
                    previousScanDate: previousDate,
                    healthFocus: HealthFocus(fromStored: healthFocus),
                    onViewDetails: {
                        viewModel.showDuplicateScan = false
                        showProductDetail = true
                    },
                    onScanNew: {
                        viewModel.showDuplicateScan = false
                        viewModel.resetScanner()
                    }
                )
            }
        }
        .sheet(isPresented: $showInsightsUnlocked) {
            InsightsUnlockedSheet {
                appState.selectedTab = Tab.insights.rawValue
            }
        }
        .sheet(isPresented: $showNonCompliantAlert, onDismiss: {
            viewModel.resetScanner()
        }) {
            if let product = viewModel.scannedProduct {
                NonCompliantProductSheet(
                    product: product,
                    violations: currentViolations,
                    onViewAlternatives: {
                        // Dismiss current sheet first, then show product detail after a brief delay
                        showNonCompliantAlert = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showProductDetail = true
                        }
                    },
                    onScanNew: {
                        showNonCompliantAlert = false
                        viewModel.resetScanner()
                    }
                )
            }
        }
        .onChange(of: viewModel.scannedProduct?.id) { newId in
            // Check if we should show insights unlocked after this scan
            if newId != nil && !viewModel.showDuplicateScan {
                checkAndShowInsightsUnlocked()
            }
        }
        .sheet(isPresented: $showComparisonMode) {
            ComparisonModeView(appState: appState, viewModel: comparisonViewModel)
                .onDisappear {
                    // Reset comparison mode state when sheet is dismissed
                    if comparisonViewModel.comparisonProducts.isEmpty {
                        isComparisonModeActive = false
                    }
                }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Event Handlers

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            viewModel.refreshPermissionStatus()
            viewModel.startScanning()
        case .background, .inactive:
            viewModel.stopScanning()
        @unknown default:
            break
        }
    }

    private func handleScannedProduct(_ product: ProductModel?) {
        // Only show product detail if it's not a duplicate scan
        if let product = product, !viewModel.showDuplicateScan {
            // If comparison mode is active, add to comparison instead of showing detail
            if isComparisonModeActive {
                handleProductForComparison(product)
            } else {
                // Check dietary compliance if filter mode is enabled
                let restrictions = DietaryRestriction.fromStrings(appState.dietaryRestrictions)
                if isFilterModeEnabled && !restrictions.isEmpty {
                    checkDietaryCompliance(for: product, restrictions: restrictions)
                } else {
                    showProductDetail = true
                }
            }
        } else if product == nil {
            showProductDetail = false
        }
    }

    // MARK: - Comparison Mode Handling

    private func handleProductForComparison(_ product: ProductModel) {
        // Add product to comparison
        comparisonViewModel.addProduct(product)

        // Reset scanner to allow scanning next product
        viewModel.resetScanner()

        // If we've reached the max (3), show the comparison view
        if !comparisonViewModel.canAddMore() {
            showComparisonMode = true
            isComparisonModeActive = false
        }
    }

    // MARK: - Dietary Compliance Check

    private func checkDietaryCompliance(for product: ProductModel, restrictions: [DietaryRestriction]) {
        // Check for dietary violations
        let violatedRestrictions = ScoringEngine.shared.checkDietaryViolations(
            ingredients: product.ingredients,
            restrictions: restrictions
        )

        // Convert to DietaryAnalysisResult format
        let violationResults: [DietaryAnalysisResult] = violatedRestrictions.map { restriction in
            // Create violation for each ingredient that might violate
            let violations = product.ingredients.map { ingredient in
                DietaryViolation(
                    ingredient: ingredient,
                    violationType: .directMatch,
                    isDerivative: false,
                    derivedFrom: nil,
                    aiExplanation: nil
                )
            }

            return DietaryAnalysisResult.violation(
                restriction: restriction,
                violations: violations,
                confidence: .high,
                method: .regexOnly
            )
        }

        if !violationResults.isEmpty {
            // Product violates dietary restrictions
            currentViolations = violationResults
            showNonCompliantAlert = true
        } else {
            // Product is compliant - show details
            showProductDetail = true
        }
    }

    // MARK: - Insights Unlocked Check

    private func checkAndShowInsightsUnlocked() {
        let hasSeenInsightsUnlocked = UserDefaults.standard.bool(
            forKey: Constants.UserDefaults.hasSeenInsightsUnlocked
        )

        guard !hasSeenInsightsUnlocked else { return }

        // Check scan count from CoreData
        Task {
            do {
                let scanCount = try CoreDataManager.shared.getScanHistoryCount()

                await MainActor.run {
                    if scanCount >= 5 {
                        // Small delay to let product detail appear first
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showInsightsUnlocked = true
                            UserDefaults.standard.set(
                                true,
                                forKey: Constants.UserDefaults.hasSeenInsightsUnlocked
                            )
                        }
                    }
                }
            } catch {
                AppLog.warning("Could not check scan count for insights unlocked: \(error.localizedDescription)", category: .scanner)
            }
        }
    }

    private var scannerBody: some View {
        ZStack {
            if let session = viewModel.captureSession {
                CameraPreviewView(session: session)
                    .ignoresSafeArea()
            } else {
                scannerFallbackView
            }

            ScannerOverlayView(
                isScanning: viewModel.isScanning,
                hasScannedProduct: viewModel.scannedProduct != nil,
                errorMessage: viewModel.errorMessage,
                onDismissError: viewModel.dismissError,
                hasFilterMode: isFilterModeEnabled
            )
            .animation(AnimationConstants.fade, value: viewModel.errorMessage)
        }
        .overlay(alignment: .top) {
            VStack(spacing: 8) {
                // Top action bar with filter, flash, settings buttons
                HStack(spacing: 16) {
                    // Filter button
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            isFilterModeEnabled.toggle()
                        }
                    } label: {
                        Image(systemName: isFilterModeEnabled ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(isFilterModeEnabled ? "Turn off dietary filter" : "Turn on dietary filter")
                    .accessibilityHint("Uses your saved dietary restrictions while scanning")
                    .accessibilityIdentifier("scanner.filter")

                    Spacer()

                    // Flash button
                    if viewModel.hasPermission && viewModel.isTorchAvailable {
                        Button {
                            viewModel.toggleTorch()
                        } label: {
                            Image(systemName: viewModel.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel(viewModel.isTorchOn ? "Turn off flashlight" : "Turn on flashlight")
                        .accessibilityIdentifier("scanner.flash")
                    }

                    // Settings button
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Scanner settings")
                    .accessibilityIdentifier("scanner.settings")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Filter mode toggle (shows when filter is enabled)
                if isFilterModeEnabled {
                    FilterModeToggle(
                        isFilterModeEnabled: $isFilterModeEnabled,
                        activeRestrictions: DietaryRestriction.fromStrings(appState.dietaryRestrictions)
                    )
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .overlay(alignment: .bottom) {
            ScannerComparisonButton(
                isActive: isComparisonModeActive,
                productCount: comparisonViewModel.comparisonProducts.count,
                onToggle: {
                    if isComparisonModeActive {
                        isComparisonModeActive = false
                        if !comparisonViewModel.comparisonProducts.isEmpty {
                            showComparisonMode = true
                        }
                    } else {
                        isComparisonModeActive = true
                    }
                },
                onViewComparison: {
                    showComparisonMode = true
                }
            )
            .padding(.bottom, 50)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            LoadingViewWithMessage(message: "Fetching product details...")
                .padding(32)
        }
        .transition(.opacity.animation(AnimationConstants.fade))
    }

    private var scannerFallbackView: some View {
        LinearGradient(
            colors: [
                Color.deepForest.opacity(0.95),
                Color.oceanTeal.opacity(0.85),
                Color.black
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .overlay {
            VStack(spacing: Spacing.xl) {
                Spacer()

                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundColor(.white)

                VStack(spacing: Spacing.sm) {
                    Text(scannerFallbackTitle)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(scannerFallbackMessage)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.sectionSpacing)
                }

                VStack(spacing: Spacing.sm) {
                    Button {
                        viewModel.refreshPermissionStatus()
                    } label: {
                        Text(viewModel.hasPermission ? "Retry Camera" : "Enable Camera")
                            .font(.headline)
                            .foregroundColor(.textOnDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(Color.oceanTeal)
                            .cornerRadius(CornerRadius.button)
                    }
                    .accessibilityIdentifier("scanner.retryCamera")

                    Button {
                        appState.selectedTab = Tab.search.rawValue
                    } label: {
                        Text("Browse Products Instead")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(Color.white.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.button)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .cornerRadius(CornerRadius.button)
                    }
                    .accessibilityIdentifier("scanner.fallbackBrowse")
                }
                .padding(.horizontal, Spacing.sectionSpacing)

                Spacer()
            }
            .padding(.bottom, Spacing.massive)
        }
    }

    private var scannerFallbackTitle: String {
        if !viewModel.hasPermission {
            return "Camera access is off"
        }

        #if targetEnvironment(simulator)
        return "Camera preview is unavailable in Simulator"
        #else
        return "Getting the scanner ready"
        #endif
    }

    private var scannerFallbackMessage: String {
        if !viewModel.hasPermission {
            return "Allow camera access to scan barcodes and unlock product details instantly."
        }

        #if targetEnvironment(simulator)
        return "Use a physical iPhone for live barcode scanning, or switch to search while you keep building."
        #else
        return "If the camera does not appear within a moment, retry or use search to keep exploring the app."
        #endif
    }

    @ViewBuilder
    private var productDetailSheet: some View {
        let barcode = viewModel.scannedProduct?.barcode ?? ""

        if !barcode.isEmpty {
            NavigationStack {
                ProductDetailView(barcode: barcode)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showProductDetail = false
                            }
                        }
                    }
            }
        } else {
            EmptyView()
        }
    }

    private var permissionView: some View {
        VStack(spacing: 20) {
            Image("TabScanSelected")
                .renderingMode(.original)
                .resizable()
                .frame(width: 100, height: 100)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 6)

            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("Please allow camera access in Settings to scan barcodes")
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Open Settings") {
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(settingsURL)
            }
            .foregroundColor(.blue)
            .padding(.top, 10)
            .accessibilityIdentifier("scanner.openSettings")

            Button("Browse Products Instead") {
                appState.selectedTab = Tab.search.rawValue
            }
            .foregroundColor(.white)
            .padding(.top, 4)
            .accessibilityIdentifier("scanner.permissionBrowse")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

private struct ScannerComparisonButton: View {
    let isActive: Bool
    let productCount: Int
    let onToggle: () -> Void
    let onViewComparison: () -> Void

    var body: some View {
        Menu {
            Button {
                onToggle()
            } label: {
                Label(
                    isActive ? "Exit Compare Mode" : "Enter Compare Mode",
                    systemImage: isActive ? "xmark" : "scale.3d"
                )
            }

            if productCount > 0 {
                Button {
                    onViewComparison()
                } label: {
                    Label(
                        "View Comparison (\(productCount))",
                        systemImage: "eye"
                    )
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text("Compare")
                    .font(.callout)
                    .fontWeight(.semibold)

                if productCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.error)
                            .frame(width: 20, height: 20)

                        Text("\(productCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.oceanTeal)
            .cornerRadius(24)
        }
        .accessibilityLabel(isActive ? "Comparison mode active, \(productCount) products" : "Comparison mode")
        .accessibilityHint(isActive ? "Exit comparison mode or view current comparison" : "Enter comparison mode to scan and compare multiple products")
        .accessibilityIdentifier("scanner.compare")
    }
}

#Preview {
    ScannerContentView()
}
