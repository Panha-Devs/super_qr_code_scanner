import 'dart:ffi' as ffi;

/// Represents a single QR code or barcode result
class QRCode {
  /// The decoded content/text of the QR code
  final String content;

  /// The format type (e.g., 'QRCode', 'DataMatrix', 'EAN13')
  final String format;

  /// Position of the QR code in the image (optional, for future use)
  final QRCodePosition? position;

  QRCode({
    required this.content,
    required this.format,
    this.position,
  });

  /// Check if this QR code is empty
  bool get isEmpty => content.isEmpty;

  /// Check if this QR code is not empty
  bool get isNotEmpty => content.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QRCode &&
        other.content == content &&
        other.format == format;
  }

  @override
  int get hashCode => Object.hash(content, format);

  @override
  String toString() => 'QRCode(format: $format, content: $content)';

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
        'content': content,
        'format': format,
        if (position != null) 'position': position!.toJson(),
      };
}

/// Position of a QR code in the image
class QRCodePosition {
  final int x;
  final int y;
  final int width;
  final int height;

  QRCodePosition({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };
}

/// C struct bindings for QRCodeResult
final class QRCodeResult extends ffi.Struct {
  external ffi.Pointer<ffi.Char> content;
  external ffi.Pointer<ffi.Char> format;
}

/// C struct bindings for QRScanResult
final class QRScanResult extends ffi.Struct {
  external ffi.Pointer<QRCodeResult> results;
  @ffi.Int()
  external int count;
}
