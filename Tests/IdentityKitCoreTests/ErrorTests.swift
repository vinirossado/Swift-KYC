import XCTest
@testable import IdentityKitCore

final class ErrorTests: XCTestCase {

    func testCameraPermissionDeniedHasDescription() {
        let error = IdentityKitError.cameraPermissionDenied
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Camera") == true)
    }

    func testNetworkFailedIncludesUnderlyingDescription() {
        let underlying = URLError(.notConnectedToInternet)
        let error = IdentityKitError.networkFailed(underlying: underlying)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Network") == true)
    }

    func testInvalidConfigurationIncludesReason() {
        let error = IdentityKitError.invalidConfiguration(reason: "missing apiKey")
        XCTAssertTrue(error.errorDescription?.contains("missing apiKey") == true)
    }

    func testSessionExpiredHasDescription() {
        let error = IdentityKitError.sessionExpired
        XCTAssertNotNil(error.errorDescription)
    }

    func testCancelledByUserHasDescription() {
        let error = IdentityKitError.cancelledByUser
        XCTAssertNotNil(error.errorDescription)
    }

    func testDocumentCaptureFailedIncludesReason() {
        let error = IdentityKitError.documentCaptureFailed(reason: "blur")
        XCTAssertTrue(error.errorDescription?.contains("blur") == true)
    }

    func testLivenessCheckFailedIncludesReason() {
        let error = IdentityKitError.livenessCheckFailed(reason: "timeout")
        XCTAssertTrue(error.errorDescription?.contains("timeout") == true)
    }

    func testUploadFailedIncludesReason() {
        let error = IdentityKitError.uploadFailed(reason: "server error")
        XCTAssertTrue(error.errorDescription?.contains("server error") == true)
    }

    func testCircuitBreakerOpenHasDescription() {
        let error = IdentityKitError.circuitBreakerOpen
        XCTAssertTrue(error.errorDescription?.contains("unavailable") == true)
    }

    func testInternalErrorIncludesReason() {
        let error = IdentityKitError.internalError(reason: "unexpected state")
        XCTAssertTrue(error.errorDescription?.contains("unexpected state") == true)
    }
}
