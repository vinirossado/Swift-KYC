import Foundation

/// A single frame captured during the liveness challenge.
public struct LivenessFrame: Sendable {
    /// The challenge this frame was captured for.
    public let challenge: LivenessChallenge

    /// JPEG data for the frame.
    public let imageData: Data

    /// Timestamp when the frame was captured.
    public let capturedAt: Date

    /// Confidence score from face quality analysis (0.0–1.0).
    public let confidenceScore: Double

    public init(
        challenge: LivenessChallenge,
        imageData: Data,
        capturedAt: Date,
        confidenceScore: Double
    ) {
        self.challenge = challenge
        self.imageData = imageData
        self.capturedAt = capturedAt
        self.confidenceScore = confidenceScore
    }
}
