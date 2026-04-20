import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/aerobic.dart';

class LocalCacheService {
  static const String _userRecordsCacheKey = 'aerobic_user_records_cache_';
  static const String _archivedRecordsCacheKey = 'aerobic_archived_records_cache_';
  static const String _cacheSyncTimeKey = 'aerobic_cache_sync_time_';

  // Cache duration: 24 hours
  static const Duration cacheDuration = Duration(hours: 24);

  /// Save user records to local cache
  Future<void> saveUserRecords(int userId, List<Aerobic> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_userRecordsCacheKey$userId';
      final jsonRecords = records.map((r) => r.toJson()).toList();
      final encodedData = jsonEncode(jsonRecords);

      await prefs.setString(key, encodedData);
      await prefs.setInt('$_cacheSyncTimeKey$userId', DateTime.now().millisecondsSinceEpoch);

    } catch (e) {
      print('Error saving user records: $e');
    }
  }

  /// Get user records from local cache
  Future<List<Aerobic>> getUserRecords(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_userRecordsCacheKey$userId';
      final cachedData = prefs.getString(key);

      if (cachedData == null || cachedData.isEmpty) {
        return [];
      }

      final decoded = jsonDecode(cachedData) as List<dynamic>;
      final records = decoded.map((json) => Aerobic.fromJson(json as Map<String, dynamic>)).toList();

      return records;
    } catch (e) {
      print('Error retrieving user records: $e');
      return [];
    }
  }

  /// Save archived records to local cache
  Future<void> saveArchivedRecords(int userId, List<Aerobic> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_archivedRecordsCacheKey$userId';
      final jsonRecords = records.map((r) => r.toJson()).toList();
      final encodedData = jsonEncode(jsonRecords);

      await prefs.setString(key, encodedData);
      await prefs.setInt('$_cacheSyncTimeKey${userId}_archived', DateTime.now().millisecondsSinceEpoch);

    } catch (e) {
      print('Error saving archived records: $e');
    }
  }

  /// Get archived records from local cache
  Future<List<Aerobic>> getArchivedRecords(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_archivedRecordsCacheKey$userId';
      final cachedData = prefs.getString(key);

      if (cachedData == null || cachedData.isEmpty) {
        return [];
      }

      final decoded = jsonDecode(cachedData) as List<dynamic>;
      final records = decoded.map((json) => Aerobic.fromJson(json as Map<String, dynamic>)).toList();

      print('📱 [CACHE] Retrieved ${records.length} archived records from local cache for user $userId');
      return records;
    } catch (e) {
      print('Error retrieving archived records: $e');
      return [];
    }
  }

  /// Save activity types to local cache
  Future<void> saveActivityTypes(int userId, List<String> types) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_userRecordsCacheKey}activity_types_$userId';
      final encodedData = jsonEncode(types);

      await prefs.setString(key, encodedData);
      print('📱 [CACHE] Saved ${types.length} activity types to local cache for user $userId');
    } catch (e) {
      print('❌ [CACHE] Error saving activity types: $e');
    }
  }

  /// Get activity types from local cache
  Future<List<String>> getActivityTypes(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_userRecordsCacheKey}activity_types_$userId';
      final cachedData = prefs.getString(key);

      if (cachedData == null || cachedData.isEmpty) {
        print('📱 [CACHE] No cached activity types found for user $userId');
        return [];
      }

      final decoded = jsonDecode(cachedData) as List<dynamic>;
      final types = decoded.cast<String>();

      print('📱 [CACHE] Retrieved ${types.length} activity types from local cache for user $userId');
      return types;
    } catch (e) {
      print('❌ [CACHE] Error retrieving activity types: $e');
      return [];
    }
  }

  /// Clear activity types cache
  Future<void> clearActivityTypesCache(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_userRecordsCacheKey}activity_types_$userId';
      await prefs.remove(key);

      print('📱 [CACHE] Cleared activity types cache for user $userId');
    } catch (e) {
      print('❌ [CACHE] Error clearing activity types cache: $e');
    }
  }

  /// Check if cache is still valid (not older than cacheDuration)
  Future<bool> isCacheValid(int userId, {bool isArchived = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = isArchived ? '$_cacheSyncTimeKey${userId}_archived' : '$_cacheSyncTimeKey$userId';
      final lastSyncTime = prefs.getInt(key);

      if (lastSyncTime == null) {
        return false;
      }

      final lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncTime);
      final isValid = DateTime.now().difference(lastSync) < cacheDuration;

      return isValid;
    } catch (e) {
      print('Error checking cache validity: $e');
      return false;
    }
  }

  /// Clear user records cache
  Future<void> clearUserRecordsCache(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_userRecordsCacheKey$userId';
      await prefs.remove(key);
      await prefs.remove('$_cacheSyncTimeKey$userId');

    } catch (e) {
      print('Error clearing user records cache: $e');
    }
  }

  /// Clear archived records cache
  Future<void> clearArchivedRecordsCache(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_archivedRecordsCacheKey$userId';
      await prefs.remove(key);
      await prefs.remove('$_cacheSyncTimeKey${userId}_archived');

    } catch (e) {
    }
  }

  /// Clear all cache for a user
  Future<void> clearAllCache(int userId) async {
    try {
      await clearUserRecordsCache(userId);
      await clearArchivedRecordsCache(userId);
      await clearActivityTypesCache(userId);

    } catch (e) {
      print('Error clearing all cache: $e');
    }
  }
}

