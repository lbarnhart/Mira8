import SwiftUI
import UIKit
import Combine

struct ScannerContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = ScannerViewModel()
    @State private var showProductDetail = false

    let onScanComplete: (ScanResult) -> Void

    init(onScanComplete: @escaping (ScanResult) -> Void = { _ in }) {
        self.onScanComplete = onScanComplete
    }

    var body: some View {
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
        .task {
            await viewModel.setupCamera()
        }
        .onAppear {
            viewModel.startScanning()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
        .onChange(of: scenePhase) { phase in
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
        .onReceive(viewModel.$scannedProduct) { product in
            showProductDetail = product != nil
        }
        .onReceive(viewModel.$lastScanResult.compactMap { $0 }) { result in
            onScanComplete(result)
        }
        .sheet(isPresented: $showProductDetail, onDismiss: {
            viewModel.resetScanner()
        }) {
            if let product = viewModel.scannedProduct {
                NavigationStack {
                    ProductDetailView(barcode: product.barcode)
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
                onDismissError: viewModel.dismissError
            )
            .animation(AnimationConstants.fade, value: viewModel.errorMessage)
        }
        .overlay(alignment: .topTrailing) {
            TorchButton(
                isVisible: viewModel.hasPermission && viewModel.isTorchAvailable,
                isOn: viewModel.isTorchOn,
                toggleAction: viewModel.toggleTorch
            )
            .padding(.trailing, 16)
            .padding(.top, 16)
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

private struct TorchButton: View {
    let isVisible: Bool
    let isOn: Bool
    let toggleAction: () -> Void

    var body: some View {
        Group {
            if isVisible {
                Button(action: toggleAction) {
                    Image(systemName: isOn ? "flashlight.on.fill" : "flashlight.off.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                        .padding(10)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                }
            }
        }
    }
}

#Preview {
    ScannerContentView()
}
