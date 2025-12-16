import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineCacheManager {
  static const String _cachePrefix = 'offline_cache_';
  static const Duration _defaultCacheDuration = Duration(hours: 24);

  // Cache data with a key
  static Future<void> cacheData(
    String key,
    dynamic data, {
    Duration? duration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cachePrefix$key';

    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': DateTime.now()
          .add(duration ?? _defaultCacheDuration)
          .millisecondsSinceEpoch,
    };

    await prefs.setString(cacheKey, jsonEncode(cacheData));
  }

  // Retrieve cached data
  static Future<T?> getCachedData<T>(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cachePrefix$key';

    final cachedString = prefs.getString(cacheKey);
    if (cachedString == null) return null;

    try {
      final cacheData = jsonDecode(cachedString);
      final expiry = cacheData['expiry'] as int;

      // Check if cache is still valid
      if (DateTime.now().millisecondsSinceEpoch > expiry) {
        await clearCachedData(key);
        return null;
      }

      return cacheData['data'] as T;
    } catch (e) {
      await clearCachedData(key);
      return null;
    }
  }

  // Clear specific cached data
  static Future<void> clearCachedData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_cachePrefix$key');
  }

  // Clear all cached data
  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((key) => key.startsWith(_cachePrefix))
        .toList();

    for (var key in keys) {
      await prefs.remove(key);
    }
  }

  // Get cache size
  static Future<int> getCacheSize() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((key) => key.startsWith(_cachePrefix))
        .toList();

    return keys.length;
  }
}
