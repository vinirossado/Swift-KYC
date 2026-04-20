import SwiftUI

/// Displays the verification result with document thumbnails and metadata.
struct ResultView: View {
    let result: VerificationResultData
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Success header
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.green)
                        Text("Verification Complete")
                            .font(.title2.bold())
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top)

                    Divider()

                    // Session info
                    InfoSection(title: "Session") {
                        InfoRow(label: "Session ID", value: result.sessionId)
                        InfoRow(label: "Completed", value: result.completedAt.formatted())
                        InfoRow(label: "Liveness Frames", value: "\(result.livenessFrameCount)")
                    }

                    // Documents
                    InfoSection(title: "Captured Documents") {
                        ForEach(result.documentImages) { doc in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(doc.typeName)
                                    .font(.subheadline.bold())

                                if let uiImage = UIImage(data: doc.frontData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .accessibilityLabel("Front of \(doc.typeName)")
                                }

                                if let backData = doc.backData, let backImage = UIImage(data: backData) {
                                    Image(uiImage: backImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .accessibilityLabel("Back of \(doc.typeName)")
                                }
                            }
                        }
                    }

                    // Metadata
                    if !result.metadata.isEmpty {
                        InfoSection(title: "Client Metadata") {
                            ForEach(result.metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                InfoRow(label: key, value: value)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Reusable components

private struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            content
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.monospaced())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

#Preview {
    ResultView(
        result: VerificationResultData(
            sessionId: "session-abc123",
            documentImages: [],
            livenessFrameCount: 3,
            completedAt: Date(),
            metadata: ["device": "iPhone 15", "sdk_version": "1.0.0"]
        ),
        onDismiss: {}
    )
}
