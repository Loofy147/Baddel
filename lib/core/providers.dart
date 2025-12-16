import 'package:baddel/core/models/item_model.dart';
import 'package:baddel/core/services/auth_service.dart';
import 'package:baddel/core/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

// A provider for the SupabaseClient
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// 1. Service Provider
// A simple provider for the SupabaseService, so we can access it from other providers.
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final authService = ref.watch(authServiceProvider);
  return SupabaseService(client, authService);
});

// 2. Data Provider (FutureProvider)
// This provider will fetch the user profile data.
// It uses the supabaseServiceProvider to get an instance of SupabaseService.
// The .autoDispose modifier is used to automatically dispose the provider's state when it's no longer listened to.
final userProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return await supabaseService.getUserProfile();
});

final userProfileStreamProvider = StreamProvider.autoDispose<Map<String, dynamic>?>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return supabaseService.getUserProfileStream();
});

final myInventoryProvider = FutureProvider.autoDispose<List<Item>>((ref) async {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return await supabaseService.getMyInventory();
});

final userPrivateDataProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final supabaseService = ref.watch(supabaseServiceProvider);
  // This method needs to be created in SupabaseService
  return await supabaseService.getUserPrivateData();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final isAdminProvider = Provider.autoDispose<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.when(
    data: (data) => data?['is_admin'] ?? false,
    loading: () => false,
    error: (e, s) => false,
  );
});
