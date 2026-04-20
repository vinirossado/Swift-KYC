# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `IdentityKitCore` module with public models: `DocumentType`, `CapturedDocument`, `LivenessFrame`, `LivenessChallenge`, `VerificationCheck`, `VerificationSession`, `VerificationResult`
- `IdentityKitError` enum with typed error cases and localized descriptions
- `IdentityKitConfiguration` with fluent builder pattern and validation
- `IdentityKitTheme` for visual customization
- `IdentityKitDelegate`, `IdentityKitLogger`, `IdentityKitTelemetry` protocols
- `DefaultLogger` using `OSLog`
- `LogLevel` enum with `Comparable` ordering
- SPM multi-module project structure
- `IdentityKitNetwork` module: `APIClient`, `RetryPolicy`, `CircuitBreaker`, `CertificatePinner`, `RequestSigner`
- Multipart upload support for document/liveness images
- `MockURLProtocol` for URL-level test interception
- `IdentityKitCapture` module: `DocumentEdgeDetector`, `FaceQualityAnalyzer`, `CaptureSessionManager`, `DocumentCaptureController`, `LivenessCaptureController`
- `CaptureQuality` aggregated quality assessment model
- Challenge evaluation logic for blink (eye state), turn left/right (yaw angle)
- `IdentityKitUI` module: `IdentityKit` facade, `IdentityKitFlowCoordinator`, `DocumentCaptureViewController`, `LivenessViewController`, `ResultReviewViewController`, `InstructionViewController`
- `ThemeApplier` for hex→UIColor, Dynamic Type, font customization
- `AsyncDelegateBridge` for async/await verification API
- Full accessibility: VoiceOver labels/hints/announcements, Dynamic Type up to XXXL, Reduce Motion, dark mode, RTL
- `IdentityKitStorage` module: `KeychainStore`, `OutboxQueue`, `BackgroundUploadManager`
- Secure token storage via Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
- File-based persistent outbox queue for resilient uploads
- Actor-based background upload processor with retry and expiry
- 125 unit and integration tests covering all modules
