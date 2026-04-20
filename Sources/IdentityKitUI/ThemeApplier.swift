#if canImport(UIKit)
import UIKit
import IdentityKitCore

/// Converts `IdentityKitTheme` values into UIKit types for use in view controllers.
///
/// Centralizes hex→UIColor conversion and font resolution so individual
/// VCs don't duplicate this logic.
enum ThemeApplier {

    static func primaryColor(from theme: IdentityKitTheme) -> UIColor {
        UIColor(hex: theme.primaryColorHex) ?? .systemBlue
    }

    static func backgroundColor(from theme: IdentityKitTheme) -> UIColor {
        UIColor(hex: theme.backgroundColorHex) ?? .systemBackground
    }

    static func textColor(from theme: IdentityKitTheme) -> UIColor {
        UIColor(hex: theme.textColorHex) ?? .label
    }

    static func cornerRadius(from theme: IdentityKitTheme) -> CGFloat {
        CGFloat(theme.cornerRadius)
    }

    /// Returns a Dynamic Type-aware font, using the custom font name if specified.
    static func bodyFont(from theme: IdentityKitTheme, style: UIFont.TextStyle = .body) -> UIFont {
        if let fontName = theme.fontName,
           let font = UIFont(name: fontName, size: UIFont.preferredFont(forTextStyle: style).pointSize) {
            return UIFontMetrics(forTextStyle: style).scaledFont(for: font)
        }
        return UIFont.preferredFont(forTextStyle: style)
    }

    static func titleFont(from theme: IdentityKitTheme) -> UIFont {
        bodyFont(from: theme, style: .title2)
    }
}

// MARK: - UIColor hex initializer

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6 else { return nil }

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
#endif
