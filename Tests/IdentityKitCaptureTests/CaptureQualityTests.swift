import XCTest
@testable import IdentityKitCapture

final class CaptureQualityTests: XCTestCase {

    func testAcceptableWhenAllCriteriaMet() {
        let quality = CaptureQuality(isFramed: true, isSharp: true, isBright: true, confidence: 0.8)
        XCTAssertTrue(quality.isAcceptable)
    }

    func testNotAcceptableWhenNotFramed() {
        let quality = CaptureQuality(isFramed: false, isSharp: true, isBright: true, confidence: 0.8)
        XCTAssertFalse(quality.isAcceptable)
    }

    func testNotAcceptableWhenNotSharp() {
        let quality = CaptureQuality(isFramed: true, isSharp: false, isBright: true, confidence: 0.8)
        XCTAssertFalse(quality.isAcceptable)
    }

    func testNotAcceptableWhenNotBright() {
        let quality = CaptureQuality(isFramed: true, isSharp: true, isBright: false, confidence: 0.8)
        XCTAssertFalse(quality.isAcceptable)
    }

    func testNotAcceptableWhenLowConfidence() {
        let quality = CaptureQuality(isFramed: true, isSharp: true, isBright: true, confidence: 0.3)
        XCTAssertFalse(quality.isAcceptable)
    }

    func testAcceptableAtExactThreshold() {
        let quality = CaptureQuality(isFramed: true, isSharp: true, isBright: true, confidence: 0.6)
        XCTAssertTrue(quality.isAcceptable)
    }

    func testUndetectedIsNotAcceptable() {
        XCTAssertFalse(CaptureQuality.undetected.isAcceptable)
        XCTAssertEqual(CaptureQuality.undetected.confidence, 0)
    }
}
