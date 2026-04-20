import SwiftUI

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

                // Debug toggles
                VStack(spacing: 12) {
                    Toggle("Simulate network failure", isOn: $viewModel.simulateNetworkFailure)

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
            .sheet(isPresented: $viewModel.showingVerification) {
                VerificationFlowView(viewModel: viewModel)
            }
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
