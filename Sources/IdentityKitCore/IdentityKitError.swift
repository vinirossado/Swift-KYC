import Foundation

/// Errors that can occur during the IdentityKit verification flow.
public enum IdentityKitError: Error, @unchecked Sendable {
    /// Camera permission was denied or restricted by the user.
    case cameraPermissionDenied

    /// A network request failed.
    case networkFailed(underlying: Error)

    /// The SDK configuration is invalid.
    case invalidConfiguration(reason: String)

    /// The verification session has expired.
    case sessionExpired

    /// The session was cancelled by the user.
    case cancelledByUser

    /// Document capture failed (e.g., quality too low after max retries).
    case documentCaptureFailed(reason: String)

    /// Liveness challenge failed (e.g., timeout, no face detected).
    case livenessCheckFailed(reason: String)

    /// Upload of verification data failed after all retries.
    case uploadFailed(reason: String)

    /// The circuit breaker is open — backend is considered unavailable.
    case circuitBreakerOpen

    /// An unexpected internal error occurred.
    case internalError(reason: String)
}

extension IdentityKitError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .cameraPermissionDenied:
            return "Camera access is required for identity verification."
        case .networkFailed(let underlying):
            return "Network request failed: \(underlying.localizedDescription)"
        case .invalidConfiguration(let reason):
            return "Invalid configuration: \(reason)"
        case .sessionExpired:
            return "The verification session has expired. Please start a new session."
        case .cancelledByUser:
            return "Verification was cancelled."
        case .documentCaptureFailed(let reason):
            return "Document capture failed: \(reason)"
        case .livenessCheckFailed(let reason):
            return "Liveness check failed: \(reason)"
        case .uploadFailed(let reason):
            return "Upload failed: \(reason)"
        case .circuitBreakerOpen:
            return "Service is temporarily unavailable. Please try again later."
        case .internalError(let reason):
            return "An internal error occurred: \(reason)"
        }
    }
}

