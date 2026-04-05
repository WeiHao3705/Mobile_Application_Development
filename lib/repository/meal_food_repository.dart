import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer';
import 'package:mobile_application_development/models/meal_food.dart';

class MealFoodRepository {
  final SupabaseClient supabase;

  MealFoodRepository({required this.supabase});

  // CREATE a meal food entry
  Future<MealFood> createMealFood(MealFood mealFood) async {
    try {
      final response = await supabase
          .from('MealFood')
          .insert({
            'meal_id': mealFood.mealId,
            'food_id': mealFood.foodId,
            'quantity': mealFood.quantity,
            'unit': mealFood.unit,
          })
          .select()
          .single();

      log("Insert meal food success: $response");

      return MealFood.fromJson(response);
    } catch (e) {
      log("Insert meal food failed. Error", error: e);
      rethrow;
    }
  }

  // CREATE multiple meal foods at once
  Future<List<MealFood>> createMealFoods(List<MealFood> mealFoods) async {
    try {
      final data = mealFoods.map((mf) => {
        'meal_id': mf.mealId,
        'food_id': mf.foodId,
        'quantity': mf.quantity,
        'unit': mf.unit,
      }).toList();

      final response = await supabase
          .from('MealFood')
          .insert(data)
          .select();

      log("Insert ${mealFoods.length} meal foods success");

      return (response as List)
          .map((json) => MealFood.fromJson(json))
          .toList();
    } catch (e) {
      log("Insert meal foods failed. Error", error: e);
      rethrow;
    }
  }

  // READ meal foods by meal ID
  Future<List<MealFood>> getMealFoodsByMealId(int mealId) async {
    try {
      final response = await supabase
          .from('MealFood')
          .select()
          .eq('meal_id', mealId);

      log("Fetched ${(response as List).length} meal foods for meal $mealId");

      return (response as List)
          .map((json) => MealFood.fromJson(json))
          .toList();
    } catch (e) {
      log("Fetch meal foods failed. Error", error: e);
      rethrow;
    }
  }

  // UPDATE meal food
  Future<MealFood> updateMealFood(MealFood mealFood) async {
    try {
      if (mealFood.mealFoodId == null) {
        throw Exception('Cannot update meal food without an ID');
      }

      final response = await supabase
          .from('MealFood')
          .update({
            'quantity': mealFood.quantity,
            'unit': mealFood.unit,
          })
          .eq('meal_food_id', mealFood.mealFoodId!)
          .select()
          .single();

      log("Update meal food success: $response");

      return MealFood.fromJson(response);
    } catch (e) {
      log("Update meal food failed. Error", error: e);
      rethrow;
    }
  }

  // DELETE meal food
  Future<void> deleteMealFood(int mealFoodId) async {
    try {
      await supabase
          .from('MealFood')
          .delete()
          .eq('meal_food_id', mealFoodId);

      log("Delete meal food success.");
    } catch (e) {
      log("Delete meal food failed. Error", error: e);
      rethrow;
    }
  }

  // DELETE all meal foods for a meal
  Future<void> deleteMealFoodsByMealId(int mealId) async {
    try {
      await supabase
          .from('MealFood')
          .delete()
          .eq('meal_id', mealId);

      log("Delete all meal foods for meal $mealId success.");
    } catch (e) {
      log("Delete meal foods failed. Error", error: e);
      rethrow;
    }
  }
}


