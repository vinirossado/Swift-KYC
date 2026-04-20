import XCTest
@testable import IdentityKitNetwork

final class RetryPolicyTests: XCTestCase {

    func testDefaultValues() {
        let policy = RetryPolicy()
        XCTAssertEqual(policy.maxAttempts, 3)
        XCTAssertEqual(policy.baseDelay, 0.5)
        XCTAssertEqual(policy.maxDelay, 10.0)
    }

    func testDelayIncreasesExponentially() {
        let policy = RetryPolicy(baseDelay: 1.0, maxDelay: 100.0)

        // Run multiple times to account for jitter — delay should always be
        // between 0 and the exponential cap.
        for attempt in 0..<5 {
            let delay = policy.delay(forAttempt: attempt)
            let maxExpected = min(pow(2.0, Double(attempt)), 100.0)
            XCTAssertGreaterThanOrEqual(delay, 0)
            XCTAssertLessThanOrEqual(delay, maxExpected)
        }
    }

    func testDelayIsCappedAtMaxDelay() {
        let policy = RetryPolicy(baseDelay: 1.0, maxDelay: 5.0)

        // Attempt 10 would give 2^10 = 1024 without cap.
        let delay = policy.delay(forAttempt: 10)
        XCTAssertLessThanOrEqual(delay, 5.0)
    }

    // MARK: - Retryable Status Codes

    func testRetryableStatusCodes() {
        let policy = RetryPolicy()
        let retryable = [408, 429, 500, 502, 503, 504]

        for code in retryable {
            XCTAssertTrue(policy.isRetryable(statusCode: code), "Status \(code) should be retryable")
        }
    }

    func testNonRetryableStatusCodes() {
        let policy = RetryPolicy()
        let nonRetryable = [200, 201, 301, 400, 401, 403, 404, 405, 409, 422]

        for code in nonRetryable {
            XCTAssertFalse(policy.isRetryable(statusCode: code), "Status \(code) should NOT be retryable")
        }
    }

    // MARK: - Retryable Errors

    func testRetryableNetworkErrors() {
        let policy = RetryPolicy()

        let retryableCodes: [URLError.Code] = [
            .timedOut,
            .cannotFindHost,
            .cannotConnectToHost,
            .networkConnectionLost,
            .notConnectedToInternet
        ]

        for code in retryableCodes {
            let error = URLError(code)
            XCTAssertTrue(policy.isRetryable(error: error), "\(code) should be retryable")
        }
    }

    func testNonRetryableErrors() {
        let policy = RetryPolicy()

        let nonRetryable: [URLError.Code] = [
            .badURL,
            .unsupportedURL,
            .cancelled,
            .badServerResponse
        ]

        for code in nonRetryable {
            let error = URLError(code)
            XCTAssertFalse(policy.isRetryable(error: error), "\(code) should NOT be retryable")
        }
    }

    func testNonURLErrorIsNotRetryable() {
        let policy = RetryPolicy()
        struct CustomError: Error {}
        XCTAssertFalse(policy.isRetryable(error: CustomError()))
    }
}
