import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase credentials
const String supabaseUrl = 'https://hjbnqwbjxprdkacrbtbl.supabase.co';
const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqYm5xd2JqeHByZGthY3JidGJsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MjM3NDIsImV4cCI6MjA4ODE5OTc0Mn0.MdAs0wtyd-qLuNhBUOE6SZZJQU2QcR4xw7xL_uOAldU';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('======================================');
  print('🔧 SUPABASE CONNECTION TEST');
  print('======================================');

  // Initialize Supabase
  try {
    print('\n1️⃣ Initializing Supabase...');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
    print('   ✅ Supabase initialized successfully');
  } catch (e) {
    print('   ❌ Supabase initialization error: $e');
    return;
  }

  // Test connection
  try {
    print('\n2️⃣ Getting Supabase client...');
    final client = Supabase.instance.client;
    print('   ✅ Client obtained: ${client.runtimeType}');
  } catch (e) {
    print('   ❌ Error getting client: $e');
    return;
  }

  // Test User table query
  try {
    print('\n3️⃣ Querying User table...');
    final client = Supabase.instance.client;

    print('   📡 Executing: SELECT * FROM User');
    final response = await client.from('User').select();

    print('   ✅ Query successful!');
    print('   📊 Response type: ${response.runtimeType}');
    print('   📦 Raw response: $response');

    if (response is List) {
      print('   📝 Number of records: ${response.length}');

      if (response.isEmpty) {
        print('   ⚠️  No records found in User table');
      } else {
        print('   👥 Users found:');
        for (var i = 0; i < response.length; i++) {
          print('   ---');
          print('   User #${i + 1}:');
          final user = response[i];
          if (user is Map) {
            user.forEach((key, value) {
              print('      $key: $value');
            });
          } else {
            print('      $user');
          }
        }
      }
    }
  } catch (e, stackTrace) {
    print('   ❌ Error querying User table: $e');
    print('   📍 Stack trace: $stackTrace');
  }

  print('\n======================================');
  print('✅ TEST COMPLETE');
  print('======================================\n');
}

