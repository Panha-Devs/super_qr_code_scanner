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
XC_NAME="super_qr_code_scanner-macos.xcframework"
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
# Build Framework Per Arch
# =========================
build_arch() {
  ARCH=$1

  echo ""
  echo "🚀 Building macOS framework for $ARCH"

  cmake -S "$PLUGIN_ROOT/src" \
        -B "$BUILD_DIR/$ARCH" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_ARCHITECTURES=$ARCH \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=10.15 \
        -DMACOS_BUILD_FRAMEWORK=ON \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR/$ARCH"

  cmake --build "$BUILD_DIR/$ARCH" --config Release
  cmake --install "$BUILD_DIR/$ARCH"

  echo "✅ $ARCH build complete"

  # =========================
  # Verify Framework
  # =========================
  echo ""
  echo "🔍 Verifying framework arch slices:"
  lipo -info "$INSTALL_DIR/$ARCH/lib/$FRAMEWORK_NAME/super_qr_code_scanner"
}

build_arch arm64
build_arch x86_64

# =========================
# Create Universal macOS Framework
# =========================
echo ""
echo "🧬 Creating universal macOS framework..."

UNIVERSAL_DIR="$BUILD_DIR/universal"
mkdir -p "$UNIVERSAL_DIR"

cp -R "$INSTALL_DIR/arm64/lib/$FRAMEWORK_NAME" "$UNIVERSAL_DIR/"

BIN_ARM="$INSTALL_DIR/arm64/lib/$FRAMEWORK_NAME/super_qr_code_scanner"
BIN_X64="$INSTALL_DIR/x86_64/lib/$FRAMEWORK_NAME/super_qr_code_scanner"
BIN_UNI="$UNIVERSAL_DIR/$FRAMEWORK_NAME/super_qr_code_scanner"

lipo -create "$BIN_ARM" "$BIN_X64" -output "$BIN_UNI"

echo "✅ Universal framework created:"
lipo -info "$BIN_UNI"

# =========================
# Create XCFramework
# =========================
echo ""
echo "📦 Creating macOS XCFramework..."

xcodebuild -create-xcframework \
  -framework "$UNIVERSAL_DIR/$FRAMEWORK_NAME" \
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