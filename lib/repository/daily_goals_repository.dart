import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_application_development/models/daily_goals.dart';
import 'dart:developer';

class DailyGoalsRepository {
  final SupabaseClient supabase;

  DailyGoalsRepository({required this.supabase});

  /// Create or insert daily goals
  Future<DailyGoals> createDailyGoals(DailyGoals goals) async {
    try {
      log('📝 Creating daily goals for user ${goals.userId}');

      final response = await supabase
          .from('DailyGoals')
          .insert(goals.toJson())
          .select()
          .single();

      log('✅ Daily goals created successfully');
      return DailyGoals.fromJson(response);
    } catch (e) {
      log('❌ Error creating daily goals: $e');
      rethrow;
    }
  }

  /// Read daily goals by user ID
  Future<DailyGoals?> getDailyGoalsByUserId(int userId) async {
    try {
      log('📖 Fetching daily goals for user $userId');

      final response = await supabase
          .from('DailyGoals')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        log('⚠️ No daily goals found for user $userId');
        return null;
      }

      log('✅ Daily goals fetched successfully');
      return DailyGoals.fromJson(response);
    } catch (e) {
      log('❌ Error fetching daily goals: $e');
      rethrow;
    }
  }

  /// Update daily goals
  Future<DailyGoals> updateDailyGoals(DailyGoals goals) async {
    try {
      log('✏️ Updating daily goals for user ${goals.userId}');

      final updateData = {
        'target_calories': goals.targetCalories,
        'target_protein': goals.targetProtein,
        'target_carbs': goals.targetCarbs,
        'target_fat': goals.targetFat,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from('DailyGoals')
          .update(updateData)
          .eq('daily_goals_id', goals.dailyGoalsId)
          .select()
          .single();

      log('✅ Daily goals updated successfully');
      return DailyGoals.fromJson(response);
    } catch (e) {
      log('❌ Error updating daily goals: $e');
      rethrow;
    }
  }

  /// Delete daily goals
  Future<void> deleteDailyGoals(int dailyGoalsId) async {
    try {
      log('🗑️ Deleting daily goals with ID $dailyGoalsId');

      await supabase
          .from('DailyGoals')
          .delete()
          .eq('daily_goals_id', dailyGoalsId);

      log('✅ Daily goals deleted successfully');
    } catch (e) {
      log('❌ Error deleting daily goals: $e');
      rethrow;
    }
  }
}

