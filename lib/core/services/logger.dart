// A simple static logger for the application.
// In a real production app, this would be replaced with a more robust
// logging package like 'logger' or 'sentry'.
class Logger {
  // Log levels
  static const String _info = '[INFO]';
  static const String _warning = '[WARNING]';
  static const String _error = '[ERROR]';

  // Info log
  static void info(String message) {
    print('$_info $message');
  }

  // Warning log
  static void warning(String message) {
    print('$_warning $message');
  }

  // Error log
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    print('$_error $message');
    if (error != null) {
      print('  Error: $error');
    }
    if (stackTrace != null) {
      print('  StackTrace: $stackTrace');
    }
  }
}
