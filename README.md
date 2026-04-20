# IdentityKit

iOS SDK for identity verification (KYC) — document capture and liveness detection.

![Swift 5.10+](https://img.shields.io/badge/Swift-5.10+-orange)
![iOS 15+](https://img.shields.io/badge/iOS-15.0+-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## Overview

IdentityKit provides a drop-in identity verification flow for iOS apps. Capture identity documents with automatic edge detection and perform liveness checks — all in a UIKit-based SDK with zero third-party dependencies.

## Quick Start

```swift
import IdentityKit

let config = try IdentityKitConfiguration.Builder()
    .apiKey("pk_demo_123")
    .sessionId("session-abc")
    .environment(.staging)
    .enabledChecks([.document(.passport), .liveness])
    .build()

let flow = IdentityKit.verificationFlow(configuration: config, delegate: self)
present(flow, animated: true)
```

## Architecture

The SDK is split into focused modules:

| Module | Responsibility |
|---|---|
| `IdentityKitCore` | Public models, errors, protocols, configuration |
| `IdentityKitCapture` | AVFoundation + Vision (document edge detection, face analysis) |
| `IdentityKitUI` | UIKit view controllers, coordinator, accessibility |
| `IdentityKitNetwork` | URLSession client, retry, circuit breaker, cert pinning |
| `IdentityKitStorage` | Keychain, outbox queue, background upload |

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/user/identity-kit.git", from: "1.0.0")
]
```

## Current Status

### Milestone 1 — Core Models & Configuration
- [x] SPM multi-module project structure
- [x] `DocumentType`, `CapturedDocument`, `LivenessFrame`, `LivenessChallenge`
- [x] `VerificationSession`, `VerificationResult`, `VerificationCheck`
- [x] `IdentityKitError` with typed cases and localized descriptions
- [x] `IdentityKitConfiguration` with fluent builder pattern and validation
- [x] `IdentityKitTheme` for visual customization
- [x] `IdentityKitDelegate`, `IdentityKitLogger`, `IdentityKitTelemetry` protocols
- [x] `DefaultLogger` using `os.Logger`
- [x] `LogLevel` with `Comparable` conformance
- [x] Comprehensive unit tests for all core types
- [x] Strict concurrency compliance (`-strict-concurrency=complete`)
- [x] Zero force unwraps in SDK code

### Milestone 2 — Networking Layer
- [x] `APIClient` with async/await, automatic JSON decoding
- [x] `RetryPolicy` — exponential backoff with jitter, retryable status codes and errors
- [x] `CircuitBreaker` — closed/open/half-open state machine, thread-safe (NSLock)
- [x] `CertificatePinner` — public key pinning via CryptoKit SHA-256
- [x] `RequestSigner` — HMAC-SHA256 request signing
- [x] Multipart upload support
- [x] PII-redacted logging (no headers/bodies, only paths and status codes)
- [x] `MockURLProtocol` for test interception
- [x] 33 network tests (retry, circuit breaker, signing, happy/error paths)

### Milestone 3 — Capture (AVFoundation + Vision)
- [x] `DocumentEdgeDetector` — `VNDetectRectanglesRequest`, quality assessment (framing, sharpness, brightness)
- [x] `FaceQualityAnalyzer` — `VNDetectFaceLandmarksRequest` + `VNDetectFaceCaptureQualityRequest`, yaw/blink detection
- [x] `CaptureSessionManager` — AVCaptureSession on dedicated serial queue, configurable for front/back camera
- [x] `DocumentCaptureController` — orchestrates document capture with async event stream
- [x] `LivenessCaptureController` — challenge sequence (blink, turn), timeout, key frame capture
- [x] `CaptureQuality` — aggregated quality model with acceptance threshold
- [x] Challenge evaluation logic (blink via eye state change, turn via yaw angle)
- [x] 24 capture tests (Vision detection with synthetic images, quality, challenge evaluation)

### Milestone 4 — UI Layer (UIKit)
- [x] `IdentityKit` facade — delegate-based and `async/await` public APIs
- [x] `IdentityKitFlowCoordinator` — coordinator pattern orchestrating Intro → Document → Liveness → Review
- [x] `DocumentCaptureViewController` — camera preview, document overlay, real-time quality feedback
- [x] `LivenessViewController` — oval face guide, challenge instructions, progress bar
- [x] `ResultReviewViewController` — image review with confirm/retake
- [x] `InstructionViewController` — reusable intro/instruction screen
- [x] `ThemeApplier` — hex→UIColor, Dynamic Type fonts, corner radius
- [x] Full accessibility: VoiceOver labels/hints, announcements, Dynamic Type, Reduce Motion

## License

MIT
