#if canImport(UIKit)
import UIKit
import AVFoundation
import IdentityKitCore
import IdentityKitCapture

/// Displays the camera preview with a document guide overlay.
///
/// Shows real-time quality feedback and a capture button that enables
/// only when the document is properly framed, sharp, and bright.
/// Supports Dynamic Type, VoiceOver, dark mode, and RTL layouts.
public final class DocumentCaptureViewController: UIViewController {

    // MARK: - Dependencies

    private let controller: DocumentCaptureController
    private let theme: IdentityKitTheme
    private let side: DocumentSide

    /// Which side of the document is being captured.
    public enum DocumentSide {
        case front
        case back
    }

    /// Callback when a document is captured.
    public var onCaptured: ((CapturedDocument) -> Void)?

    /// Callback when an error occurs.
    public var onError: ((IdentityKitError) -> Void)?

    // MARK: - UI Elements

    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: controller.captureSession.session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()

    private lazy var overlayView: DocumentOverlayView = {
        let view = DocumentOverlayView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = ThemeApplier.bodyFont(from: theme, style: .headline)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.text = side == .front
            ? "Position the front of your document"
            : "Now flip and position the back"
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var qualityIndicatorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = ThemeApplier.bodyFont(from: theme, style: .subheadline)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.isAccessibilityElement = true
        return label
    }()

    private lazy var captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false

        let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .light)
        button.setImage(UIImage(systemName: "circle.inset.filled", withConfiguration: config), for: .normal)
        button.tintColor = ThemeApplier.primaryColor(from: theme)
        button.isEnabled = false

        button.accessibilityLabel = "Capture document"
        button.accessibilityHint = "Takes a photo of your document when quality is acceptable"

        button.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Init

    public init(
        controller: DocumentCaptureController,
        theme: IdentityKitTheme = .default,
        side: DocumentSide = .front
    ) {
        self.controller = controller
        self.theme = theme
        self.side = side
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
        setupAccessibility()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCapture()
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

        view.addSubview(overlayView)
        view.addSubview(instructionLabel)
        view.addSubview(qualityIndicatorLabel)
        view.addSubview(captureButton)

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            qualityIndicatorLabel.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -16),
            qualityIndicatorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            qualityIndicatorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            captureButton.widthAnchor.constraint(equalToConstant: 72),
            captureButton.heightAnchor.constraint(equalToConstant: 72)
        ])
    }

    private func setupAccessibility() {
        view.accessibilityElements = [instructionLabel, qualityIndicatorLabel, captureButton]
        UIAccessibility.post(notification: .announcement, argument: instructionLabel.text)
    }

    // MARK: - Capture

    private func startCapture() {
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

    private func handleEvent(_ event: DocumentCaptureController.Event) {
        switch event {
        case .qualityUpdated(let quality):
            updateQualityUI(quality)
        case .edgeDetected(let rectangle):
            overlayView.updateGuide(with: rectangle, in: view.bounds)
        case .captured(let document):
            UIAccessibility.post(notification: .announcement, argument: "Document captured successfully")
            onCaptured?(document)
        case .error(let error):
            onError?(error)
        }
    }

    private func updateQualityUI(_ quality: CaptureQuality) {
        captureButton.isEnabled = quality.isAcceptable

        var hints: [String] = []
        if !quality.isFramed { hints.append("Move closer to frame the document") }
        if !quality.isSharp { hints.append("Hold steady for focus") }
        if !quality.isBright { hints.append("Improve lighting") }

        if quality.isAcceptable {
            qualityIndicatorLabel.text = "Ready — tap to capture"
            qualityIndicatorLabel.textColor = .systemGreen
        } else {
            qualityIndicatorLabel.text = hints.joined(separator: ". ")
            qualityIndicatorLabel.textColor = .systemYellow
        }

        qualityIndicatorLabel.accessibilityValue = qualityIndicatorLabel.text
    }

    @objc private func captureButtonTapped() {
        captureButton.isEnabled = false
        controller.triggerCapture()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

// MARK: - DocumentOverlayView

/// Draws a translucent overlay with a cutout rectangle guiding document placement.
final class DocumentOverlayView: UIView {

    private var guidePath: UIBezierPath?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func updateGuide(with rectangle: DocumentEdgeDetector.NormalizedRectangle, in bounds: CGRect) {
        let path = UIBezierPath()
        // Vision uses bottom-left origin; UIKit uses top-left.
        let tl = CGPoint(x: rectangle.topLeft.x * bounds.width, y: (1 - rectangle.topLeft.y) * bounds.height)
        let tr = CGPoint(x: rectangle.topRight.x * bounds.width, y: (1 - rectangle.topRight.y) * bounds.height)
        let br = CGPoint(x: rectangle.bottomRight.x * bounds.width, y: (1 - rectangle.bottomRight.y) * bounds.height)
        let bl = CGPoint(x: rectangle.bottomLeft.x * bounds.width, y: (1 - rectangle.bottomLeft.y) * bounds.height)

        path.move(to: tl)
        path.addLine(to: tr)
        path.addLine(to: br)
        path.addLine(to: bl)
        path.close()

        guidePath = path
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // Semi-transparent overlay.
        context.setFillColor(UIColor.black.withAlphaComponent(0.4).cgColor)
        context.fill(rect)

        if let path = guidePath {
            context.setBlendMode(.clear)
            path.fill()
            context.setBlendMode(.normal)
            context.setStrokeColor(UIColor.systemGreen.cgColor)
            context.setLineWidth(3.0)
            path.stroke()
        } else {
            // Default centered guide (ID card aspect ratio).
            let margin: CGFloat = 40
            let aspectRatio: CGFloat = 1.586
            let width = rect.width - margin * 2
            let height = width / aspectRatio
            let guideRect = CGRect(x: margin, y: (rect.height - height) / 2, width: width, height: height)

            context.setBlendMode(.clear)
            UIBezierPath(roundedRect: guideRect, cornerRadius: 12).fill()
            context.setBlendMode(.normal)
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.6).cgColor)
            context.setLineWidth(2.0)
            context.setLineDash(phase: 0, lengths: [8, 4])
            UIBezierPath(roundedRect: guideRect, cornerRadius: 12).stroke()
        }
    }
}
#endif
