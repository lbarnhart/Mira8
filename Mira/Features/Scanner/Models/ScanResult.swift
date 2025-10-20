import Foundation
import AVFoundation

struct ScanResult: Equatable, Identifiable {
    var id: String { barcode }
    let barcode: String
    let type: ScanResultType
    let timestamp: Date

    init(barcode: String, type: ScanResultType, timestamp: Date = Date()) {
        self.barcode = barcode
        self.type = type
        self.timestamp = timestamp
    }
}

enum ScanResultType: Equatable {
    case ean13
    case ean8
    case upca
    case upce
    case code128
    case code39
    case qr
    case unknown

    init(from metadataObjectType: AVMetadataObject.ObjectType) {
        switch metadataObjectType {
        case .ean13:
            self = .ean13
        case .ean8:
            self = .ean8
        case .upce:
            self = .upce
        case .code128:
            self = .code128
        case .code39:
            self = .code39
        case .qr:
            self = .qr
        default:
            // UPC-A is actually part of EAN-13, so we'll treat it as such
            // or unknown if it's a truly unknown type
            self = .unknown
        }
    }

    var displayName: String {
        switch self {
        case .ean13:
            return "EAN-13"
        case .ean8:
            return "EAN-8"
        case .upca:
            return "UPC-A"
        case .upce:
            return "UPC-E"
        case .code128:
            return "Code 128"
        case .code39:
            return "Code 39"
        case .qr:
            return "QR Code"
        case .unknown:
            return "Unknown"
        }
    }
}