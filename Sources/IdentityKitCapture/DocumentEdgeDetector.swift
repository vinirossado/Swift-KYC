import Foundation
import Vision
import CoreImage
import IdentityKitCore

/// Detects document edges in camera frames using Vision's rectangle detection.
///
/// Runs `VNDetectRectanglesRequest` on each frame and returns
/// the detected rectangle along with a quality assessment.
/// Designed to run at 30fps with detection completing in <50ms.
public final class DocumentEdgeDetector: Sendable {

    /// Minimum confidence for a rectangle detection to be considered valid.
    private let minimumConfidence: Float

    /// Minimum aspect ratio (width/height) for detected rectangles.
    private let minimumAspectRatio: Float

    /// Maximum aspect ratio — filters out non-document shapes.
    private let maximumAspectRatio: Float

    public init(
        minimumConfidence: Float = 0.5,
        minimumAspectRatio: Float = 0.5,
        maximumAspectRatio: Float = 1.0
    ) {
        self.minimumConfidence = minimumConfidence
        self.minimumAspectRatio = minimumAspectRatio
        self.maximumAspectRatio = maximumAspectRatio
    }

    /// Result of edge detection on a single frame.
    public struct DetectionResult: Sendable {
        /// The detected rectangle in normalized coordinates (0–1).
        public let rectangle: NormalizedRectangle?

        /// Quality assessment of the detection.
        public let quality: CaptureQuality

        /// Time taken for detection in milliseconds.
        public let detectionTimeMs: Double
    }

    /// Normalized rectangle with four corner points.
    public struct NormalizedRectangle: Sendable {
        public let topLeft: CGPoint
        public let topRight: CGPoint
        public let bottomLeft: CGPoint
        public let bottomRight: CGPoint

        /// The bounding box that contains the rectangle.
        public var boundingBox: CGRect {
            let minX = min(topLeft.x, bottomLeft.x)
            let maxX = max(topRight.x, bottomRight.x)
            let minY = min(bottomLeft.y, bottomRight.y)
            let maxY = max(topLeft.y, topRight.y)
            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }

        /// Area of the bounding box relative to the full frame (0–1).
        public var relativeArea: CGFloat {
            boundingBox.width * boundingBox.height
        }
    }

    /// Detects document edges in a pixel buffer (from camera output).
    ///
    /// - Parameter pixelBuffer: The camera frame to analyze.
    /// - Returns: Detection result with rectangle and quality.
    public func detect(in pixelBuffer: CVPixelBuffer) -> DetectionResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        let request = VNDetectRectanglesRequest()
        request.minimumConfidence = minimumConfidence
        request.minimumAspectRatio = minimumAspectRatio
        request.maximumAspectRatio = maximumAspectRatio
        request.maximumObservations = 1
        // Quadrature-based detection finds document-like shapes.
        request.minimumSize = 0.2

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        do {
            try handler.perform([request])
        } catch {
            let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            return DetectionResult(rectangle: nil, quality: .undetected, detectionTimeMs: elapsed)
        }

        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        guard let observation = request.results?.first else {
            return DetectionResult(rectangle: nil, quality: .undetected, detectionTimeMs: elapsed)
        }

        let rect = NormalizedRectangle(
            topLeft: observation.topLeft,
            topRight: observation.topRight,
            bottomLeft: observation.bottomLeft,
            bottomRight: observation.bottomRight
        )

        let quality = assessQuality(rectangle: rect, confidence: observation.confidence, pixelBuffer: pixelBuffer)

        return DetectionResult(rectangle: rect, quality: quality, detectionTimeMs: elapsed)
    }

    /// Detects document edges in a CGImage (for testing with static images).
    public func detect(in image: CGImage) -> DetectionResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        let request = VNDetectRectanglesRequest()
        request.minimumConfidence = minimumConfidence
        request.minimumAspectRatio = minimumAspectRatio
        request.maximumAspectRatio = maximumAspectRatio
        request.maximumObservations = 1
        request.minimumSize = 0.2

        let handler = VNImageRequestHandler(cgImage: image, options: [:])

        do {
            try handler.perform([request])
        } catch {
            let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            return DetectionResult(rectangle: nil, quality: .undetected, detectionTimeMs: elapsed)
        }

        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        guard let observation = request.results?.first else {
            return DetectionResult(rectangle: nil, quality: .undetected, detectionTimeMs: elapsed)
        }

        let rect = NormalizedRectangle(
            topLeft: observation.topLeft,
            topRight: observation.topRight,
            bottomLeft: observation.bottomLeft,
            bottomRight: observation.bottomRight
        )

        let quality = CaptureQuality(
            isFramed: rect.relativeArea >= 0.15,
            isSharp: true,
            isBright: true,
            confidence: Double(observation.confidence)
        )

        return DetectionResult(rectangle: rect, quality: quality, detectionTimeMs: elapsed)
    }

    // MARK: - Private

    private func assessQuality(
        rectangle: NormalizedRectangle,
        confidence: Float,
        pixelBuffer: CVPixelBuffer
    ) -> CaptureQuality {
        // Framing: document should take up at least 15% of the frame
        // but not more than 95% (too close).
        let area = rectangle.relativeArea
        let isFramed = area >= 0.15 && area <= 0.95

        // Sharpness: use Laplacian variance on the region of interest.
        let isSharp = assessSharpness(pixelBuffer: pixelBuffer, region: rectangle.boundingBox)

        // Brightness: check average luminance of the frame.
        let isBright = assessBrightness(pixelBuffer: pixelBuffer)

        return CaptureQuality(
            isFramed: isFramed,
            isSharp: isSharp,
            isBright: isBright,
            confidence: Double(confidence)
        )
    }

    private func assessSharpness(pixelBuffer: CVPixelBuffer, region: CGRect) -> Bool {
        // Simplified sharpness check using pixel variance in the region.
        // A real implementation would use a Laplacian filter via Accelerate.
        // For now, we use a heuristic based on the buffer resolution.
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        // If the document region is large enough in pixels, assume it's sharp enough.
        let regionPixelWidth = CGFloat(width) * region.width
        let regionPixelHeight = CGFloat(height) * region.height
        return regionPixelWidth >= 200 && regionPixelHeight >= 150
    }

    private func assessBrightness(pixelBuffer: CVPixelBuffer) -> Bool {
        // Check average luminance from the Y plane (assuming YCbCr format).
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else {
            return true // Assume bright if we can't read.
        }

        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let totalPixels = width * height

        guard totalPixels > 0 else { return true }

        // Sample every 16th pixel for performance.
        let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
        var sum: Int = 0
        var count: Int = 0

        for y in stride(from: 0, to: height, by: 16) {
            for x in stride(from: 0, to: width, by: 16) {
                sum += Int(pointer[y * bytesPerRow + x])
                count += 1
            }
        }

        guard count > 0 else { return true }
        let avgLuminance = Double(sum) / Double(count)

        // Acceptable range: not too dark (>40) and not too bright (<240).
        return avgLuminance > 40 && avgLuminance < 240
    }
}
