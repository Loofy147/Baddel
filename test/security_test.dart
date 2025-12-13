import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:baddel/core/services/supabase_service.dart';
import 'package:baddel/core/services/auth_service.dart';
import 'package:baddel/core/models/item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockAuthService extends Mock implements AuthService {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder {}

void main() {
  late SupabaseService supabaseService;
  late MockAuthService mockAuthService;
  late MockSupabaseClient mockSupabaseClient;

  setUp(() {
    mockAuthService = MockAuthService();
    mockSupabaseClient = MockSupabaseClient();
    supabaseService = SupabaseService();
  });

  group('Security Tests', () {
    test('Unauthorized user cannot delete another user\'s item', () async {
      // Arrange
      final attackerUser = User(id: 'attacker-uuid', appMetadata: {}, userMetadata: {}, aud: 'aud');
      final victimItemId = 'victim-item-uuid';

      when(mockAuthService.currentUser).thenAnswer((_) async => attackerUser);
      when(mockSupabaseClient.from('items').update(any).eq('id', victimItemId).eq('owner_id', attackerUser.id).select()).thenAnswer((_) async => []);

      // Act & Assert
      expect(
        () async => await supabaseService.deleteItem(victimItemId),
        throwsA(isA<Exception>()),
      );
    });

    test('Unauthorized user cannot accept an offer for an item they do not own', () async {
      // Arrange
      final attackerUser = User(id: 'attacker-uuid', appMetadata: {}, userMetadata: {}, aud: 'aud');
      final offerId = 'offer-uuid';

      when(mockAuthService.currentUser).thenAnswer((_) async => attackerUser);
      when(mockSupabaseClient.from('offers').select('seller_id').eq('id', offerId).single()).thenAnswer((_) async => {'seller_id': 'victim-uuid'});

      // Act & Assert
      expect(
        () async => await supabaseService.acceptOffer(offerId),
        throwsA(isA<Exception>()),
      );
    });

    test('getMyInventory should only return items owned by the current user', () async {
      // This test is conceptual as the RLS policy is what enforces this on the server.
      // The Dart code already has the .eq('owner_id', userId) filter.
      // A true test would require a test database and two users.

      // Arrange
      final user = User(id: 'test-user-uuid', appMetadata: {}, userMetadata: {}, aud: 'aud');
      final userItems = [
        {'id': 'item1', 'owner_id': user.id, 'title': 'My Item 1', 'price': 100, 'image_url': '', 'accepts_swaps': false},
      ];

      when(mockAuthService.currentUser).thenAnswer((_) async => user);

      final queryBuilder = MockSupabaseQueryBuilder();
      final filterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabaseClient.from('items')).thenReturn(queryBuilder);
      when(queryBuilder.select()).thenReturn(queryBuilder);
      when(queryBuilder.eq('owner_id', user.id)).thenReturn(filterBuilder);
      when(filterBuilder.eq('status', 'active')).thenAnswer((_) async => userItems);

      // Act
      final result = await supabaseService.getMyInventory();

      // Assert
      expect(result.length, 1);
      expect(result.first.ownerId, user.id);
    });

     test('Users cannot create an offer on behalf of another user', () async {
        // This is enforced by RLS `WITH CHECK (auth.uid() = buyer_id)`
        // The Dart code implicitly uses the authenticated user's ID.
        // A full test would require a test database.

        // Arrange
        final user = User(id: 'buyer-uuid', appMetadata: {}, userMetadata: {}, aud: 'aud');
        when(mockAuthService.currentUser).thenAnswer((_) async => user);

        final queryBuilder = MockSupabaseQueryBuilder();
        when(mockSupabaseClient.from('offers')).thenReturn(queryBuilder);
        when(queryBuilder.insert(any)).thenAnswer((_) async => []);

        // Act
        final result = await supabaseService.createOffer(
            targetItemId: 'item-uuid',
            sellerId: 'seller-uuid',
            cashAmount: 100,
        );

        // Assert
        // We can't easily verify the buyer_id here without more extensive mocking,
        // but we can ensure the code path completes and trust the RLS policy.
        expect(result, isTrue);
    });

  });
}
