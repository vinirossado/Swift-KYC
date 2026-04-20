import Foundation
import AVFoundation
import IdentityKitCore

/// Manages an `AVCaptureSession` on a dedicated serial queue.
///
/// Encapsulates camera setup, configuration, and frame delivery.
/// All AVCaptureSession operations run on `sessionQueue` to avoid
/// blocking the main thread and prevent data races.
public final class CaptureSessionManager: NSObject, @unchecked Sendable {

    /// Camera position to use.
    public enum CameraPosition: Sendable {
        case back   // For document capture
        case front  // For liveness/selfie
    }

    /// Callback type for delivering sample buffers.
    public typealias FrameHandler = @Sendable (CMSampleBuffer) -> Void

    // All session operations happen on this serial queue — no concurrent
    // access to AVCaptureSession, which is not thread-safe.
    private let sessionQueue = DispatchQueue(label: "com.identitykit.capture.session", qos: .userInitiated)
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let outputQueue = DispatchQueue(label: "com.identitykit.capture.output", qos: .userInitiated)

    private var frameHandler: FrameHandler?
    private let logger: IdentityKitLogger
    private let logLevel: LogLevel

    public private(set) var isRunning: Bool = false

    public init(
        logger: IdentityKitLogger = DefaultLogger(),
        logLevel: LogLevel = .warning
    ) {
        self.logger = logger
        self.logLevel = logLevel
        super.init()
    }

    /// The underlying capture session, for attaching a preview layer.
    public var session: AVCaptureSession {
        captureSession
    }

    /// Configures the capture session for the given camera position.
    ///
    /// Must be called before `startSession()`. Runs asynchronously on the session queue.
    public func configure(
        position: CameraPosition,
        frameHandler: @escaping FrameHandler
    ) async throws {
        self.frameHandler = frameHandler

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: IdentityKitError.internalError(reason: "CaptureSessionManager deallocated"))
                    return
                }

                do {
                    try self.configureSynchronously(position: position)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Starts the capture session.
    public func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            self.isRunning = true
            self.log(.debug, "Capture session started")
        }
    }

    /// Stops the capture session.
    public func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            self.isRunning = false
            self.log(.debug, "Capture session stopped")
        }
    }

    // MARK: - Private

    /// Synchronous configuration — must be called on sessionQueue.
    private func configureSynchronously(position: CameraPosition) throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        // Remove existing inputs/outputs.
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.outputs.forEach { captureSession.removeOutput($0) }

        // Session preset for high-quality still photos.
        captureSession.sessionPreset = .photo

        // Find the appropriate camera device.
        let avPosition: AVCaptureDevice.Position = position == .back ? .back : .front
        guard let device = bestCamera(for: avPosition) else {
            throw IdentityKitError.cameraPermissionDenied
        }

        // Configure the device for optimal document/face capture.
        try configureDevice(device)

        // Add input.
        let input = try AVCaptureDeviceInput(device: device)
        guard captureSession.canAddInput(input) else {
            throw IdentityKitError.internalError(reason: "Cannot add camera input to session")
        }
        captureSession.addInput(input)

        // Configure video output.
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: outputQueue)

        guard captureSession.canAddOutput(videoOutput) else {
            throw IdentityKitError.internalError(reason: "Cannot add video output to session")
        }
        captureSession.addOutput(videoOutput)

        log(.debug, "Capture session configured for \(position)")
    }

    private func bestCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        // Prefer wide-angle camera, fall back to default.
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            return device
        }
        return AVCaptureDevice.default(for: .video)
    }

    private func configureDevice(_ device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        // Enable continuous auto-focus for document capture.
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }

        // Enable continuous auto-exposure.
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }

        // Smooth auto-focus for less hunting (iOS only).
        #if os(iOS)
        if device.isSmoothAutoFocusSupported {
            device.isSmoothAutoFocusEnabled = true
        }
        #endif
    }

    private func log(_ level: LogLevel, _ message: String) {
        guard level >= logLevel else { return }
        logger.log(level: level, message: message, file: #file, function: #function, line: #line)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CaptureSessionManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        frameHandler?(sampleBuffer)
    }

    public func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        log(.debug, "Frame dropped")
    }
}
