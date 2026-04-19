import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import '../models/aerobic.dart';
import '../config/supabase_config.dart';

class AerobicRepository {
  final _supabase = Supabase.instance.client;

  Map<String, String> routeImageRequestHeaders() {
    return const {
      'apikey': supabaseAnonKey,
      'Authorization': 'Bearer $supabaseAnonKey',
    };
  }

  String resolveRouteImageUrl(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return '';
    }

    if (value.contains('via.placeholder.com')) {
      return '';
    }

    String objectPath = value;
    String? hintedBucket;
    final uri = Uri.tryParse(value);

    // Handle full Supabase public URLs and extract bucket + object path.
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      final publicIndex = uri.pathSegments.indexOf('public');
      if (publicIndex != -1 && uri.pathSegments.length > publicIndex + 2) {
        hintedBucket = uri.pathSegments[publicIndex + 1];
        objectPath = uri.pathSegments.sublist(publicIndex + 2).join('/');
      } else {
        return value;
      }
    } else {
      if (value.startsWith('/storage/v1/object/public/')) {
        final parts = value.substring('/storage/v1/object/public/'.length).split('/');
        if (parts.length >= 2) {
          hintedBucket = parts.first;
          objectPath = parts.sublist(1).join('/');
        }
      } else if (value.startsWith('storage/v1/object/public/')) {
        final parts = value.substring('storage/v1/object/public/'.length).split('/');
        if (parts.length >= 2) {
          hintedBucket = parts.first;
          objectPath = parts.sublist(1).join('/');
        }
      } else if (value.startsWith('aerobic_route/')) {
        hintedBucket = 'aerobic_route';
        objectPath = value.substring('aerobic_route/'.length);
      } else if (value.startsWith('aerobic_routes/')) {
        hintedBucket = 'aerobic_routes';
        objectPath = value.substring('aerobic_routes/'.length);
      } else if (value.startsWith('routes/')) {
        hintedBucket = 'aerobic_route';
        objectPath = value;
      }
    }

    try {
      objectPath = Uri.decodeComponent(objectPath);
    } catch (_) {
      // Keep original path if it is not encoded.
    }

    final normalizedPath = objectPath.startsWith('/') ? objectPath.substring(1) : objectPath;
    final pathCandidates = <String>{
      if (normalizedPath.isNotEmpty) normalizedPath,
      if (normalizedPath.isNotEmpty && !normalizedPath.startsWith('routes/')) 'routes/$normalizedPath',
      if (normalizedPath.startsWith('routes/')) normalizedPath.substring('routes/'.length),
    };

    final bucketCandidates = <String>{
      if (hintedBucket != null && hintedBucket.isNotEmpty) hintedBucket,
      'aerobic_route',
      'aerobic_routes',
    };

    // Try to construct URL manually in the CORRECT format: https://{project}.supabase.co/storage/v1/object/public/{bucket}/{path}
    for (final bucket in bucketCandidates) {
      for (final path in pathCandidates) {
        try {
          // Manually construct the correct URL format
          final manualUrl = '$supabaseUrl/storage/v1/object/public/$bucket/$path';
          return manualUrl;
        } catch (_) {
          // Try the next candidate.
        }
      }
    }

    return '';
  }

  // Initialize and verify storage bucket on first use
  Future<void> _initializeStorage() async {
    try {
      print('📦 [STORAGE] Checking if aerobic_route bucket exists...');
      print('📦 [STORAGE] Listing all available buckets...');

      // Try to list buckets to see what's actually available
      final buckets = await _supabase.storage.listBuckets();

      print('📦 [STORAGE] Available buckets:');
      for (var bucket in buckets) {
        print('   - Name: "${bucket.name}" | Public: ${bucket.public}');
      }

      final aerobicBucketExists = buckets.any((b) => b.name == 'aerobic_route');

      if (!aerobicBucketExists) {
        print('❌ [STORAGE] "aerobic_route" bucket NOT found!');
        print('⚠️  [STORAGE] Check the exact bucket name above');
        print('⚠️  [STORAGE] Supabase bucket names are case-sensitive');
      } else {
        final aerobicBucket = buckets.firstWhere((b) => b.name == 'aerobic_route');
        print('✅ [STORAGE] aerobic_route bucket exists');
        print('   Public: ${aerobicBucket.public}');
      }
    } catch (e) {
      print('❌ [STORAGE] Error listing buckets: $e');
      print('⚠️  [STORAGE] This might be an authentication issue');
      print('⚠️  [STORAGE] Check: Is your Supabase anon key correct in main.dart?');
    }
  }

  Future<List<Aerobic>> fetchUserRecords(int userId) async {
    try {
      print('\n📥 [FETCH] ========== FETCHING RECORDS ==========');
      print('📥 [FETCH] User ID: $userId');
      final response = await _supabase
          .from('AerobicExercise')
          .select()
          .eq('user_id', userId)
          .eq('is_archived', false)
          .order('start_at', ascending: false);

      if (response is List) {
        print('📥 [FETCH] Retrieved ${response.length} records from database');

        final records = <Aerobic>[];

        for (int i = 0; i < response.length; i++) {
          final data = response[i];
          if (data is Map<String, dynamic>) {
            final aerobic = Aerobic.fromJson(data);

            // Print detailed info about each record
            print('\n📥 [FETCH] Record #${i + 1}:');
            print('   Activity: ${aerobic.activity_type}');
            print('   Location: ${aerobic.location}');
            print('   Distance: ${aerobic.total_distance} km');
            print('   🖼️  RAW route_image from DB:');
            print('       "${aerobic.route_image}"');
            print('   URL Length: ${aerobic.route_image.length} characters');
            print('   Is HTTPS: ${aerobic.route_image.startsWith('https://')}');
            print('   Contains supabase.co: ${aerobic.route_image.contains('supabase.co')}');
            print('   Contains /storage/: ${aerobic.route_image.contains('/storage/')}');
            print('   Contains aerobic_route: ${aerobic.route_image.contains('aerobic_route')}');

            records.add(aerobic);
          }
        }

        print('\n✅ [FETCH] Successfully parsed ${records.length} records');
        print('📥 [FETCH] ========== FETCH COMPLETE ==========\n');
        return records;
      }

      print('⚠️  [FETCH] Response is not a list: ${response.runtimeType}');
      return [];
    } catch (e) {
      print('❌ [FETCH] Error fetching user records: $e');
      throw Exception('Failed to fetch user records: $e');
    }
  }

  // ✅ NEW: Fetch ARCHIVED records only
  Future<List<Aerobic>> fetchArchivedRecords(int userId) async {
    try {
      print('\n📥 [FETCH-ARCHIVED] ========== FETCHING ARCHIVED RECORDS ==========');
      print('📥 [FETCH-ARCHIVED] User ID: $userId');
      final response = await _supabase
          .from('AerobicExercise')
          .select()
          .eq('user_id', userId)
          .eq('is_archived', true)
          .order('start_at', ascending: false);

      if (response is List) {
        print('📥 [FETCH-ARCHIVED] Retrieved ${response.length} ARCHIVED records from database');

        final records = <Aerobic>[];

        for (int i = 0; i < response.length; i++) {
          final data = response[i];
          if (data is Map<String, dynamic>) {
            final aerobic = Aerobic.fromJson(data);

            // Print detailed info about each archived record
            print('\n📥 [FETCH-ARCHIVED] Archived Record #${i + 1}:');
            print('   Activity: ${aerobic.activity_type}');
            print('   Location: ${aerobic.location}');
            print('   Distance: ${aerobic.total_distance} km');
            print('   Is Archived: ${aerobic.is_archived}');
            print('   Date: ${aerobic.start_at}');

            records.add(aerobic);
          }
        }

        print('\n✅ [FETCH-ARCHIVED] Successfully parsed ${records.length} ARCHIVED records');
        print('📥 [FETCH-ARCHIVED] ========== FETCH COMPLETE ==========\n');
        return records;
      }

      print('⚠️  [FETCH-ARCHIVED] Response is not a list: ${response.runtimeType}');
      return [];
    } catch (e) {
      print('❌ [FETCH-ARCHIVED] Error fetching archived records: $e');
      throw Exception('Failed to fetch archived records: $e');
    }
  }

  Future<Aerobic> createAerobicRecord(Aerobic aerobicRecord) async {
    try {
      final recordData = aerobicRecord.toJson();

      recordData.remove('id');

      final response = await _supabase.from('AerobicExercise').insert(
          recordData).select().single();

      print('Aerobic record created successfully');
      return Aerobic.fromJson(response);
    } catch (e) {
      print('Error creating aerobic record: $e');
      throw Exception('Failed to create aerobic record: $e');
    }
  }

  Future<String> uploadAerobicRouteImage(String fileName, Uint8List imageBytes) async {
    const String bucketId = 'aerobic_route';
    const int maxUploadAttempts = 3;

    try {
      print('📤 [UPLOAD] Starting route image upload...');
      print('📤 [UPLOAD] File: $fileName');
      print('📤 [UPLOAD] Size: ${imageBytes.length} bytes');
      print('📤 [UPLOAD] Supabase URL: $supabaseUrl');

      if (imageBytes.isEmpty) {
        throw Exception('Image bytes are empty');
      }

      // Build the object path
      final objectPath = 'routes/$fileName';
      print('📤 [UPLOAD] Object path: $objectPath');

      // Try upload with retries
      String? lastError;
      for (var attempt = 1; attempt <= maxUploadAttempts; attempt++) {
        try {
          print('📤 [UPLOAD] Attempt $attempt/$maxUploadAttempts...');

          await _uploadViaRestApi(
            bucketId: bucketId,
            objectPath: objectPath,
            imageBytes: imageBytes,
          );

          // IMPORTANT: Manually construct the public URL in the correct format
          // Format: https://{project}.supabase.co/storage/v1/object/public/{bucket}/{path}
          // This matches the exact format Supabase expects for public bucket access
          final publicUrl = '$supabaseUrl/storage/v1/object/public/$bucketId/$objectPath';

          print('✅ [UPLOAD] Upload successful!');
          print('✅ [UPLOAD] Constructed public URL: $publicUrl');

          // Verify the URL is accessible by checking if we can reach it
          try {
            final response = await http.head(
              Uri.parse(publicUrl),
              headers: routeImageRequestHeaders(),
            ).timeout(const Duration(seconds: 5));

            if (response.statusCode == 200) {
              print('✅ [VERIFY] Public URL is accessible (HTTP ${response.statusCode})');
            } else if (response.statusCode == 403) {
              print('⚠️  [VERIFY] URL accessible but got 403 - bucket might not be public');
              print('⚠️  [ACTION] Go to Supabase console → Storage → aerobic_route → Toggle "Public" ON');
            } else {
              print('⚠️  [VERIFY] Got HTTP ${response.statusCode} - URL may not be fully accessible');
            }
          } catch (e) {
            print('⚠️  [VERIFY] Could not verify URL accessibility: $e');
          }

          return publicUrl;
        } catch (e) {
          lastError = e.toString();
          print('❌ [UPLOAD] Attempt $attempt failed: $e');

          if (attempt < maxUploadAttempts) {
            await Future.delayed(Duration(milliseconds: 400 * attempt));
          }
        }
      }

      throw Exception('Upload failed after $maxUploadAttempts attempts: $lastError');
    } catch (e) {
      print('❌ [UPLOAD] Error: $e');

      // Provide diagnostic info
      if (e.toString().contains('404')) {
        print('⚠️  Bucket not found - ensure "aerobic_route" bucket exists');
      } else if (e.toString().contains('403') || e.toString().contains('permission')) {
        print('⚠️  Permission denied - ensure bucket is PUBLIC');
      }

      return '';
    }
  }

  Future<void> _uploadViaRestApi({
    required String bucketId,
    required String objectPath,
    required Uint8List imageBytes,
  }) async {
    // Encode path properly
    final encodedPath = objectPath
        .split('/')
        .map(Uri.encodeComponent)
        .join('/');

    final uri = Uri.parse('$supabaseUrl/storage/v1/object/$bucketId/$encodedPath');
    print('📤 [REST] POST to: $uri');

    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);

      // Set required headers - EXACTLY like the working code
      request.headers.set('apikey', supabaseAnonKey);
      request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
      request.headers.set('x-upsert', 'true');
      request.headers.set(HttpHeaders.contentTypeHeader, 'image/png');

      print('📤 [REST] Headers set, adding image bytes...');
      request.add(imageBytes);

      print('📤 [REST] Sending request...');
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('📤 [REST] Response status: ${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}: $responseBody');
      }

      print('✅ [REST] Request successful');
    } finally {
      client.close(force: true);
    }
  }

  Future<List<Aerobic>> fetchUserArchivedRecords(String userId) async {
    try {
      print('\n📥 [FETCH-ARCHIVED] Fetching archived records for user: $userId');
      final response = await _supabase
          .from('AerobicExercise')
          .select()
          .eq('user_id', userId)
          .eq('is_archived', true)
          .order('start_at', ascending: false);

      if (response is List) {
        final records = response.map((data) => Aerobic.fromJson(data as Map<String, dynamic>)).toList();
        print('✅ [FETCH-ARCHIVED] Retrieved ${records.length} archived records');
        return records;
      }

      return [];
    } catch (e) {
      print('❌ [FETCH-ARCHIVED] Error: $e');
      throw Exception('Failed to fetch archived records: $e');
    }
  }

  Future<void> archiveRecord(String recordId) async {
    try {
      print('🗂️ [ARCHIVE] Archiving record: $recordId');
      await _supabase
          .from('AerobicExercise')
          .update({'is_archived': true})
          .eq('aerobic_id', recordId);
      print('✅ [ARCHIVE] Record archived successfully');
    } catch (e) {
      print('❌ [ARCHIVE] Error: $e');
      throw Exception('Failed to archive record: $e');
    }
  }

  Future<void> unarchiveRecord(String recordId) async {
    try {
      print('📤 [UNARCHIVE] Unarchiving record: $recordId');
      await _supabase
          .from('AerobicExercise')
          .update({'is_archived': false})
          .eq('aerobic_id', recordId);
      print('✅ [UNARCHIVE] Record unarchived successfully');
    } catch (e) {
      print('❌ [UNARCHIVE] Error: $e');
      throw Exception('Failed to unarchive record: $e');
    }
  }

  // ✅ NEW: Update archive status and return the updated record
  Future<Aerobic> updateAerobicArchiveStatus(String recordId, bool isArchived) async {
    try {
      print('🔄 [UPDATE-ARCHIVE] Updating record $recordId to isArchived: $isArchived');
      
      await _supabase
          .from('AerobicExercise')
          .update({'is_archived': isArchived})
          .eq('aerobic_id', recordId);
      
      print('✅ [UPDATE-ARCHIVE] Record updated successfully');
      
      // Fetch the updated record
      final response = await _supabase
          .from('AerobicExercise')
          .select()
          .eq('aerobic_id', recordId)
          .single();
      
      return Aerobic.fromJson(response);
    } catch (e) {
      print('❌ [UPDATE-ARCHIVE] Error: $e');
      throw Exception('Failed to update archive status: $e');
    }
  }

  // ✅ Upload snap photo and update database
  Future<String> uploadSnapPhoto(String recordId, File photoFile) async {
    try {
      
      final fileName = 'snap_${recordId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final storagePath = 'snap_photos/$fileName';

      print('📤 [SNAP-PHOTO] File name: $fileName');
      print('📤 [SNAP-PHOTO] Storage path: $storagePath');

      // Upload to storage
      final response = await _supabase.storage
          .from('aerobic_route')
          .upload(storagePath, photoFile);

      print('✅ [SNAP-PHOTO] Upload successful');

      // Build the full URL
      final photoUrl = '$supabaseUrl/storage/v1/object/public/aerobic_route/$storagePath';
      print('✅ [SNAP-PHOTO] Photo URL: $photoUrl');

      // Update the database with the photo URL
      await _supabase
          .from('AerobicExercise')
          .update({'snap_photo': photoUrl})
          .eq('aerobic_id', recordId);

      print('✅ [SNAP-PHOTO] Database updated successfully');
      print('📤 [SNAP-PHOTO] ========== UPLOAD COMPLETE ==========');

      return photoUrl;
    } catch (e) {
      print('❌ [SNAP-PHOTO] Error: $e');
      throw Exception('Failed to upload snap photo: $e');
    }
  }

  // ✅ Resolve snap photo URL similar to route image
  String resolveSnapPhotoUrl(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty || value.contains('via.placeholder.com')) {
      return '';
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    // Handle storage paths
    if (value.contains('/storage/v1/object/public/')) {
      return value;
    }

    if (value.startsWith('snap_photos/')) {
      return '$supabaseUrl/storage/v1/object/public/aerobic_route/$value';
    }

    return '';
  }

  // ✅ Fetch distinct activity types for filtering
  Future<List<String>> fetchDistinctActivityTypes(int userId) async {
    try {
      print('📥 [FETCH-TYPES] Fetching distinct activity types for user: $userId');
      final response = await _supabase
          .from('AerobicExercise')
          .select('activity_type')
          .eq('user_id', userId)
          .order('activity_type', ascending: true);

      if (response is List) {
        // Extract unique activity types
        final Set<String> uniqueTypes = {};
        for (var item in response) {
          if (item is Map<String, dynamic> && item['activity_type'] != null) {
            uniqueTypes.add(item['activity_type'].toString());
          }
        }

        final typeList = uniqueTypes.toList();
        print('📥 [FETCH-TYPES] Found ${typeList.length} activity types: $typeList');
        return typeList;
      }

      print('⚠️  [FETCH-TYPES] Response is not a list');
      return [];
    } catch (e) {
      print('❌ [FETCH-TYPES] Error fetching activity types: $e');
      return [];
    }
  }
}

