import SwiftUI
import UIKit
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
        uiView.videoPreviewLayer.videoGravity = .resizeAspectFill
        uiView.videoPreviewLayer.frame = uiView.bounds
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            AppLog.error("PreviewView layer is not an AVCaptureVideoPreviewLayer. This should never happen.", category: .scanner)
            // Return a new instance to avoid crash, though this indicates a serious implementation error
            return AVCaptureVideoPreviewLayer()
        }
        return layer
    }
}
