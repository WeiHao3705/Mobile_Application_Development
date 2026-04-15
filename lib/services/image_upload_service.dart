import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_application_development/config/supabase_config.dart';
import 'dart:developer' as developer;

class _StorageHttpException implements Exception {
  const _StorageHttpException(this.statusCode, this.body);
  final int statusCode;
  final String body;
  @override
  String toString() => 'Storage HTTP $statusCode: $body';
}

class ImageUploadService {
  static const String _imageBucketId = 'meal_photo';
  static const int _maxUploadAttempts = 3;

  SupabaseClient get _supabaseClient => Supabase.instance.client;

  String _buildObjectPath(File file) {
    final rawName = file.path.split(Platform.pathSeparator).last;
    final sanitizedName = rawName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return 'meals/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
  }

  String _detectContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'application/octet-stream';
  }

  Future<void> _uploadViaRest({
    required String objectPath,
    required File file,
    required String contentType,
  }) async {
    final encodedPath = objectPath
        .split('/')
        .map(Uri.encodeComponent)
        .join('/');
    final uri = Uri.parse('$supabaseUrl/storage/v1/object/$_imageBucketId/$encodedPath');
    final client = HttpClient();

    try {
      final request = await client.postUrl(uri);
      request.headers.set('apikey', supabaseAnonKey);
      request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
      request.headers.set('x-upsert', 'true');
      request.headers.set(HttpHeaders.contentTypeHeader, contentType);

      final bytes = await file.readAsBytes();
      request.add(bytes);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _StorageHttpException(response.statusCode, responseBody);
      }
    } finally {
      client.close(force: true);
    }
  }

  /// Upload image file to Supabase Storage (meal_photo bucket)
  Future<String> uploadMealImage({
    required File imageFile,
    required int userId,
    DateTime? mealDate,
  }) async {
    try {
      developer.log('🔵 ImageUploadService.uploadMealImage START');
      developer.log('📤 Uploading from: ${imageFile.path}');
      developer.log('👤 User ID: $userId');

      if (!imageFile.existsSync()) {
        throw Exception('❌ File does not exist: ${imageFile.path}');
      }
      developer.log('✅ File exists and is readable');

      if (userId <= 0) {
        throw Exception('❌ INVALID USER ID: User ID must be greater than 0');
      }
      developer.log('👤 User ID validated: $userId');

      final imageBytes = await imageFile.readAsBytes();
      developer.log('📊 Image size: ${imageBytes.lengthInBytes} bytes');

      if (imageBytes.isEmpty) {
        throw Exception('❌ Image file is empty');
      }

      return await _uploadImageAndGetUrl(imageFile);
    } on _StorageHttpException catch (e) {
      developer.log('❌ StorageException: HTTP ${e.statusCode}');
      developer.log('❌ Response: ${e.body}');
      if (e.statusCode == 404) {
        developer.log('⚠️  404 Error - Bucket may not exist or not PUBLIC');
        developer.log('⚠️  Check: Storage → meal_photo → Make it public');
      } else if (e.statusCode == 401 || e.statusCode == 403) {
        developer.log('⚠️  Permission Error - Check Storage policies');
      }
      rethrow;
    } catch (e) {
      developer.log('❌ Image upload failed: $e');
      rethrow;
    }
  }

  /// Upload image from bytes (e.g., from camera)
  Future<String> uploadMealImageFromBytes({
    required Uint8List imageBytes,
    required int userId,
    DateTime? mealDate,
  }) async {
    try {
      developer.log('🔵 ImageUploadService.uploadMealImageFromBytes START');
      developer.log('📊 Image size: ${imageBytes.lengthInBytes} bytes');
      developer.log('👤 User ID: $userId');

      if (imageBytes.isEmpty) {
        throw Exception('❌ Image bytes are empty - invalid file');
      }
      developer.log('✅ Image bytes valid');

      if (userId <= 0) {
        throw Exception('❌ INVALID USER ID: User ID must be greater than 0');
      }
      developer.log('👤 User ID validated: $userId');

      // Create temporary file from bytes
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/meal_temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(imageBytes);

      try {
        return await _uploadImageAndGetUrl(tempFile);
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    } on _StorageHttpException catch (e) {
      developer.log('❌ StorageException: HTTP ${e.statusCode}');
      developer.log('❌ Response: ${e.body}');
      rethrow;
    } catch (e) {
      developer.log('❌ Image upload from bytes failed: $e');
      rethrow;
    }
  }

  Future<String> _uploadImageAndGetUrl(File file) async {
    final storage = _supabaseClient.storage;
    final objectPath = _buildObjectPath(file);
    final contentType = _detectContentType(file.path);

    Object? lastTransientError;

    for (var attempt = 1; attempt <= _maxUploadAttempts; attempt++) {
      try {
        developer.log('⏳ Upload attempt $attempt/$_maxUploadAttempts...');
        await _uploadViaRest(
          objectPath: objectPath,
          file: file,
          contentType: contentType,
        );
        final url = storage.from(_imageBucketId).getPublicUrl(objectPath);
        developer.log('✅ Upload response: $objectPath');
        developer.log('🔗 Public URL: $url');
        developer.log('✅ Image uploaded successfully');
        return url;
      } on _StorageHttpException catch (error) {
        final code = error.statusCode;
        if (code == 404) {
          developer.log('⚠️  404 Error on attempt $attempt - bucket issue');
          break;
        }
        developer.log('⚠️  HTTP $code on attempt $attempt');
        rethrow;
      } on SocketException catch (error) {
        lastTransientError = error;
        developer.log('⚠️  Network error on attempt $attempt: $error');
      } on TimeoutException catch (error) {
        lastTransientError = error;
        developer.log('⚠️  Timeout on attempt $attempt');
      } catch (error) {
        if (error.toString().contains('ClientException') && error.toString().contains('Connection')) {
          lastTransientError = error;
          developer.log('⚠️  Connection error on attempt $attempt');
        } else {
          rethrow;
        }
      }

      if (attempt < _maxUploadAttempts) {
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }

    if (lastTransientError != null) {
      developer.log('❌ All attempts failed with network error');
      throw lastTransientError;
    }

    developer.log('❌ Bucket not found or not accessible');
    throw Exception(
      'Bucket "$_imageBucketId" not found or not accessible (404). '
      'Make sure bucket is PUBLIC in Supabase Storage settings.',
    );
  }
}




