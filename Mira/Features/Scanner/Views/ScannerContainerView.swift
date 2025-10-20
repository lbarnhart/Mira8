import SwiftUI

struct ScannerContainerView: View {
    @State private var showSettings = false
    let onScanComplete: (ScanResult) -> Void

    init(onScanComplete: @escaping (ScanResult) -> Void = { _ in }) {
        self.onScanComplete = onScanComplete
    }

    var body: some View {
        NavigationStack {
            ScannerContentView(onScanComplete: onScanComplete)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image("tab-settings-selected")
                                .renderingMode(.original)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        .accessibilityLabel("Open Settings")
                    }
                }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

#Preview {
    ScannerContainerView()
}
