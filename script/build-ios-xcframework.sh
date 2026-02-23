#!/bin/bash
set -e

# =========================
# Path Resolution
# =========================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

BUILD_DIR="$SCRIPT_DIR/build"
INSTALL_DIR="$SCRIPT_DIR/install"
DIST_LOCAL="$SCRIPT_DIR/dist"

FRAMEWORK_NAME="super_qr_code_scanner.framework"
XC_NAME="super_qr_code_scanner-ios.xcframework"
ZIP_NAME="$XC_NAME.zip"

rm -rf "$BUILD_DIR" "$INSTALL_DIR" "$DIST_LOCAL"
mkdir -p "$BUILD_DIR" "$INSTALL_DIR" "$DIST_LOCAL"

FINAL_DIST="$REPO_ROOT/artifacts/dist"
[ ! -d "$FINAL_DIST" ] && mkdir -p "$FINAL_DIST"

echo ""
echo "🏠 Repo root   : $REPO_ROOT"
echo "🚀 Script dir  : $SCRIPT_DIR"
echo "🔌 Plugin root : $PLUGIN_ROOT"
echo "📦 Build dir   : $BUILD_DIR"
echo "📦 Install dir : $INSTALL_DIR"
echo "📦 Dist local  : $DIST_LOCAL"
echo "📦 Final dist  : $FINAL_DIST"
echo ""

# =========================
# Build iOS Framework
# =========================
build_ios() {
  SDK=$1
  ARCH=$2
  OUT=$3

  echo ""
  echo "🚀 Building iOS framework: $SDK | $ARCH"

  cmake -S "$PLUGIN_ROOT/src" \
        -B "$BUILD_DIR/$OUT" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_SYSROOT=$SDK \
        -DCMAKE_OSX_ARCHITECTURES=$ARCH \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
        -DIOS_BUILD_FRAMEWORK=ON \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR/$OUT"

  cmake --build "$BUILD_DIR/$OUT" --config Release
  cmake --install "$BUILD_DIR/$OUT"

  echo "✅ $OUT build complete"

  echo "🔍 Slice:"
  lipo -info "$INSTALL_DIR/$OUT/lib/$FRAMEWORK_NAME/super_qr_code_scanner"
}

# Device
build_ios iphoneos arm64 ios-device

# Simulator (Intel only)
build_ios iphonesimulator x86_64 ios-simulator

# =========================
# Create XCFramework
# =========================
echo ""
echo "📦 Creating iOS XCFramework..."

xcodebuild -create-xcframework \
  -framework "$INSTALL_DIR/ios-device/lib/$FRAMEWORK_NAME" \
  -framework "$INSTALL_DIR/ios-simulator/lib/$FRAMEWORK_NAME" \
  -output "$DIST_LOCAL/$XC_NAME"

# =========================
# Zip XCFramework
# =========================
cd "$DIST_LOCAL"
zip -r "$ZIP_NAME" "$XC_NAME"

[ -f "$FINAL_DIST/$ZIP_NAME" ] && rm "$FINAL_DIST/$ZIP_NAME"

# =========================
# Move artifact
# =========================
mv "$ZIP_NAME" "$FINAL_DIST/"

# =========================
# Compute SwiftPM checksum
# =========================
echo ""
echo "🔐 Computing SwiftPM checksum..."

CHECKSUM=$(swift package compute-checksum "$FINAL_DIST/$ZIP_NAME")

echo ""
echo "✅ SwiftPM Checksum:"
echo "   $CHECKSUM"
echo ""
echo "📋 Use it inside Package.swift:"
echo "   checksum: \"$CHECKSUM\""

# =========================
# Cleanup
# =========================
cd "$SCRIPT_DIR"
rm -rf "$BUILD_DIR" "$INSTALL_DIR" "$DIST_LOCAL"

echo ""
echo "🎉 Build complete!"
echo "📦 Artifact:"
echo "   $FINAL_DIST/$ZIP_NAME"