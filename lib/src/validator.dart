import 'dart:io';
import 'exceptions.dart';

/// Input validation utilities
class QRScannerValidator {
  /// Validate an image file path
  static Future<void> validateImagePath(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      throw InvalidParameterException(
        'Image path cannot be null or empty',
      );
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw InvalidParameterException(
        'Image file does not exist',
        details: 'Path: $imagePath',
      );
    }

    // Check file extension
    final extension = imagePath.toLowerCase().split('.').last;
    const validExtensions = [
      'jpg',
      'jpeg',
      'png',
      'bmp',
      'webp',
      'tiff',
      'tif'
    ];

    if (!validExtensions.contains(extension)) {
      throw InvalidParameterException(
        'Unsupported image format',
        details:
            'Extension: .$extension, Supported: ${validExtensions.join(", ")}',
      );
    }

    // Check file size (prevent loading extremely large files)
    final fileSize = await file.length();
    const maxSize = 50 * 1024 * 1024; // 50MB
    if (fileSize > maxSize) {
      throw InvalidParameterException(
        'Image file is too large',
        details:
            'Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB, Max: ${maxSize / 1024 / 1024}MB',
      );
    }
  }

  /// Validate raw image data parameters
  static void validateImageBytes({
    required List<int>? imageData,
    required int? width,
    required int? height,
    required int? channels,
  }) {
    if (imageData == null || imageData.isEmpty) {
      throw InvalidParameterException(
        'Image data cannot be null or empty',
      );
    }

    if (width == null || width <= 0) {
      throw InvalidParameterException(
        'Width must be a positive integer',
        details: 'Provided: $width',
      );
    }

    if (height == null || height <= 0) {
      throw InvalidParameterException(
        'Height must be a positive integer',
        details: 'Provided: $height',
      );
    }

    if (channels == null || ![1, 3, 4].contains(channels)) {
      throw InvalidParameterException(
        'Channels must be 1 (grayscale), 3 (RGB), or 4 (RGBA)',
        details: 'Provided: $channels',
      );
    }

    final expectedSize = width * height * channels;
    if (imageData.length != expectedSize) {
      throw InvalidParameterException(
        'Image data size does not match dimensions',
        details:
            'Expected: $expectedSize bytes, Got: ${imageData.length} bytes',
      );
    }

    // Check reasonable image dimensions
    const maxDimension = 10000;
    if (width > maxDimension || height > maxDimension) {
      throw InvalidParameterException(
        'Image dimensions exceed maximum allowed',
        details: 'Max dimension: $maxDimension, Provided: ${width}x$height',
      );
    }
  }
}
