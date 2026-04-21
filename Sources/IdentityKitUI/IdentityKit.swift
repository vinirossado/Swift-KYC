#if canImport(UIKit)
import UIKit
import ObjectiveC
import IdentityKitCore
import IdentityKitCapture

/// Top-level entry point for the IdentityKit verification SDK.
///
/// Provides both delegate-based and async/await APIs for starting
/// the verification flow.
public enum IdentityKit {

    /// Creates a verification flow view controller configured with the given settings.
    ///
    /// Present the returned view controller modally. Results are delivered via the delegate.
    ///
    /// ```swift
    /// let flow = IdentityKit.verificationFlow(configuration: config, delegate: self)
    /// present(flow, animated: true)
    /// ```
    @MainActor
    public static func verificationFlow(
        configuration: IdentityKitConfiguration,
        delegate: IdentityKitDelegate
    ) -> UIViewController {
        let coordinator = IdentityKitFlowCoordinator(
            configuration: configuration,
            delegate: delegate
        )
        coordinator.start()

        let vc = coordinator.viewController

        // Retain the coordinator on the view controller so it stays alive
        // for the lifetime of the presented flow.
        objc_setAssociatedObject(
            vc,
            &AssociatedKeys.coordinator,
            coordinator,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        return vc
    }

    /// Runs the verification flow and returns the result asynchronously.
    ///
    /// Presents the flow on the given view controller and awaits completion.
    /// Throws `IdentityKitError` on failure or cancellation.
    ///
    /// ```swift
    /// let result = try await IdentityKit.verify(configuration: config, presentingOn: self)
    /// ```
    @MainActor
    public static func verify(
        configuration: IdentityKitConfiguration,
        presentingOn viewController: UIViewController
    ) async throws -> VerificationResult {
        try await withCheckedThrowingContinuation { continuation in
            let bridge = AsyncDelegateBridge(continuation: continuation)

            let coordinator = IdentityKitFlowCoordinator(
                configuration: configuration,
                delegate: bridge
            )
            coordinator.start()

            // Retain both coordinator and bridge on the view controller.
            bridge.retainedCoordinator = coordinator

            let flowVC = coordinator.viewController
            objc_setAssociatedObject(
                flowVC,
                &AssociatedKeys.coordinator,
                coordinator,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            objc_setAssociatedObject(
                flowVC,
                &AssociatedKeys.bridge,
                bridge,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )

            viewController.present(flowVC, animated: true)
        }
    }
}

// MARK: - Associated Object Keys

private enum AssociatedKeys {
    nonisolated(unsafe) static var coordinator = "identitykit_coordinator"
    nonisolated(unsafe) static var bridge = "identitykit_bridge"
}

// MARK: - AsyncDelegateBridge

@MainActor
private final class AsyncDelegateBridge: IdentityKitDelegate {
    private var continuation: CheckedContinuation<VerificationResult, Error>?
    var retainedCoordinator: IdentityKitFlowCoordinator?

    init(continuation: CheckedContinuation<VerificationResult, Error>) {
        self.continuation = continuation
    }

    func identityKitDidComplete(with result: VerificationResult) {
        continuation?.resume(returning: result)
        continuation = nil
        retainedCoordinator = nil
    }

    func identityKitDidFail(with error: IdentityKitError) {
        continuation?.resume(throwing: error)
        continuation = nil
        retainedCoordinator = nil
    }

    func identityKitDidCancel() {
        continuation?.resume(throwing: IdentityKitError.cancelledByUser)
        continuation = nil
        retainedCoordinator = nil
    }

    func identityKitUploadProgress(_ progress: Double) {}
}
#endif
