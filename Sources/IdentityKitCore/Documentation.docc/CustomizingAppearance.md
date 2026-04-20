# Customizing Appearance

Match the IdentityKit verification screens to your app's brand identity.

## Overview

IdentityKit separates theme data from UIKit rendering. The ``IdentityKitTheme`` struct lives in `IdentityKitCore` (no UIKit dependency), while the `IdentityKitUI` module reads the theme at runtime and applies it to all verification screens. This means you can configure appearance without importing UIKit yourself.

### Creating a Custom Theme

Pass an ``IdentityKitTheme`` to the configuration builder:

```swift
let theme = IdentityKitTheme(
    primaryColorHex: "#1A73E8",
    backgroundColorHex: "#F8F9FA",
    textColorHex: "#202124",
    cornerRadius: 16.0,
    fontName: "Avenir-Medium"
)

let config = try IdentityKitConfiguration.Builder()
    .apiKey("ik_live_abc123")
    .sessionId("sess_9f8e7d6c")
    .theme(theme)
    .build()
```

### Theme Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `primaryColorHex` | `String` | `"#007AFF"` | Primary action color for buttons, progress indicators, and highlights. |
| `backgroundColorHex` | `String` | `"#FFFFFF"` | Background color for capture and instruction screens. |
| `textColorHex` | `String` | `"#000000"` | Text color for instructions, labels, and body copy. |
| `cornerRadius` | `Double` | `12.0` | Corner radius applied to buttons, cards, and capture overlays. |
| `fontName` | `String?` | `nil` | Custom font name. When `nil`, the SDK uses the system font. |

### Color Format

Colors are specified as hex strings with a leading `#`. The SDK supports both 6-digit (`#RRGGBB`) and 8-digit (`#RRGGBBAA`) formats:

```swift
// Opaque blue
IdentityKitTheme(primaryColorHex: "#1A73E8")

// Semi-transparent overlay
IdentityKitTheme(backgroundColorHex: "#00000080")
```

### Using the Default Theme

If you do not specify a theme, the SDK uses ``IdentityKitTheme/default`` which matches the iOS system appearance:

```swift
// These are equivalent:
let config1 = try IdentityKitConfiguration.Builder()
    .apiKey("ik_live_abc123")
    .sessionId("sess_9f8e7d6c")
    .build()

let config2 = try IdentityKitConfiguration.Builder()
    .apiKey("ik_live_abc123")
    .sessionId("sess_9f8e7d6c")
    .theme(.default)
    .build()
```

### Custom Fonts

When you set `fontName`, the SDK uses your custom font for all labels, buttons, and instruction text. Make sure the font is bundled in your app target and registered in your `Info.plist` under `UIAppFonts`:

```xml
<key>UIAppFonts</key>
<array>
    <string>Avenir-Medium.ttf</string>
</array>
```

Then reference it by its PostScript name:

```swift
IdentityKitTheme(fontName: "Avenir-Medium")
```

> Important: If the specified font name cannot be resolved at runtime, the SDK falls back to the system font silently. No error is thrown.

### What Gets Themed

The theme applies to the following UI elements across all verification screens:

- **Buttons** -- primary color fill, corner radius, and font.
- **Instruction text** -- text color and font.
- **Screen backgrounds** -- background color.
- **Capture overlay** -- primary color for the document frame guide.
- **Progress indicators** -- primary color tint.
- **Cards and panels** -- corner radius and background color.

### Dark Mode Considerations

IdentityKit does not automatically switch themes based on the system appearance mode. If your app supports dark mode, provide a different ``IdentityKitTheme`` based on the current `UITraitCollection`:

```swift
let theme: IdentityKitTheme
if traitCollection.userInterfaceStyle == .dark {
    theme = IdentityKitTheme(
        primaryColorHex: "#8AB4F8",
        backgroundColorHex: "#1C1C1E",
        textColorHex: "#FFFFFF"
    )
} else {
    theme = IdentityKitTheme(
        primaryColorHex: "#1A73E8",
        backgroundColorHex: "#F8F9FA",
        textColorHex: "#202124"
    )
}
```

## See Also

- ``IdentityKitTheme``
- <doc:GettingStarted>
