#if canImport(UIKit)
import UIKit
import AVFoundation
import IdentityKitCore
import IdentityKitCapture

/// Orchestrates the full verification flow as a sequence of view controllers.
///
/// Uses the coordinator pattern to decouple navigation from individual screens.
/// The flow: Intro → Camera Permission → Document Capture → Liveness → Review → Done.
@MainActor
public final class IdentityKitFlowCoordinator {

    private let configuration: IdentityKitConfiguration
    private weak var delegate: IdentityKitDelegate?
    private let navigationController: UINavigationController

    private var capturedDocuments: [CapturedDocument] = []
    private var livenessFrames: [LivenessFrame] = []
    private var pendingDocumentChecks: [DocumentType] = []

    public var viewController: UIViewController {
        navigationController
    }

    public init(configuration: IdentityKitConfiguration, delegate: IdentityKitDelegate?) {
        self.configuration = configuration
        self.delegate = delegate

        self.navigationController = UINavigationController()
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.navigationBar.prefersLargeTitles = false

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance

        for check in configuration.enabledChecks {
            if case .document(let docType) = check {
                pendingDocumentChecks.append(docType)
            }
        }
    }

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
            self?.requestCameraAndProceed()
        }

        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelFlow)
        )

        return vc
    }

    /// Requests camera permission before proceeding to capture screens.
    private func requestCameraAndProceed() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            proceedToNextStep()

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    if granted {
                        self?.proceedToNextStep()
                    } else {
                        self?.showPermissionDeniedAlert()
                    }
                }
            }

        case .denied, .restricted:
            showPermissionDeniedAlert()

        @unknown default:
            proceedToNextStep()
        }
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "IdentityKit needs camera access to capture your document and verify your identity. Please enable it in Settings.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.delegate?.identityKitDidFail(with: .cameraPermissionDenied)
        })
        navigationController.present(alert, animated: true)
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
            self?.showErrorAlert(error)
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
            self?.showErrorAlert(error)
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

    // MARK: - Completion & Error Handling

    private func completeFlow() {
        let result = VerificationResult(
            sessionId: configuration.sessionId,
            capturedDocuments: capturedDocuments,
            livenessFrames: livenessFrames
        )
        delegate?.identityKitDidComplete(with: result)
    }

    /// Shows an error alert with retry/cancel options instead of failing silently.
    private func showErrorAlert(_ error: IdentityKitError) {
        let alert = UIAlertController(
            title: "Verification Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.navigationController.popViewController(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.delegate?.identityKitDidFail(with: error)
        })
        navigationController.present(alert, animated: true)
    }

    @objc private func cancelFlow() {
        delegate?.identityKitDidCancel()
    }

    private func restartFlow() {
        capturedDocuments.removeAll()
        livenessFrames.removeAll()

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
