# Super QR Code Scanner Example

This example demonstrates how to use the super_qr_code_scanner plugin in a Flutter app.

## Features Demonstrated

- ✅ Scanner initialization
- ✅ Configuration switching (Fast, Default, Accurate)
- ✅ Error handling with specific exception types
- ✅ Debug logging
- ✅ Results display

## Running the Example

```bash
cd example
flutter pub get
flutter run
```

## Usage in Your App

### 1. Add to pubspec.yaml

```yaml
dependencies:
  super_qr_code_scanner: ^1.0.0
```

### 2. Import and Use

```dart
import 'package:super_qr_code_scanner/super_qr_code_scanner.dart';

// Initialize scanner
final scanner = SuperQRCodeScanner();

// Scan image
final results = scanner.scanImageFile('/path/to/image.jpg');

// Process results
for (var qr in results) {
  print('${qr.format}: ${qr.content}');
}
```

### 3. Getting Image Paths

To scan real images, you'll need to get the image path from:

#### Option 1: Image Picker (Camera/Gallery)

Add `image_picker` to your `pubspec.yaml`:

```yaml
dependencies:
  image_picker: ^1.0.7
```

Use it:

```dart
import 'package:image_picker/image_picker.dart';

final picker = ImagePicker();
final image = await picker.pickImage(source: ImageSource.gallery);

if (image != null) {
  final results = scanner.scanImageFile(image.path);
}
```

#### Option 2: File Picker

```yaml
dependencies:
  file_picker: ^6.0.0
```

```dart
import 'package:file_picker/file_picker.dart';

final result = await FilePicker.platform.pickFiles(
  type: FileType.image,
);

if (result != null) {
  final results = scanner.scanImageFile(result.files.first.path!);
}
```

#### Option 3: Assets

```dart
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// Copy asset to temp file
final byteData = await rootBundle.load('assets/qr_code.jpg');
final tempDir = await getTemporaryDirectory();
final file = File('${tempDir.path}/temp_qr.jpg');
await file.writeAsBytes(byteData.buffer.asUint8List());

// Scan it
final results = scanner.scanImageFile(file.path);
```

## Configuration Options

```dart
// Fast - for real-time or quick scans
scanner.updateConfig(QRScannerConfig.fastConfig);

// Default - balanced speed and accuracy
scanner.updateConfig(QRScannerConfig.defaultConfig);

// Accurate - thorough scanning, slower
scanner.updateConfig(QRScannerConfig.accurateConfig);

// Custom
scanner.updateConfig(QRScannerConfig(
  tryHarder: true,
  tryRotate: true,
  maxNumberOfSymbols: 10,
  enableLogging: true,
));
```

## Error Handling

```dart
try {
  final results = scanner.scanImageFile(imagePath);
  // Handle results
} on InvalidParameterException catch (e) {
  print('Invalid input: ${e.message}');
} on ImageProcessingException catch (e) {
  print('Processing failed: ${e.message}');
} on LibraryLoadException catch (e) {
  print('Library error: ${e.message}');
}
```

## See Also

- [Package README](../README.md) - Full documentation
- [API Reference](https://pub.dev/documentation/super_qr_code_scanner/latest/)
- [CHANGELOG](../CHANGELOG.md) - Version history
