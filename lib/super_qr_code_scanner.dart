import 'dart:ffi' as ffi;
import 'package:flutter/foundation.dart';
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
export 'src/logger.dart' show LogLevel, QRScannerLogger;

/// Main QR Scanner API
class SuperQRCodeScanner {
  static final SuperQRCodeScanner _instance = SuperQRCodeScanner._internal();
  factory SuperQRCodeScanner() => _instance;

  QRScannerConfig _config = QRScannerConfig.defaultConfig;

  SuperQRCodeScanner._internal();

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
  Future<List<QRCode>> scanImageFile(String imagePath) async {
    final stopwatch = Stopwatch()..start();
    QRScannerLogger.info('Scanning image file: $imagePath');

    try {
      // Validate input
      await QRScannerValidator.validateImagePath(imagePath);

      // Run in separate isolate to prevent UI freeze
      final results = await compute(_scanImageFileSync, imagePath);

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

  /// Synchronous scan for use in compute isolate
  static List<QRCode> _scanImageFileSync(String imagePath) {
    final bindings = QRScannerBindings.load();
    final resultPtr = bindings.scanImageFile(imagePath);

    if (resultPtr == ffi.nullptr) {
      return [];
    }

    return _parseResultsSync(bindings, resultPtr);
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
  Future<List<QRCode>> scanImageBytes(
    List<int> imageData,
    int width,
    int height,
    int channels,
  ) async {
    final stopwatch = Stopwatch()..start();
    QRScannerLogger.info(
        'Scanning image bytes: ${width}x$height, $channels channels');

    try {
      // Validate input
      QRScannerValidator.validateImageBytes(
        imageData: imageData,
        width: width,
        height: height,
        channels: channels,
      );

      // Run in separate isolate to prevent UI freeze
      final params = _ScanBytesParams(imageData, width, height, channels);
      final results = await compute(_scanImageBytesSync, params);

      stopwatch.stop();
      QRScannerLogger.info(
        'Found ${results.length} QR code(s) in ${stopwatch.elapsedMilliseconds}ms',
      );

      return results;
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

  /// Synchronous scan from bytes for use in compute isolate
  static List<QRCode> _scanImageBytesSync(_ScanBytesParams params) {
    final bindings = QRScannerBindings.load();
    final dataPtr = malloc<ffi.Uint8>(params.imageData.length);

    try {
      final dataList = dataPtr.asTypedList(params.imageData.length);
      dataList.setAll(0, params.imageData);

      final resultPtr = bindings.scanImageBytes(
        dataPtr,
        params.width,
        params.height,
        params.channels,
      );

      if (resultPtr == ffi.nullptr) {
        return [];
      }

      return _parseResultsSync(bindings, resultPtr);
    } finally {
      malloc.free(dataPtr);
    }
  }

  /// Parse native scan results into Dart objects (static for use in isolates)
  static List<QRCode> _parseResultsSync(
    QRScannerBindings bindings,
    ffi.Pointer<QRScanResult> resultPtr,
  ) {
    QRScannerLogger.debug('Starting to parse native scan results');

    try {
      final result = resultPtr.ref;
      final List<QRCode> qrCodes = [];

      QRScannerLogger.debug(
          'Found ${result.count} QR code(s) in native results');

      for (int i = 0; i < result.count; i++) {
        final qrResult = result.results[i];

        QRScannerLogger.debug('Parsing QR code [$i]');

        // Convert C strings to Dart strings
        final content = qrResult.content.cast<Utf8>().toDartString();
        final format = qrResult.format.cast<Utf8>().toDartString();

        QRScannerLogger.debug('  Format: $format');
        QRScannerLogger.debug(
            '  Content: ${content.substring(0, content.length > 50 ? 50 : content.length)}${content.length > 50 ? "..." : ""}');

        qrCodes.add(QRCode(content: content, format: format));
      }

      QRScannerLogger.debug('Successfully parsed ${qrCodes.length} QR code(s)');
      return qrCodes;
    } catch (e, stackTrace) {
      QRScannerLogger.error('Error parsing native results', e, stackTrace);
      rethrow;
    } finally {
      // Always free native memory
      QRScannerLogger.debug('Freeing native memory');
      bindings.freeResult(resultPtr);
    }
  }
}

/// Helper class to pass multiple parameters to compute
class _ScanBytesParams {
  final List<int> imageData;
  final int width;
  final int height;
  final int channels;

  _ScanBytesParams(this.imageData, this.width, this.height, this.channels);
}
