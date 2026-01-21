import 'package:flutter_test/flutter_test.dart';
import 'package:super_qr_code_scanner/super_qr_code_scanner.dart';

void main() {
  group('QRCode Model', () {
    test('creates QRCode with required fields', () {
      final qr = QRCode(content: 'test', format: 'QRCode');
      expect(qr.content, 'test');
      expect(qr.format, 'QRCode');
      expect(qr.position, null);
    });

    test('QRCode equality works correctly', () {
      final qr1 = QRCode(content: 'test', format: 'QRCode');
      final qr2 = QRCode(content: 'test', format: 'QRCode');
      final qr3 = QRCode(content: 'other', format: 'QRCode');

      expect(qr1, equals(qr2));
      expect(qr1, isNot(equals(qr3)));
    });

    test('QRCode toJson works', () {
      final qr = QRCode(content: 'test', format: 'QRCode');
      final json = qr.toJson();
      
      expect(json['content'], 'test');
      expect(json['format'], 'QRCode');
      expect(json.containsKey('position'), true);
    });
  });

  group('QRCodePosition Model', () {
    test('creates position with coordinates', () {
      final pos = QRCodePosition(x: 10, y: 20, width: 100, height: 100);
      expect(pos.x, 10);
      expect(pos.y, 20);
      expect(pos.width, 100);
      expect(pos.height, 100);
    });

    test('toJson works correctly', () {
      final pos = QRCodePosition(x: 10, y: 20, width: 100, height: 100);
      final json = pos.toJson();
      
      expect(json['x'], 10);
      expect(json['y'], 20);
      expect(json['width'], 100);
      expect(json['height'], 100);
    });
  });

  group('QRScannerConfig', () {
    test('default config has expected values', () {
      final config = QRScannerConfig.defaultConfig;
      expect(config.maxSymbols, 20);
      expect(config.enableLogging, false);
      expect(config.tryHarder, true);
      expect(config.timeoutMs, 30000);
    });

    test('fast config optimizes for speed', () {
      final config = QRScannerConfig.fastConfig;
      expect(config.maxSymbols, 5);
      expect(config.tryHarder, false);
      expect(config.timeoutMs, 5000);
    });

    test('accurate config optimizes for accuracy', () {
      final config = QRScannerConfig.accurateConfig;
      expect(config.maxSymbols, 50);
      expect(config.tryHarder, true);
      expect(config.timeoutMs, 60000);
    });

    test('copyWith creates modified config', () {
      final config = QRScannerConfig.defaultConfig;
      final modified = config.copyWith(maxSymbols: 10);
      
      expect(modified.maxSymbols, 10);
      expect(modified.enableLogging, config.enableLogging);
      expect(modified.tryHarder, config.tryHarder);
    });
  });

  group('Exceptions', () {
    test('QRScannerException has message and details', () {
      final ex = QRScannerException('test message', details: 'test details');
      expect(ex.message, 'test message');
      expect(ex.details, 'test details');
      expect(ex.toString(), contains('test message'));
      expect(ex.toString(), contains('test details'));
    });

    test('LibraryLoadException is QRScannerException', () {
      final ex = LibraryLoadException('failed to load');
      expect(ex, isA<QRScannerException>());
      expect(ex.message, 'failed to load');
    });

    test('ImageProcessingException is QRScannerException', () {
      final ex = ImageProcessingException('failed to process');
      expect(ex, isA<QRScannerException>());
      expect(ex.message, 'failed to process');
    });

    test('InvalidParameterException is QRScannerException', () {
      final ex = InvalidParameterException('invalid param');
      expect(ex, isA<QRScannerException>());
      expect(ex.message, 'invalid param');
    });
  });

  group('Logger', () {
    test('can set log level', () {
      QRScannerLogger.setLevel(LogLevel.debug);
      QRScannerLogger.setLevel(LogLevel.error);
      // No assertion, just ensuring no crash
    });

    test('can enable/disable logging', () {
      QRScannerLogger.setEnabled(true);
      QRScannerLogger.setEnabled(false);
      // No assertion, just ensuring no crash
    });

    test('logging methods do not crash', () {
      QRScannerLogger.debug('debug message');
      QRScannerLogger.info('info message');
      QRScannerLogger.warning('warning message');
      QRScannerLogger.error('error message');
      // No assertion, just ensuring no crash
    });
  });
}
