import 'logger.dart' show LogLevel;

/// QR Scanner configuration options
class QRScannerConfig {
  /// Maximum number of QR codes to detect in a single image
  final int maxSymbols;

  /// Whether to enable debug logging
  final bool enableLogging;

  /// Logging level
  final LogLevel logLevel;

  /// Timeout for scanning operations in milliseconds
  final int timeoutMs;

  /// Whether to try harder to detect QR codes (slower but more accurate)
  final bool tryHarder;

  const QRScannerConfig({
    this.maxSymbols = 20,
    this.enableLogging = true,
    this.logLevel = LogLevel.debug,
    this.timeoutMs = 30000,
    this.tryHarder = true,
  });

  /// Default configuration
  static const defaultConfig = QRScannerConfig();

  /// Configuration optimized for speed
  static const fastConfig = QRScannerConfig(
    maxSymbols: 5,
    tryHarder: false,
    timeoutMs: 5000,
  );

  /// Configuration optimized for accuracy
  static const accurateConfig = QRScannerConfig(
    maxSymbols: 50,
    tryHarder: true,
    timeoutMs: 60000,
  );

  QRScannerConfig copyWith({
    int? maxSymbols,
    bool? enableLogging,
    LogLevel? logLevel,
    int? timeoutMs,
    bool? tryHarder,
  }) {
    return QRScannerConfig(
      maxSymbols: maxSymbols ?? this.maxSymbols,
      enableLogging: enableLogging ?? this.enableLogging,
      logLevel: logLevel ?? this.logLevel,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      tryHarder: tryHarder ?? this.tryHarder,
    );
  }

  @override
  String toString() {
    return 'QRScannerConfig(maxSymbols: $maxSymbols, enableLogging: $enableLogging, '
        'logLevel: $logLevel, timeoutMs: $timeoutMs, tryHarder: $tryHarder)';
  }
}
