import XCTest
@testable import IdentityKitCore

final class VerificationResultTests: XCTestCase {

    func testResultContainsAllFields() {
        let doc = CapturedDocument(
            documentType: .passport,
            frontImageData: Data([0xFF, 0xD8]),
            frontCapturedAt: Date(),
            qualityScore: 0.95
        )

        let frame = LivenessFrame(
            challenge: .blink,
            imageData: Data([0xFF, 0xD8]),
            capturedAt: Date(),
            confidenceScore: 0.88
        )

        let completedAt = Date()
        let result = VerificationResult(
            sessionId: "session-abc",
            capturedDocuments: [doc],
            livenessFrames: [frame],
            completedAt: completedAt,
            clientMetadata: ["device": "iPhone15,2"]
        )

        XCTAssertEqual(result.sessionId, "session-abc")
        XCTAssertEqual(result.capturedDocuments.count, 1)
        XCTAssertEqual(result.livenessFrames.count, 1)
        XCTAssertEqual(result.completedAt, completedAt)
        XCTAssertEqual(result.clientMetadata["device"], "iPhone15,2")
    }

    func testResultWithDefaults() {
        let result = VerificationResult(
            sessionId: "s1",
            capturedDocuments: [],
            livenessFrames: []
        )

        XCTAssertTrue(result.clientMetadata.isEmpty)
    }
}
