import Foundation

/// A verification check that the SDK should perform during the session.
public enum VerificationCheck: Sendable, Hashable {
    /// Document capture for the specified document type.
    case document(DocumentType)

    /// Liveness detection via face challenges.
    case liveness
}
