import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer';
import 'package:mobile_application_development/models/meal_log.dart';

class MealLogRepository {
  final SupabaseClient supabase;

  MealLogRepository({required this.supabase});

  // CREATE a new meal
  Future<MealLog> createMeal(MealLog meal) async {
    try {
      log("🔵 MealLogRepository.createMeal START");
      log("📝 Meal data: ${meal.toJson()}");
      log("📊 Attempting to insert into 'MealLog' table...");

      final response = await supabase
          .from('MealLog')
          .insert(meal.toJson())
          .select()
          .single();

      log("✅ Insert new meal success: $response");

      return MealLog.fromJson(response);
    } on PostgrestException catch (e) {
      log("❌ PostgrestException in createMeal:");
      log("   Message: ${e.message}");
      log("   Code: ${e.code}");
      log("   Details: ${e.details}");
      log("   Hint: ${e.hint}");

      // Provide helpful debugging information
      if (e.code == 'PGRST205') {
        log("⚠️ TABLE NOT FOUND - The 'MealLog' table doesn't exist in Supabase");
        log("⚠️ Hint from Supabase: ${e.hint}");
        log("⚠️ Available tables: Check your Supabase dashboard");
      }

      rethrow;
    } catch (e) {
      log("❌ Unexpected error in createMeal: $e");
      rethrow;
    }
  }

  // READ meals by user
  Future<List<MealLog>> getMealsByUser(int userId) async {
    try {
      final response = await supabase
          .from('MealLog')
          .select()
          .eq('user_id', userId);

      log("Data fetched successfully.");

      return (response as List)
          .map((json) => MealLog.fromJson(json))
          .toList();
    } catch (e) {
      log("Fetch failed. Error", error: e);
      rethrow;
    }
  }

  // READ a single meal by mealId
  Future<MealLog?> getMealById(int mealId) async {
    try {
      final response = await supabase
          .from('MealLog')
          .select()
          .eq('meal_id', mealId)
          .maybeSingle();

      if (response == null) return null;

      return MealLog.fromJson(response);
    } catch (e) {
      log("Fetch by ID failed. Error", error: e);
      rethrow;
    }
  }

  // UPDATE meal
  Future<MealLog> updateMeal(MealLog meal) async {
    try {
      if (meal.mealId == null) {
        throw Exception('Cannot update meal without an ID');
      }

      final response = await supabase
          .from('MealLog')
          .update(meal.toJson())
          .eq('meal_id', meal.mealId!)
          .select()
          .single();

      log("Update success: $response");

      return MealLog.fromJson(response);
    } catch (e) {
      log("Update failed. Error", error: e);
      rethrow;
    }
  }

  // DELETE meal
  Future<void> deleteMeal(int mealId) async {
    try {
      await supabase
          .from('MealLog')
          .delete()
          .eq('meal_id', mealId);

      log("Delete success.");
    } catch (e) {
      log("Delete failed. Error", error: e);
      rethrow;
    }
  }
}