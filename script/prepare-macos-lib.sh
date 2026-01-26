#!/bin/bash
set -e

# =========================
# macOS Build Script
# =========================

# =========================
# Paths (relative to this script)
# =========================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."        # script/.. is plugin root
SRC_DIR="$ROOT_DIR/src"          # C++ code + CMakeLists.txt
LIB_DIR="$ROOT_DIR/macos/libs"
BUILD_DIR="$ROOT_DIR/build/macos"
SYSROOT_NAME="macosx"
MIN_VERSION="10.15"

if [ "$1" = "force" ]; then
    rm -rf "$LIB_DIR" "$BUILD_DIR"
else
    if [ -f "$LIB_DIR/libsuper_qr_code_scanner.a" ]; then
        echo "✅ Library already exists at: $LIB_DIR/libsuper_qr_code_scanner.a"
        exit 0
    fi
fi

mkdir -p "$LIB_DIR"
mkdir -p "$BUILD_DIR"

# =========================
# Architectures
# =========================
ARCHS=("arm64" "x86_64")   # Device + Simulator
LIBS=()

for ARCH in "${ARCHS[@]}"; do
    echo "🏗 Building for macOS architecture: $ARCH"

    ARCH_BUILD_DIR="$BUILD_DIR/$ARCH"
    mkdir -p "$ARCH_BUILD_DIR"
    cd "$ARCH_BUILD_DIR"

    SYSROOT="$SYSROOT_NAME"
    SYSTEM_NAME="Darwin"

    cmake "$SRC_DIR" \
        -G Xcode \
        -DCMAKE_SYSTEM_NAME=$SYSTEM_NAME \
        -DCMAKE_OSX_ARCHITECTURES=$ARCH \
        -DCMAKE_OSX_SYSROOT=$SYSROOT \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=$MIN_VERSION \
        -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY="-" \
        -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED=NO \
        -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO \
        -DCMAKE_BUILD_TYPE=Release

    cmake --build . --config Release

    LIB_PATH=$(find "$PWD" -name "libsuper_qr_code_scanner.a" | head -n1)
    if [[ ! -f "$LIB_PATH" ]]; then
        echo "❌ libsuper_qr_code_scanner.a not found for $ARCH - skipping"
    else
        # Set up dependency library paths
        OPENCV_LIB_DIR="$SRC_DIR/opencv/libs/macos-$ARCH"
        ZXING_LIB_DIR="$SRC_DIR/zxing/libs/macos-$ARCH"
        
        # Only include the OpenCV libraries that are actually used
        OPENCV_LIBS="$OPENCV_LIB_DIR/libopencv_core.a $OPENCV_LIB_DIR/libopencv_imgcodecs.a $OPENCV_LIB_DIR/libopencv_imgproc.a"
        # Add 3rdparty dependencies (excluding zlib which is linked as system library)
        for lib in "$OPENCV_LIB_DIR"/liblib*.a; do
            if [[ "$lib" != *zlib* ]]; then
                OPENCV_LIBS="$OPENCV_LIBS $lib"
            fi
        done
        ZXING_LIB="$ZXING_LIB_DIR/libZXing.a"
        
        echo "📚 OpenCV libs: $OPENCV_LIBS"
        echo "📚 ZXing lib: $ZXING_LIB"
        
        # Combine with dependencies using libtool
        COMBINED_LIB="$ARCH_BUILD_DIR/libsuper_qr_code_scanner_combined.a"
        
        # Use libtool to combine all libraries
        libtool -static -o "$COMBINED_LIB" "$LIB_PATH" $OPENCV_LIBS "$ZXING_LIB"
        
        LIBS+=("$COMBINED_LIB")
    fi
done

if [ ${#LIBS[@]} -eq 0 ]; then
    echo "❌ No libraries built successfully"
    exit 1
fi

echo "⚡ Creating fat library for macOS..."
lipo -create "${LIBS[@]}" -output "$LIB_DIR/libsuper_qr_code_scanner.a"

echo "✅ Fat library created at: $LIB_DIR/libsuper_qr_code_scanner.a"

# Clean up intermediate combined libraries
rm -f "${LIBS[@]}"
