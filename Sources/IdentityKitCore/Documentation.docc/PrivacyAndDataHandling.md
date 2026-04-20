# Privacy and Data Handling

How IdentityKit protects user data throughout the verification flow.

## Overview

IdentityKit is designed with a privacy-first approach. The SDK handles sensitive personal data -- identity documents and biometric liveness frames -- and applies multiple layers of protection to ensure this data is secured in transit, at rest, and in logs.

### Zero Third-Party Dependencies

IdentityKit has no third-party dependencies. Every component -- networking, storage, image processing -- is implemented using Apple frameworks only. This eliminates supply-chain risk and ensures no user data is shared with external libraries.

### Data in Transit

All network communication enforces strict security:

- **App Transport Security (ATS):** The SDK requires ATS with no exceptions. All API endpoints use HTTPS with TLS 1.2 or later.
- **Certificate Pinning:** The `IdentityKitNetwork` module pins the expected server certificates. Connections to servers presenting unexpected certificates are rejected immediately.
- **Request Signing:** When an HMAC secret is provided via ``IdentityKitConfiguration/Builder/hmacSecret(_:)``, every API request is signed. The backend can verify request integrity and authenticity.

### Data at Rest

- **Keychain Storage:** Session tokens and API keys are stored in the iOS Keychain via the `IdentityKitStorage` module, not in `UserDefaults` or on disk.
- **No Persistent Image Storage:** Captured document images and liveness frames are held in memory only. They are written to the upload outbox queue as encrypted temporary files and deleted immediately after successful upload.
- **Background Upload Queue:** If the app is backgrounded or the network is unavailable, the outbox queue retains encrypted payloads for upload on next launch. Once uploaded, all temporary files are purged.

### Logging

- **No PII in Logs:** The SDK's internal logger (``IdentityKitLogger``) never includes personally identifiable information in log output. Session IDs are truncated, and image data is never logged.
- **Configurable Log Level:** Set the log level via ``IdentityKitConfiguration/Builder/logLevel(_:)`` to control verbosity. In production, use `.warning` or `.error` to minimize log output. Set `.none` to disable SDK logging entirely.
- **Custom Logger Integration:** Implement the ``IdentityKitLogger`` protocol to route SDK logs into your own logging infrastructure with your own redaction rules.

### Camera and Permissions

- **Minimal Permission Scope:** The SDK requests only camera access (`NSCameraUsageDescription`). It does not request photo library, microphone, or location access.
- **Graceful Denial:** If camera permission is denied, the SDK reports ``IdentityKitError/cameraPermissionDenied`` and does not attempt to access the camera.

### Network Resilience and Data Protection

- **Retry with Backoff:** Failed uploads are retried with exponential backoff. The maximum number of attempts is configurable via ``IdentityKitConfiguration/Builder/maxRetryAttempts(_:)``.
- **Circuit Breaker:** After repeated backend failures, the circuit breaker opens to prevent further requests. This protects both the user's device (battery, bandwidth) and the backend from cascading load. The SDK reports ``IdentityKitError/circuitBreakerOpen`` so your app can inform the user.

### Telemetry

The optional ``IdentityKitTelemetry`` protocol allows you to track SDK events and performance metrics. The SDK itself does not send any telemetry data to Anthropic or any third party. If you implement the protocol, you control where the data goes.

### Summary of Security Controls

| Layer | Mechanism |
|---|---|
| Transport | TLS 1.2+, ATS strict, certificate pinning |
| Request integrity | HMAC request signing (optional) |
| Storage | iOS Keychain for secrets, encrypted temp files for media |
| Logging | No PII, configurable level, custom logger support |
| Permissions | Camera only, graceful denial handling |
| Resilience | Retry with backoff, circuit breaker |
| Dependencies | Zero third-party libraries |

## See Also

- ``IdentityKitError``
- <doc:HandlingErrors>
