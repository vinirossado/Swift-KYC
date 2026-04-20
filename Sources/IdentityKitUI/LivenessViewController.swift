#if canImport(UIKit)
import UIKit
import AVFoundation
import IdentityKitCore
import IdentityKitCapture

/// Displays the front camera with an oval face guide and liveness challenge instructions.
///
/// Shows animated challenge prompts and real-time feedback via VoiceOver announcements.
public final class LivenessViewController: UIViewController {

    private let controller: LivenessCaptureController
    private let theme: IdentityKitTheme

    /// Callback when all liveness challenges are completed.
    public var onCompleted: (([LivenessFrame]) -> Void)?

    /// Callback when liveness check fails.
    public var onError: ((IdentityKitError) -> Void)?

    // MARK: - UI Elements

    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: controller.captureSession.session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()

    private lazy var ovalGuideView: OvalGuideView = {
        let view = OvalGuideView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.accessibilityElementsHidden = true
        return view
    }()

    private lazy var challengeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = ThemeApplier.titleFont(from: theme)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits = .updatesFrequently
        return label
    }()

    private lazy var feedbackLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = ThemeApplier.bodyFont(from: theme, style: .subheadline)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.progressTintColor = ThemeApplier.primaryColor(from: theme)
        progress.trackTintColor = .white.withAlphaComponent(0.3)
        progress.accessibilityLabel = "Challenge progress"
        return progress
    }()

    // MARK: - Init

    public init(
        controller: LivenessCaptureController,
        theme: IdentityKitTheme = .default
    ) {
        self.controller = controller
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startLiveness()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        controller.stop()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .black
        view.layer.addSublayer(previewLayer)

        view.addSubview(ovalGuideView)
        view.addSubview(challengeLabel)
        view.addSubview(feedbackLabel)
        view.addSubview(progressView)

        NSLayoutConstraint.activate([
            ovalGuideView.topAnchor.constraint(equalTo: view.topAnchor),
            ovalGuideView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ovalGuideView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ovalGuideView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            challengeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            challengeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            challengeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            feedbackLabel.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -12),
            feedbackLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            feedbackLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            progressView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])

        view.accessibilityElements = [challengeLabel, feedbackLabel, progressView]
    }

    // MARK: - Liveness

    private func startLiveness() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.controller.start()
                await self.observeEvents()
            } catch {
                await MainActor.run {
                    self.onError?(error as? IdentityKitError ?? .internalError(reason: error.localizedDescription))
                }
            }
        }
    }

    private func observeEvents() async {
        for await event in controller.events {
            await MainActor.run { [weak self] in
                self?.handleEvent(event)
            }
        }
    }

    private func handleEvent(_ event: LivenessCaptureController.Event) {
        switch event {
        case .qualityUpdated(let quality):
            if !quality.isFramed {
                feedbackLabel.text = "Position your face in the oval"
            } else {
                feedbackLabel.text = nil
            }

        case .challengeStarted(let challenge):
            challengeLabel.text = challenge.instructionText
            progressView.setProgress(0, animated: false)

            // VoiceOver: announce the challenge instruction.
            UIAccessibility.post(
                notification: .announcement,
                argument: challenge.accessibilityInstruction
            )

            // Animate the oval guide color.
            if !UIAccessibility.isReduceMotionEnabled {
                UIView.animate(withDuration: 0.3) {
                    self.ovalGuideView.guideColor = .systemYellow
                }
            } else {
                ovalGuideView.guideColor = .systemYellow
            }

        case .challengeProgress(let progress):
            progressView.setProgress(Float(progress), animated: true)

        case .challengeCompleted(let challenge):
            feedbackLabel.text = "Great!"
            UIAccessibility.post(notification: .announcement, argument: "\(challenge.instructionText) completed")

            if !UIAccessibility.isReduceMotionEnabled {
                UIView.animate(withDuration: 0.3) {
                    self.ovalGuideView.guideColor = .systemGreen
                }
            } else {
                ovalGuideView.guideColor = .systemGreen
            }

        case .frameCaptured:
            break

        case .completed(let frames):
            UIAccessibility.post(notification: .announcement, argument: "Liveness check completed")
            onCompleted?(frames)

        case .challengeTimeout(let challenge):
            feedbackLabel.text = "Time's up — \(challenge.instructionText) timed out"
            feedbackLabel.textColor = .systemRed

        case .error(let error):
            onError?(error)
        }
    }
}

// MARK: - OvalGuideView

/// Draws a translucent overlay with an oval cutout for face positioning.
final class OvalGuideView: UIView {

    var guideColor: UIColor = .white.withAlphaComponent(0.6) {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // Semi-transparent overlay.
        context.setFillColor(UIColor.black.withAlphaComponent(0.4).cgColor)
        context.fill(rect)

        // Oval cutout in the center.
        let ovalWidth = rect.width * 0.65
        let ovalHeight = ovalWidth * 1.35  // Face oval is taller than wide.
        let ovalRect = CGRect(
            x: (rect.width - ovalWidth) / 2,
            y: (rect.height - ovalHeight) / 2 - 30,
            width: ovalWidth,
            height: ovalHeight
        )

        let ovalPath = UIBezierPath(ovalIn: ovalRect)

        // Clear the oval area.
        context.setBlendMode(.clear)
        ovalPath.fill()

        // Draw guide border.
        context.setBlendMode(.normal)
        context.setStrokeColor(guideColor.cgColor)
        context.setLineWidth(3.0)
        ovalPath.stroke()
    }
}
#endif
