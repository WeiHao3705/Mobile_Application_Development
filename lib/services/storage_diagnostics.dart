import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_application_development/config/supabase_config.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

/// Diagnostic tool to test storage bucket configuration
/// Run this to identify storage issues before uploading images
class StorageDiagnostics {
  static final StorageDiagnostics _instance =
      StorageDiagnostics._internal();

  StorageDiagnostics._internal();

  factory StorageDiagnostics() {
    return _instance;
  }

  Future<void> runFullDiagnostics() async {
    developer.log('🔧 STORAGE DIAGNOSTICS START');
    developer.log('=====================================');

    try {
      await _checkSupabaseInitialization();
      await _checkAuthentication();
      await _checkBucketExists();
      await _checkBucketPolicies();
      await _testUploadCapability();

      developer.log('✅ DIAGNOSTICS COMPLETE');
      developer.log('=====================================');
    } catch (e) {
      developer.log('❌ DIAGNOSTICS FAILED: $e');
    }
  }

  Future<void> _checkSupabaseInitialization() async {
    developer.log('\n📡 1️⃣ Checking Supabase Initialization...');
    try {
      final client = Supabase.instance.client;
      developer.log('   ✅ Supabase initialized');
      developer.log('   ✅ Client type: ${client.runtimeType}');
      developer.log('   ✅ Project URL: $supabaseUrl');
    } catch (e) {
      developer.log('   ❌ Initialization error: $e');
      rethrow;
    }
  }

  Future<void> _checkAuthentication() async {
    developer.log('\n🔐 2️⃣ Checking Authentication Status...');
    try {
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;
      final user = client.auth.currentUser;

      if (session != null) {
        developer.log('   ✅ Active session found');
        developer.log('   ✅ User ID: ${user?.id ?? "Unknown"}');
        developer.log('   ✅ User email: ${user?.email ?? "Unknown"}');
      } else {
        developer.log('   ⚠️  No active session');
        developer.log('   ℹ️  Proceeding with anon key access');
      }
    } catch (e) {
      developer.log('   ❌ Authentication check error: $e');
    }
  }

  Future<void> _checkBucketExists() async {
    developer.log('\n🪣 3️⃣ Checking "meal_photo" Bucket Exists...');
    try {
      final client = Supabase.instance.client;

      // Try to list buckets
      final buckets = await client.storage.listBuckets();

      developer.log('   📋 Available buckets:');
      for (var bucket in buckets) {
        developer.log('      - ${bucket.name} (public: ${bucket.public})');
      }

      final bucketExists =
          buckets.any((bucket) => bucket.name == 'meal_photo');

      if (bucketExists) {
        developer.log('   ✅ Bucket "meal_photo" exists');

        // Get bucket details
        final bucket =
            buckets.firstWhere((b) => b.name == 'meal_photo');
        developer.log('   ℹ️  Public: ${bucket.public}');
        developer.log('   ℹ️  Created: ${bucket.createdAt}');
      } else {
        developer.log('   ❌ Bucket "meal_photo" NOT FOUND');
        developer.log('   ⚠️  Action: Create "meal_photo" bucket in Supabase Storage');
      }
    } catch (e) {
      developer.log('   ❌ Bucket check error: $e');
      developer.log('   ⚠️  Might be permission issue or bucket not accessible');
    }
  }

  Future<void> _checkBucketPolicies() async {
    developer.log('\n🔐 4️⃣ Checking Bucket Policies...');
    try {
      final client = Supabase.instance.client;

      // Try to list objects in the bucket (requires list permission)
      try {
        final objects = await client.storage
            .from('meal_photo')
            .list(path: 'meals');

        developer.log('   ✅ Can list bucket contents');
        developer.log('   ℹ️  Objects in meals/: ${objects.length}');
        if (objects.isNotEmpty) {
          developer.log('   Sample objects:');
          for (var i = 0; i < (objects.length > 3 ? 3 : objects.length); i++) {
            developer.log('      - ${objects[i].name}');
          }
        }
      } catch (e) {
        developer.log('   ⚠️  Cannot list bucket: $e');
      }

      developer.log('   ℹ️  Required policies for full access:');
      developer.log('      - SELECT (read)');
      developer.log('      - INSERT (upload)');
      developer.log('      - UPDATE (modify)');
      developer.log('      - DELETE (remove)');
    } catch (e) {
      developer.log('   ❌ Policy check error: $e');
    }
  }

  Future<void> _testUploadCapability() async {
    developer.log('\n📤 5️⃣ Testing Upload Capability...');
    try {
      final client = Supabase.instance.client;

      // Create a test image (small 1x1 PNG)
      final testImageBytes = [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
        0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0x99, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
      ];

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testPath = 'test/diagnostic_${timestamp}.png';

      developer.log('   ⏳ Uploading test file to: test/diagnostic_${timestamp}.png');

      await client.storage
          .from('meal_photo')
          .uploadBinary(
            testPath,
            Uint8List.fromList(testImageBytes),
            fileOptions: const FileOptions(
              contentType: 'image/png',
            ),
          );

      developer.log('   ✅ Upload successful!');

      // Try to get public URL
      try {
        final publicUrl =
            client.storage.from('meal_photo').getPublicUrl(testPath);
        developer.log('   ✅ Public URL generated: $publicUrl');
      } catch (e) {
        developer.log('   ⚠️  Could not generate URL: $e');
      }

      // Clean up
      try {
        await client.storage.from('meal_photo').remove([testPath]);
        developer.log('   🧹 Test file cleaned up');
      } catch (e) {
        developer.log('   ⚠️  Could not clean up test file: $e');
      }
    } catch (e) {
      developer.log('   ❌ Upload test failed: $e');
      developer.log('   💡 This is the actual error you would get on real uploads');

      if (e.toString().contains('404')) {
        developer.log('   🔴 404 Error - Bucket likely does not exist');
        developer.log('   Action: Create meal_photo bucket in Supabase Storage');
      } else if (e.toString().contains('permission')) {
        developer.log('   🔴 Permission Error - Policies might be missing');
        developer.log('   Action: Add storage policies for meal_photo bucket');
      } else if (e.toString().contains('Unauthorized')) {
        developer.log('   🔴 Authentication Error - API key issues');
        developer.log('   Action: Verify anon key has storage permissions');
      }
    }
  }
}

// Usage in your app:
// 
// void checkStorageIssues() async {
//   final diagnostics = StorageDiagnostics();
//   await diagnostics.runFullDiagnostics();
// }
//
// Call this from your app initialization or a debug button