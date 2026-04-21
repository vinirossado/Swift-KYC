#if canImport(UIKit)
import XCTest
import UIKit
@testable import IdentityKitCore

/// Generates portfolio screenshots by drawing each SDK screen programmatically.
///
/// Run with: `fastlane screenshots` or `xcodebuild test ...`
/// Output: `fastlane/screenshots/`
final class ScreenshotGenerator: XCTestCase {

    private var outputDir: URL!
    private let screenSize = CGSize(width: 393, height: 852)
    private let scale: CGFloat = 3.0

    // Colors
    private let primaryBlue = UIColor(red: 0, green: 0.478, blue: 1, alpha: 1)    // #007AFF
    private let bgLight = UIColor.white
    private let bgDark = UIColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 1)   // #1C1C1E
    private let textDark = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
    private let textLight = UIColor.white
    private let mutedLight = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
    private let mutedDark = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)
    private let greenAccent = UIColor.systemGreen
    private let yellowAccent = UIColor.systemYellow

    override func setUp() {
        super.setUp()
        let root = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("fastlane/screenshots")
        outputDir = root
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
    }

    // MARK: - Test Cases

    func testScreenshot_01_IntroLight() {
        let image = drawIntroScreen(dark: false)
        save(image, name: "01_intro_light")
    }

    func testScreenshot_02_IntroDark() {
        let image = drawIntroScreen(dark: true)
        save(image, name: "02_intro_dark")
    }

    func testScreenshot_03_DocumentCapture() {
        let image = drawDocumentCaptureScreen()
        save(image, name: "03_document_capture")
    }

    func testScreenshot_04_LivenessCheck() {
        let image = drawLivenessScreen()
        save(image, name: "04_liveness_check")
    }

    func testScreenshot_05_ReviewLight() {
        let image = drawReviewScreen(dark: false)
        save(image, name: "05_review")
    }

    func testScreenshot_06_ReviewDark() {
        let image = drawReviewScreen(dark: true)
        save(image, name: "06_review_dark")
    }

    // MARK: - Intro Screen

    private func drawIntroScreen(dark: Bool) -> UIImage {
        let bg = dark ? bgDark : bgLight
        let text = dark ? textLight : textDark
        let muted = dark ? mutedDark : mutedLight

        return render { ctx, bounds in
            // Background
            bg.setFill()
            ctx.fill(bounds)

            // Status bar area
            drawStatusBar(ctx: ctx, bounds: bounds, dark: dark)

            // Icon
            let iconRect = CGRect(x: bounds.midX - 40, y: 260, width: 80, height: 80)
            drawRoundedRect(ctx: ctx, rect: iconRect, radius: 20, fill: primaryBlue.withAlphaComponent(0.12))
            drawSFSymbolPlaceholder(ctx: ctx, rect: iconRect.insetBy(dx: 16, dy: 16), color: primaryBlue, symbol: "person.text.rectangle")

            // Title
            drawText("Identity Verification", at: CGPoint(x: bounds.midX, y: 370),
                     font: .systemFont(ofSize: 26, weight: .bold), color: text, centered: true, maxWidth: 300)

            // Message
            let msg = "We'll need to capture your identity document and verify your face. Please have your document ready and ensure good lighting."
            drawText(msg, at: CGPoint(x: bounds.midX, y: 420),
                     font: .systemFont(ofSize: 15), color: muted, centered: true, maxWidth: 320)

            // Steps indicator
            let steps = ["📄 Document", "🤳 Selfie", "✅ Review"]
            let stepY: CGFloat = 530
            for (i, step) in steps.enumerated() {
                let x = 60 + CGFloat(i) * 100
                let stepRect = CGRect(x: x, y: stepY, width: 90, height: 36)
                let stepBg = dark ? UIColor.white.withAlphaComponent(0.08) : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
                drawRoundedRect(ctx: ctx, rect: stepRect, radius: 8, fill: stepBg)
                drawText(step, at: CGPoint(x: stepRect.midX, y: stepRect.midY - 7),
                         font: .systemFont(ofSize: 11, weight: .medium), color: text, centered: true, maxWidth: 86)
            }

            // Start button
            let btnRect = CGRect(x: 46, y: 700, width: 300, height: 52)
            drawRoundedRect(ctx: ctx, rect: btnRect, radius: 14, fill: primaryBlue)
            drawText("Start Verification", at: CGPoint(x: btnRect.midX, y: btnRect.midY - 8),
                     font: .systemFont(ofSize: 17, weight: .semibold), color: .white, centered: true, maxWidth: 260)

            // Cancel link
            drawText("Cancel", at: CGPoint(x: bounds.midX, y: 780),
                     font: .systemFont(ofSize: 15), color: primaryBlue, centered: true, maxWidth: 200)
        }
    }

    // MARK: - Document Capture Screen

    private func drawDocumentCaptureScreen() -> UIImage {
        return render { ctx, bounds in
            // Black background (camera)
            UIColor.black.setFill()
            ctx.fill(bounds)

            // Simulated camera gradient
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: [UIColor(white: 0.15, alpha: 1).cgColor,
                                               UIColor(white: 0.08, alpha: 1).cgColor] as CFArray,
                                      locations: [0, 1])!
            ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: bounds.height), options: [])

            // Semi-transparent overlay
            UIColor.black.withAlphaComponent(0.4).setFill()
            ctx.fill(bounds)

            // Document cutout (clear area)
            let margin: CGFloat = 36
            let cardWidth = bounds.width - margin * 2
            let cardHeight = cardWidth / 1.586
            let cardRect = CGRect(x: margin, y: (bounds.height - cardHeight) / 2 - 40, width: cardWidth, height: cardHeight)

            // Draw the clear cutout
            ctx.setBlendMode(.normal)
            UIColor(white: 0.2, alpha: 0.3).setFill()
            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 12)
            cardPath.fill()

            // Dashed border
            UIColor.white.withAlphaComponent(0.7).setStroke()
            ctx.setLineWidth(2.5)
            ctx.setLineDash(phase: 0, lengths: [10, 6])
            cardPath.stroke()
            ctx.setLineDash(phase: 0, lengths: [])

            // Corner markers
            drawCornerMarkers(ctx: ctx, rect: cardRect, color: greenAccent, length: 30, width: 3)

            // Instruction label
            drawText("Position the front of your document",
                     at: CGPoint(x: bounds.midX, y: 100),
                     font: .systemFont(ofSize: 18, weight: .semibold), color: .white, centered: true, maxWidth: 340)

            // Quality indicator
            drawPill(ctx: ctx, text: "✓ Ready — tap to capture", center: CGPoint(x: bounds.midX, y: bounds.height - 160),
                     font: .systemFont(ofSize: 14, weight: .medium), textColor: greenAccent,
                     bgColor: greenAccent.withAlphaComponent(0.15), padding: CGSize(width: 16, height: 8), radius: 16)

            // Capture button
            let btnCenter = CGPoint(x: bounds.midX, y: bounds.height - 80)
            drawCaptureButton(ctx: ctx, center: btnCenter, radius: 34, color: primaryBlue)
        }
    }

    // MARK: - Liveness Screen

    private func drawLivenessScreen() -> UIImage {
        return render { ctx, bounds in
            // Black background
            UIColor.black.setFill()
            ctx.fill(bounds)

            // Gradient
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: [UIColor(white: 0.12, alpha: 1).cgColor,
                                               UIColor(white: 0.05, alpha: 1).cgColor] as CFArray,
                                      locations: [0, 1])!
            ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: bounds.height), options: [])

            // Semi-transparent overlay
            UIColor.black.withAlphaComponent(0.4).setFill()
            ctx.fill(bounds)

            // Oval cutout
            let ovalWidth = bounds.width * 0.6
            let ovalHeight = ovalWidth * 1.35
            let ovalRect = CGRect(x: (bounds.width - ovalWidth) / 2,
                                  y: (bounds.height - ovalHeight) / 2 - 40,
                                  width: ovalWidth, height: ovalHeight)

            // Oval fill (simulated face area)
            UIColor(white: 0.18, alpha: 0.4).setFill()
            let ovalPath = UIBezierPath(ovalIn: ovalRect)
            ovalPath.fill()

            // Oval border
            greenAccent.setStroke()
            ctx.setLineWidth(3)
            ovalPath.stroke()

            // Animated ring effect
            let outerOval = ovalRect.insetBy(dx: -8, dy: -8)
            greenAccent.withAlphaComponent(0.3).setStroke()
            ctx.setLineWidth(1.5)
            UIBezierPath(ovalIn: outerOval).stroke()

            // Challenge text
            drawText("Turn your head to the right →",
                     at: CGPoint(x: bounds.midX, y: 100),
                     font: .systemFont(ofSize: 22, weight: .bold), color: .white, centered: true, maxWidth: 320)

            // Feedback
            drawPill(ctx: ctx, text: "Great!", center: CGPoint(x: bounds.midX, y: bounds.height - 130),
                     font: .systemFont(ofSize: 15, weight: .medium), textColor: greenAccent,
                     bgColor: greenAccent.withAlphaComponent(0.15), padding: CGSize(width: 20, height: 8), radius: 16)

            // Progress bar
            let barY = bounds.height - 70
            let barRect = CGRect(x: 40, y: barY, width: bounds.width - 80, height: 4)
            UIColor.white.withAlphaComponent(0.2).setFill()
            UIBezierPath(roundedRect: barRect, cornerRadius: 2).fill()

            let filledRect = CGRect(x: 40, y: barY, width: (bounds.width - 80) * 0.75, height: 4)
            primaryBlue.setFill()
            UIBezierPath(roundedRect: filledRect, cornerRadius: 2).fill()

            // Progress label
            drawText("Challenge 2 of 3",
                     at: CGPoint(x: bounds.midX, y: barY - 20),
                     font: .systemFont(ofSize: 12, weight: .medium), color: mutedDark, centered: true, maxWidth: 200)
        }
    }

    // MARK: - Review Screen

    private func drawReviewScreen(dark: Bool) -> UIImage {
        let bg = dark ? bgDark : bgLight
        let text = dark ? textLight : textDark
        let muted = dark ? mutedDark : mutedLight
        let cardBg = dark ? UIColor(white: 0.16, alpha: 1) : UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1)

        return render { ctx, bounds in
            bg.setFill()
            ctx.fill(bounds)

            drawStatusBar(ctx: ctx, bounds: bounds, dark: dark)

            // Nav bar
            let navBg = dark ? UIColor(white: 0.13, alpha: 1) : UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1)
            navBg.setFill()
            ctx.fill(CGRect(x: 0, y: 44, width: bounds.width, height: 50))
            drawText("Review", at: CGPoint(x: bounds.midX, y: 57),
                     font: .systemFont(ofSize: 17, weight: .semibold), color: text, centered: true, maxWidth: 200)

            // Title
            drawText("Review your captures", at: CGPoint(x: bounds.midX, y: 120),
                     font: .systemFont(ofSize: 22, weight: .bold), color: text, centered: true, maxWidth: 340)

            // Document section
            var y: CGFloat = 160
            drawText("Document 1 — Passport", at: CGPoint(x: 24, y: y),
                     font: .systemFont(ofSize: 15, weight: .semibold), color: text, centered: false, maxWidth: 300)
            y += 30

            // Document image placeholder
            let docRect = CGRect(x: 24, y: y, width: bounds.width - 48, height: 170)
            drawDocumentPlaceholder(ctx: ctx, rect: docRect, text: dark ? "ID CARD" : "PASSPORT", bgColor: cardBg, accentColor: primaryBlue)
            y += 190

            // Quality badge
            drawPill(ctx: ctx, text: "Quality: 95%", center: CGPoint(x: 80, y: y),
                     font: .systemFont(ofSize: 11, weight: .medium), textColor: greenAccent,
                     bgColor: greenAccent.withAlphaComponent(0.12), padding: CGSize(width: 10, height: 5), radius: 10)
            y += 40

            // Liveness section
            drawText("Liveness frames", at: CGPoint(x: 24, y: y),
                     font: .systemFont(ofSize: 15, weight: .semibold), color: text, centered: false, maxWidth: 300)
            y += 30

            // Liveness thumbnails
            let thumbSize: CGFloat = 80
            for i in 0..<3 {
                let thumbRect = CGRect(x: 24 + CGFloat(i) * (thumbSize + 10), y: y, width: thumbSize, height: thumbSize)
                drawRoundedRect(ctx: ctx, rect: thumbRect, radius: 10, fill: cardBg)
                let emoji = ["🙂", "→", "✓"][i]
                drawText(emoji, at: CGPoint(x: thumbRect.midX, y: thumbRect.midY - 10),
                         font: .systemFont(ofSize: 24), color: text, centered: true, maxWidth: 60)
                let label = ["Front", "Right", "Done"][i]
                drawText(label, at: CGPoint(x: thumbRect.midX, y: thumbRect.maxY - 18),
                         font: .systemFont(ofSize: 9, weight: .medium), color: muted, centered: true, maxWidth: thumbSize)
            }
            y += thumbSize + 25

            // Flow screenshots section
            drawText("Flow screenshots", at: CGPoint(x: 24, y: y),
                     font: .systemFont(ofSize: 15, weight: .semibold), color: text, centered: false, maxWidth: 300)
            y += 28

            let flowLabels = ["Introduction", "Document", "Liveness", "Review"]
            let flowColors: [UIColor] = [.systemIndigo, .systemTeal, .systemGreen, .systemOrange]
            let flowW: CGFloat = 72
            let flowH: CGFloat = 100
            for (i, label) in flowLabels.enumerated() {
                let fx = 24 + CGFloat(i) * (flowW + 8)
                let flowRect = CGRect(x: fx, y: y, width: flowW, height: flowH)
                drawRoundedRect(ctx: ctx, rect: flowRect, radius: 8, fill: flowColors[i].withAlphaComponent(0.15))
                drawRoundedRect(ctx: ctx, rect: flowRect, radius: 8, stroke: flowColors[i].withAlphaComponent(0.3), width: 1)
                drawText("📱", at: CGPoint(x: flowRect.midX, y: flowRect.midY - 14),
                         font: .systemFont(ofSize: 20), color: text, centered: true, maxWidth: 60)
                drawText(label, at: CGPoint(x: flowRect.midX, y: flowRect.maxY + 10),
                         font: .systemFont(ofSize: 9, weight: .medium), color: muted, centered: true, maxWidth: flowW)
            }
            y += flowH + 40

            // Buttons
            let confirmRect = CGRect(x: 24, y: y, width: bounds.width - 48, height: 50)
            drawRoundedRect(ctx: ctx, rect: confirmRect, radius: 14, fill: primaryBlue)
            drawText("Confirm & Submit", at: CGPoint(x: confirmRect.midX, y: confirmRect.midY - 8),
                     font: .systemFont(ofSize: 16, weight: .semibold), color: .white, centered: true, maxWidth: 260)

            drawText("Retake", at: CGPoint(x: bounds.midX, y: y + 70),
                     font: .systemFont(ofSize: 15, weight: .medium), color: primaryBlue, centered: true, maxWidth: 200)
        }
    }

    // MARK: - Drawing Helpers

    private func render(draw: (CGContext, CGRect) -> Void) -> UIImage {
        let pixelSize = CGSize(width: screenSize.width * scale, height: screenSize.height * scale)
        let renderer = UIGraphicsImageRenderer(size: pixelSize)
        return renderer.image { rendererCtx in
            let ctx = rendererCtx.cgContext
            ctx.scaleBy(x: scale, y: scale)
            let bounds = CGRect(origin: .zero, size: screenSize)
            draw(ctx, bounds)
        }
    }

    private func save(_ image: UIImage, name: String) {
        guard let pngData = image.pngData() else {
            XCTFail("Failed to generate PNG for \(name)")
            return
        }
        let fileURL = outputDir.appendingPathComponent("\(name).png")
        do {
            try pngData.write(to: fileURL)
            print("📸 Screenshot saved: \(fileURL.path)")
        } catch {
            XCTFail("Failed to write \(name): \(error)")
        }

        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func drawText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor,
                          centered: Bool, maxWidth: CGFloat) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = centered ? .center : .left
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]

        let textSize = (text as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: 500),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs, context: nil).size

        let origin: CGPoint
        if centered {
            origin = CGPoint(x: point.x - textSize.width / 2, y: point.y)
        } else {
            origin = point
        }

        (text as NSString).draw(
            in: CGRect(origin: origin, size: CGSize(width: maxWidth, height: textSize.height + 4)),
            withAttributes: attrs)
    }

    private func drawRoundedRect(ctx: CGContext, rect: CGRect, radius: CGFloat, fill: UIColor) {
        fill.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: radius).fill()
    }

    private func drawRoundedRect(ctx: CGContext, rect: CGRect, radius: CGFloat, stroke: UIColor, width: CGFloat) {
        stroke.setStroke()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        path.lineWidth = width
        path.stroke()
    }

    private func drawStatusBar(ctx: CGContext, bounds: CGRect, dark: Bool) {
        let color = dark ? UIColor.white : UIColor.black
        drawText("9:41", at: CGPoint(x: bounds.midX, y: 14),
                 font: .systemFont(ofSize: 14, weight: .semibold), color: color, centered: true, maxWidth: 60)
    }

    private func drawSFSymbolPlaceholder(ctx: CGContext, rect: CGRect, color: UIColor, symbol: String) {
        // Draw a simple icon placeholder
        color.setFill()
        let iconRect = rect.insetBy(dx: rect.width * 0.15, dy: rect.height * 0.15)
        let path = UIBezierPath(roundedRect: iconRect, cornerRadius: 4)
        path.fill()

        // Inner detail
        UIColor.white.withAlphaComponent(0.6).setFill()
        let innerRect = iconRect.insetBy(dx: iconRect.width * 0.2, dy: iconRect.height * 0.25)
        UIBezierPath(ovalIn: innerRect).fill()
    }

    private func drawCornerMarkers(ctx: CGContext, rect: CGRect, color: UIColor, length: CGFloat, width: CGFloat) {
        color.setStroke()
        ctx.setLineWidth(width)
        ctx.setLineDash(phase: 0, lengths: [])

        let corners: [(CGPoint, CGPoint, CGPoint)] = [
            (CGPoint(x: rect.minX, y: rect.minY + length), rect.origin, CGPoint(x: rect.minX + length, y: rect.minY)),
            (CGPoint(x: rect.maxX - length, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY + length)),
            (CGPoint(x: rect.maxX, y: rect.maxY - length), CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.maxX - length, y: rect.maxY)),
            (CGPoint(x: rect.minX + length, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY - length)),
        ]

        for (start, corner, end) in corners {
            ctx.move(to: start)
            ctx.addLine(to: corner)
            ctx.addLine(to: end)
            ctx.strokePath()
        }
    }

    private func drawCaptureButton(ctx: CGContext, center: CGPoint, radius: CGFloat, color: UIColor) {
        // Outer ring
        UIColor.white.setStroke()
        ctx.setLineWidth(3)
        let outerPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        outerPath.stroke()

        // Inner filled circle
        color.setFill()
        let innerPath = UIBezierPath(arcCenter: center, radius: radius - 6, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        innerPath.fill()
    }

    private func drawPill(ctx: CGContext, text: String, center: CGPoint, font: UIFont,
                          textColor: UIColor, bgColor: UIColor, padding: CGSize, radius: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let textSize = (text as NSString).size(withAttributes: attrs)
        let pillRect = CGRect(x: center.x - textSize.width / 2 - padding.width,
                              y: center.y - textSize.height / 2 - padding.height,
                              width: textSize.width + padding.width * 2,
                              height: textSize.height + padding.height * 2)
        drawRoundedRect(ctx: ctx, rect: pillRect, radius: radius, fill: bgColor)
        drawText(text, at: CGPoint(x: center.x, y: pillRect.minY + padding.height - 1),
                 font: font, color: textColor, centered: true, maxWidth: textSize.width + 10)
    }

    private func drawDocumentPlaceholder(ctx: CGContext, rect: CGRect, text: String, bgColor: UIColor, accentColor: UIColor) {
        drawRoundedRect(ctx: ctx, rect: rect, radius: 12, fill: bgColor)
        drawRoundedRect(ctx: ctx, rect: rect, radius: 12, stroke: accentColor.withAlphaComponent(0.2), width: 1)

        // Simulated document lines
        let lineColor = accentColor.withAlphaComponent(0.15)
        let lineHeight: CGFloat = 3
        for i in 0..<4 {
            let lineWidth = [180.0, 140.0, 160.0, 100.0][i]
            let lineRect = CGRect(x: rect.minX + 24, y: rect.minY + 40 + CGFloat(i) * 22,
                                  width: lineWidth, height: lineHeight)
            drawRoundedRect(ctx: ctx, rect: lineRect, radius: 1.5, fill: lineColor)
        }

        // Photo placeholder
        let photoRect = CGRect(x: rect.maxX - 90, y: rect.minY + 30, width: 60, height: 75)
        drawRoundedRect(ctx: ctx, rect: photoRect, radius: 6, fill: accentColor.withAlphaComponent(0.1))
        drawRoundedRect(ctx: ctx, rect: photoRect, radius: 6, stroke: accentColor.withAlphaComponent(0.2), width: 1)

        // Face icon in photo
        drawText("👤", at: CGPoint(x: photoRect.midX, y: photoRect.midY - 10),
                 font: .systemFont(ofSize: 22), color: .white, centered: true, maxWidth: 40)

        // Document label
        drawText(text, at: CGPoint(x: rect.midX, y: rect.maxY - 35),
                 font: .systemFont(ofSize: 14, weight: .bold), color: accentColor.withAlphaComponent(0.5),
                 centered: true, maxWidth: 200)
    }
}
#endif
