import Foundation
import AVFoundation
import CoreImage
import IdentityKitCore

/// Orchestrates the liveness capture flow: camera → face analysis → challenge evaluation → frame capture.
///
/// Presents a sequence of challenges and captures key frames when challenges are completed.
public final class LivenessCaptureController: @unchecked Sendable {

    /// Events emitted during liveness capture.
    public enum Event: Sendable {
        /// Quality updated for the current frame.
        case qualityUpdated(CaptureQuality)

        /// A new challenge is being presented.
        case challengeStarted(LivenessChallenge)

        /// Progress on the current challenge (0.0–1.0).
        case challengeProgress(Double)

        /// A challenge was completed successfully.
        case challengeCompleted(LivenessChallenge)

        /// A key frame was captured for the given challenge.
        case frameCaptured(LivenessFrame)

        /// All challenges completed — liveness verified.
        case completed([LivenessFrame])

        /// Challenge timed out.
        case challengeTimeout(LivenessChallenge)

        /// An error occurred.
        case error(IdentityKitError)
    }

    private let sessionManager: CaptureSessionManager
    private let faceAnalyzer: FaceQualityAnalyzer
    private let challenges: [LivenessChallenge]
    private let challengeTimeout: TimeInterval
    private let logger: IdentityKitLogger

    private let eventContinuation: AsyncStream<Event>.Continuation
    public let events: AsyncStream<Event>

    // State — accessed from the output queue.
    private var currentChallengeIndex = 0
    private var capturedFrames: [LivenessFrame] = []
    private var baselineResult: FaceQualityAnalyzer.AnalysisResult?
    private var challengeStartTime: Date?
    private var challengeCompleted = false

    public init(
        challenges: [LivenessChallenge],
        challengeTimeout: TimeInterval = 30.0,
        sessionManager: CaptureSessionManager = CaptureSessionManager(),
        faceAnalyzer: FaceQualityAnalyzer = FaceQualityAnalyzer(),
        logger: IdentityKitLogger = DefaultLogger()
    ) {
        self.challenges = challenges
        self.challengeTimeout = challengeTimeout
        self.sessionManager = sessionManager
        self.faceAnalyzer = faceAnalyzer
        self.logger = logger

        var continuation: AsyncStream<Event>.Continuation!
        self.events = AsyncStream { continuation = $0 }
        self.eventContinuation = continuation
    }

    /// Generates a random pair of challenges from the available set.
    public static func randomChallenges(count: Int = 2) -> [LivenessChallenge] {
        Array(LivenessChallenge.allCases.shuffled().prefix(count))
    }

    /// Starts the liveness capture session.
    public func start() async throws {
        guard !challenges.isEmpty else {
            throw IdentityKitError.invalidConfiguration(reason: "No liveness challenges configured")
        }

        try await sessionManager.configure(position: .front) { [weak self] sampleBuffer in
            self?.processFrame(sampleBuffer)
        }

        sessionManager.startSession()
        startNextChallenge()
    }

    /// Stops the capture session.
    public func stop() {
        sessionManager.stopSession()
        eventContinuation.finish()
    }

    // MARK: - Private

    private func startNextChallenge() {
        guard currentChallengeIndex < challenges.count else {
            // All challenges done.
            eventContinuation.yield(.completed(capturedFrames))
            return
        }

        let challenge = challenges[currentChallengeIndex]
        challengeStartTime = Date()
        challengeCompleted = false
        baselineResult = nil

        eventContinuation.yield(.challengeStarted(challenge))
    }

    private func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard currentChallengeIndex < challenges.count else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let result = faceAnalyzer.analyze(pixelBuffer: pixelBuffer)
        eventContinuation.yield(.qualityUpdated(result.quality))

        // Check timeout.
        if let startTime = challengeStartTime,
           Date().timeIntervalSince(startTime) > challengeTimeout {
            let challenge = challenges[currentChallengeIndex]
            eventContinuation.yield(.challengeTimeout(challenge))
            eventContinuation.yield(.error(.livenessCheckFailed(reason: "Challenge '\(challenge.rawValue)' timed out")))
            return
        }

        guard result.faceDetected, !challengeCompleted else { return }

        // Capture baseline on first face detection for the current challenge.
        if baselineResult == nil {
            baselineResult = result
            return
        }

        let challenge = challenges[currentChallengeIndex]
        let passed = faceAnalyzer.evaluateChallenge(challenge, currentResult: result, baselineResult: baselineResult)

        if passed {
            challengeCompleted = true
            eventContinuation.yield(.challengeCompleted(challenge))

            // Capture the key frame.
            if let jpegData = convertToJPEG(pixelBuffer: pixelBuffer) {
                let frame = LivenessFrame(
                    challenge: challenge,
                    imageData: jpegData,
                    capturedAt: Date(),
                    confidenceScore: result.quality.confidence
                )
                capturedFrames.append(frame)
                eventContinuation.yield(.frameCaptured(frame))
            }

            // Move to next challenge.
            currentChallengeIndex += 1
            startNextChallenge()
        }
    }

    private func convertToJPEG(pixelBuffer: CVPixelBuffer) -> Data? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        return context.jpegRepresentation(of: ciImage, colorSpace: colorSpace, options: [:])
    }
}
