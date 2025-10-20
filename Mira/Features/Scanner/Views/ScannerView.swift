import SwiftUI

struct ScannerView: View {
    let onScanComplete: (ScanResult) -> Void

    init(onScanComplete: @escaping (ScanResult) -> Void = { _ in }) {
        self.onScanComplete = onScanComplete
    }

    var body: some View {
        ScannerContainerView(onScanComplete: onScanComplete)
    }
}

#Preview {
    ScannerView()
}
