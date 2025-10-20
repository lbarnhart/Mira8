import SwiftUI

enum AnimationConstants {
    static let scanLine: Animation = .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    static let pulse: Animation = .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    static let fade: Animation = .easeInOut(duration: 0.3)
}
