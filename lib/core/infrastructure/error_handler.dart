import 'package:flutter/material.dart';

class OfflineException implements Exception {
  final String message;
  OfflineException(this.message);

  @override
  String toString() => 'OfflineException: $message';
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException(this.message, {this.statusCode});

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

class ErrorHandler {
  static String getUserFriendlyMessage(dynamic error) {
    if (error is OfflineException) {
      return 'No internet connection. Please check your network settings.';
    }

    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }

    if (error is ServerException) {
      if (error.statusCode == 429) {
        return 'Too many requests. Please wait a moment and try again.';
      }
      if (error.statusCode! >= 500) {
        return 'Server error. Please try again later.';
      }
      return 'Something went wrong: ${error.message}';
    }

    // Generic error
    return 'An unexpected error occurred. Please try again.';
  }

  static IconData getErrorIcon(dynamic error) {
    if (error is OfflineException) {
      return Icons.wifi_off;
    }
    if (error is TimeoutException) {
      return Icons.hourglass_empty;
    }
    if (error is ServerException) {
      return Icons.cloud_off;
    }
    return Icons.error_outline;
  }

  static Color getErrorColor(dynamic error) {
    if (error is OfflineException) {
      return Colors.orange;
    }
    if (error is TimeoutException) {
      return Colors.amber;
    }
    return Colors.red;
  }
}
