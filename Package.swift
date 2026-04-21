// swift-tools-version: 5.10

import PackageDescription

let strictConcurrency: SwiftSetting = .enableExperimentalFeature("StrictConcurrency")

let package = Package(
    name: "IdentityKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "IdentityKit",
            targets: [
                "IdentityKitCore",
                "IdentityKitCapture",
                "IdentityKitUI",
                "IdentityKitNetwork",
                "IdentityKitStorage"
            ]
        ),
        .library(name: "IdentityKitCore", targets: ["IdentityKitCore"]),
        .library(name: "IdentityKitCapture", targets: ["IdentityKitCapture"]),
        .library(name: "IdentityKitUI", targets: ["IdentityKitUI"]),
        .library(name: "IdentityKitNetwork", targets: ["IdentityKitNetwork"]),
        .library(name: "IdentityKitStorage", targets: ["IdentityKitStorage"])
    ],
    targets: [
        // MARK: - Core
        .target(
            name: "IdentityKitCore",
            swiftSettings: [strictConcurrency]
        ),

        // MARK: - Capture
        .target(
            name: "IdentityKitCapture",
            dependencies: ["IdentityKitCore"],
            swiftSettings: [strictConcurrency]
        ),

        // MARK: - UI
        .target(
            name: "IdentityKitUI",
            dependencies: ["IdentityKitCore", "IdentityKitCapture"],
            swiftSettings: [strictConcurrency]
        ),

        // MARK: - Network
        .target(
            name: "IdentityKitNetwork",
            dependencies: ["IdentityKitCore"],
            swiftSettings: [strictConcurrency]
        ),

        // MARK: - Storage
        .target(
            name: "IdentityKitStorage",
            dependencies: ["IdentityKitCore"],
            swiftSettings: [strictConcurrency]
        ),

        // MARK: - Tests
        .testTarget(
            name: "IdentityKitCoreTests",
            dependencies: ["IdentityKitCore"],
            swiftSettings: [strictConcurrency]
        ),
        .testTarget(
            name: "IdentityKitCaptureTests",
            dependencies: ["IdentityKitCapture"],
            swiftSettings: [strictConcurrency]
        ),
        .testTarget(
            name: "IdentityKitNetworkTests",
            dependencies: ["IdentityKitNetwork"],
            swiftSettings: [strictConcurrency]
        ),
        .testTarget(
            name: "IdentityKitIntegrationTests",
            dependencies: [
                "IdentityKitCore",
                "IdentityKitNetwork",
                "IdentityKitStorage"
            ],
            swiftSettings: [strictConcurrency]
        ),
        .testTarget(
            name: "IdentityKitSnapshotTests",
            dependencies: [
                "IdentityKitCore",
                "IdentityKitUI"
            ],
            swiftSettings: [strictConcurrency]
        )
    ]
)
