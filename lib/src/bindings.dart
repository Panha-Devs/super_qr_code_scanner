import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

import 'exceptions.dart';
import 'models.dart';

/// Native function type definitions
typedef QRScanImageNative = ffi.Pointer<QRScanResult> Function(
    ffi.Pointer<ffi.Char> imagePath);
typedef QRScanImageDart = ffi.Pointer<QRScanResult> Function(
    ffi.Pointer<ffi.Char> imagePath);

typedef QRScanBytesNative = ffi.Pointer<QRScanResult> Function(
    ffi.Pointer<ffi.Uint8> imageData,
    ffi.Int width,
    ffi.Int height,
    ffi.Int channels);
typedef QRScanBytesDart = ffi.Pointer<QRScanResult> Function(
    ffi.Pointer<ffi.Uint8> imageData, int width, int height, int channels);

typedef QRFreeResultNative = ffi.Void Function(
    ffi.Pointer<QRScanResult> result);
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
  ffi.Pointer<QRScanResult> scanImageFile(String imagePath) {
    _ensureInitialized();
    
    final pathPtr = imagePath.toNativeUtf8();
    try {
      return _scanImage(pathPtr.cast());
    } finally {
      malloc.free(pathPtr);
    }
  }

  /// Scan QR codes from raw image bytes
  ffi.Pointer<QRScanResult> scanImageBytes(
    ffi.Pointer<ffi.Uint8> imageData,
    int width,
    int height,
    int channels,
  ) {
    _ensureInitialized();
    return _scanBytes(imageData, width, height, channels);
  }

  /// Free the memory allocated for a scan result
  void freeResult(ffi.Pointer<QRScanResult> result) {
    if (result != ffi.nullptr) {
      _freeResult(result);
    }
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
      return ['libqr_scanner_native.so'];
    } else if (Platform.isIOS) {
      return ['QRScannerNative.framework/QRScannerNative'];
    } else if (Platform.isMacOS) {
      return [
        'libqr_scanner_native.dylib',
        'Frameworks/libqr_scanner_native.dylib',
      ];
    } else if (Platform.isLinux) {
      return [
        'libqr_scanner_native.so',
        './libqr_scanner_native.so',
        '/usr/local/lib/libqr_scanner_native.so',
      ];
    } else if (Platform.isWindows) {
      return [
        'qr_scanner_native.dll',
        'bin/qr_scanner_native.dll',
      ];
    } else {
      throw UnsupportedError(
          'Platform ${Platform.operatingSystem} is not supported');
    }
  }
}
