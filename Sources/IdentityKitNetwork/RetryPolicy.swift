import Foundation
import IdentityKitCore

/// Exponential backoff retry policy with jitter.
///
/// Each retry waits `baseDelay * 2^attempt` plus random jitter,
/// capped at `maxDelay`. This spreads retries to avoid thundering herd
/// when many clients hit a recovering backend simultaneously.
public struct RetryPolicy: Sendable {
    public let maxAttempts: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval

    public init(
        maxAttempts: Int = 3,
        baseDelay: TimeInterval = 0.5,
        maxDelay: TimeInterval = 10.0
    ) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
    }

    /// Calculates the delay before the given attempt (0-indexed).
    public func delay(forAttempt attempt: Int) -> TimeInterval {
        let exponential = baseDelay * pow(2.0, Double(attempt))
        let capped = min(exponential, maxDelay)
        // Jitter: random value between 0 and the computed delay.
        let jitter = Double.random(in: 0...capped)
        return (capped + jitter) / 2.0
    }

    /// Whether the given HTTP status code is retryable.
    public func isRetryable(statusCode: Int) -> Bool {
        switch statusCode {
        case 408, 429, 500, 502, 503, 504:
            return true
        default:
            return false
        }
    }

    /// Whether the given error is retryable (network-level failures).
    public func isRetryable(error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else { return false }

        let retryableCodes: Set<Int> = [
            NSURLErrorTimedOut,
            NSURLErrorCannotFindHost,
            NSURLErrorCannotConnectToHost,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorNotConnectedToInternet
        ]
        return retryableCodes.contains(nsError.code)
    }
}
