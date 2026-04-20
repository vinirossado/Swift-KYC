# Handling Errors

Understand and recover from errors that occur during the identity verification flow.

## Overview

All errors produced by the SDK are represented by the ``IdentityKitError`` enum. This type conforms to both `Error` and `LocalizedError`, so you can display `localizedDescription` directly to users or match specific cases to drive your app's recovery logic.

### Error Cases at a Glance

| Case | When it occurs | Typical recovery |
|---|---|---|
| ``IdentityKitError/cameraPermissionDenied`` | User denied or restricted camera access. | Prompt the user to enable camera permission in Settings. |
| ``IdentityKitError/networkFailed(underlying:)`` | A network request failed (timeout, DNS, TLS, etc.). | Retry or check connectivity. Inspect the `underlying` error for details. |
| ``IdentityKitError/invalidConfiguration(reason:)`` | The ``IdentityKitConfiguration/Builder`` detected an invalid or missing field. | Fix the configuration. This is a programming error -- check the `reason` string. |
| ``IdentityKitError/sessionExpired`` | The backend reports the session token is no longer valid. | Request a new session ID from your server and restart the flow. |
| ``IdentityKitError/cancelledByUser`` | The user tapped a cancel or back button. | Return the user to the previous screen. No action required. |
| ``IdentityKitError/documentCaptureFailed(reason:)`` | Document quality was too low after maximum retries. | Let the user retry with better lighting or a different document. |
| ``IdentityKitError/livenessCheckFailed(reason:)`` | Liveness detection timed out or no face was found. | Let the user retry with a clearer view of their face. |
| ``IdentityKitError/uploadFailed(reason:)`` | Upload of captured data failed after all retry attempts. | Check network connectivity. The SDK's outbox queue will retry on next app launch. |
| ``IdentityKitError/circuitBreakerOpen`` | The circuit breaker tripped after repeated backend failures. | Wait and retry later. The backend may be experiencing an outage. |
| ``IdentityKitError/internalError(reason:)`` | An unexpected internal failure occurred. | Log the `reason` and report it as a bug. |

### Matching Errors in a Switch

```swift
func handle(_ error: IdentityKitError) {
    switch error {
    case .cameraPermissionDenied:
        showSettingsPrompt()

    case .networkFailed(let underlying):
        log("Network error: \(underlying)")
        showRetryDialog()

    case .invalidConfiguration(let reason):
        assertionFailure("Bad config: \(reason)")

    case .sessionExpired:
        refreshSessionAndRestart()

    case .cancelledByUser:
        // No action needed.
        break

    case .documentCaptureFailed(let reason):
        showRetryAlert(message: reason)

    case .livenessCheckFailed(let reason):
        showRetryAlert(message: reason)

    case .uploadFailed(let reason):
        log("Upload failed: \(reason)")
        showRetryDialog()

    case .circuitBreakerOpen:
        showTemporarilyUnavailableAlert()

    case .internalError(let reason):
        log("Internal SDK error: \(reason)")
        showGenericErrorAlert()
    }
}
```

### Async/Await Error Handling

When using the async API, errors are thrown directly:

```swift
do {
    let result = try await IdentityKit.verify(
        configuration: config,
        presentingOn: self
    )
    handleSuccess(result)
} catch let error as IdentityKitError {
    handle(error)
} catch {
    // Unexpected non-SDK error
    log("Unexpected: \(error)")
}
```

### Delegate Error Handling

With the delegate API, errors arrive through ``IdentityKitDelegate/identityKitDidFail(with:)``:

```swift
func identityKitDidFail(with error: IdentityKitError) {
    dismiss(animated: true) {
        self.handle(error)
    }
}
```

### User-Facing Messages

Every ``IdentityKitError`` case provides a human-readable `localizedDescription` via its `LocalizedError` conformance. You can display these directly, or use them as a starting point for your own localized strings:

```swift
let alert = UIAlertController(
    title: "Verification Failed",
    message: error.localizedDescription,
    preferredStyle: .alert
)
```

### Configuration Errors Are Programming Errors

``IdentityKitError/invalidConfiguration(reason:)`` is thrown at build time by ``IdentityKitConfiguration/Builder/build()``. Treat these as programmer mistakes rather than runtime conditions -- they indicate a missing API key, empty session ID, or invalid retry count. Catch them during development and ensure your configuration is always valid before shipping.

## See Also

- ``IdentityKitError``
- <doc:GettingStarted>
