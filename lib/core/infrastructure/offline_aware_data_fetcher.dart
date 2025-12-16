import 'package:baddel/core/infrastructure/connectivity_service.dart';
import 'package:baddel/core/infrastructure/error_handler.dart';
import 'package:baddel/core/infrastructure/offline_cache_manager.dart';

class OfflineAwareDataFetcher<T> {
  final Future<T> Function() fetchFunction;
  final String cacheKey;
  final Duration? cacheDuration;

  OfflineAwareDataFetcher({
    required this.fetchFunction,
    required this.cacheKey,
    this.cacheDuration,
  });

  Future<T> fetch({
    required ConnectivityService connectivityService,
    bool forceRefresh = false,
  }) async {
    final isConnected = await connectivityService.checkConnectivity();

    // Try to fetch from cache first if offline or not forcing refresh
    if (!isConnected || !forceRefresh) {
      final cachedData = await OfflineCacheManager.getCachedData<T>(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }

    // If online, fetch fresh data
    if (isConnected) {
      try {
        final data = await fetchFunction();
        await OfflineCacheManager.cacheData(
          cacheKey,
          data,
          duration: cacheDuration,
        );
        return data;
      } catch (e) {
        // If fetch fails but we have cached data, return it
        final cachedData = await OfflineCacheManager.getCachedData<T>(cacheKey);
        if (cachedData != null) {
          return cachedData;
        }
        rethrow;
      }
    }

    throw OfflineException('No internet connection and no cached data available');
  }
}
