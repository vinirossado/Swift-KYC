import Foundation

/// Visual theme configuration for IdentityKit UI elements.
///
/// Core module defines the theme data; the UI module applies it.
/// This keeps Core free of UIKit imports while allowing host apps
/// to customize colors via hex strings.
public struct IdentityKitTheme: Sendable {

    /// Primary action color (hex string, e.g., "#007AFF").
    public let primaryColorHex: String

    /// Background color for capture screens.
    public let backgroundColorHex: String

    /// Text color for instructions and labels.
    public let textColorHex: String

    /// Corner radius for buttons and cards.
    public let cornerRadius: Double

    /// Whether to use the system font or a custom font name.
    public let fontName: String?

    public init(
        primaryColorHex: String = "#007AFF",
        backgroundColorHex: String = "#FFFFFF",
        textColorHex: String = "#000000",
        cornerRadius: Double = 12.0,
        fontName: String? = nil
    ) {
        self.primaryColorHex = primaryColorHex
        self.backgroundColorHex = backgroundColorHex
        self.textColorHex = textColorHex
        self.cornerRadius = cornerRadius
        self.fontName = fontName
    }

    /// The default theme matching iOS system appearance.
    public static let `default` = IdentityKitTheme()
}
