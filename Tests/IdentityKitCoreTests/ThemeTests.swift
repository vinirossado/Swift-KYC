import XCTest
@testable import IdentityKitCore

final class ThemeTests: XCTestCase {

    func testDefaultThemeValues() {
        let theme = IdentityKitTheme.default

        XCTAssertEqual(theme.primaryColorHex, "#007AFF")
        XCTAssertEqual(theme.backgroundColorHex, "#FFFFFF")
        XCTAssertEqual(theme.textColorHex, "#000000")
        XCTAssertEqual(theme.cornerRadius, 12.0)
        XCTAssertNil(theme.fontName)
    }

    func testCustomTheme() {
        let theme = IdentityKitTheme(
            primaryColorHex: "#FF0000",
            backgroundColorHex: "#111111",
            textColorHex: "#EEEEEE",
            cornerRadius: 8.0,
            fontName: "Avenir-Medium"
        )

        XCTAssertEqual(theme.primaryColorHex, "#FF0000")
        XCTAssertEqual(theme.backgroundColorHex, "#111111")
        XCTAssertEqual(theme.textColorHex, "#EEEEEE")
        XCTAssertEqual(theme.cornerRadius, 8.0)
        XCTAssertEqual(theme.fontName, "Avenir-Medium")
    }
}
