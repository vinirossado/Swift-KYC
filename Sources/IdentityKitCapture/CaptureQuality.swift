import Foundation
import IdentityKitCore

/// Aggregated quality assessment for a captured frame.
///
/// Used by both document and liveness capture to decide
/// whether the current frame is good enough to accept.
public struct CaptureQuality: Sendable {
    /// Whether the document/face is properly framed.
    public let isFramed: Bool

    /// Whether the image is in focus (not blurry).
    public let isSharp: Bool

    /// Whether lighting conditions are acceptable.
    public let isBright: Bool

    /// Overall confidence score (0.0–1.0).
    public let confidence: Double

    /// Whether all quality criteria pass.
    public var isAcceptable: Bool {
        isFramed && isSharp && isBright && confidence >= 0.6
    }

    public init(isFramed: Bool, isSharp: Bool, isBright: Bool, confidence: Double) {
        self.isFramed = isFramed
        self.isSharp = isSharp
        self.isBright = isBright
        self.confidence = confidence
    }

    /// A failing quality result for when detection finds nothing.
    public static let undetected = CaptureQuality(
        isFramed: false, isSharp: false, isBright: false, confidence: 0
    )
}
