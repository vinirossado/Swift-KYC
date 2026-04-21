#!/usr/bin/env bash
#
# build-xcframework.sh
# Archives each IdentityKit module and assembles XCFrameworks.
# Output: build/<ModuleName>.xcframework
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

BUILD_DIR="$PROJECT_ROOT/build"
DEVICE_ARCHIVE="$BUILD_DIR/ios-device.xcarchive"
SIM_ARCHIVE="$BUILD_DIR/ios-simulator.xcarchive"

TARGETS=(
  IdentityKitCore
  IdentityKitNetwork
  IdentityKitCapture
  IdentityKitStorage
  IdentityKitUI
)

# ── Clean ─────────────────────────────────────────────────────
echo "==> Cleaning..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ── Archive for device ────────────────────────────────────────
echo "==> Archiving for iOS device..."
xcodebuild archive \
  -scheme IdentityKit-Package \
  -destination "generic/platform=iOS" \
  -archivePath "$DEVICE_ARCHIVE" \
  -derivedDataPath "$BUILD_DIR/dd" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  -quiet

echo "    Device archive done."

# ── Archive for simulator ─────────────────────────────────────
echo "==> Archiving for iOS Simulator..."
xcodebuild archive \
  -scheme IdentityKit-Package \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$SIM_ARCHIVE" \
  -derivedDataPath "$BUILD_DIR/dd" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  -quiet

echo "    Simulator archive done."

# ── Find where the frameworks/libs ended up ───────────────────
echo ""
echo "==> Archive contents:"
echo "    Device:"
find "$DEVICE_ARCHIVE" \( -name "*.framework" -o -name "*.a" \) -maxdepth 5 2>/dev/null | head -10
echo "    Simulator:"
find "$SIM_ARCHIVE" \( -name "*.framework" -o -name "*.a" \) -maxdepth 5 2>/dev/null | head -10

# ── Create XCFrameworks ───────────────────────────────────────
echo ""
echo "==> Creating XCFrameworks..."

SUCCESS=0
for TARGET in "${TARGETS[@]}"; do
  # Search for framework or library in the archive
  DEVICE_FW=$(find "$DEVICE_ARCHIVE" -name "$TARGET.framework" -type d 2>/dev/null | head -1)
  DEVICE_LIB=$(find "$DEVICE_ARCHIVE" -name "lib${TARGET}.a" -type f 2>/dev/null | head -1)
  SIM_FW=$(find "$SIM_ARCHIVE" -name "$TARGET.framework" -type d 2>/dev/null | head -1)
  SIM_LIB=$(find "$SIM_ARCHIVE" -name "lib${TARGET}.a" -type f 2>/dev/null | head -1)

  if [ -n "$DEVICE_FW" ] && [ -n "$SIM_FW" ]; then
    echo "    $TARGET.xcframework (framework)"
    xcodebuild -create-xcframework \
      -framework "$DEVICE_FW" \
      -framework "$SIM_FW" \
      -output "$BUILD_DIR/$TARGET.xcframework"
    SUCCESS=$((SUCCESS + 1))
  elif [ -n "$DEVICE_LIB" ] && [ -n "$SIM_LIB" ]; then
    echo "    $TARGET.xcframework (static lib)"
    xcodebuild -create-xcframework \
      -library "$DEVICE_LIB" \
      -library "$SIM_LIB" \
      -output "$BUILD_DIR/$TARGET.xcframework"
    SUCCESS=$((SUCCESS + 1))
  else
    echo "    SKIP: $TARGET"
  fi
done

echo ""
if [ $SUCCESS -gt 0 ]; then
  echo "==> $SUCCESS XCFramework(s) created:"
  du -sh "$BUILD_DIR"/*.xcframework
else
  echo "==> No XCFrameworks created."
  echo "    Check archive contents above."
fi
