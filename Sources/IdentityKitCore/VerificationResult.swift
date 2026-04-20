import Foundation

/// The final result of a completed verification session.
public struct VerificationResult: Sendable {
    /// The session identifier.
    public let sessionId: String

    /// Documents captured during the session.
    public let capturedDocuments: [CapturedDocument]

    /// Liveness frames captured during the session.
    public let livenessFrames: [LivenessFrame]

    /// When the verification was completed.
    public let completedAt: Date

    /// Arbitrary metadata from the client for traceability.
    public let clientMetadata: [String: String]

    public init(
        sessionId: String,
        capturedDocuments: [CapturedDocument],
        livenessFrames: [LivenessFrame],
        completedAt: Date = Date(),
        clientMetadata: [String: String] = [:]
    ) {
        self.sessionId = sessionId
        self.capturedDocuments = capturedDocuments
        self.livenessFrames = livenessFrames
        self.completedAt = completedAt
        self.clientMetadata = clientMetadata
    }
}
