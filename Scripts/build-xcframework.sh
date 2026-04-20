#!/usr/bin/env bash
#
# build-xcframework.sh
# Builds IdentityKit XCFramework for iOS device (arm64) and iOS Simulator (arm64).
# Output: build/IdentityKit.xcframework
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FRAMEWORK_NAME="IdentityKit"
SCHEME="IdentityKit"
BUILD_DIR="$PROJECT_ROOT/build"
ARCHIVE_DIR="$BUILD_DIR/archives"

DEVICE_ARCHIVE="$ARCHIVE_DIR/ios-device.xcarchive"
SIMULATOR_ARCHIVE="$ARCHIVE_DIR/ios-simulator.xcarchive"

TARGETS=(
  IdentityKitCore
  IdentityKitCapture
  IdentityKitUI
  IdentityKitNetwork
  IdentityKitStorage
)

# ── Clean previous artifacts ──────────────────────────────────
echo "==> Cleaning previous build artifacts..."
rm -rf "$BUILD_DIR"
mkdir -p "$ARCHIVE_DIR"

# ── Archive for iOS device (arm64) ────────────────────────────
echo "==> Archiving for iOS device..."
xcodebuild archive \
  -scheme "$SCHEME" \
  -destination "generic/platform=iOS" \
  -archivePath "$DEVICE_ARCHIVE" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface" \
  | tail -1

# ── Archive for iOS Simulator (arm64) ─────────────────────────
echo "==> Archiving for iOS Simulator..."
xcodebuild archive \
  -scheme "$SCHEME" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$SIMULATOR_ARCHIVE" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface" \
  | tail -1

# ── Assemble XCFramework ─────────────────────────────────────
echo "==> Creating XCFramework..."

FRAMEWORK_ARGS=()
for TARGET in "${TARGETS[@]}"; do
  FRAMEWORK_ARGS+=(
    -framework "$DEVICE_ARCHIVE/Products/Library/Frameworks/$TARGET.framework"
    -framework "$SIMULATOR_ARCHIVE/Products/Library/Frameworks/$TARGET.framework"
  )
done

xcodebuild -create-xcframework \
  "${FRAMEWORK_ARGS[@]}" \
  -output "$BUILD_DIR/$FRAMEWORK_NAME.xcframework"

echo ""
echo "==> XCFramework created at:"
echo "    $BUILD_DIR/$FRAMEWORK_NAME.xcframework"
