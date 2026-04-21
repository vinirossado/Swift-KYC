import Foundation

/// A screenshot captured during a specific step of the verification flow.
public struct FlowScreenshot: Sendable {
    /// Label describing which step this screenshot was taken at.
    public let stepLabel: String

    /// JPEG image data of the screenshot.
    public let imageData: Data

    /// When the screenshot was captured.
    public let capturedAt: Date

    public init(stepLabel: String, imageData: Data, capturedAt: Date = Date()) {
        self.stepLabel = stepLabel
        self.imageData = imageData
        self.capturedAt = capturedAt
    }
}
