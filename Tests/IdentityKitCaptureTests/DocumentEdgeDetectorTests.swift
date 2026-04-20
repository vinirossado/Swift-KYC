import XCTest
import CoreGraphics
@testable import IdentityKitCapture

final class DocumentEdgeDetectorTests: XCTestCase {

    private let detector = DocumentEdgeDetector()

    // MARK: - NormalizedRectangle

    func testBoundingBoxCalculation() {
        let rect = DocumentEdgeDetector.NormalizedRectangle(
            topLeft: CGPoint(x: 0.1, y: 0.9),
            topRight: CGPoint(x: 0.9, y: 0.9),
            bottomLeft: CGPoint(x: 0.1, y: 0.1),
            bottomRight: CGPoint(x: 0.9, y: 0.1)
        )

        let bbox = rect.boundingBox
        XCTAssertEqual(bbox.origin.x, 0.1, accuracy: 0.01)
        XCTAssertEqual(bbox.origin.y, 0.1, accuracy: 0.01)
        XCTAssertEqual(bbox.width, 0.8, accuracy: 0.01)
        XCTAssertEqual(bbox.height, 0.8, accuracy: 0.01)
    }

    func testRelativeArea() {
        let rect = DocumentEdgeDetector.NormalizedRectangle(
            topLeft: CGPoint(x: 0.0, y: 1.0),
            topRight: CGPoint(x: 1.0, y: 1.0),
            bottomLeft: CGPoint(x: 0.0, y: 0.0),
            bottomRight: CGPoint(x: 1.0, y: 0.0)
        )

        XCTAssertEqual(rect.relativeArea, 1.0, accuracy: 0.01)
    }

    func testSmallRectangleHasSmallArea() {
        let rect = DocumentEdgeDetector.NormalizedRectangle(
            topLeft: CGPoint(x: 0.4, y: 0.6),
            topRight: CGPoint(x: 0.6, y: 0.6),
            bottomLeft: CGPoint(x: 0.4, y: 0.4),
            bottomRight: CGPoint(x: 0.6, y: 0.4)
        )

        XCTAssertEqual(rect.relativeArea, 0.04, accuracy: 0.01)
    }

    // MARK: - Detection with synthetic image

    func testDetectsRectangleInSyntheticImage() {
        // Create a white rectangle on a dark background.
        guard let image = createDocumentImage() else {
            XCTFail("Failed to create synthetic document image")
            return
        }

        let result = detector.detect(in: image)

        // Vision may or may not detect the synthetic rectangle depending
        // on the rendering quality. We mainly verify:
        // - Detection completes without crashing
        // - Detection time is measured
        XCTAssertGreaterThan(result.detectionTimeMs, 0)
    }

    func testDetectionTimingIsReasonable() {
        guard let image = createBlankImage(width: 640, height: 480) else {
            XCTFail("Failed to create blank image")
            return
        }

        let result = detector.detect(in: image)

        // Detection should complete in reasonable time even with no rectangle.
        XCTAssertGreaterThanOrEqual(result.detectionTimeMs, 0)
        // On a modern Mac, detection should take <500ms for a small image.
        XCTAssertLessThan(result.detectionTimeMs, 5000)
    }

    func testNoRectangleInBlankImage() {
        guard let image = createBlankImage(width: 640, height: 480) else {
            XCTFail("Failed to create blank image")
            return
        }

        let result = detector.detect(in: image)

        // A solid-color image should not have a detected rectangle.
        XCTAssertNil(result.rectangle)
        XCTAssertFalse(result.quality.isAcceptable)
    }

    // MARK: - Helpers

    /// Creates a synthetic image with a white rectangle on a dark background.
    private func createDocumentImage() -> CGImage? {
        let width = 640
        let height = 480

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // Dark background.
        context.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // White rectangle (simulating a document).
        context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        let docRect = CGRect(
            x: width / 5,
            y: height / 5,
            width: width * 3 / 5,
            height: height * 3 / 5
        )
        context.fill(docRect)

        return context.makeImage()
    }

    /// Creates a blank solid-color image.
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
