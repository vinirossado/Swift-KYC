#if canImport(UIKit)
import UIKit
import IdentityKitCore

/// Displays captured document images for user review before submission.
///
/// Allows the user to confirm or retake the capture.
public final class ResultReviewViewController: UIViewController {

    private let capturedDocuments: [CapturedDocument]
    private let livenessFrames: [LivenessFrame]
    private let theme: IdentityKitTheme

    /// Callback when the user confirms the captures.
    public var onConfirm: (() -> Void)?

    /// Callback when the user wants to retake.
    public var onRetake: (() -> Void)?

    // MARK: - UI Elements

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private lazy var stackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 16
        sv.alignment = .fill
        return sv
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ThemeApplier.titleFont(from: theme)
        label.textColor = ThemeApplier.textColor(from: theme)
        label.text = "Review your captures"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Confirm & Submit", for: .normal)
        button.titleLabel?.font = ThemeApplier.bodyFont(from: theme, style: .headline)
        button.backgroundColor = ThemeApplier.primaryColor(from: theme)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = ThemeApplier.cornerRadius(from: theme)
        button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 24, bottom: 14, right: 24)
        button.accessibilityLabel = "Confirm and submit captures"
        button.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        return button
    }()

    private lazy var retakeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Retake", for: .normal)
        button.titleLabel?.font = ThemeApplier.bodyFont(from: theme, style: .body)
        button.setTitleColor(ThemeApplier.primaryColor(from: theme), for: .normal)
        button.accessibilityLabel = "Retake captures"
        button.accessibilityHint = "Returns to the capture screen to start over"
        button.addTarget(self, action: #selector(retakeTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Init

    public init(
        capturedDocuments: [CapturedDocument],
        livenessFrames: [LivenessFrame],
        theme: IdentityKitTheme = .default
    ) {
        self.capturedDocuments = capturedDocuments
        self.livenessFrames = livenessFrames
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
        populateImages()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = ThemeApplier.backgroundColor(from: theme)

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        view.addSubview(confirmButton)
        view.addSubview(retakeButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: confirmButton.topAnchor, constant: -16),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48),

            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            confirmButton.bottomAnchor.constraint(equalTo: retakeButton.topAnchor, constant: -12),
            confirmButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),

            retakeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            retakeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func populateImages() {
        stackView.addArrangedSubview(titleLabel)

        // Document images.
        for (index, doc) in capturedDocuments.enumerated() {
            let sectionLabel = makeSectionLabel("Document \(index + 1) — \(doc.documentType.displayName)")
            stackView.addArrangedSubview(sectionLabel)

            let frontImage = makeImageView(
                data: doc.frontImageData,
                accessibilityLabel: "Front of \(doc.documentType.displayName)"
            )
            stackView.addArrangedSubview(frontImage)

            if let backData = doc.backImageData {
                let backImage = makeImageView(
                    data: backData,
                    accessibilityLabel: "Back of \(doc.documentType.displayName)"
                )
                stackView.addArrangedSubview(backImage)
            }
        }

        // Liveness frames.
        if !livenessFrames.isEmpty {
            let sectionLabel = makeSectionLabel("Liveness frames")
            stackView.addArrangedSubview(sectionLabel)

            for frame in livenessFrames {
                let imageView = makeImageView(
                    data: frame.imageData,
                    accessibilityLabel: "Liveness frame for \(frame.challenge.instructionText)"
                )
                stackView.addArrangedSubview(imageView)
            }
        }
    }

    // MARK: - Helpers

    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = ThemeApplier.bodyFont(from: theme, style: .headline)
        label.textColor = ThemeApplier.textColor(from: theme)
        label.text = text
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits = .header
        return label
    }

    private func makeImageView(data: Data, accessibilityLabel: String) -> UIImageView {
        let imageView = UIImageView()
        imageView.image = UIImage(data: data)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = ThemeApplier.cornerRadius(from: theme)
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = accessibilityLabel
        imageView.accessibilityTraits = .image
        imageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        return imageView
    }

    // MARK: - Actions

    @objc private func confirmTapped() {
        onConfirm?()
    }

    @objc private func retakeTapped() {
        onRetake?()
    }
}
#endif
