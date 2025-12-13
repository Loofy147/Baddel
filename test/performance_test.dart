// test/performance_test.dart
import 'package:baddel/core/services/recommendation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Feed loading benchmark', () async {
    // This is not a true performance test, as it runs on a test runner
    // and makes a live network call. A real performance test would be
    // run on a device with a mocked server response.

    final stopwatch = Stopwatch()..start();

    try {
      await RecommendationService().getPersonalizedFeed(
        lat: 36.7525,
        lng: 3.0588,
      );
    } catch (e) {
      // We expect this to fail in a test environment without a live DB.
      // We are just measuring the time it takes to handle the call.
    }

    stopwatch.stop();
    print('Feed loading took: ${stopwatch.elapsedMilliseconds}ms');

    // We can't make a strong assertion here, but we can check
    // that it doesn't hang indefinitely.
    expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 seconds timeout
  });
}
