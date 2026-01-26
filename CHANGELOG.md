# CHANGELOG

## [1.0.7]
- Fixed error when launch on ios
- Update script to build ios native lib
- Update readme info for setup development
- Add version when call setup script

## [1.0.6]
- Fix setup script to properly handle both relative and absolute rootUri paths in package_config.json

## [1.0.5]
- Update setup script to find path to save fetch libs correctly

## [1.0.4]
- Update archive dependency to ^4.0.0 for better compatibility with other packages

## [1.0.3]
- Add logic to request binaries base on platform request
- Improve performance and add thread and non-blocking UI
- Enchantment for functionality

## [1.0.2]
- Add example folder for demo use cases

## [1.0.1]
- Update latest version for flutter lints

## [1.0.0]

### 🎉 Initial Release - Production Ready!

**Zero Setup Required!** The package is now completely self-contained.

### Added

#### Core Features
- Multi-platform QR code scanning (Android, iOS, macOS, Linux, Windows)
- FFI-based native integration with OpenCV and ZXing
- Multiple QR code detection in single image (up to 50 codes)
- 6 advanced detection strategies for high accuracy:
  1. Original image with aggressive options
  2. Multi-scale processing (0.5x, 1.5x, 2.0x, 2.5x, 3.0x)
  3. Histogram equalization for contrast improvement
  4. Adaptive thresholding (Otsu and adaptive)
  5. Inverted grayscale scanning
  6. Sharpened image with kernel filter
- Duplicate detection to avoid counting same QR code multiple times

#### Architecture
- Robust modular architecture with clear separation of concerns
- Custom exception hierarchy (QRScannerException, LibraryLoadException, ImageProcessingException, InvalidParameterException)
- Comprehensive input validation for image paths and raw bytes
- Type-safe models (QRCode, QRCodePosition)
- Memory-safe native bindings with automatic cleanup
- Configurable scanning parameters (QRScannerConfig)
- Built-in debug logging system (QRScannerLogger)

#### API
- `scanImageFile()` - Scan QR codes from file path
- `scanImageBytes()` - Scan QR codes from raw pixel data
- `updateConfig()` - Configure scanning behavior at runtime
- Predefined configs: defaultConfig, fastConfig, accurateConfig

#### Validation
- Automatic file path validation (existence, format, size)
- Image format support: jpg, jpeg, png, bmp, webp, tiff, tif
- File size limit: 50MB maximum
- Raw image data validation (dimensions, channels, data size)
- Supported dimensions: up to 10000x10000 pixels
- Supported channels: 1 (grayscale), 3 (RGB), 4 (RGBA)

#### Self-Contained Package
- **ZXing-C++ v2.2.1** source code bundled (no external installation)
- **OpenCV** automatically fetched:
  - Android: From Maven Central (org.opencv:opencv:4.5.3)
  - iOS: Via CocoaPods dependency
- All paths relative to package (no external dependencies)
- Native C++ compilation handled automatically

#### Documentation
- Complete README with installation and usage
- API reference with examples
- Exception handling guide
- Performance optimization tips
- Troubleshooting section
- Example app with image picker integration

#### Testing
- Unit tests for models and utilities
- Example app demonstrating all features

### Platform Support
- **Android**: Min SDK 21 (Android 5.0), supports arm64-v8a, armeabi-v7a, x86, x86_64
- **iOS**: Min iOS 12.0, supports device and simulator
- **Desktop**: macOS, Linux, Windows (experimental)

### Performance
- Efficient singleton pattern for resource reuse
- Early validation to fail fast
- Configurable behavior for speed vs accuracy trade-off
- Typical scan times: 50-500ms depending on image size and config

### Dependencies
- Flutter SDK: >=3.0.0
- Dart SDK: >=3.0.0
- ffi: ^2.1.0

### License
- MIT License
- Includes Apache 2.0 licensed ZXing-C++ and OpenCV
