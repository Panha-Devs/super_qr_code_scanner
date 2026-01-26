# Super QR Code Scanner

A robust Flutter FFI plugin for scanning QR codes from images using OpenCV and ZXing.

**Zero setup required!** Just add to your `pubspec.yaml` and start scanning.

## Features

- ✅ **Multi-platform support**: Android, iOS, macOS, Linux, Windows
- ✅ **Multiple QR codes**: Detect up to 50 QR codes in a single image
- ✅ **High accuracy**: 6 detection strategies with image preprocessing
- ✅ **Non-blocking UI**: Async API with isolate-based processing
- ✅ **Native threading**: C++ worker threads for parallel execution
- ✅ **Type-safe**: Strong type checking with custom exception hierarchy
- ✅ **Configurable**: Adjust scanning parameters for speed vs accuracy
- ✅ **Logging**: Built-in debug logging for troubleshooting
- ✅ **Validated input**: Automatic validation of image paths and data
- ✅ **Memory-safe**: Proper native memory management
- ✅ **Zero setup**: All dependencies bundled, no external configuration needed

## Supported Platforms

| Platform | Minimum Version | Status | Architecture |
|----------|----------------|--------|--------------|
| **Android** | API 21 (Android 5.0) | ✅ Tested | arm64-v8a, armeabi-v7a |
| **iOS** | iOS 12.0+ | ✅ Tested | arm64, x86_64 (simulator) |
| **macOS** | macOS 10.14+ | ✅ Tested | arm64 (Apple Silicon), x86_64 (Intel) |
| **Linux** | Ubuntu 18.04+ | ⚠️ Experimental | x64 |
| **Windows** | Windows 10+ | ⚠️ Experimental | x64 |

**Notes:**
- Android and iOS are fully tested and production-ready
- Desktop platforms (macOS/Linux/Windows) are functional but require more testing
- All platforms use the same native libraries and API

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  super_qr_code_scanner: ^1.0.0
  image_picker: ^1.0.7  # Optional: For picking images
```

Run:
```bash
flutter pub get
```

### Platform Setup

To reduce package size, native libraries are not bundled. Run the setup command to download libraries for your target platforms:

```bash
# For Android and iOS (default - recommended for most apps)
dart run super_qr_code_scanner:setup

# For specific platforms
dart run super_qr_code_scanner:setup --platforms android,ios

# For all platforms
dart run super_qr_code_scanner:setup --platforms android,ios,macos,linux,windows

# Specify a specific version (if needed)
dart run super_qr_code_scanner:setup --version v1.0.1

# Combine platforms and version
dart run super_qr_code_scanner:setup --platforms android,ios --version v1.0.1
```

This downloads OpenCV and ZXing libraries from our public GitHub releases and places them in the plugin's native directories. The setup is safe to run multiple times - it skips downloads if libraries are already present.

**Note:** Libraries are hosted at [Panha-Devs/super_qr_code_scanner_artifacts](https://github.com/Panha-Devs/super_qr_code_scanner_artifacts).

## Development Setup

For developers contributing to or building this plugin from source, additional tools are required for iOS and macOS platforms:

### iOS Development Requirements
- **Xcode**: Latest version with Command Line Tools (`xcode-select --install`)
- **CMake**: Install via Homebrew: `brew install cmake`
- **Flutter SDK**: Follow [official installation guide](https://flutter.dev/docs/get-started/install/macos)

The iOS build process uses:
- `libtool` (included with Xcode) for combining static libraries
- `lipo` (included with Xcode) for creating universal binaries
- CMake for cross-compiling native C++ code

### macOS Development Requirements
- **Xcode**: Latest version with Command Line Tools
- **CMake**: Install via Homebrew: `brew install cmake`
- **Flutter SDK**: Follow [official installation guide](https://flutter.dev/docs/get-started/install/macos)

### Building Native Libraries
The native iOS and macOS libraries are built automatically when running `flutter build ios`, `flutter run ios`, `flutter build macos`, or `flutter run macos`. The build process uses platform-specific scripts (`prepare-ios-lib.sh` for iOS, `prepare-macos-lib.sh` for macOS) to compile and combine the required OpenCV and ZXing libraries for each platform.

## Quick Start

### Basic Usage

```dart
import 'package:super_qr_code_scanner/super_qr_code_scanner.dart';

// Initialize scanner (singleton - done once)
final scanner = SuperQRCodeScanner();

// Scan from file path (async - runs in isolate)
Future<void> scanImage() async {
  try {
    final results = await scanner.scanImageFile('/path/to/image.jpg');
    
    for (final qr in results) {
      print('Format: ${qr.format}');
      print('Content: ${qr.content}');
    }
    
    if (results.isEmpty) {
      print('No QR codes found');
    }
  } on InvalidParameterException catch (e) {
    print('Invalid input: ${e.message}');
  } on ImageProcessingException catch (e) {
    print('Failed to process: ${e.message}');
  }
}
```

### Scan from Raw Bytes

```dart
import 'dart:typed_data';

Future<void> scanFromBytes(Uint8List imageData, int width, int height) async {
  final scanner = SuperQRCodeScanner();
  
  // Scan RGB image (3 channels) - runs in isolate
  final results = await scanner.scanImageBytes(
    imageData,
    width,
    height,
    3, // channels: 1=grayscale, 3=RGB, 4=RGBA
  );
  
  print('Found ${results.length} QR codes');
}
```

### Complete Example with Image Picker

```dart
import 'package:flutter/material.dart';
import 'package:super_qr_code_scanner/super_qr_code_scanner.dart';
import 'package:image_picker/image_picker.dart';

class QRScannerDemo extends StatefulWidget {
  @override
  State<QRScannerDemo> createState() => _QRScannerDemoState();
}

class _QRScannerDemoState extends State<QRScannerDemo> {
  final scanner = SuperQRCodeScanner();
  final picker = ImagePicker();
  List<QRCode> results = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    // Optional: Configure scanner for accuracy
    scanner.updateConfig(QRScannerConfig.accurateConfig);
  }

  Future<void> pickAndScan() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );
      
      if (image == null) return;

      setState(() => isScanning = true);

      // Scan in isolate - UI remains responsive
      final qrCodes = await scanner.scanImageFile(image.path);

      setState(() {
        results = qrCodes;
        isScanning = false;
      });
    } catch (e) {
      setState(() => isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR Scanner')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: isScanning ? null : pickAndScan,
            child: Text(isScanning ? 'Scanning...' : 'Pick Image'),
          ),
          
          if (results.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final qr = results[index];
                  return Card(
                    child: ListTile(
                      title: Text(qr.content),
                      subtitle: Text('Format: ${qr.format}'),
                    ),
                  );
                },
              ),
            )
          else
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('No QR codes found'),
            ),
        ],
      ),
    );
  }
}
```

## Configuration

### Predefined Configs

```dart
// Fast scanning (fewer strategies, good for real-time)
scanner.updateConfig(QRScannerConfig.fastConfig);

// Balanced (default, recommended for most use cases)
scanner.updateConfig(QRScannerConfig.defaultConfig);

// Accurate (all strategies, thorough but slower)
scanner.updateConfig(QRScannerConfig.accurateConfig);
```

### Custom Configuration

```dart
scanner.updateConfig(QRScannerConfig(
  tryHarder: true,           // More thorough scanning
  tryRotate: true,           // Try rotating image
  tryDownscale: true,        // Try downscaling
  maxNumberOfSymbols: 50,    // Max QR codes to detect
  enableLogging: true,       // Enable debug logs
));
```

## Debug Logging

```dart
// Enable logging in main()
void main() {
  QRScannerLogger.setEnabled(true);
  QRScannerLogger.setLevel(LogLevel.debug);  // debug, info, warning, error
  
  runApp(MyApp());
}

// Or via config
scanner.updateConfig(
  QRScannerConfig(enableLogging: true)
);
```

## Exception Handling

The plugin provides specific exception types:

| Exception | Description |
|-----------|-------------|
| `QRScannerException` | Base exception class |
| `LibraryLoadException` | Failed to load native library |
| `ImageProcessingException` | Failed to process image |
| `InvalidParameterException` | Invalid input parameters |

```dart
try {
  final results = scanner.scanImageFile(imagePath);
  // Process results
} on LibraryLoadException catch (e) {
  // Native library failed to load
  print('Library error: ${e.message}');
  print('Details: ${e.details}');
} on InvalidParameterException catch (e) {
  // Invalid image path, format, or parameters
  print('Invalid input: ${e.message}');
} on ImageProcessingException catch (e) {
  // Image processing failed
  print('Processing error: ${e.message}');
} on QRScannerException catch (e) {
  // Generic scanner error
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
}Supported Image Formats

The plugin automatically validates input:

- **File formats**: JPG, JPEG, PNG, BMP, WEBP, TIFF, TIF
- **Max file size**: 50MB
- **Max dimensions**: 10000x10000 pixels
- **Color modes**: Grayscale (1 channel), RGB (3 channels), RGBA (4 channels)
- **Path validation**: Checks file exists and is readable
- **Data validation**: Verifies raw image data size matches dimensionsg, bmp, webp, tiff, tif
- Image dimensions (max 10000x10000)
- Raw image data size matches dimensions
- Valid channel count (1, 3, or 4)

## API Reference

### Methods

#### `Future<List<QRCode>> scanImageFile(String imagePath)`
Scans QR codes from an image file. Runs in a separate isolate to avoid blocking the UI.

**Returns:** `Future<List<QRCode>>` - Found QR codes (empty if none)

**Throws:** `InvalidParameterException`, `ImageProcessingException`

```dart
final results = await scanner.scanImageFile('/path/to/image.jpg');
```

#### `Future<List<QRCode>> scanImageBytes(List<int> imageData, int width, int height, int channels)`
Scans QR codes from raw image data. Runs in a separate isolate to avoid blocking the UI.

**Parameters:**
- `imageData`: Raw pixel data
- `width`: Image width in pixels
- `height`: Image height in pixels
- `channels`: 1 (grayscale), 3 (RGB), or 4 (RGBA)

**Returns:** `Future<List<QRCode>>` - Found QR codes (empty if none)

```dart
final results = await scanner.scanImageBytes(data, width, height, 3);
```

#### `updateConfig(QRScannerConfig config)`
Updates scanner configuration.

### Models

#### `QRCode`
```dart
class QRCode {
  final String content;  // QR code text content
  final String format;   // Format (e.g., "QR_CODE")
}
```

## Performance Architecture

### Multi-Level Threading

The plugin uses a sophisticated threading architecture for optimal performance:

**Flutter Layer (Dart):**
- Uses `compute()` to run FFI calls in separate Dart isolates
- Prevents UI thread blocking during image processing
- Each scan runs in its own isolated environment

**Native Layer (C++):**
- Uses `std::async(std::launch::async)` for parallel execution
- Worker threads handle image loading and processing
- Multiple detection strategies run concurrently

**Result:**
- ✅ UI remains responsive even during heavy processing
- ✅ True parallel execution on multi-core devices
- ✅ No manual thread management required
- ✅ Automatic memory cleanup

### Why This Matters

```dart
// ❌ Old synchronous approach (blocks UI)
final results = scanImageSync(path);  // UI freezes!

// ✅ New async approach (smooth UI)
final results = await scanner.scanImageFile(path);  // UI responsive!
```Platform Setup

### Android
- **Min SDK**: 21 (Android 5.0)
- **Permissions**: Add to `AndroidManifest.xml` if using camera:
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  ```

### iOS
- **Min Version**: iOS 12.0
- **Permissions**: Add to `Info.plist` if using camera:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>We need camera access to scan QR codes</string>
  <key>NSPhotoLibraryUsageDescription</key>
  <string>We need photo library access to select images</string>
  ```

### Dependencies (Automatic)

The package is completely self-contained:

**Android:**
- Op"No QR codes found"
- Ensure image has good quality and lighting
- Try `accurateConfig` for difficult images
- Check image isn't too blurry or small

### "Invalid image path"
- Use absolute paths
- Verify file exists and is readable
- Check supported formats

### Build errors on Android
- Clean build: `flutter clean && flutter pub get`
- Check NDK is installed in Android Studio

### Build errors on iOS
- Run `cd ios && pod install`
- Clean Xcode build folder

### Library not found error
```dart
// Enable logging to see detailed error messages
QRScannerLogger.setEnabled(true);
QRScannerLogger.setLevel(LogLevel.debug);
```t
4. **Adaptive threshold**: Otsu and adaptive thresholding
5. **Inverted**: Scan inverted grayscale image
6. **Sharpened**: Apply sharpening kernel

## Requirements

### No setup required!

The package is completely self-contained with custom-compiled native libraries:

**Android:**
- Min SDK: 21 (Android 5.0)
- OpenCV 4.14.0-pre: Custom compiled, bundled as native libraries
- ZXing-C++ 2.3.0: Custom compiled, bundled as static libraries
- NDK: Automatically managed by Flutter

**iOS:**
- iOS 12.0+
- OpenCV 4.14.0-pre: Custom compiled, bundled as frameworks
- ZXing-C++ 2.3.0: Custom compiled, bundled as static libraries
- No CocoaPods dependencies required

**Desktop (macOS, Linux, Windows):**
- OpenCV 4.14.0-pre: Custom compiled, bundled
- ZXing-C++ 2.3.0: Custom compiled, bundled
- All native libraries included

**First build may take 2-5 minutes** as native code is compiled. Subsequent builds are fast.

## Example App

See the [example app](example/) for a complete working implementation with image picker.

## Troubleshooting

### Android build errors with .cxx directory

If you encounter build errors related to CMake or native compilation, try removing the `.cxx` directory:

```bash
cd android
rm -rf .cxx
cd ..
flutter clean
flutter pub get
```

This directory contains cached CMake build artifacts that may become corrupted.

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

### UI still freezes during scan

- Ensure you're using `await` with scan methods
- Check that you're not blocking the UI thread elsewhere
- Verify Flutter version supports `compute()` (Flutter 1.0+)

### Memory issues

- Reduce image size before scanning
- Ensure proper disposal of resources
- Check that file size is within limits (50MB)
- Multiple concurrent scans may increase memory usage

## License

See LICENSE file for details.
