/// Logging level for the QR scanner
enum LogLevel {
  debug,
  info,
  warning,
  error,
  none,
}

/// Simple logger for the QR scanner plugin
class QRScannerLogger {
  static LogLevel _currentLevel = LogLevel.warning;
  static bool _enabled = true;

  /// Set the current logging level
  static void setLevel(LogLevel level) {
    _currentLevel = level;
  }

  /// Enable or disable logging
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Log a debug message
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  /// Log an info message
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  /// Log a warning message
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  /// Log an error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  static void _log(
    LogLevel level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    if (!_enabled || level.index < _currentLevel.index) {
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    final prefix = '[$timestamp] [$levelStr] QRScanner:';

    print('$prefix $message');
    
    if (error != null) {
      print('$prefix Error: $error');
    }
    
    if (stackTrace != null) {
      print('$prefix StackTrace:\n$stackTrace');
    }
  }
}
