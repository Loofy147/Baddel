class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  static AppException fromSupabaseError(dynamic error) {
    if (error.toString().contains('JWT')) {
      return AppException('Session expired. Please login again.', code: 'AUTH_EXPIRED');
    }
    // ... handle other cases
    return AppException('An unexpected error occurred.', originalError: error);
  }
}
