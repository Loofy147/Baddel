import 'package:baddel/core/services/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// A custom exception class for the application.
// This allows for consistent error handling and user feedback.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  // Factory constructor to create an AppException from a Supabase error.
  // This is the core of the error handling strategy, translating cryptic backend
  // errors into user-friendly messages.
  factory AppException.fromSupabaseError(dynamic error) {
    // Log the original error for debugging purposes.
    Logger.instance.e('Supabase Error Caught', error: error, stackTrace: StackTrace.current);

    if (error is PostgrestException) {
      // Handle specific Postgres error codes for more granular feedback.
      // See: https://www.postgresql.org/docs/current/errcodes-appendix.html
      switch (error.code) {
        case '23505': // unique_violation
          return AppException(
            'This item already exists or has been reported by you.',
            code: 'DUPLICATE_RECORD',
            originalError: error,
          );
        case '42501': // insufficient_privilege
          return AppException(
            'You do not have permission to perform this action.',
            code: 'UNAUTHORIZED',
            originalError: error,
          );
        case 'PGRST116': // RLS violation
          return AppException(
            'Could not find the requested resource or you do not have permission.',
            code: 'NOT_FOUND_OR_UNAUTHORIZED',
            originalError: error,
          );
        // Add more specific cases as needed.
        default:
          return AppException(
            'A database error occurred: ${error.message}',
            code: error.code,
            originalError: error,
          );
      }
    } else if (error.toString().contains('SocketException')) {
      return AppException(
        'Could not connect to the server. Please check your internet connection.',
        code: 'NETWORK_ERROR',
        originalError: error,
      );
    } else if (error.toString().contains('JWT')) {
      return AppException(
        'Your session has expired. Please log in again.',
        code: 'AUTH_EXPIRED',
        originalError: error,
      );
    }

    // Generic fallback for unexpected errors.
    return AppException(
      'An unexpected error occurred. Please try again later.',
      code: 'UNKNOWN_ERROR',
      originalError: error,
    );
  }

  @override
  String toString() {
    return 'AppException(message: $message, code: $code, originalError: $originalError)';
  }
}
