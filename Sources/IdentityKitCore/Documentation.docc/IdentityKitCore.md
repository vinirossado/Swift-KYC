# ``IdentityKitCore``

A modular iOS SDK for identity verification (KYC) with document capture and liveness detection.

@Metadata {
    @DisplayName("IdentityKit")
}

## Overview

IdentityKit provides a complete identity verification flow for iOS applications. The SDK captures identity documents, performs liveness detection, and uploads verification data to your backend -- all with zero third-party dependencies.

The SDK is organized into five modules:

| Module | Responsibility |
|---|---|
| **IdentityKitCore** | Configuration, error types, protocols, and shared models. |
| **IdentityKitCapture** | Camera-based document capture and liveness frame analysis. |
| **IdentityKitUI** | UIKit view controllers for the verification flow screens. |
| **IdentityKitNetwork** | API client with retry policies, certificate pinning, and circuit breaking. |
| **IdentityKitStorage** | Keychain-backed storage and background upload queue. |

IdentityKit supports both a delegate-based API and a modern async/await API. Configuration uses a fluent builder pattern that validates all required fields at build time.

### Requirements

- Swift 5.10+
- iOS 15+
- No third-party dependencies

## Topics

### Essentials

- <doc:GettingStarted>
- ``IdentityKitConfiguration``
- ``IdentityKitEnvironment``

### Verification Flow

- ``VerificationCheck``
- ``VerificationResult``
- ``VerificationSession``

### Delegate Protocol

- ``IdentityKitDelegate``

### Error Handling

- <doc:HandlingErrors>
- ``IdentityKitError``

### Appearance

- <doc:CustomizingAppearance>
- ``IdentityKitTheme``

### Privacy

- <doc:PrivacyAndDataHandling>

### Models

- ``CapturedDocument``
- ``DocumentType``
- ``LivenessChallenge``
- ``LivenessFrame``

### Logging and Telemetry

- ``IdentityKitLogger``
- ``IdentityKitTelemetry``
- ``LogLevel``
