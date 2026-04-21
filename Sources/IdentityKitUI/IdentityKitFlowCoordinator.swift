#if canImport(UIKit)
import UIKit
import IdentityKitCore
import IdentityKitCapture

/// Orchestrates the full verification flow as a sequence of view controllers.
///
/// Uses the coordinator pattern to decouple navigation from individual screens.
/// The flow: Intro → Document Capture (front → back if needed) → Liveness → Review → Done.
///
/// The coordinator owns a `UINavigationController` which is presented modally
/// by the host app. It reports results back via the `IdentityKitDelegate`.
@MainActor
public final class IdentityKitFlowCoordinator {

    private let configuration: IdentityKitConfiguration
    private weak var delegate: IdentityKitDelegate?
    private let navigationController: UINavigationController

    // State accumulated during the flow.
    private var capturedDocuments: [CapturedDocument] = []
    private var livenessFrames: [LivenessFrame] = []
    private var pendingDocumentChecks: [DocumentType] = []

    /// The view controller to present — a `UINavigationController` wrapping the flow.
    public var viewController: UIViewController {
        navigationController
    }

    public init(configuration: IdentityKitConfiguration, delegate: IdentityKitDelegate?) {
        self.configuration = configuration
        self.delegate = delegate

        self.navigationController = UINavigationController()
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.navigationBar.prefersLargeTitles = false

        // Apply theme to navigation bar.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance

        // Extract document types from enabled checks.
        for check in configuration.enabledChecks {
            if case .document(let docType) = check {
                pendingDocumentChecks.append(docType)
            }
        }
    }

    /// Starts the verification flow by showing the intro screen.
    public func start() {
        let intro = makeIntroViewController()
        navigationController.setViewControllers([intro], animated: false)
    }

    // MARK: - Flow Steps

    private func makeIntroViewController() -> UIViewController {
        let vc = InstructionViewController(
            title: "Identity Verification",
            message: "We'll need to capture your identity document and verify your face. Please have your document ready and ensure good lighting.",
            buttonTitle: "Start",
            theme: configuration.theme
        )
        vc.onAction = { [weak self] in
            self?.proceedToNextStep()
        }

        // Cancel button.
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelFlow)
        )

        return vc
    }

    private func proceedToNextStep() {
        if !pendingDocumentChecks.isEmpty {
            let docType = pendingDocumentChecks.removeFirst()
            showDocumentCapture(for: docType, side: .front)
        } else if configuration.enabledChecks.contains(.liveness), livenessFrames.isEmpty {
            showLiveness()
        } else {
            showReview()
        }
    }

    private func showDocumentCapture(for documentType: DocumentType, side: DocumentCaptureViewController.DocumentSide) {
        let controller = DocumentCaptureController(documentType: documentType)

        let vc = DocumentCaptureViewController(
            controller: controller,
            theme: configuration.theme,
            side: side
        )

        vc.onCaptured = { [weak self] document in
            self?.capturedDocuments.append(document)
            self?.proceedToNextStep()
        }

        vc.onError = { [weak self] error in
            self?.handleError(error)
        }

        navigationController.pushViewController(vc, animated: true)
    }

    private func showLiveness() {
        let challenges = LivenessCaptureController.randomChallenges(count: 2)
        let controller = LivenessCaptureController(
            challenges: challenges,
            challengeTimeout: configuration.challengeTimeoutSeconds
        )

        let vc = LivenessViewController(
            controller: controller,
            theme: configuration.theme
        )

        vc.onCompleted = { [weak self] frames in
            self?.livenessFrames = frames
            self?.proceedToNextStep()
        }

        vc.onError = { [weak self] error in
            self?.handleError(error)
        }

        navigationController.pushViewController(vc, animated: true)
    }

    private func showReview() {
        let vc = ResultReviewViewController(
            capturedDocuments: capturedDocuments,
            livenessFrames: livenessFrames,
            theme: configuration.theme
        )

        vc.onConfirm = { [weak self] in
            self?.completeFlow()
        }

        vc.onRetake = { [weak self] in
            self?.restartFlow()
        }

        navigationController.pushViewController(vc, animated: true)
    }

    // MARK: - Completion

    private func completeFlow() {
        let result = VerificationResult(
            sessionId: configuration.sessionId,
            capturedDocuments: capturedDocuments,
            livenessFrames: livenessFrames
        )
        delegate?.identityKitDidComplete(with: result)
    }

    private func handleError(_ error: IdentityKitError) {
        delegate?.identityKitDidFail(with: error)
    }

    @objc private func cancelFlow() {
        delegate?.identityKitDidCancel()
    }

    private func restartFlow() {
        capturedDocuments.removeAll()
        livenessFrames.removeAll()

        // Re-populate pending doc checks.
        pendingDocumentChecks.removeAll()
        for check in configuration.enabledChecks {
            if case .document(let docType) = check {
                pendingDocumentChecks.append(docType)
            }
        }

        navigationController.popToRootViewController(animated: true)
    }
}
#endif
