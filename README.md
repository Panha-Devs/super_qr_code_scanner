# Super QR Code Scanner

A robust Flutter FFI plugin for scanning QR codes from images using OpenCV and ZXing.

**Zero setup required!** Just add to your `pubspec.yaml` and start scanning.

## Features

- ✅ **Multi-platform support**: Android, iOS, macOS, Linux, Windows
- ✅ **Multiple QR codes**: Detect up to 50 QR codes in a single image
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
  image_picker: ^1.0.7  # Optional: For picking images
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

### Basic Usage

```dart
import 'package:super_qr_code_scanner/super_qr_code_scanner.dart';

// Initialize scanner (singleton - done once)
final scanner = SuperQRCodeScanner();

// Scan from file path
try {
  final results = scanner.scanImageFile('/path/to/image.jpg');
  
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
```

### Scan from Raw Bytes

```dart
import 'dart:typed_data';

void scanFromBytes(Uint8List imageData, int width, int height) {
  final scanner = SuperQRCodeScanner();
  
  // Scan RGB image (3 channels)
  final results = scanner.scanImageBytes(
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

      // Scan in background to avoid blocking UI
      final qrCodes = await Future.microtask(
        () => scanner.scanImageFile(image.path),
      );

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

#### `scanImageFile(String imagePath)`
Scans QR codes from an image file.

**Returns:** `List<QRCode>` - Found QR codes (empty if none)

**Throws:** `InvalidParameterException`, `ImageProcessingException`

#### `scanImageBytes(List<int> imageData, int width, int height, int channels)`
Scans QR codes from raw image data.

**Parameters:**
- `imageData`: Raw pixel data
- `width`: Image width in pixels
- `height`: Image height in pixels
- `channels`: 1 (grayscale), 3 (RGB), or 4 (RGBA)

**Returns:** `List<QRCode>` - Found QR codes (empty if none)

#### `updateConfig(QRScannerConfig config)`
Updates scanner configuration.

### Models

#### `QRCode`
```dart
class QRCode {
  final String content;  // QR code text content
  final String format;   // Format (e.g., "QR_CODE")
}Platform Setup

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
