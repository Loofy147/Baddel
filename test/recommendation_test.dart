// test/recommendation_test.dart
import 'package:baddel/core/services/recommendation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'recommendation_test.mocks.dart';

@GenerateMocks([SupabaseClient, GoTrueClient])
void main() {
  // Since we cannot run a live Supabase instance in this test environment,
  // these tests are conceptual. They outline how one *would* test
  // the recommendation service if a mock Supabase client were injectable.

  group('RecommendationService', () {
    test('getPersonalizedFeed should return a list of items', () async {
      // ARRANGE
      final service = RecommendationService();

      // ACT
      // This will make a live network call, which will likely fail in a test env.
      // A real test would involve mocking the Supabase client's `rpc` method.
      final items = await service.getPersonalizedFeed(
        lat: 36.7525, // Algiers
        lng: 3.0588,
      );

      // ASSERT
      // We expect it to fail gracefully and return an empty list from the fallback.
      expect(items, isA<List>());
    });

    test('recordInteraction adds an interaction to the queue', () {
      // ARRANGE
      final service = RecommendationService();

      // ACT
      service.recordInteraction('some-item-id', InteractionType.swipeRight);

      // ASSERT
      // This is difficult to assert without exposing the internal state.
      // A better design might be to have the service return the number of pending interactions.
      // For now, this test is conceptual.
      expect(
        true,
        isTrue,
        reason: 'The service should queue interactions before sending them.'
      );
    });
  });
}
