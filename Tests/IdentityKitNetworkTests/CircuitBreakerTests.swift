import XCTest
@testable import IdentityKitNetwork
import IdentityKitCore

final class CircuitBreakerTests: XCTestCase {

    func testInitialStateIsClosed() {
        let cb = CircuitBreaker()
        XCTAssertEqual(cb.state, .closed)
    }

    func testRemainsClosedBelowThreshold() {
        let cb = CircuitBreaker(failureThreshold: 3)

        cb.recordFailure()
        cb.recordFailure()
        XCTAssertEqual(cb.state, .closed)
    }

    func testOpensAfterReachingThreshold() {
        let cb = CircuitBreaker(failureThreshold: 3)

        cb.recordFailure()
        cb.recordFailure()
        cb.recordFailure()
        XCTAssertEqual(cb.state, .open)
    }

    func testOpenStateThrowsOnPreRequest() {
        let cb = CircuitBreaker(failureThreshold: 1)
        cb.recordFailure()

        XCTAssertThrowsError(try cb.preRequest()) { error in
            guard case IdentityKitError.circuitBreakerOpen = error else {
                XCTFail("Expected circuitBreakerOpen, got \(error)")
                return
            }
        }
    }

    func testClosedStateAllowsPreRequest() {
        let cb = CircuitBreaker()
        XCTAssertNoThrow(try cb.preRequest())
    }

    func testSuccessResetsToClosed() {
        let cb = CircuitBreaker(failureThreshold: 2)
        cb.recordFailure()
        cb.recordFailure()
        XCTAssertEqual(cb.state, .open)

        cb.recordSuccess()
        XCTAssertEqual(cb.state, .closed)
        XCTAssertNoThrow(try cb.preRequest())
    }

    func testSuccessResetsConsecutiveFailureCount() {
        let cb = CircuitBreaker(failureThreshold: 3)

        cb.recordFailure()
        cb.recordFailure()
        cb.recordSuccess()
        // After success, counter resets — need 3 more failures to open.
        cb.recordFailure()
        XCTAssertEqual(cb.state, .closed)
    }

    func testHalfOpenAfterTimeout() {
        let cb = CircuitBreaker(failureThreshold: 1, resetTimeout: 0.1)
        cb.recordFailure()
        XCTAssertEqual(cb.state, .open)

        // Wait for the reset timeout.
        let expectation = expectation(description: "timeout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(cb.state, .halfOpen)
        // Half-open should allow a probe request.
        XCTAssertNoThrow(try cb.preRequest())
    }

    func testHalfOpenSuccessClosesCB() {
        let cb = CircuitBreaker(failureThreshold: 1, resetTimeout: 0.1)
        cb.recordFailure()

        let expectation = expectation(description: "timeout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(cb.state, .halfOpen)
        cb.recordSuccess()
        XCTAssertEqual(cb.state, .closed)
    }

    func testHalfOpenFailureReopens() {
        let cb = CircuitBreaker(failureThreshold: 1, resetTimeout: 0.1)
        cb.recordFailure()

        let expectation = expectation(description: "timeout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(cb.state, .halfOpen)
        cb.recordFailure()
        XCTAssertEqual(cb.state, .open)
    }

    func testResetBringsBackToClosed() {
        let cb = CircuitBreaker(failureThreshold: 1)
        cb.recordFailure()
        XCTAssertEqual(cb.state, .open)

        cb.reset()
        XCTAssertEqual(cb.state, .closed)
    }

    func testThreadSafety() {
        let cb = CircuitBreaker(failureThreshold: 100)
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)

        // Hammer the circuit breaker from many threads simultaneously.
        for _ in 0..<1000 {
            group.enter()
            queue.async {
                cb.recordFailure()
                _ = cb.state
                cb.recordSuccess()
                group.leave()
            }
        }

        group.wait()
        // If no crash, thread safety is validated.
        XCTAssertEqual(cb.state, .closed)
    }
}
