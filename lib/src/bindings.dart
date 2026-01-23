import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:super_qr_code_scanner/src/logger.dart';

import 'exceptions.dart';
import 'models.dart';
import 'config.dart';

/// Native function type definitions
typedef QRScanImageNative = ffi.Pointer<QRScanResult> Function(
  ffi.Pointer<ffi.Char> imagePath,
  ffi.Pointer<QRScannerConfigNative> config,
);
typedef QRScanImageDart = ffi.Pointer<QRScanResult> Function(
  ffi.Pointer<ffi.Char> imagePath,
  ffi.Pointer<QRScannerConfigNative> config,
);

typedef QRScanBytesNative = ffi.Pointer<QRScanResult> Function(
  ffi.Pointer<ffi.Uint8> imageData,
  ffi.Int width,
  ffi.Int height,
  ffi.Int channels,
  ffi.Pointer<QRScannerConfigNative> config,
);
typedef QRScanBytesDart = ffi.Pointer<QRScanResult> Function(
  ffi.Pointer<ffi.Uint8> imageData,
  int width,
  int height,
  int channels,
  ffi.Pointer<QRScannerConfigNative> config,
);

typedef QRFreeResultNative = ffi.Void Function(
  ffi.Pointer<QRScanResult> result,
);
typedef QRFreeResultDart = void Function(ffi.Pointer<QRScanResult> result);

/// Low-level FFI bindings to the native QR scanner library
class QRScannerBindings {
  final ffi.DynamicLibrary _dylib;
  late final QRScanImageDart _scanImage;
  late final QRScanBytesDart _scanBytes;
  late final QRFreeResultDart _freeResult;

  bool _initialized = false;

  QRScannerBindings._(this._dylib) {
    try {
      _scanImage = _dylib
          .lookup<ffi.NativeFunction<QRScanImageNative>>('qr_scan_image')
          .asFunction();
      _scanBytes = _dylib
          .lookup<ffi.NativeFunction<QRScanBytesNative>>('qr_scan_bytes')
          .asFunction();
      _freeResult = _dylib
          .lookup<ffi.NativeFunction<QRFreeResultNative>>('qr_free_result')
          .asFunction();
      _initialized = true;
    } catch (e, stackTrace) {
      QRScannerLogger.error(
        'Failed to get native function pointers from library',
      );
      throw LibraryLoadException(
        'Failed to load native functions',
        details: e.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  /// Load the native library for the current platform
  factory QRScannerBindings.load() {
    try {
      final dylib = _loadLibrary();
      return QRScannerBindings._(dylib);
    } catch (e, stackTrace) {
      throw LibraryLoadException(
        'Failed to load native library',
        details: e.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if the bindings are properly initialized
  bool get isInitialized => _initialized;

  /// Scan QR codes from an image file path
  ffi.Pointer<QRScanResult> scanImageFile(
    String imagePath,
    QRScannerConfig config,
  ) {
    _ensureInitialized();

    final pathPtr = imagePath.toNativeUtf8();
    final configPtr = _createConfigPtr(config);
    try {
      return _scanImage(pathPtr.cast(), configPtr);
    } finally {
      malloc.free(pathPtr);
      malloc.free(configPtr);
    }
  }

  /// Scan QR codes from raw image bytes
  ffi.Pointer<QRScanResult> scanImageBytes(
    ffi.Pointer<ffi.Uint8> imageData,
    int width,
    int height,
    int channels,
    QRScannerConfig config,
  ) {
    _ensureInitialized();
    final configPtr = _createConfigPtr(config);
    try {
      return _scanBytes(imageData, width, height, channels, configPtr);
    } finally {
      malloc.free(configPtr);
    }
  }

  /// Free the memory allocated for a scan result
  void freeResult(ffi.Pointer<QRScanResult> result) {
    if (result != ffi.nullptr) {
      _freeResult(result);
    }
  }

  /// Create a native config pointer from Dart config
  ffi.Pointer<QRScannerConfigNative> _createConfigPtr(QRScannerConfig config) {
    final configPtr = malloc<QRScannerConfigNative>();
    configPtr.ref.max_symbols = config.maxSymbols;
    configPtr.ref.timeout_ms = config.timeoutMs;
    configPtr.ref.try_harder = config.tryHarder ? 1 : 0;
    return configPtr;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw QRScannerException('Native library not properly initialized');
    }
  }

  static ffi.DynamicLibrary _loadLibrary() {
    final libraryNames = _getLibraryNames();

    for (final name in libraryNames) {
      try {
        if (Platform.isIOS) {
          // iOS uses static linking, all symbols are in the process
          return ffi.DynamicLibrary.process();
        } else {
          return ffi.DynamicLibrary.open(name);
        }
      } catch (e) {
        // Try next library name
        continue;
      }
    }

    throw LibraryLoadException(
      'Could not load native library for ${Platform.operatingSystem}',
      details: 'Tried: ${libraryNames.join(", ")}',
    );
  }

  static List<String> _getLibraryNames() {
    if (Platform.isAndroid) {
      return ['libsuper_qr_code_scanner.so'];
    } else if (Platform.isIOS) {
      // iOS FFI plugin uses DynamicLibrary.process() for static linking
      return ['super_qr_code_scanner'];
    } else if (Platform.isMacOS) {
      return [
        'libsuper_qr_code_scanner.dylib',
        'Frameworks/libsuper_qr_code_scanner.dylib',
      ];
    } else if (Platform.isLinux) {
      return [
        'libsuper_qr_code_scanner.so',
        './libsuper_qr_code_scanner.so',
        '/usr/local/lib/libsuper_qr_code_scanner.so',
      ];
    } else if (Platform.isWindows) {
      return [
        'super_qr_code_scanner.dll',
        'bin/super_qr_code_scanner.dll',
      ];
    } else {
      throw UnsupportedError(
          'Platform ${Platform.operatingSystem} is not supported');
    }
  }
}
