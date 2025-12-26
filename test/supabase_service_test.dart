import 'package:baddel/core/models/item_model.dart';
import 'package:baddel/core/services/auth_service.dart';
import 'package:baddel/core/services/error_handler.dart';
import 'package:baddel/core/services/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Because I can't run build_runner, I'll create manual mocks.
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockAuthService extends Mock implements AuthService {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}
class MockPostgrestQueryBuilder<T> extends Mock implements PostgrestQueryBuilder<T> {}
class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}
class MockStorageFileApi extends Mock implements StorageFileApi {}
class MockConnectivityService extends Mock implements ConnectivityService {}


void main() {
  late SupabaseService supabaseService;
  late MockSupabaseClient mockSupabaseClient;
  late MockAuthService mockAuthService;
  late MockUser mockUser;
  late MockPostgrestQueryBuilder<dynamic> mockQueryBuilder;
  late MockConnectivityService mockConnectivityService;

  setUp(() {
    // 1. Initialize mocks
    mockSupabaseClient = MockSupabaseClient();
    mockAuthService = MockAuthService();
    mockUser = MockUser();
    mockQueryBuilder = MockPostgrestQueryBuilder();
    mockConnectivityService = MockConnectivityService();

    // 2. Instantiate the service with mocks
    supabaseService = SupabaseService(mockSupabaseClient, mockAuthService, mockConnectivityService);

    // 3. Stub the common method calls
    // Mock the auth flow to always return a logged-in user
    when(mockAuthService.currentUser).thenAnswer((_) async => mockUser);
    when(mockUser.id).thenReturn('test_user_id');
     when(mockConnectivityService.isOnline).thenAnswer((_) async => true);


    // Mock the Supabase fluent interface
    when(mockSupabaseClient.from(any)).thenReturn(mockQueryBuilder);
    when(mockQueryBuilder.select()).thenReturn(mockQueryBuilder);
    when(mockQueryBuilder.update(any)).thenReturn(mockQueryBuilder);
    when(mockQueryBuilder.insert(any)).thenReturn(mockQueryBuilder);
    when(mockQueryBuilder.eq(any, any)).thenReturn(mockQueryBuilder);
    when(mockQueryBuilder.single()).thenAnswer((_) async => {});
  });

  group('SupabaseService Unit Tests', () {
    group('getMyInventory', () {
      test('should return a list of items for a valid user', () async {
        // Arrange
        final mockResponse = [
          {'id': 'item1', 'owner_id': 'test_user_id', 'title': 'Test Item 1', 'price': 100, 'image_url': 'http://example.com/img1.png', 'accepts_swaps': true, 'is_cash_only': false, 'status': 'active'},
          {'id': 'item2', 'owner_id': 'test_user_id', 'title': 'Test Item 2', 'price': 200, 'image_url': 'http://example.com/img2.png', 'accepts_swaps': false, 'is_cash_only': true, 'status': 'active'},
        ];
        // The final call in the chain returns the mock response
        when(mockQueryBuilder.eq('status', 'active')).thenAnswer((_) async => mockResponse);

        // Act
        final result = await supabaseService.getMyInventory();

        // Assert
        expect(result, isA<List<Item>>());
        expect(result.length, 2);
        expect(result[0].title, 'Test Item 1');
        verify(mockSupabaseClient.from('items')).called(1);
        verify(mockQueryBuilder.eq('owner_id', 'test_user_id')).called(1);
      });

      test('should throw AppException on database error', () {
        // Arrange
        when(mockQueryBuilder.eq('status', 'active')).thenThrow(PostgrestException(message: 'Connection error'));

        // Act & Assert
        expect(supabaseService.getMyInventory(), throwsA(isA<AppException>()));
      });
    });

    group('deleteItem', () {
      test('should complete successfully if delete is valid', () async {
        // Arrange
        // The final select() returns a non-empty list to indicate success
        when(mockQueryBuilder.select()).thenAnswer((_) async => [{'id': 'item_to_delete'}]);

        // Act & Assert
        // We expect the future to complete without errors.
        await expectLater(supabaseService.deleteItem('item_to_delete'), completes);
        verify(mockQueryBuilder.update({'status': 'deleted'})).called(1);
        verify(mockQueryBuilder.eq('id', 'item_to_delete')).called(1);
      });

      test('should throw AppException if item does not exist or user is not owner', () {
        // Arrange
        // The final select() returns an empty list to indicate failure
        when(mockQueryBuilder.select()).thenAnswer((_) async => []);

        // Act & Assert
        expect(supabaseService.deleteItem('wrong_item_id'), throwsA(isA<AppException>()));
      });
    });

    group('reportItem', () {
        test('should throw AppException for a duplicate report', () {
            // Arrange
            final duplicateError = PostgrestException(message: 'duplicate key value violates unique constraint', code: '23505');
            when(mockQueryBuilder.insert(any)).thenThrow(duplicateError);

            // Act & Assert
            final call = supabaseService.reportItem(itemId: 'item1', reason: 'spam');
            expect(call, throwsA(isA<AppException>().having((e) => e.code, 'code', 'DUPLICATE_RECORD')));
        });
    });
  });
}
