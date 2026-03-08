import SwiftUI

struct ScannerContainerView: View {
    let onScanComplete: (ScanResult) -> Void

    init(onScanComplete: @escaping (ScanResult) -> Void = { _ in }) {
        self.onScanComplete = onScanComplete
    }

    var body: some View {
        NavigationStack {
            ScannerContentView(onScanComplete: onScanComplete)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarHidden(true)
        }
    }
}

#Preview {
    ScannerContainerView()
}
