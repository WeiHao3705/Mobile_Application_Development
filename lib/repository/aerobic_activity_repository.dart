import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/aerobic.dart';

class AerobicRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchAerobicActivity() async {
    try{
      final response = await _supabase
          .from('Aerobic_Activity')
          .select('aerobic_name, caloriesPerKM');
      return List<Map<String, dynamic>>.from(response);

    } catch(e) {
      print('Error to fetch aerobic activity record : $e');
      return [];
    }
  }

  // ✅ CREATE: Add new aerobic activity
  Future<void> createAerobicActivity(String aerobicName, int caloriesPerKM) async {
    try {
      print('📝 [ADMIN] Creating new aerobic activity: $aerobicName');
      await _supabase
          .from('Aerobic_Activity')
          .insert({
            'aerobic_name': aerobicName,
            'caloriesPerKM': caloriesPerKM,
          });
      print('✅ [ADMIN] Aerobic activity created successfully');
    } catch (e) {
      print('❌ [ADMIN] Error creating aerobic activity: $e');
      throw Exception('Failed to create aerobic activity: $e');
    }
  }

  // ✅ UPDATE: Update existing aerobic activity
  Future<void> updateAerobicActivity(
    String oldName,
    String newName,
    int caloriesPerKM,
  ) async {
    try {
      print('📝 [ADMIN] Updating aerobic activity: $oldName -> $newName');
      await _supabase
          .from('Aerobic_Activity')
          .update({
            'aerobic_name': newName,
            'caloriesPerKM': caloriesPerKM,
          })
          .eq('aerobic_name', oldName);
      print('✅ [ADMIN] Aerobic activity updated successfully');
    } catch (e) {
      print('❌ [ADMIN] Error updating aerobic activity: $e');
      throw Exception('Failed to update aerobic activity: $e');
    }
  }

  // ✅ DELETE: Delete aerobic activity
  Future<void> deleteAerobicActivity(String aerobicName) async {
    try {
      print('🗑️  [ADMIN] Deleting aerobic activity: $aerobicName');
      await _supabase
          .from('Aerobic_Activity')
          .delete()
          .eq('aerobic_name', aerobicName);
      print('✅ [ADMIN] Aerobic activity deleted successfully');
    } catch (e) {
      print('❌ [ADMIN] Error deleting aerobic activity: $e');
      throw Exception('Failed to delete aerobic activity: $e');
    }
  }
}