#if canImport(UIKit)
import UIKit
import IdentityKitCore

/// A reusable screen showing a title, message, and action button.
///
/// Used for intro screens, error recovery, and between-step instructions.
/// Fully supports Dynamic Type, VoiceOver, dark mode, and RTL.
final class InstructionViewController: UIViewController {

    private let titleText: String
    private let message: String
    private let buttonTitle: String
    private let theme: IdentityKitTheme

    var onAction: (() -> Void)?

    // MARK: - UI Elements

    private lazy var iconImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .light)
        let image = UIImage(systemName: "person.text.rectangle", withConfiguration: config)
        let iv = UIImageView(image: image)
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = ThemeApplier.primaryColor(from: theme)
        iv.contentMode = .scaleAspectFit
        iv.isAccessibilityElement = false
        return iv
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = ThemeApplier.titleFont(from: theme)
        label.textColor = ThemeApplier.textColor(from: theme)
        label.text = titleText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = ThemeApplier.bodyFont(from: theme)
        label.textColor = ThemeApplier.textColor(from: theme).withAlphaComponent(0.7)
        label.text = message
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(buttonTitle, for: .normal)
        button.titleLabel?.font = ThemeApplier.bodyFont(from: theme, style: .headline)
        button.backgroundColor = ThemeApplier.primaryColor(from: theme)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = ThemeApplier.cornerRadius(from: theme)
        button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 24, bottom: 14, right: 24)
        button.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Init

    init(
        title: String,
        message: String,
        buttonTitle: String,
        theme: IdentityKitTheme = .default
    ) {
        self.titleText = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = ThemeApplier.backgroundColor(from: theme)

        view.addSubview(iconImageView)
        view.addSubview(titleLabel)
        view.addSubview(messageLabel)
        view.addSubview(actionButton)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconImageView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -24),
            iconImageView.widthAnchor.constraint(equalToConstant: 64),
            iconImageView.heightAnchor.constraint(equalToConstant: 64),

            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 32),
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
    }

    @objc private func actionTapped() {
        onAction?()
    }
}
#endif
