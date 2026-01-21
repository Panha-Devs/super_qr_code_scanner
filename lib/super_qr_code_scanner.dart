import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

import 'src/models.dart';
import 'src/exceptions.dart';
import 'src/bindings.dart';
import 'src/validator.dart';
import 'src/config.dart';
import 'src/logger.dart';

export 'src/models.dart' show QRCode, QRCodePosition;
export 'src/exceptions.dart';
export 'src/config.dart';
export 'src/logger.dart' show LogLevel;

/// Main QR Scanner API
class SuperQRCodeScanner {
  static final SuperQRCodeScanner _instance = SuperQRCodeScanner._internal();
  factory SuperQRCodeScanner() => _instance;

  late final QRScannerBindings _bindings;
  QRScannerConfig _config = QRScannerConfig.defaultConfig;

  SuperQRCodeScanner._internal() {
    try {
      QRScannerLogger.info('Initializing QR Scanner Native');
      _bindings = QRScannerBindings.load();
      QRScannerLogger.info('QR Scanner Native initialized successfully');
    } catch (e, stackTrace) {
      QRScannerLogger.error('Failed to initialize QR Scanner', e, stackTrace);
      rethrow;
    }
  }

  /// Get the current configuration
  QRScannerConfig get config => _config;

  /// Update the scanner configuration
  void updateConfig(QRScannerConfig config) {
    _config = config;
    QRScannerLogger.setEnabled(config.enableLogging);
    QRScannerLogger.info('Configuration updated: $config');
  }

  /// Scan QR codes from an image file path
  /// 
  /// Throws [InvalidParameterException] if the image path is invalid
  /// Throws [ImageProcessingException] if the image cannot be processed
  /// Returns an empty list if no QR codes are found
  List<QRCode> scanImageFile(String imagePath) {
    final stopwatch = Stopwatch()..start();
    QRScannerLogger.info('Scanning image file: $imagePath');

    try {
      // Validate input
      QRScannerValidator.validateImagePath(imagePath);

      // Perform scan
      final resultPtr = _bindings.scanImageFile(imagePath);
      
      if (resultPtr == ffi.nullptr) {
        QRScannerLogger.info('No QR codes found in image');
        return [];
      }

      // Parse results
      final results = _parseResults(resultPtr);
      
      stopwatch.stop();
      QRScannerLogger.info(
        'Found ${results.length} QR code(s) in ${stopwatch.elapsedMilliseconds}ms',
      );
      
      return results;
    } on QRScannerException {
      rethrow;
    } catch (e, stackTrace) {
      QRScannerLogger.error('Error scanning image file', e, stackTrace);
      throw ImageProcessingException(
        'Failed to scan image file',
        details: e.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  /// Scan QR codes from raw image bytes
  /// 
  /// [imageData] - Raw pixel data (grayscale, RGB, or RGBA)
  /// [width] - Image width in pixels
  /// [height] - Image height in pixels
  /// [channels] - Number of channels (1=grayscale, 3=RGB, 4=RGBA)
  /// 
  /// Throws [InvalidParameterException] if parameters are invalid
  /// Throws [ImageProcessingException] if the image cannot be processed
  /// Returns an empty list if no QR codes are found
  List<QRCode> scanImageBytes(
    List<int> imageData,
    int width,
    int height,
    int channels,
  ) {
    final stopwatch = Stopwatch()..start();
    QRScannerLogger.info('Scanning image bytes: ${width}x$height, $channels channels');

    try {
      // Validate input
      QRScannerValidator.validateImageBytes(
        imageData: imageData,
        width: width,
        height: height,
        channels: channels,
      );

      // Allocate native memory
      final dataPtr = malloc<ffi.Uint8>(imageData.length);
      
      try {
        // Copy data to native memory
        final dataList = dataPtr.asTypedList(imageData.length);
        dataList.setAll(0, imageData);

        // Perform scan
        final resultPtr = _bindings.scanImageBytes(dataPtr, width, height, channels);
        
        if (resultPtr == ffi.nullptr) {
          QRScannerLogger.info('No QR codes found in image bytes');
          return [];
        }

        // Parse results
        final results = _parseResults(resultPtr);
        
        stopwatch.stop();
        QRScannerLogger.info(
          'Found ${results.length} QR code(s) in ${stopwatch.elapsedMilliseconds}ms',
        );
        
        return results;
      } finally {
        // Always free allocated memory
        malloc.free(dataPtr);
      }
    } on QRScannerException {
      rethrow;
    } catch (e, stackTrace) {
      QRScannerLogger.error('Error scanning image bytes', e, stackTrace);
      throw ImageProcessingException(
        'Failed to scan image bytes',
        details: e.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  /// Parse native scan results into Dart objects
  List<QRCode> _parseResults(ffi.Pointer<QRScanResult> resultPtr) {
    try {
      final result = resultPtr.ref;
      final List<QRCode> qrCodes = [];

      QRScannerLogger.debug('Parsing ${result.count} QR code(s)');

      for (int i = 0; i < result.count; i++) {
        final qrResult = result.results.elementAt(i).ref;
        
        // Convert C strings to Dart strings
        final content = qrResult.content.cast<Utf8>().toDartString();
        final format = qrResult.format.cast<Utf8>().toDartString();
        
        qrCodes.add(QRCode(content: content, format: format));
        QRScannerLogger.debug('  [$i] $format: ${content.substring(0, content.length > 50 ? 50 : content.length)}${content.length > 50 ? "..." : ""}');
      }

      return qrCodes;
    } catch (e, stackTrace) {
      QRScannerLogger.error('Error parsing results', e, stackTrace);
      throw ImageProcessingException(
        'Failed to parse scan results',
        details: e.toString(),
        stackTrace: stackTrace,
      );
    } finally {
      // Always free native memory
      _bindings.freeResult(resultPtr);
    }
  }
}
