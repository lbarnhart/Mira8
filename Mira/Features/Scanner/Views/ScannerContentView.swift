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
    @State private var showImageScanner = false
    @State private var showPhotoCamera = false
    @State private var scannedBarcodeFromImage: String?
    @State private var showComparisonMode = false
    @State private var isComparisonModeActive = false
    @State private var showSettings = false
    @StateObject private var comparisonViewModel = ComparisonModeViewModel()
    @StateObject private var imageScannerViewModel = ImageScannerViewModel()

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
            }
            .onAppear {
                viewModel.startScanning()
                // Filter mode always defaults to hidden
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
            print("📤 Product detail sheet dismissed")
            viewModel.resetScanner()
            scannedBarcodeFromImage = nil
            imageScannerViewModel.reset()
        }) {
            productDetailSheet
        }
        .sheet(isPresented: $viewModel.showDuplicateScan, onDismiss: {
            viewModel.resetScanner()
            imageScannerViewModel.reset()
        }) {
            if let product = viewModel.scannedProduct,
               let previousDate = viewModel.previousScanDate {
                let healthFocus = UserDefaults.standard.string(forKey: "healthFocus") ?? "generalWellness"
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
            imageScannerViewModel.reset()
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
        .sheet(isPresented: $showImageScanner) {
            ImageScannerView(
                viewModel: imageScannerViewModel,
                onProductSelected: { barcode in
                    showImageScanner = false
                    scannedBarcodeFromImage = barcode
                    // Small delay to let the sheet dismiss first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showProductDetail = true
                    }
                },
                onDismiss: {
                    showImageScanner = false
                }
            )
        }
        .fullScreenCover(isPresented: $showPhotoCamera, onDismiss: {
            // Restart barcode scanner when returning from photo mode
            if viewModel.hasPermission {
                viewModel.startScanning()
            }
        }) {
            CameraView(
                onCapture: { image in
                    showPhotoCamera = false
                    // Reset state before processing new image
                    imageScannerViewModel.reset()
                    // Process the image automatically
                    Task {
                        await imageScannerViewModel.processImage(image)
                    }
                },
                onCancel: {
                    showPhotoCamera = false
                    imageScannerViewModel.reset()
                }
            )
            .overlay(alignment: .topTrailing) {
                // Photo library button
                Button {
                    showPhotoCamera = false
                    // Small delay before showing image scanner
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showImageScanner = true
                    }
                } label: {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(.trailing, 16)
                .padding(.top, 16)
            }
        }
        .onChange(of: imageScannerViewModel.state) { newState in
            // When recognition completes with a match, set the barcode
            if case .matched(let matches) = newState, let match = matches.first {
                if matches.count == 1 {
                    // Single match - set barcode (sheet will be triggered by barcode onChange)
                    scannedBarcodeFromImage = match.barcode
                } else {
                    // Multiple matches - need to show disambiguation
                    showImageScanner = true
                }
            } else if case .noMatches = newState {
                // No matches found - show the image scanner with error state
                showImageScanner = true
            } else if case .error = newState {
                // Error occurred - show the image scanner with error state
                showImageScanner = true
            }
        }
        .onChange(of: scannedBarcodeFromImage) { newBarcode in
            // When barcode is set from image scanning, show product detail
            // This ensures the barcode state is propagated before the sheet builds
            if let barcode = newBarcode, !barcode.isEmpty, !showProductDetail {
                showProductDetail = true
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
        .fullScreenCover(isPresented: Binding(
            get: { imageScannerViewModel.isProcessing },
            set: { _ in }
        )) {
            PhotoProcessingLoadingView(state: imageScannerViewModel.state)
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
        let hasSeenInsightsUnlocked = UserDefaults.standard.bool(forKey: "hasSeenInsightsUnlocked")

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
                            UserDefaults.standard.set(true, forKey: "hasSeenInsightsUnlocked")
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
                Color.black
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
            HStack(spacing: Spacing.md) {
                // Comparison Mode Button
                ScannerComparisonButton(
                    isActive: isComparisonModeActive,
                    productCount: comparisonViewModel.comparisonProducts.count,
                    onToggle: {
                        if isComparisonModeActive {
                            // Deactivate and show comparison if we have products
                            isComparisonModeActive = false
                            if !comparisonViewModel.comparisonProducts.isEmpty {
                                showComparisonMode = true
                            }
                        } else {
                            // Activate comparison mode
                            isComparisonModeActive = true
                        }
                    },
                    onViewComparison: {
                        showComparisonMode = true
                    }
                )

                // Photo Mode Button
                PhotoModeButton {
                    // Stop the barcode scanner camera before switching to photo mode
                    // This prevents the two camera sessions from competing
                    viewModel.stopScanning()
                    showPhotoCamera = true
                }
            }
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

    @ViewBuilder
    private var productDetailSheet: some View {
        // Handle both barcode scanner and image scanner results
        let barcode = viewModel.scannedProduct?.barcode ?? scannedBarcodeFromImage ?? ""
        let _ = print("📄 Sheet content building - barcode: \(barcode.isEmpty ? "EMPTY" : barcode)")
        let _ = print("   viewModel.scannedProduct?.barcode: \(viewModel.scannedProduct?.barcode ?? "nil")")
        let _ = print("   scannedBarcodeFromImage: \(scannedBarcodeFromImage ?? "nil")")

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
            let _ = print("⚠️ Showing EmptyView because barcode is empty!")
            EmptyView()
        }
    }

    private var permissionView: some View {
        VStack(spacing: 20) {
            Image("tab-scan-selected")
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

private struct PhotoModeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 16, weight: .semibold))
                Text("Photo")
                    .font(.callout)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.oceanTeal)
            .cornerRadius(24)
        }
        .accessibilityLabel("Photo Mode")
        .accessibilityHint("Switch to photo-based product scanning")
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
    }
}

#Preview {
    ScannerContentView()
}
