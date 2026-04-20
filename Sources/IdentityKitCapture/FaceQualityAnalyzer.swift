import Foundation
import Vision
import IdentityKitCore

/// Analyzes face quality in camera frames using Vision framework.
///
/// Detects faces, landmarks, and evaluates quality for liveness checks.
/// Used by `LivenessController` to determine if a frame is suitable
/// for challenge verification.
public final class FaceQualityAnalyzer: Sendable {

    /// Minimum face size relative to frame (0–1).
    private let minimumFaceSize: Float

    public init(minimumFaceSize: Float = 0.15) {
        self.minimumFaceSize = minimumFaceSize
    }

    /// Result of face analysis on a single frame.
    public struct AnalysisResult: Sendable {
        /// Detected face observation, if any.
        public let faceDetected: Bool

        /// Face bounding box in normalized coordinates.
        public let faceBoundingBox: CGRect?

        /// Yaw angle in degrees (negative = left, positive = right).
        public let yawAngle: Double?

        /// Whether eyes appear open (for blink detection).
        public let eyesOpen: Bool?

        /// Quality assessment.
        public let quality: CaptureQuality

        /// Detection time in milliseconds.
        public let detectionTimeMs: Double
    }

    /// Analyzes a pixel buffer for face quality.
    public func analyze(pixelBuffer: CVPixelBuffer) -> AnalysisResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
        let faceCaptureQualityRequest = VNDetectFaceCaptureQualityRequest()

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        do {
            try handler.perform([faceLandmarksRequest, faceCaptureQualityRequest])
        } catch {
            let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            return AnalysisResult(
                faceDetected: false, faceBoundingBox: nil,
                yawAngle: nil, eyesOpen: nil,
                quality: .undetected, detectionTimeMs: elapsed
            )
        }

        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        guard let faceObservation = faceLandmarksRequest.results?.first else {
            return AnalysisResult(
                faceDetected: false, faceBoundingBox: nil,
                yawAngle: nil, eyesOpen: nil,
                quality: .undetected, detectionTimeMs: elapsed
            )
        }

        let boundingBox = faceObservation.boundingBox
        let yaw = faceObservation.yaw?.doubleValue
        let eyesOpen = detectEyesOpen(from: faceObservation)

        // Face capture quality from the dedicated request.
        let captureQuality = faceCaptureQualityRequest.results?.first?.faceCaptureQuality ?? 0

        let isFaceFramed = boundingBox.width >= CGFloat(minimumFaceSize)
            && boundingBox.height >= CGFloat(minimumFaceSize)
        let isCentered = abs(boundingBox.midX - 0.5) < 0.25
            && abs(boundingBox.midY - 0.5) < 0.25

        let quality = CaptureQuality(
            isFramed: isFaceFramed && isCentered,
            isSharp: captureQuality > 0.3,
            isBright: captureQuality > 0.2,
            confidence: Double(captureQuality)
        )

        return AnalysisResult(
            faceDetected: true,
            faceBoundingBox: boundingBox,
            yawAngle: yaw,
            eyesOpen: eyesOpen,
            quality: quality,
            detectionTimeMs: elapsed
        )
    }

    /// Analyzes a CGImage for face quality (for testing with static images).
    public func analyze(image: CGImage) -> AnalysisResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
        let faceCaptureQualityRequest = VNDetectFaceCaptureQualityRequest()

        let handler = VNImageRequestHandler(cgImage: image, options: [:])

        do {
            try handler.perform([faceLandmarksRequest, faceCaptureQualityRequest])
        } catch {
            let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            return AnalysisResult(
                faceDetected: false, faceBoundingBox: nil,
                yawAngle: nil, eyesOpen: nil,
                quality: .undetected, detectionTimeMs: elapsed
            )
        }

        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        guard let faceObservation = faceLandmarksRequest.results?.first else {
            return AnalysisResult(
                faceDetected: false, faceBoundingBox: nil,
                yawAngle: nil, eyesOpen: nil,
                quality: .undetected, detectionTimeMs: elapsed
            )
        }

        let boundingBox = faceObservation.boundingBox
        let yaw = faceObservation.yaw?.doubleValue
        let eyesOpen = detectEyesOpen(from: faceObservation)
        let captureQuality = faceCaptureQualityRequest.results?.first?.faceCaptureQuality ?? 0

        let quality = CaptureQuality(
            isFramed: boundingBox.width >= CGFloat(minimumFaceSize),
            isSharp: captureQuality > 0.3,
            isBright: captureQuality > 0.2,
            confidence: Double(captureQuality)
        )

        return AnalysisResult(
            faceDetected: true,
            faceBoundingBox: boundingBox,
            yawAngle: yaw,
            eyesOpen: eyesOpen,
            quality: quality,
            detectionTimeMs: elapsed
        )
    }

    // MARK: - Liveness Challenge Evaluation

    /// Evaluates whether a liveness challenge has been completed.
    public func evaluateChallenge(
        _ challenge: LivenessChallenge,
        currentResult: AnalysisResult,
        baselineResult: AnalysisResult?
    ) -> Bool {
        guard currentResult.faceDetected else { return false }

        switch challenge {
        case .blink:
            // Eyes were open in baseline but now closed (or vice versa).
            guard let baselineEyes = baselineResult?.eyesOpen,
                  let currentEyes = currentResult.eyesOpen else {
                return false
            }
            return baselineEyes && !currentEyes

        case .turnLeft:
            guard let yaw = currentResult.yawAngle else { return false }
            // Yaw > 20 degrees to the left (negative in Vision coordinates).
            return yaw < -15

        case .turnRight:
            guard let yaw = currentResult.yawAngle else { return false }
            // Yaw > 20 degrees to the right.
            return yaw > 15
        }
    }

    // MARK: - Private

    /// Heuristic eye-open detection from face landmarks.
    ///
    /// Uses the eye contour landmark points — if the vertical spread
    /// of the eye region is small relative to the eye width, eyes are likely closed.
    private func detectEyesOpen(from observation: VNFaceObservation) -> Bool? {
        guard let landmarks = observation.landmarks,
              let leftEye = landmarks.leftEye,
              let rightEye = landmarks.rightEye else {
            return nil
        }

        let leftOpen = isEyeOpen(eye: leftEye)
        let rightOpen = isEyeOpen(eye: rightEye)

        // Both eyes should agree for a reliable reading.
        return leftOpen && rightOpen
    }

    private func isEyeOpen(eye: VNFaceLandmarkRegion2D) -> Bool {
        let points = eye.normalizedPoints
        guard points.count >= 4 else { return true }

        // Calculate vertical spread vs horizontal spread.
        let ys = points.map(\.y)
        let xs = points.map(\.x)

        let verticalSpread = (ys.max() ?? 0) - (ys.min() ?? 0)
        let horizontalSpread = (xs.max() ?? 0) - (xs.min() ?? 0)

        guard horizontalSpread > 0 else { return true }

        // Aspect ratio of the eye region — open eyes have a higher ratio.
        let aspectRatio = verticalSpread / horizontalSpread
        return aspectRatio > 0.15
    }
}
