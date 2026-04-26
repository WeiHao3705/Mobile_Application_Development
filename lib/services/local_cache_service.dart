import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/aerobic.dart';
import '../models/exercise.dart';

enum ExerciseMediaType { image, video }

class LocalCacheService {
  static const String _userRecordsCacheKey = 'aerobic_user_records_cache_';
  static const String _archivedRecordsCacheKey =
      'aerobic_archived_records_cache_';
  static const String _cacheSyncTimeKey = 'aerobic_cache_sync_time_';
  static const String _exerciseMediaCacheKey = 'exercise_media_cache_';
  static const String _exerciseMediaDirectoryName = 'exercise_media_cache';
  static const String _exerciseDataDirectoryName = 'exercise_data_cache';
  static const String _exerciseListCacheFileName = 'exercise_list_cache.json';

  // Cache duration: 24 hours
  static const Duration cacheDuration = Duration(hours: 24);

  Future<void> saveExerciseListCache(List<Exercise> exercises) async {
    try {
      final file = await _getExerciseListCacheFile();
      final payload = <String, dynamic>{
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'items': exercises
            .map(
              (exercise) => <String, dynamic>{
                'id': exercise.id,
                'name': exercise.name,
                'primary_muscle': exercise.primaryMuscle,
                'equipment': exercise.equipment,
                'image_url': exercise.imageUrl,
                'secondary_muscle': exercise.secondaryMuscles,
                'instruction': exercise.howTo,
                'video_url': exercise.videoUrl,
              },
            )
            .toList(),
      };

      await file.writeAsString(jsonEncode(payload), flush: true);
    } catch (e) {
      print('Error saving exercise list cache: $e');
    }
  }

  Future<List<Exercise>> getExerciseListCache() async {
    try {
      final file = await _getExerciseListCacheFile();
      if (!await file.exists()) {
        return [];
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return [];
      }

      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final savedAtRaw = payload['savedAt'] as int?;
      final items = payload['items'];
      if (savedAtRaw == null || items is! List) {
        return [];
      }

      final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtRaw);
      if (DateTime.now().difference(savedAt) >= cacheDuration) {
        await file.delete();
        return [];
      }

      return items
          .whereType<Map>()
          .map((json) => Exercise.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print('Error reading exercise list cache: $e');
      return [];
    }
  }

  Future<void> clearExerciseListCache() async {
    try {
      final file = await _getExerciseListCacheFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error clearing exercise list cache: $e');
    }
  }

  Future<File?> getCachedExerciseMediaFile({
    required String exerciseId,
    required String mediaUrl,
    required ExerciseMediaType mediaType,
  }) async {
    try {
      final normalizedUrl = mediaUrl.trim();
      if (normalizedUrl.isEmpty) {
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final key = _exerciseMediaMetadataKey(
        exerciseId: exerciseId,
        mediaUrl: normalizedUrl,
        mediaType: mediaType,
      );
      final metadataRaw = prefs.getString(key);
      if (metadataRaw == null || metadataRaw.isEmpty) {
        return null;
      }

      final metadata = jsonDecode(metadataRaw) as Map<String, dynamic>;
      final filePath = metadata['path'] as String?;
      final savedAtRaw = metadata['savedAt'] as int?;
      if (filePath == null || filePath.isEmpty || savedAtRaw == null) {
        await prefs.remove(key);
        return null;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        await prefs.remove(key);
        return null;
      }

      final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtRaw);
      if (DateTime.now().difference(savedAt) >= cacheDuration) {
        await file.delete();
        await prefs.remove(key);
        return null;
      }

      return file;
    } catch (e) {
      print('Error reading exercise media cache: $e');
      return null;
    }
  }

  Future<File?> cacheExerciseMediaFromUrl({
    required String exerciseId,
    required String mediaUrl,
    required ExerciseMediaType mediaType,
  }) async {
    try {
      final normalizedUrl = mediaUrl.trim();
      if (normalizedUrl.isEmpty) {
        return null;
      }

      final uri = Uri.tryParse(normalizedUrl);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        return null;
      }

      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final dir = await _getExerciseMediaDirectory();
      final extension = _resolveFileExtension(uri, mediaType);
      final fileName = _exerciseMediaFileName(
        exerciseId: exerciseId,
        mediaUrl: normalizedUrl,
        mediaType: mediaType,
        extension: extension,
      );
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes, flush: true);

      final prefs = await SharedPreferences.getInstance();
      final key = _exerciseMediaMetadataKey(
        exerciseId: exerciseId,
        mediaUrl: normalizedUrl,
        mediaType: mediaType,
      );
      await prefs.setString(
        key,
        jsonEncode(<String, dynamic>{
          'path': file.path,
          'savedAt': DateTime.now().millisecondsSinceEpoch,
        }),
      );

      return file;
    } catch (e) {
      print('Error caching exercise media file: $e');
      return null;
    }
  }

  Future<File?> getOrCacheExerciseMediaFile({
    required String exerciseId,
    required String mediaUrl,
    required ExerciseMediaType mediaType,
  }) async {
    final cached = await getCachedExerciseMediaFile(
      exerciseId: exerciseId,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
    );
    if (cached != null) {
      return cached;
    }

    return cacheExerciseMediaFromUrl(
      exerciseId: exerciseId,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
    );
  }

  Future<void> clearExerciseMediaCacheForExercise(String exerciseId) async {
    try {
      final id = exerciseId.trim();
      if (id.isEmpty) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
        (key) => key.startsWith('$_exerciseMediaCacheKey${id}_'),
      );

      for (final key in keys) {
        final metadataRaw = prefs.getString(key);
        if (metadataRaw != null && metadataRaw.isNotEmpty) {
          try {
            final metadata = jsonDecode(metadataRaw) as Map<String, dynamic>;
            final path = metadata['path'] as String?;
            if (path != null && path.isNotEmpty) {
              final file = File(path);
              if (await file.exists()) {
                await file.delete();
              }
            }
          } catch (_) {
            // Ignore metadata parse errors and remove key.
          }
        }

        await prefs.remove(key);
      }
    } catch (e) {
      print('Error clearing exercise media cache: $e');
    }
  }

  /// Save user records to local cache
  Future<void> saveUserRecords(int userId, List<Aerobic> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_userRecordsCacheKey$userId';
      final jsonRecords = records.map((r) => r.toJson()).toList();
      final encodedData = jsonEncode(jsonRecords);

      await prefs.setString(key, encodedData);
      await prefs.setInt(
        '$_cacheSyncTimeKey$userId',
        DateTime.now().millisecondsSinceEpoch,
      );
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
      final records = decoded
          .map((json) => Aerobic.fromJson(json as Map<String, dynamic>))
          .toList();

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
      await prefs.setInt(
        '$_cacheSyncTimeKey${userId}_archived',
        DateTime.now().millisecondsSinceEpoch,
      );
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
      final records = decoded
          .map((json) => Aerobic.fromJson(json as Map<String, dynamic>))
          .toList();

      print(
        'Retrieved ${records.length} archived records from local cache for user $userId',
      );
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
      print(
        'Saved ${types.length} activity types to local cache for user $userId',
      );
    } catch (e) {
      print('Error saving activity types: $e');
    }
  }

  /// Get activity types from local cache
  Future<List<String>> getActivityTypes(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_userRecordsCacheKey}activity_types_$userId';
      final cachedData = prefs.getString(key);

      if (cachedData == null || cachedData.isEmpty) {
        print('No cached activity types found for user $userId');
        return [];
      }

      final decoded = jsonDecode(cachedData) as List<dynamic>;
      final types = decoded.cast<String>();

      print(
        'Retrieved ${types.length} activity types from local cache for user $userId',
      );
      return types;
    } catch (e) {
      print('Error retrieving activity types: $e');
      return [];
    }
  }

  /// Clear activity types cache
  Future<void> clearActivityTypesCache(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_userRecordsCacheKey}activity_types_$userId';
      await prefs.remove(key);

      print('Cleared activity types cache for user $userId');
    } catch (e) {
      print('Error clearing activity types cache: $e');
    }
  }

  /// Check if cache is still valid (not older than cacheDuration)
  Future<bool> isCacheValid(int userId, {bool isArchived = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = isArchived
          ? '$_cacheSyncTimeKey${userId}_archived'
          : '$_cacheSyncTimeKey$userId';
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
    } catch (e) {}
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

  String _exerciseMediaMetadataKey({
    required String exerciseId,
    required String mediaUrl,
    required ExerciseMediaType mediaType,
  }) {
    final normalizedExerciseId = exerciseId.trim().isEmpty
        ? 'unknown'
        : exerciseId.trim();
    final hash = sha1.convert(utf8.encode(mediaUrl.trim())).toString();
    return '$_exerciseMediaCacheKey${normalizedExerciseId}_${mediaType.name}_$hash';
  }

  String _exerciseMediaFileName({
    required String exerciseId,
    required String mediaUrl,
    required ExerciseMediaType mediaType,
    required String extension,
  }) {
    final normalizedExerciseId = exerciseId.trim().isEmpty
        ? 'unknown'
        : exerciseId.trim();
    final hash = sha1.convert(utf8.encode(mediaUrl.trim())).toString();
    return '${normalizedExerciseId}_${mediaType.name}_$hash$extension';
  }

  String _resolveFileExtension(Uri uri, ExerciseMediaType mediaType) {
    final path = uri.path.toLowerCase();
    if (path.endsWith('.gif')) return '.gif';
    if (path.endsWith('.png')) return '.png';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return '.jpg';
    if (path.endsWith('.webp')) return '.webp';
    if (path.endsWith('.mp4')) return '.mp4';
    if (path.endsWith('.mov')) return '.mov';
    if (path.endsWith('.webm')) return '.webm';
    return mediaType == ExerciseMediaType.image ? '.img' : '.video';
  }

  Future<Directory> _getExerciseMediaDirectory() async {
    final root = await getTemporaryDirectory();
    final dir = Directory('${root.path}/$_exerciseMediaDirectoryName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _getExerciseListCacheFile() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/$_exerciseDataDirectoryName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}/$_exerciseListCacheFileName');
  }
}
