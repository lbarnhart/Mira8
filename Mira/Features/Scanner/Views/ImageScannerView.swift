import SwiftUI
import PhotosUI

/// View for image-based product scanning.
/// Allows capturing product images and identifying them via AI.
struct ImageScannerView: View {
    @ObservedObject var viewModel: ImageScannerViewModel
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedItem: PhotosPickerItem?

    var onProductSelected: ((String) -> Void)?
    var onDismiss: (() -> Void)?

    init(viewModel: ImageScannerViewModel, onProductSelected: ((String) -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onProductSelected = onProductSelected
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    // Preview / Result Area
                    previewArea

                    // Status
                    statusView

                    // Actions
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Photo Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss?()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showDisambiguation) {
                ProductDisambiguationSheet(
                    matches: viewModel.matches,
                    identification: viewModel.identification,
                    onSelect: { match in
                        viewModel.selectMatch(match)
                        if let barcode = viewModel.confirmMatch() {
                            onProductSelected?(barcode)
                        }
                    },
                    onCancel: {
                        viewModel.showDisambiguation = false
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .photosPicker(
                isPresented: $showImagePicker,
                selection: $selectedItem,
                matching: .images
            )
            .onChange(of: selectedItem) { newItem in
                guard let newItem else { return }
                Task {
                    do {
                        guard let data = try await newItem.loadTransferable(type: Data.self) else {
                            viewModel.handleImageImportFailure()
                            return
                        }
                        await viewModel.processImageData(data)
                    } catch is CancellationError {
                        return
                    } catch {
                        viewModel.handleImageImportFailure()
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { image in
                    showCamera = false
                    Task {
                        await viewModel.processImage(image)
                    }
                } onCancel: {
                    showCamera = false
                }
            }
            .task {
                let hasPermission = await viewModel.checkCameraPermission()
                if !hasPermission {
                    // Will show photo library option instead
                }
                viewModel.applyConfiguredSimulationIfNeeded()
            }
        }
    }

    // MARK: - Preview Area

    private var previewArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.backgroundSecondary)
                .frame(height: 300)

            if let image = viewModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 280)
                    .cornerRadius(CornerRadius.md)
            } else {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.textTertiary)

                    Text("Capture or select a product image")
                        .font(.callout)
                        .foregroundColor(.textSecondary)
                }
            }

            // Processing overlay
            if viewModel.isProcessing {
                processingOverlay
            }
        }
    }

    private var processingOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.black.opacity(0.6))

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text(viewModel.statusMessage)
                    .font(.callout)
                    .foregroundColor(.white)

                if let name = viewModel.identification?.name {
                    Text("Identified: \(name)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }

    // MARK: - Status View

    @ViewBuilder
    private var statusView: some View {
        VStack(spacing: Spacing.sm) {
            // Identification result
            if let identification = viewModel.identification, !viewModel.isProcessing {
                identificationCard(identification)
            }

            // Error state
            if viewModel.hasError {
                errorCard
            }

            // Match result (single high-confidence match)
            if case .matched(let matches) = viewModel.state,
               matches.count == 1,
               let match = matches.first {
                matchCard(match)
            }

            // No matches state
            if case .noMatches = viewModel.state {
                noMatchesCard
            }
        }
    }

    private func identificationCard(_ identification: ProductIdentification) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "sparkles")
                .foregroundColor(.primaryBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text(identification.name)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)

                if let brand = identification.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            Text("\(Int(identification.confidence * 100))%")
                .font(.caption)
                .foregroundColor(identification.isHighConfidence ? .scoreExcellent : .scoreFair)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    (identification.isHighConfidence ? Color.scoreExcellent : Color.scoreFair)
                        .opacity(0.12)
                )
                .cornerRadius(CornerRadius.sm)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }

    private func matchCard(_ match: ProductMatch) -> some View {
        Button {
            if let barcode = viewModel.confirmMatch() {
                onProductSelected?(barcode)
            }
        } label: {
            VStack(spacing: Spacing.sm) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.scoreExcellent)
                    Text("Product Found!")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Spacer()

                    // Match score badge
                    Text("\(Int(match.matchScore * 100))% match")
                        .font(.caption)
                        .foregroundColor(.scoreExcellent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.scoreExcellent.opacity(0.2))
                        .cornerRadius(CornerRadius.sm)
                }

                HStack(spacing: Spacing.md) {
                    // Thumbnail placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.backgroundSecondary)
                            .frame(width: 60, height: 60)

                        if let urlString = match.thumbnailURL,
                           let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "photo")
                                    .foregroundColor(.textTertiary)
                            }
                            .frame(width: 60, height: 60)
                            .cornerRadius(CornerRadius.sm)
                        } else {
                            Image(systemName: "shippingbox")
                                .font(.title2)
                                .foregroundColor(.textTertiary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(match.name)
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if let brand = match.brand {
                            Text(brand)
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }

                        if let category = match.category {
                            Text(category)
                                .font(.caption2)
                                .foregroundColor(.textTertiary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundColor(.textTertiary)
                }

                // Tap to confirm hint
                Text("Tap to view product details")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .padding(.top, Spacing.xs)
            }
            .padding()
            .background(Color.scoreExcellent.opacity(0.12))
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("photoScan.singleMatch")
    }

    private var errorCard: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                if case .error(let error) = viewModel.state {
                    Image(systemName: error.iconName)
                        .foregroundColor(.scorePoor)
                }
                Text(viewModel.errorMessage ?? "An error occurred")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.scorePoor)
                Spacer()
            }

            if let recovery = viewModel.recoveryMessage {
                Text(recovery)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.scorePoor.opacity(0.12))
        .cornerRadius(CornerRadius.md)
    }

    private var noMatchesCard: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.textTertiary)
                Text("No matching products found")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                Spacer()
            }

            Text("Try taking a clearer photo or use the barcode scanner instead")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: Spacing.md) {
            if shouldShowCaptureButtons {
                // Primary actions - capture or select
                HStack(spacing: Spacing.md) {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primaryBlue)
                            .foregroundColor(.white)
                            .cornerRadius(CornerRadius.md)
                    }
                    .accessibilityIdentifier("photoScan.camera")

                    Button {
                        showImagePicker = true
                    } label: {
                        Label("Photos", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.backgroundSecondary)
                            .foregroundColor(.primaryBlue)
                            .cornerRadius(CornerRadius.md)
                    }
                    .accessibilityIdentifier("photoScan.photos")
                }
            } else if shouldShowRetryButtons {
                // Retry actions
                Button {
                    viewModel.retry()
                } label: {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(CornerRadius.md)
                }
                .accessibilityIdentifier("photoScan.retry")

                Button {
                    viewModel.retryWithNewImage()
                } label: {
                    Text("Take New Photo")
                        .font(.callout)
                        .foregroundColor(.primaryBlue)
                }
                .accessibilityIdentifier("photoScan.newPhoto")
            }
        }
    }

    // MARK: - Computed Properties

    private var shouldShowCaptureButtons: Bool {
        guard case .idle = viewModel.state else { return false }
        return viewModel.capturedImage == nil
    }

    private var shouldShowRetryButtons: Bool {
        guard viewModel.capturedImage != nil else { return false }
        if viewModel.hasError { return true }
        if case .noMatches = viewModel.state { return true }
        return false
    }
}

// MARK: - Product Disambiguation Sheet

struct ProductDisambiguationSheet: View {
    let matches: [ProductMatch]
    let identification: ProductIdentification?
    let onSelect: (ProductMatch) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    if let identification = identification {
                        VStack(spacing: Spacing.xs) {
                            Text("Multiple Matches Found")
                                .font(.headline)

                            Text("We identified \"\(identification.name)\" - please select the correct product:")
                                .font(.callout)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }

                    // Match list
                    VStack(spacing: Spacing.sm) {
                        ForEach(matches) { match in
                            MatchSelectionRow(match: match) {
                                onSelect(match)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // None of these option
                    Button {
                        onCancel()
                    } label: {
                        Text("None of these are correct")
                            .font(.callout)
                            .foregroundColor(.primaryBlue)
                    }
                    .padding()
                    .accessibilityIdentifier("photoScan.noneCorrect")
                }
            }
            .navigationTitle("Select Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}

struct MatchSelectionRow: View {
    let match: ProductMatch
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                // Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color.backgroundSecondary)
                        .frame(width: 60, height: 60)

                    if let urlString = match.thumbnailURL,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "photo")
                                .foregroundColor(.textTertiary)
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(CornerRadius.sm)
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(match.name)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let brand = match.brand {
                        Text(brand)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    // Match quality indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(matchQualityColor)
                            .frame(width: 8, height: 8)

                        Text("\(Int(match.matchScore * 100))% match")
                            .font(.caption2)
                            .foregroundColor(.textTertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("photoScan.match.\(match.barcode)")
    }

    private var matchQualityColor: Color {
        switch match.matchQuality {
        case .excellent: return .scoreExcellent
        case .good: return .scoreGood
        case .fair: return .scoreFair
        case .poor: return .scorePoor
        }
    }
}

// MARK: - Simple Camera View

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onCancel: onCancel)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        let onCancel: () -> Void

        init(onCapture: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            } else {
                onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}

// MARK: - Preview

#Preview {
    ImageScannerView(viewModel: ImageScannerViewModel())
}
