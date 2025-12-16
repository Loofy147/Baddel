import 'dart:async';

class RetryHandler {
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
  }) async {
    int retryCount = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;

        if (retryCount >= maxRetries) {
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(delay);

        // Increase delay for next retry
        delay *= backoffMultiplier;
      }
    }
  }
}
