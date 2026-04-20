import Foundation

// MARK: - IdentityKitDelegate

/// Delegate protocol for receiving verification flow events.
///
/// All delegate methods are called on the main actor.
@MainActor
public protocol IdentityKitDelegate: AnyObject {
    /// Called when the verification flow completes successfully.
    func identityKitDidComplete(with result: VerificationResult)

    /// Called when the verification flow fails with an error.
    func identityKitDidFail(with error: IdentityKitError)

    /// Called when the user cancels the verification flow.
    func identityKitDidCancel()

    /// Called to report upload progress (0.0–1.0).
    func identityKitUploadProgress(_ progress: Double)
}

// Default implementations so delegates can opt into only the callbacks they need.
public extension IdentityKitDelegate {
    func identityKitUploadProgress(_ progress: Double) {}
}

// MARK: - IdentityKitLogger

/// Abstraction for SDK logging. Host apps provide an implementation
/// to route SDK logs into their own logging infrastructure.
///
/// This replaces all uses of `print` / `NSLog` inside the SDK.
public protocol IdentityKitLogger: Sendable {
    func log(level: LogLevel, message: String, file: String, function: String, line: Int)
}

/// Log severity levels.
public enum LogLevel: Int, Sendable, Comparable, CaseIterable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case none = 4

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - IdentityKitTelemetry

/// Telemetry protocol for tracking SDK events and performance metrics.
///
/// Host apps implement this to feed data into their analytics pipeline.
public protocol IdentityKitTelemetry: Sendable {
    /// Track a named event with optional properties.
    func trackEvent(_ name: String, properties: [String: String])

    /// Track a timing metric in milliseconds.
    func trackTiming(_ name: String, durationMs: Double)
}
