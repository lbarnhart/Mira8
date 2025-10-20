import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingScanner = false
    @State private var navigateToHistory = false
    @State private var selectedScanResult: ScanResult?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Welcome Section
                VStack(spacing: 8) {
                    Text("Welcome to Mira")
                        .font(.largeTitle)
                        .foregroundColor(.textPrimary)

                    Text("Scan food products to get personalized health insights")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                Spacer()

                // Scan Button
                VStack(spacing: 16) {
                    Button {
                        showingScanner = true
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 60))
                                .foregroundColor(.white)

                            Text("Scan Product")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .frame(width: 200, height: 200)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.primaryBlue, .primaryGreen]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }

                    Text("Tap to start scanning")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                // TEMP: Image test button
                Button("Test Image Fetch") {
                    Task {
                        await OpenFoodFactsService.shared.testImageFetch()
                    }
                }
                .font(.caption)
                .foregroundColor(.primaryBlue)

                Spacer()

                // Recent Scans Section (placeholder)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent Scans")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Spacer()

                        Button("View All") {
                            navigateToHistory = true
                        }
                        .font(.caption)
                        .foregroundColor(.primaryBlue)
                    }

                    if viewModel.isLoading {
                        LoadingView()
                    } else if let recentScan = viewModel.recentScans.first {
                        recentScanCard(recentScan)
                    } else {
                        emptyStateView
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingScanner) {
            ScannerView { result in
                viewModel.handleScanResult(result)
                selectedScanResult = result
                AppLog.debug("Scanned barcode: \(result.barcode)", category: .scanner)
            }
        }
        .sheet(item: $selectedScanResult) { result in
            ProductDetailPlaceholderView(barcode: result.barcode)
        }
        .sheet(isPresented: $navigateToHistory) {
            HistoryView()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error occurred")
        }
    }

    private func recentScanCard(_ scanResult: ScanResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Last Scanned Product")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Text(scanResult.barcode)
                    .font(.bodyMedium)
                    .fontWeight(.medium)

                Text(scanResult.type.displayName)
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .padding(16)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.title)
                .foregroundColor(.textTertiary)

            Text("No recent scans")
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)

            Text("Start by scanning your first product")
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

// Temporary placeholder view for product details
private struct ProductDetailPlaceholderView: View {
    let barcode: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "barcode")
                    .font(.system(size: 60))
                    .foregroundColor(.primaryBlue)

                Text("Product Detail")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Barcode: \(barcode)")
                    .font(.body)
                    .foregroundColor(.textSecondary)

                Text("Full product details view coming soon!")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
