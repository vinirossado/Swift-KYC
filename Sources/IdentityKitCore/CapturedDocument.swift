import Foundation

/// Represents a captured identity document with its associated images and metadata.
public struct CapturedDocument: Sendable {
    /// The type of document that was captured.
    public let documentType: DocumentType

    /// JPEG data for the front side of the document.
    public let frontImageData: Data

    /// JPEG data for the back side, if applicable.
    public let backImageData: Data?

    /// Timestamp when the front side was captured.
    public let frontCapturedAt: Date

    /// Timestamp when the back side was captured, if applicable.
    public let backCapturedAt: Date?

    /// Quality score from edge detection (0.0–1.0).
    public let qualityScore: Double

    public init(
        documentType: DocumentType,
        frontImageData: Data,
        backImageData: Data? = nil,
        frontCapturedAt: Date,
        backCapturedAt: Date? = nil,
        qualityScore: Double
    ) {
        self.documentType = documentType
        self.frontImageData = frontImageData
        self.backImageData = backImageData
        self.frontCapturedAt = frontCapturedAt
        self.backCapturedAt = backCapturedAt
        self.qualityScore = qualityScore
    }
}
