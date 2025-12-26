import 'package:baddel/core/services/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enhanced exception class with recovery strategies and user-friendly messaging.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final bool isRetryable;
  final String? recoveryAction;

  AppException(
    this.message, {
    this.code,
    this.originalError,
    this.isRetryable = false,
    this.recoveryAction,
  });

  /// Factory constructor to create an AppException from a Supabase error.
  /// This translates backend errors into user-friendly messages with recovery strategies.
  factory AppException.fromSupabaseError(dynamic error) {
    Logger.error('Supabase Error Caught', error, StackTrace.current);

    if (error is PostgrestException) {
      switch (error.code) {
        case '23505': // unique_violation
          return AppException(
            'This item already exists. Please try with different details.',
            code: 'DUPLICATE_RECORD',
            originalError: error,
            isRetryable: false,
            recoveryAction: 'modify_item_details',
          );
        case '42501': // insufficient_privilege
          return AppException(
            'You do not have permission to perform this action. Please check your account status.',
            code: 'UNAUTHORIZED',
            originalError: error,
            isRetryable: false,
            recoveryAction: 'contact_support',
          );
        case 'PGRST116': // RLS violation
          return AppException(
            'Could not access the requested resource. Please try again or contact support.',
            code: 'NOT_FOUND_OR_UNAUTHORIZED',
            originalError: error,
            isRetryable: true,
            recoveryAction: 'retry_or_contact_support',
          );
        case '23503': // foreign_key_violation
          return AppException(
            'The referenced item no longer exists. Please refresh and try again.',
            code: 'REFERENCE_NOT_FOUND',
            originalError: error,
            isRetryable: true,
            recoveryAction: 'refresh_and_retry',
          );
        default:
          return AppException(
            'A database error occurred. Please try again.',
            code: error.code,
            originalError: error,
            isRetryable: true,
            recoveryAction: 'retry',
          );
      }
    } else if (error.toString().contains('SocketException')) {
      return AppException(
        'No internet connection. Please check your network and try again.',
        code: 'NETWORK_ERROR',
        originalError: error,
        isRetryable: true,
        recoveryAction: 'check_connection_and_retry',
      );
    } else if (error.toString().contains('TimeoutException')) {
      return AppException(
        'Request timed out. Please check your connection and try again.',
        code: 'TIMEOUT_ERROR',
        originalError: error,
        isRetryable: true,
        recoveryAction: 'retry',
      );
    } else if (error.toString().contains('JWT')) {
      return AppException(
        'Your session has expired. Please log in again.',
        code: 'AUTH_EXPIRED',
        originalError: error,
        isRetryable: false,
        recoveryAction: 'login_again',
      );
    } else if (error.toString().contains('Invalid')) {
      return AppException(
        'Invalid request. Please check your input and try again.',
        code: 'INVALID_REQUEST',
        originalError: error,
        isRetryable: false,
        recoveryAction: 'validate_input',
      );
    }

    // Generic fallback for unexpected errors.
    return AppException(
      'An unexpected error occurred. Please try again later.',
      code: 'UNKNOWN_ERROR',
      originalError: error,
      isRetryable: true,
      recoveryAction: 'retry_or_contact_support',
    );
  }

  @override
  String toString() {
    return 'AppException(message: $message, code: $code, isRetryable: $isRetryable)';
  }
}

/// Error recovery strategies for handling different types of errors.
class ErrorRecoveryStrategy {
  static Future<T?> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delayBetweenRetries = const Duration(seconds: 2),
    bool exponentialBackoff = true,
  }) async {
    int retryCount = 0;
    Duration currentDelay = delayBetweenRetries;

    while (retryCount < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          Logger.error('Max retries exceeded', e);
          rethrow;
        }

        Logger.warning('Retry attempt $retryCount/$maxRetries after ${currentDelay.inSeconds}s');
        await Future.delayed(currentDelay);

        if (exponentialBackoff) {
          currentDelay = Duration(milliseconds: (currentDelay.inMilliseconds * 1.5).toInt());
        }
      }
    }
    return null;
  }

  /// Handles network-related errors with offline fallback support.
  static Future<T?> executeWithOfflineFallback<T>(
    Future<T> Function() onlineOperation,
    Future<T?> Function() offlineFallback,
  ) async {
    try {
      return await onlineOperation();
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        Logger.warning('Network error detected, attempting offline fallback');
        return await offlineFallback();
      }
      rethrow;
    }
  }

  /// Validates input before sending to the server.
  static bool validateInput(String input, {int minLength = 1, int maxLength = 500}) {
    if (input.isEmpty) return false;
    if (input.length < minLength || input.length > maxLength) return false;
    return true;
  }
}
