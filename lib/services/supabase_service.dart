import 'package:baddel/services/storage_service.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerSingleton<SupabaseService>(SupabaseService());
  locator.registerLazySingleton<StorageService>(() => StorageService());
}

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;
}
