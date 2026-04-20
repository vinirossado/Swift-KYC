import SwiftUI
import IdentityKitCore

/// Wraps the SDK's UIKit verification flow in a SwiftUI sheet.
///
/// On a real device this would present the camera-based flow.
/// In the simulator (no camera), it shows a mock flow that
/// generates synthetic data to demonstrate the result screen.
struct VerificationFlowView: View {
    @ObservedObject var viewModel: VerificationViewModel
    @State private var currentStep = 0
    @State private var isProcessing = false

    private let steps = [
        "Preparing camera...",
        "Capturing document front...",
        "Capturing document back...",
        "Performing liveness check...",
        "Processing..."
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Progress indicator
                ProgressView(value: Double(currentStep), total: Double(steps.count))
                    .padding(.horizontal, 40)

                Image(systemName: iconForStep)
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                    .opacity(isProcessing ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isProcessing)

                Text(steps[min(currentStep, steps.count - 1)])
                    .font(.headline)
                    .multilineTextAlignment(.center)

                if viewModel.simulateNetworkFailure && currentStep >= 4 {
                    Label("Network failure simulated", systemImage: "wifi.slash")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.handleCancel()
                    }
                }
            }
            .task {
                await runMockFlow()
            }
        }
    }

    private var iconForStep: String {
        switch currentStep {
        case 0: return "camera.fill"
        case 1: return "doc.text.viewfinder"
        case 2: return "doc.text.viewfinder"
        case 3: return "faceid"
        default: return "arrow.up.circle"
        }
    }

    private func runMockFlow() async {
        isProcessing = true

        for step in 0..<steps.count {
            currentStep = step
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s per step
        }

        if viewModel.simulateNetworkFailure {
            isProcessing = false
            viewModel.handleError("Upload failed: Network connection lost (simulated)")
            return
        }

        // Generate mock result.
        let mockDocImage = generateMockDocumentImage()
        let result = VerificationResultData(
            sessionId: "session-\(UUID().uuidString.prefix(8))",
            documentImages: [
                DocumentImageData(
                    typeName: "Passport",
                    frontData: mockDocImage,
                    backData: nil
                )
            ],
            livenessFrameCount: 3,
            completedAt: Date(),
            metadata: [
                "device": "iPhone (Simulator)",
                "sdk_version": "1.0.0",
                "environment": viewModel.selectedEnvironment.rawValue
            ]
        )

        isProcessing = false
        viewModel.handleResult(result)
    }

    /// Generates a simple colored rectangle as mock document image data.
    private func generateMockDocumentImage() -> Data {
        let size = CGSize(width: 400, height: 260)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            // Background
            UIColor.systemBlue.withAlphaComponent(0.15).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // Border
            UIColor.systemBlue.setStroke()
            let borderRect = CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)
            ctx.cgContext.setLineWidth(2)
            ctx.cgContext.stroke(borderRect)

            // Text
            let text = "MOCK PASSPORT" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.systemBlue
            ]
            let textSize = text.size(withAttributes: attrs)
            text.draw(
                at: CGPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2),
                withAttributes: attrs
            )
        }
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }
}

#Preview {
    VerificationFlowView(viewModel: VerificationViewModel())
}
