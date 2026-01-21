/// Exception thrown when QR scanner operations fail
class QRScannerException implements Exception {
  final String message;
  final String? details;
  final StackTrace? stackTrace;

  QRScannerException(this.message, {this.details, this.stackTrace});

  @override
  String toString() {
    final buffer = StringBuffer('QRScannerException: $message');
    if (details != null) {
      buffer.write('\nDetails: $details');
    }
    return buffer.toString();
  }
}

/// Exception thrown when the native library cannot be loaded
class LibraryLoadException extends QRScannerException {
  LibraryLoadException(super.message, {super.details, super.stackTrace});
}

/// Exception thrown when image processing fails
class ImageProcessingException extends QRScannerException {
  ImageProcessingException(super.message, {super.details, super.stackTrace});
}

/// Exception thrown when invalid parameters are provided
class InvalidParameterException extends QRScannerException {
  InvalidParameterException(super.message, {super.details, super.stackTrace});
}
