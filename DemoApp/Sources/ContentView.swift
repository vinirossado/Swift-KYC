import SwiftUI
import IdentityKitCore

/// Main screen with a button to start verification and toggles for debug settings.
struct ContentView: View {
    @StateObject private var viewModel = VerificationViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "person.text.rectangle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)

                Text("IdentityKit Demo")
                    .font(.largeTitle.bold())

                Text("Tap below to start the identity verification flow.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                // Mode indicator
                #if targetEnvironment(simulator)
                Label("Simulator — Mock flow", systemImage: "desktopcomputer")
                    .font(.caption)
                    .foregroundStyle(.orange)
                #else
                Label("Device — Real camera flow", systemImage: "camera.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                #endif

                // Debug toggles
                VStack(spacing: 12) {
                    #if targetEnvironment(simulator)
                    Toggle("Simulate network failure", isOn: $viewModel.simulateNetworkFailure)
                    #endif

                    Picker("Environment", selection: $viewModel.selectedEnvironment) {
                        Text("Mock").tag(AppEnvironment.mock)
                        Text("Staging").tag(AppEnvironment.staging)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 24)

                Button {
                    viewModel.startVerification()
                } label: {
                    Label("Start Verification", systemImage: "checkmark.shield")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 24)

                Spacer()
            }
            .navigationTitle("Demo")
            .navigationBarTitleDisplayMode(.inline)

            // Simulator: mock SwiftUI flow
            #if targetEnvironment(simulator)
            .sheet(isPresented: $viewModel.showingVerification) {
                VerificationFlowView(viewModel: viewModel)
            }
            #else
            // Device: real SDK flow with camera
            .fullScreenCover(isPresented: $viewModel.showingVerification) {
                if let config = try? viewModel.buildConfiguration() {
                    SDKFlowBridge(
                        configuration: config,
                        onComplete: { result in
                            let data = VerificationResultData(
                                sessionId: result.sessionId,
                                documentImages: result.capturedDocuments.map {
                                    DocumentImageData(
                                        typeName: $0.documentType.displayName,
                                        frontData: $0.frontImageData,
                                        backData: $0.backImageData
                                    )
                                },
                                livenessFrameCount: result.livenessFrames.count,
                                completedAt: result.completedAt,
                                metadata: result.clientMetadata
                            )
                            viewModel.handleResult(data)
                        },
                        onError: { error in
                            viewModel.handleError(error.localizedDescription)
                        },
                        onCancel: {
                            viewModel.handleCancel()
                        }
                    )
                    .ignoresSafeArea()
                }
            }
            #endif

            .sheet(isPresented: $viewModel.showingResult) {
                if let result = viewModel.verificationResult {
                    ResultView(result: result) {
                        viewModel.showingResult = false
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

#Preview {
    ContentView()
}
