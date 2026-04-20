import Foundation

/// Represents an active verification session managed by the SDK.
public struct VerificationSession: Sendable {
    /// Unique identifier for this session, provided by the host app.
    public let sessionId: String

    /// The API key used to authenticate this session.
    public let apiKey: String

    /// Checks to be performed in this session.
    public let checks: [VerificationCheck]

    /// When the session was created.
    public let createdAt: Date

    /// Current status of the session.
    public private(set) var status: Status

    public enum Status: String, Sendable, Codable, CaseIterable {
        case pending
        case inProgress
        case completed
        case failed
        case cancelled
    }

    public init(
        sessionId: String,
        apiKey: String,
        checks: [VerificationCheck],
        createdAt: Date = Date(),
        status: Status = .pending
    ) {
        self.sessionId = sessionId
        self.apiKey = apiKey
        self.checks = checks
        self.createdAt = createdAt
        self.status = status
    }

    /// Returns a copy with the status updated.
    public func withStatus(_ newStatus: Status) -> VerificationSession {
        var copy = self
        copy.status = newStatus
        return copy
    }
}
