import XCTest
import CoreGraphics
@testable import IdentityKitCapture
import IdentityKitCore

final class FaceQualityAnalyzerTests: XCTestCase {

    private let analyzer = FaceQualityAnalyzer()

    func testNoFaceInBlankImage() {
        guard let image = createBlankImage(width: 640, height: 480) else {
            XCTFail("Failed to create blank image")
            return
        }

        let result = analyzer.analyze(image: image)

        XCTAssertFalse(result.faceDetected)
        XCTAssertNil(result.faceBoundingBox)
        XCTAssertNil(result.yawAngle)
        XCTAssertFalse(result.quality.isAcceptable)
    }

    func testAnalysisTimingIsReasonable() {
        guard let image = createBlankImage(width: 640, height: 480) else {
            XCTFail("Failed to create blank image")
            return
        }

        let result = analyzer.analyze(image: image)

        XCTAssertGreaterThanOrEqual(result.detectionTimeMs, 0)
        XCTAssertLessThan(result.detectionTimeMs, 5000)
    }

    // MARK: - Challenge Evaluation

    func testBlinkChallengeRequiresEyeStateChange() {
        let baseline = FaceQualityAnalyzer.AnalysisResult(
            faceDetected: true,
            faceBoundingBox: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4),
            yawAngle: 0,
            eyesOpen: true,
            quality: CaptureQuality(isFramed: true, isSharp: true, isBright: true, confidence: 0.8),
            detectionTimeMs: 10
        )

        let current = FaceQualityAnalyzer.AnalysisResult(
            faceDetected: true,
            faceBoundingBox: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4),
            yawAngle: 0,
            eyesOpen: false,
            quality: CaptureQuality(isFramed: true, isSharp: true, isBright: true, confidence: 0.8),
            detectionTimeMs: 10
        )

        let passed = analyzer.evaluateChallenge(.blink, currentResult: current, baselineResult: baseline)
        XCTAssertTrue(passed)
    }

    func testBlinkChallengeFailsWhenEyesStayOpen() {
        let baseline = FaceQualityAnalyzer.AnalysisResult(
            faceDetected: true,
            faceBoundingBox: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4),
            yawAngle: 0,
            eyesOpen: true,
            quality: CaptureQuality(isFramed: true, isSharp: true, isBright: true, confidence: 0.8),
            detectionTimeMs: 10
        )

        let current = FaceQualityAnalyzer.AnalysisResult(
            faceDetected: true,
            faceBoundingBox: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4),
            yawAngle: 0,
            eyesOpen: true,
            quality: CaptureQuality(isFramed: true, isSharp: true, isBright: true, confidence: 0.8),
            detectionTimeMs: 10
        )

        let passed = analyzer.evaluateChallenge(.blink, currentResult: current, baselineResult: baseline)
        XCTAssertFalse(passed)
    }

    func testTurnLeftChallenge() {
        let current = FaceQualityAnalyzer.AnalysisResult(
            faceDetected: true,
            faceBoundingBox: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4),
            yawAngle: -20,
            eyesOpen: true,
            quality: CaptureQuality(isFramed: true, isSharp: true, isBright: true, confidence: 0.8),
            detectionTimeMs: 10
        )

        let passed = analyzer.evaluateChallenge(.turnLeft, currentResult: current, baselineResult: nil)
        XCTAssertTrue(passed)
    }

    func testTurnLeftChallengeFailsWhenFacingForward() {
        let current = FaceQualityAnalyzer.AnalysisResult(
            faceDetected: true,
            faceBoundingBox: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4),
            yawAngle: 0,
            eyesOpen: true,
            quality: CaptureQuality(isFramed: true, isSharp: true, isBright: true, confidence: 0.8),
            detectionTimeMs: 10
        )

        let passed = analyzer.evaluateChallenge(.turnLeft, currentResult: current, baselineResult: nil)
        XCTAssertFalse(passed)
    }

    func testTurnRightChallenge() {
        let current = FaceQualityAnalyzer.AnalysisResult(
            faceDetected: true,
            faceBoundingBox: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4),
            yawAngle: 20,
            eyesOpen: true,
            quality: CaptureQuality(isFramed: true, isSharp: true, isBright: true, confidence: 0.8),
            detectionTimeMs: 10
        )

        let passed = analyzer.evaluateChallenge(.turnRight, currentResult: current, baselineResult: nil)
        XCTAssertTrue(passed)
    }

    func testChallengeFailsWhenNoFaceDetected() {
        let noFace = FaceQualityAnalyzer.AnalysisResult(
            faceDetected: false,
            faceBoundingBox: nil,
            yawAngle: nil,
            eyesOpen: nil,
            quality: .undetected,
            detectionTimeMs: 10
        )

        XCTAssertFalse(analyzer.evaluateChallenge(.blink, currentResult: noFace, baselineResult: nil))
        XCTAssertFalse(analyzer.evaluateChallenge(.turnLeft, currentResult: noFace, baselineResult: nil))
        XCTAssertFalse(analyzer.evaluateChallenge(.turnRight, currentResult: noFace, baselineResult: nil))
    }

    // MARK: - Helpers

    private func createBlankImage(width: Int, height: Int) -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage()
    }
}
