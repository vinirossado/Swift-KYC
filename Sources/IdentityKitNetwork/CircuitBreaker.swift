import Foundation
import IdentityKitCore

/// Circuit breaker that protects against cascading failures from an unstable backend.
///
/// State machine:
/// - **Closed**: requests flow normally. Consecutive failures increment a counter.
/// - **Open**: all requests fail immediately with `.circuitBreakerOpen`. After `resetTimeout`, transitions to half-open.
/// - **Half-open**: one probe request is allowed through. Success → closed. Failure → open again.
///
/// Thread-safe via an actor-style lock (NSLock) since this needs to work in non-async contexts too.
public final class CircuitBreaker: @unchecked Sendable {
    public enum State: Sendable, Equatable {
        case closed
        case open
        case halfOpen
    }

    private let failureThreshold: Int
    private let resetTimeout: TimeInterval
    private let lock = NSLock()

    private var consecutiveFailures: Int = 0
    private var lastFailureTime: Date?
    private var _state: State = .closed

    public init(failureThreshold: Int = 5, resetTimeout: TimeInterval = 30.0) {
        self.failureThreshold = failureThreshold
        self.resetTimeout = resetTimeout
    }

    /// Current state of the circuit breaker.
    public var state: State {
        lock.lock()
        defer { lock.unlock() }
        return evaluatedState()
    }

    /// Call before making a request. Throws if the circuit is open.
    public func preRequest() throws {
        lock.lock()
        defer { lock.unlock() }

        let current = evaluatedState()
        switch current {
        case .closed:
            break
        case .open:
            throw IdentityKitError.circuitBreakerOpen
        case .halfOpen:
            // Allow the probe request through.
            break
        }
    }

    /// Call after a successful request.
    public func recordSuccess() {
        lock.lock()
        defer { lock.unlock() }
        consecutiveFailures = 0
        _state = .closed
    }

    /// Call after a failed request.
    public func recordFailure() {
        lock.lock()
        defer { lock.unlock() }

        consecutiveFailures += 1
        lastFailureTime = Date()

        if consecutiveFailures >= failureThreshold {
            _state = .open
        }
    }

    /// Reset the circuit breaker to closed state. Useful for testing.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        consecutiveFailures = 0
        lastFailureTime = nil
        _state = .closed
    }

    // MARK: - Private

    /// Evaluates the real state, considering timeout transitions.
    /// Must be called with the lock held.
    private func evaluatedState() -> State {
        switch _state {
        case .open:
            guard let lastFailure = lastFailureTime else { return .closed }
            if Date().timeIntervalSince(lastFailure) >= resetTimeout {
                _state = .halfOpen
                return .halfOpen
            }
            return .open
        default:
            return _state
        }
    }
}
