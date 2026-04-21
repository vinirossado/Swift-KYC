import SwiftUI
import UIKit
import IdentityKitCore
import IdentityKitUI

/// Bridges the SDK's UIKit-based verification flow into SwiftUI.
///
/// On a real device, this presents the actual camera-based flow
/// (document capture + liveness). On simulator, it falls back to the mock flow
/// since AVCaptureSession doesn't work without a real camera.
struct SDKFlowBridge: UIViewControllerRepresentable {
    let configuration: IdentityKitConfiguration
    let onComplete: (VerificationResult) -> Void
    let onError: (IdentityKitError) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let flow = IdentityKit.verificationFlow(
            configuration: configuration,
            delegate: context.coordinator
        )
        return flow
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onComplete: onComplete,
            onError: onError,
            onCancel: onCancel
        )
    }

    @MainActor
    final class Coordinator: NSObject, IdentityKitDelegate {
        let onComplete: (VerificationResult) -> Void
        let onError: (IdentityKitError) -> Void
        let onCancel: () -> Void

        init(
            onComplete: @escaping (VerificationResult) -> Void,
            onError: @escaping (IdentityKitError) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.onComplete = onComplete
            self.onError = onError
            self.onCancel = onCancel
        }

        func identityKitDidComplete(with result: VerificationResult) {
            onComplete(result)
        }

        func identityKitDidFail(with error: IdentityKitError) {
            onError(error)
        }

        func identityKitDidCancel() {
            onCancel()
        }
    }
}
