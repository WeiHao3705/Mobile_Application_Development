import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseClient get client => Supabase.instance.client;

  /// Check if Supabase is properly connected
  bool isConnected() {
    try {
      return client.auth.currentSession != null;
    } catch (e) {
      return false;
    }
  }

  /// Save a counter value to the 'counters' table
  Future<void> saveCounter(int value) async {
    try {
      await client.from('counters').insert({
        'value': value,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ Counter saved successfully: $value');
    } on PostgrestException catch (e) {
      print('❌ Postgrest error: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Error saving counter: $e');
      rethrow;
    }
  }

  /// Fetch all counters from the database
  Future<List<Map<String, dynamic>>> getAllCounters() async {
    try {
      final response = await client.from('counters').select();
      print('✅ Fetched ${response.length} counters');
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      print('❌ Postgrest error: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Error fetching counters: $e');
      rethrow;
    }
  }

  /// Get the latest counter value
  Future<int?> getLatestCounter() async {
    try {
      final response = await client
          .from('counters')
          .select()
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        return null;
      }

      return response[0]['value'] as int;
    } on PostgrestException catch (e) {
      print('❌ Postgrest error: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Error fetching latest counter: $e');
      rethrow;
    }
  }

  /// Delete a counter by ID
  Future<void> deleteCounter(int id) async {
    try {
      await client.from('counters').delete().eq('id', id);
      print('✅ Counter deleted successfully: $id');
    } on PostgrestException catch (e) {
      print('❌ Postgrest error: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Error deleting counter: $e');
      rethrow;
    }
  }

  /// Update a counter value by ID
  Future<void> updateCounter(int id, int newValue) async {
    try {
      await client.from('counters').update({'value': newValue}).eq('id', id);
      print('✅ Counter updated successfully: $id -> $newValue');
    } on PostgrestException catch (e) {
      print('❌ Postgrest error: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Error updating counter: $e');
      rethrow;
    }
  }
}


