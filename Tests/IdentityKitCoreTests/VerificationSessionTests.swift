import XCTest
@testable import IdentityKitCore

final class VerificationSessionTests: XCTestCase {

    func testInitialStatusIsPending() {
        let session = VerificationSession(
            sessionId: "test-123",
            apiKey: "pk_test",
            checks: [.liveness]
        )

        XCTAssertEqual(session.status, .pending)
    }

    func testWithStatusReturnsNewCopyWithUpdatedStatus() {
        let session = VerificationSession(
            sessionId: "test-123",
            apiKey: "pk_test",
            checks: [.document(.passport)]
        )

        let updated = session.withStatus(.inProgress)

        // Original unchanged
        XCTAssertEqual(session.status, .pending)
        // New copy has updated status
        XCTAssertEqual(updated.status, .inProgress)
        // Other fields preserved
        XCTAssertEqual(updated.sessionId, "test-123")
        XCTAssertEqual(updated.apiKey, "pk_test")
    }

    func testSessionPreservesChecks() {
        let checks: [VerificationCheck] = [.document(.idCard), .liveness]
        let session = VerificationSession(
            sessionId: "s1",
            apiKey: "key",
            checks: checks
        )

        XCTAssertEqual(session.checks.count, 2)
    }

    func testStatusCodableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for status in VerificationSession.Status.allCases {
            let data = try encoder.encode(status)
            let decoded = try decoder.decode(VerificationSession.Status.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }
}
