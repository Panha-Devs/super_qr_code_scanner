#!/bin/bash
set -e

# =========================
# Paths (relative to this script)
# =========================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."        # script/.. is plugin root
SRC_DIR="$ROOT_DIR/src"          # C++ code + CMakeLists.txt
IOS_LIB_DIR="$ROOT_DIR/ios/libs"
BUILD_DIR="$ROOT_DIR/build/ios"

if [ "$1" = "force" ]; then
    rm -rf "$IOS_LIB_DIR" "$BUILD_DIR"
else
    if [ -f "$IOS_LIB_DIR/libsuper_qr_code_scanner.a" ]; then
        echo "✅ Library already exists at: $IOS_LIB_DIR/libsuper_qr_code_scanner.a"
        exit 0
    fi
fi

mkdir -p "$IOS_LIB_DIR"
mkdir -p "$BUILD_DIR"

# =========================
# Architectures
# =========================
ARCHS=("arm64" "x86_64")   # Device + Simulator
LIBS=()

for ARCH in "${ARCHS[@]}"; do
    echo "🏗 Building for iOS architecture: $ARCH"

    ARCH_BUILD_DIR="$BUILD_DIR/$ARCH"
    mkdir -p "$ARCH_BUILD_DIR"
    cd "$ARCH_BUILD_DIR"

    if [ "$ARCH" = "arm64" ]; then
        SYSROOT="iphoneos"
    else
        SYSROOT="iphonesimulator"
    fi

    cmake "$SRC_DIR" \
        -G Xcode \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_ARCHITECTURES=$ARCH \
        -DCMAKE_OSX_SYSROOT=$SYSROOT \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
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
        OPENCV_LIB_DIR="$SRC_DIR/opencv/libs/ios-$ARCH"
        ZXING_LIB_DIR="$SRC_DIR/zxing/libs/ios-$ARCH"
        
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

# =========================
# Create fat library
# =========================
echo "⚡ Creating fat library for iOS..."
lipo -create "${LIBS[@]}" -output "$IOS_LIB_DIR/libsuper_qr_code_scanner.a"

echo "✅ Fat library created at: $IOS_LIB_DIR/libsuper_qr_code_scanner.a"
