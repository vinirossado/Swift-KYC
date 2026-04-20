import Foundation
import AVFoundation
import CoreImage
import IdentityKitCore

/// Orchestrates the document capture flow: camera → edge detection → quality check → capture.
///
/// Delivers real-time quality feedback via an async stream and captures
/// the final document image when quality criteria are met.
public final class DocumentCaptureController: @unchecked Sendable {

    /// Events emitted during document capture.
    public enum Event: Sendable {
        /// Quality updated for the current frame.
        case qualityUpdated(CaptureQuality)

        /// A document edge was detected with the given rectangle.
        case edgeDetected(DocumentEdgeDetector.NormalizedRectangle)

        /// The document was successfully captured.
        case captured(CapturedDocument)

        /// An error occurred during capture.
        case error(IdentityKitError)
    }

    private let sessionManager: CaptureSessionManager
    private let edgeDetector: DocumentEdgeDetector
    private let documentType: DocumentType
    private let logger: IdentityKitLogger

    private let eventContinuation: AsyncStream<Event>.Continuation
    /// Public stream of capture events for the UI layer to observe.
    public let events: AsyncStream<Event>

    // Capture state — accessed only from the output queue via the frame handler.
    private var isFrontCaptured = false
    private var frontImageData: Data?
    private var frontCapturedAt: Date?
    private var isCapturing = false

    public init(
        documentType: DocumentType,
        sessionManager: CaptureSessionManager = CaptureSessionManager(),
        edgeDetector: DocumentEdgeDetector = DocumentEdgeDetector(),
        logger: IdentityKitLogger = DefaultLogger()
    ) {
        self.documentType = documentType
        self.sessionManager = sessionManager
        self.edgeDetector = edgeDetector
        self.logger = logger

        var continuation: AsyncStream<Event>.Continuation!
        self.events = AsyncStream { continuation = $0 }
        self.eventContinuation = continuation
    }

    /// Starts the document capture session.
    public func start() async throws {
        try await sessionManager.configure(position: .back) { [weak self] sampleBuffer in
            self?.processFrame(sampleBuffer)
        }
        sessionManager.startSession()
    }

    /// Triggers a manual capture of the current frame.
    ///
    /// The next frame with acceptable quality will be captured.
    public func triggerCapture() {
        isCapturing = true
    }

    /// Stops the capture session and cleans up.
    public func stop() {
        sessionManager.stopSession()
        eventContinuation.finish()
    }

    // MARK: - Private

    private func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let result = edgeDetector.detect(in: pixelBuffer)

        eventContinuation.yield(.qualityUpdated(result.quality))

        if let rectangle = result.rectangle {
            eventContinuation.yield(.edgeDetected(rectangle))
        }

        // Only capture when manually triggered and quality is acceptable.
        guard isCapturing, result.quality.isAcceptable else { return }
        isCapturing = false

        guard let jpegData = convertToJPEG(pixelBuffer: pixelBuffer) else {
            eventContinuation.yield(.error(.documentCaptureFailed(reason: "Failed to encode image as JPEG")))
            return
        }

        if !isFrontCaptured {
            // Front side captured.
            isFrontCaptured = true
            frontImageData = jpegData
            frontCapturedAt = Date()

            if !documentType.requiresBackCapture {
                // Single-side document (passport) — done.
                let document = CapturedDocument(
                    documentType: documentType,
                    frontImageData: jpegData,
                    frontCapturedAt: frontCapturedAt ?? Date(),
                    qualityScore: result.quality.confidence
                )
                eventContinuation.yield(.captured(document))
            }
            // For double-sided docs, UI will prompt user to flip and call triggerCapture again.
        } else {
            // Back side captured.
            guard let frontData = frontImageData, let frontTime = frontCapturedAt else {
                eventContinuation.yield(.error(.documentCaptureFailed(reason: "Front image data lost")))
                return
            }

            let document = CapturedDocument(
                documentType: documentType,
                frontImageData: frontData,
                backImageData: jpegData,
                frontCapturedAt: frontTime,
                backCapturedAt: Date(),
                qualityScore: result.quality.confidence
            )
            eventContinuation.yield(.captured(document))
        }
    }

    private func convertToJPEG(pixelBuffer: CVPixelBuffer) -> Data? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        return context.jpegRepresentation(of: ciImage, colorSpace: colorSpace, options: [:])
    }
}
