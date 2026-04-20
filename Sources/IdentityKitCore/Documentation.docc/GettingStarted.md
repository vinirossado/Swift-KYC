# Getting Started in 10 Lines

Integrate identity verification into your app with just a few lines of code.

@Metadata {
    @PageImage(purpose: icon, source: "identitykit-icon")
}

## Overview

IdentityKit offers two APIs for running the verification flow: a **delegate-based** API for UIKit integration with fine-grained control, and an **async/await** API for concise structured concurrency. Both start with the same configuration builder.

### Build a Configuration

Use ``IdentityKitConfiguration/Builder`` to create a validated configuration. The builder requires an API key and a session ID at minimum. Call ``IdentityKitConfiguration/Builder/build()`` to validate and produce an immutable ``IdentityKitConfiguration``.

```swift
import IdentityKitCore

let configuration = try IdentityKitConfiguration.Builder()
    .apiKey("ik_live_abc123")
    .sessionId("sess_9f8e7d6c")
    .environment(.production)
    .enabledChecks([.document(.idCard), .liveness])
    .theme(IdentityKitTheme(primaryColorHex: "#1A73E8"))
    .build()
```

> Tip: The builder defaults to `.production` environment, `[.document(.idCard), .liveness]` checks, and the system-default theme. You only need to set the values you want to change.

### Option A: Async/Await API

The simplest integration path. Call ``IdentityKit.verify(configuration:presentingOn:)`` and await the result. The SDK presents the verification flow modally on the view controller you provide.

```swift
import IdentityKitCore
import IdentityKitUI

func startVerification() async {
    do {
        let config = try IdentityKitConfiguration.Builder()
            .apiKey("ik_live_abc123")
            .sessionId("sess_9f8e7d6c")
            .build()

        let result = try await IdentityKit.verify(
            configuration: config,
            presentingOn: self
        )
        print("Verification completed: \(result.sessionId)")
    } catch {
        print("Verification failed: \(error.localizedDescription)")
    }
}
```

This is the recommended approach for new projects targeting iOS 15+.

### Option B: Delegate API

For more control -- such as receiving upload progress callbacks -- use ``IdentityKit.verificationFlow(configuration:delegate:)`` which returns a `UIViewController` you present yourself.

```swift
import IdentityKitCore
import IdentityKitUI

class VerifyViewController: UIViewController, IdentityKitDelegate {

    func startVerification() throws {
        let config = try IdentityKitConfiguration.Builder()
            .apiKey("ik_live_abc123")
            .sessionId("sess_9f8e7d6c")
            .build()

        let flow = IdentityKit.verificationFlow(
            configuration: config,
            delegate: self
        )
        present(flow, animated: true)
    }

    // MARK: - IdentityKitDelegate

    func identityKitDidComplete(with result: VerificationResult) {
        dismiss(animated: true)
        print("Session \(result.sessionId) completed at \(result.completedAt)")
    }

    func identityKitDidFail(with error: IdentityKitError) {
        dismiss(animated: true)
        presentAlert(for: error)
    }

    func identityKitDidCancel() {
        dismiss(animated: true)
    }

    func identityKitUploadProgress(_ progress: Double) {
        progressBar.setProgress(Float(progress), animated: true)
    }
}
```

> Note: All ``IdentityKitDelegate`` methods are called on the main actor. The `identityKitUploadProgress(_:)` method has a default empty implementation, so it is optional to implement.

### Add the Package Dependency

Add IdentityKit to your project using Swift Package Manager:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/your-org/identity-kit.git", from: "1.0.0")
]
```

Then add the modules you need to your target's dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: [
        "IdentityKitCore",
        "IdentityKitUI"
    ]
)
```

For most integrations, importing `IdentityKitCore` and `IdentityKitUI` is sufficient. The UI module transitively pulls in `IdentityKitCapture`.

### Camera Permission

IdentityKit requires camera access for document capture and liveness detection. Add the `NSCameraUsageDescription` key to your app's `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to verify your identity document and perform a liveness check.</string>
```

If the user denies camera permission, the SDK reports ``IdentityKitError/cameraPermissionDenied``.

## See Also

- <doc:HandlingErrors>
- <doc:CustomizingAppearance>
