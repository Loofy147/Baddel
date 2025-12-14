// lib/core/services/logger.dart

class Logger {
  static void info(String message) {
    print('[INFO] $message');
  }

  static void warning(String message) {
    print('[WARNING] $message');
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    print('[ERROR] $message');
    if (error != null) {
      print('  Error: $error');
    }
    if (stackTrace != null) {
      print('  StackTrace: $stackTrace');
    }
  }
}
