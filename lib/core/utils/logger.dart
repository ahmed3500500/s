import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    String name = 'smart_crypto_signals',
    Object? error,
    StackTrace? stackTrace,
  }) {
    final lvl = switch (level) {
      LogLevel.debug => 500,
      LogLevel.info => 800,
      LogLevel.warning => 900,
      LogLevel.error => 1000,
    };
    developer.log(
      message,
      name: name,
      level: lvl,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void debug(String message, {String name = 'smart_crypto_signals'}) {
    log(message, level: LogLevel.debug, name: name);
  }

  static void info(String message, {String name = 'smart_crypto_signals'}) {
    log(message, level: LogLevel.info, name: name);
  }

  static void warning(String message, {String name = 'smart_crypto_signals', Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.warning, name: name, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {String name = 'smart_crypto_signals', Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.error, name: name, error: error, stackTrace: stackTrace);
  }
}
