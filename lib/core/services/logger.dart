// A simple singleton logger for the application.
// In a real production app, this would be replaced with a more robust
// logging package like 'logger' or 'sentry'.
class Logger {
  // Private constructor
  Logger._internal();

  // Singleton instance
  static final Logger _instance = Logger._internal();
  static Logger get instance => _instance;

  // Log levels
  static const String _info = '[INFO]';
  static const String _warning = '[WARNING]';
  static const String _error = '[ERROR]';

  // Info log
  void i(String message) {
    print('$_info $message');
  }

  // Warning log
  void w(String message) {
    print('$_warning $message');
  }

  // Error log
  void e(String message, {dynamic error, StackTrace? stackTrace}) {
    print('$_error $message');
    if (error != null) {
      print('  Error: $error');
    }
    if (stackTrace != null) {
      print('  StackTrace: $stackTrace');
    }
  }
}
