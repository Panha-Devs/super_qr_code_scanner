# Super QR Code Scanner

A robust Flutter FFI plugin for scanning QR codes from images using OpenCV and ZXing.

**Zero setup required!** Just add to your `pubspec.yaml` and start scanning.

## Features

- ✅ **Multi-platform support**: Android, iOS, macOS, Linux, Windows
- ✅ **Multiple QR codes**: Detect multiple QR codes in a single image
- ✅ **High accuracy**: 6 detection strategies with image preprocessing
- ✅ **Type-safe**: Strong type checking with custom exception hierarchy
- ✅ **Configurable**: Adjust scanning parameters for speed vs accuracy
- ✅ **Logging**: Built-in debug logging for troubleshooting
- ✅ **Validated input**: Automatic validation of image paths and data
- ✅ **Memory-safe**: Proper native memory management
- ✅ **Zero setup**: All dependencies bundled, no external configuration needed

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  super_qr_code_scanner: ^1.0.0
```

Run:
```bash
flutter pub get
```

**That's it!** No additional setup required. The package includes:
- ZXing-C++ source code (bundled)
- OpenCV (auto-fetched from Maven for Android, CocoaPods for iOS)
- Native C++ compilation (automatic)

## Quick Start

```dart
import 'package:super_qr_code_scanner/super_qr_code_scanner.dart';

// Initialize scanner (singleton - done once)
final scanner = SuperQRCodeScanner();

// Scan from file path
try {
  final results = scanner.scanImageFile('/path/to/image.jpg');
  for (final qr in results) {
    print('${qr.format}: ${qr.content}');
  }
} on InvalidParameterException catch (e) {
  print('Invalid input: ${e.message}');
} on ImageProcessingException catch (e) {
  print('Failed to process: ${e.message}');
}

// Scan from raw bytes
final results = scanner.scanImageBytes(
  imageData,  // List<int> pixel data
  width,      // Image width
  height,     // Image height  
  3,          // Channels (1=gray, 3=RGB, 4=RGBA)
);
```

## Configuration

```dart
// Use default configuration
scanner.updateConfig(QRScannerConfig.defaultConfig);

// Optimize for speed
scanner.updateConfig(QRScannerConfig.fastConfig);

// Optimize for accuracy
scanner.updateConfig(QRScannerConfig.accurateConfig);

// Custom configuration
scanner.updateConfig(QRScannerConfig(
  maxSymbols: 10,
  enableLogging: true,
  timeoutMs: 15000,
  tryHarder: true,
));
```

## Logging

```dart
import 'package:super_qr_code_scanner/super_qr_code_scanner.dart';

// Enable debug logging
QRScannerLogger.setEnabled(true);
QRScannerLogger.setLevel(LogLevel.debug);

// Or via config
scanner.updateConfig(
  QRScannerConfig(enableLogging: true)
);
```

## Exception Handling

The plugin provides specific exception types for better error handling:

- **QRScannerException**: Base exception class
- **LibraryLoadException**: Failed to load native library
- **ImageProcessingException**: Failed to process image
- **InvalidParameterException**: Invalid input parameters

```dart
try {
  final results = scanner.scanImageFile(imagePath);
} on LibraryLoadException catch (e) {
  // Handle library loading errors
  print('Library error: ${e.message}');
  print('Details: ${e.details}');
} on InvalidParameterException catch (e) {
  // Handle validation errors
  print('Invalid input: ${e.message}');
} on ImageProcessingException catch (e) {
  // Handle processing errors
  print('Processing failed: ${e.message}');
} on QRScannerException catch (e) {
  // Handle any other scanner errors
  print('Scanner error: ${e.message}');
}
```

## Models

### QRCode

```dart
class QRCode {
  final String content;         // The decoded QR code content
  final String format;          // Format type (e.g., "QRCode")
  final QRCodePosition? position; // Optional position data
}
```

### QRCodePosition

```dart
class QRCodePosition {
  final int x;
  final int y;
  final int width;
  final int height;
}
```

## Input Validation

The plugin automatically validates:

- File path existence and format
- Image file size (max 50MB)
- Supported formats: jpg, jpeg, png, bmp, webp, tiff, tif
- Image dimensions (max 10000x10000)
- Raw image data size matches dimensions
- Valid channel count (1, 3, or 4)

## Architecture

```
lib/
├── super_qr_code_scanner.dart  # Main API
└── src/
    ├── models.dart             # Data models (QRCode, QRCodePosition)
    ├── exceptions.dart         # Exception hierarchy
    ├── bindings.dart           # FFI bindings
    ├── validator.dart          # Input validation
    ├── config.dart             # Configuration options
    └── logger.dart             # Logging utilities
```

## Performance Tips

1. **Use appropriate config**: Choose `fastConfig` for real-time, `accurateConfig` for batch processing
2. **Image size**: Smaller images scan faster but may miss small QR codes
3. **Channels**: Use grayscale (1 channel) when possible for faster processing
4. **Disable logging**: Turn off logging in production for better performance

## Detection Strategies

The native implementation uses 6 strategies:

1. **Original**: Scan image as-is with aggressive options
2. **Multi-scale**: Try different scales (0.5x, 2.0x, 3.0x)
3. **Histogram equalization**: Improve contrast
4. **Adaptive threshold**: Otsu and adaptive thresholding
5. **Inverted**: Scan inverted grayscale image
6. **Sharpened**: Apply sharpening kernel

## Requirements

### No setup required!

The package is completely self-contained. Dependencies are automatically handled:

**Android:**
- Min SDK: 21 (Android 5.0)
- OpenCV: Automatically fetched from Maven Central
- ZXing: Bundled with package

**iOS:**
- iOS 12.0+
- OpenCV: Automatically installed via CocoaPods
- ZXing: Bundled with package

**First build may take 5-10 minutes** as dependencies are downloaded and compiled. Subsequent builds are fast.

## Example App

See the [example app](example/) for a complete working implementation with image picker.

## Troubleshooting

### Library not found error

```dart
// Enable logging to see detailed error messages
QRScannerLogger.setEnabled(true);
QRScannerLogger.setLevel(LogLevel.debug);
```

### No QR codes detected

- Ensure image quality is good
- Try `accurateConfig` for difficult images
- Check that QR code is clearly visible
- Verify supported format (standard QR codes only)

### Memory issues

- Reduce image size before scanning
- Ensure proper disposal of resources
- Check that file size is within limits (50MB)

## License

See LICENSE file for details.
