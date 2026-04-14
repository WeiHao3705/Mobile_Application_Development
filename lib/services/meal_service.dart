import 'package:mobile_application_development/models/meal_log.dart';
import 'package:mobile_application_development/models/meal_food.dart';
import 'package:mobile_application_development/models/food.dart';
import 'package:mobile_application_development/repository/meal_repository.dart';
import 'package:mobile_application_development/repository/meal_food_repository.dart';
import 'package:mobile_application_development/repository/food_repository.dart';
import 'package:mobile_application_development/repository/daily_goals_repository.dart';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

class MealService {
  final MealLogRepository _repository;
  final MealFoodRepository _mealFoodRepository;
  final FoodRepository _foodRepository;
  final DailyGoalsRepository _dailyGoalsRepository;

  MealService({
    required MealLogRepository repository,
    required MealFoodRepository mealFoodRepository,
    required FoodRepository foodRepository,
    DailyGoalsRepository? dailyGoalsRepository,
  })  : _repository = repository,
        _mealFoodRepository = mealFoodRepository,
        _foodRepository = foodRepository,
        _dailyGoalsRepository = _initializeDailyGoalsRepository(dailyGoalsRepository);

  static DailyGoalsRepository _initializeDailyGoalsRepository(DailyGoalsRepository? provided) {
    if (provided != null) {
      return provided;
    }
    try {
      final client = Supabase.instance.client;
      if (client == null) {
        throw Exception('Supabase client is not initialized');
      }
      return DailyGoalsRepository(supabase: client);
    } catch (e) {
      developer.log('⚠️ Error initializing DailyGoalsRepository: $e');
      rethrow;
    }
  }

  /// Log a meal with multiple foods for a user
  /// Returns the created meal ID or null if failed
  Future<int?> logMeal({
    required int userId,
    required String mealType,
    required DateTime mealDate,
    required Map<int, Map<String, dynamic>> foodsWithQuantities,
    String? mealName,
  }) async {
    try {
      developer.log('🔵 MealService.logMeal START');
      developer.log('👤 User ID: $userId');
      developer.log('🍽️ Meal Type: $mealType');
      developer.log('📅 Meal Date: $mealDate');
      developer.log('📝 Meal Name: $mealName');
      developer.log('📊 Foods Count: ${foodsWithQuantities.length}');

      // Validate inputs
      if (foodsWithQuantities.isEmpty) {
        throw Exception('No foods selected for meal');
      }

      if (userId <= 0) {
        throw Exception('Invalid user ID');
      }

      // Calculate total calories BEFORE creating the meal
      developer.log('💾 Calculating total meal nutrition...');
      double totalCalories = 0.0;
      double totalProteins = 0.0;
      double totalCarbs = 0.0;
      double totalFats = 0.0;

      try {
        // Fetch all foods once and create a map for quick lookup
        final allFoods = await _foodRepository.getFoodsByUser(userId);
        final foodMap = {for (var food in allFoods) food.foodId: food};
        developer.log('📚 Loaded ${foodMap.length} foods from database');

        if (foodMap.isEmpty) {
          developer.log('⚠️ WARNING: No foods found for user $userId');
          throw Exception('No foods found for user $userId');
        }

        for (final entry in foodsWithQuantities.entries) {
          final foodId = entry.key;
          final foodData = entry.value;
          final quantity = (foodData['quantity'] as num).toDouble();

          developer.log('🔍 Looking up food ID: $foodId');
          developer.log('   Quantity: $quantity grams');

          // Get food from cache
          final food = foodMap[foodId];

          if (food == null) {
            developer.log('❌ Food ID $foodId not found in user foods. Available IDs: ${foodMap.keys.toList()}');
            continue;
          }

          developer.log('✓ Found food: ${food.foodName}');
          developer.log('   Calories per 100g: ${food.caloriesPer100g}');
          developer.log('   Protein per 100g: ${food.proteinPer100g}');
          developer.log('   Carbs per 100g: ${food.carbsPer100g}');
          developer.log('   Fat per 100g: ${food.fatPer100g}');

          // Calculate: (value_per_100g / 100) * quantity
          final foodCalories = (food.caloriesPer100g / 100.0) * quantity;
          final foodProteins = (food.proteinPer100g / 100.0) * quantity;
          final foodCarbs = (food.carbsPer100g / 100.0) * quantity;
          final foodFats = (food.fatPer100g / 100.0) * quantity;

          totalCalories += foodCalories;
          totalProteins += foodProteins;
          totalCarbs += foodCarbs;
          totalFats += foodFats;

          developer.log('📝 ${food.foodName}: $quantity g');
          developer.log('   ├─ Calories: ${foodCalories.toStringAsFixed(2)} kcal');
          developer.log('   ├─ Protein: ${foodProteins.toStringAsFixed(2)} g');
          developer.log('   ├─ Carbs: ${foodCarbs.toStringAsFixed(2)} g');
          developer.log('   └─ Fat: ${foodFats.toStringAsFixed(2)} g');
        }
      } catch (e) {
        developer.log('❌ Error calculating nutrition: $e');
        developer.log('❌ Stack trace: ${StackTrace.current}');
        // Continue anyway - we'll save the meal without totals
        totalCalories = 0.0;
        totalProteins = 0.0;
        totalCarbs = 0.0;
        totalFats = 0.0;
      }

      developer.log('✅ Total calculated nutrition:');
      developer.log('   ├─ Calories: ${totalCalories.toStringAsFixed(2)} kcal');
      developer.log('   ├─ Protein: ${totalProteins.toStringAsFixed(2)} g');
      developer.log('   ├─ Carbs: ${totalCarbs.toStringAsFixed(2)} g');
      developer.log('   └─ Fat: ${totalFats.toStringAsFixed(2)} g');

      // Create the meal log entry with total nutrition values
      final mealLog = MealLog(
        mealId: null,
        mealType: mealType,
        mealDate: mealDate,
        userId: userId,
        totalCalories: totalCalories > 0 ? totalCalories : null,
        totalProteins: totalProteins > 0 ? totalProteins : null,
        totalCarbs: totalCarbs > 0 ? totalCarbs : null,
        totalFats: totalFats > 0 ? totalFats : null,
        mealName: mealName,
      );

      developer.log('💾 Creating meal log entry with complete nutrition...');
      developer.log('📊 MealLog data: ${mealLog.toJson()}');
      developer.log('📊 Total Calories before save: ${mealLog.totalCalories}');
      developer.log('📊 Total Protein before save: ${mealLog.totalProteins}');
      developer.log('📊 Total Carbs before save: ${mealLog.totalCarbs}');
      developer.log('📊 Total Fat before save: ${mealLog.totalFats}');

      final createdMeal = await _repository.createMeal(mealLog);

      developer.log('✅ Meal created successfully with ID: ${createdMeal.mealId}');
      developer.log('✅ Returned total_calories from DB: ${createdMeal.totalCalories}');

      // Now save the foods for this meal
      if (createdMeal.mealId != null && createdMeal.mealId! > 0) {
        developer.log('💾 Saving ${foodsWithQuantities.length} foods to MealFood table...');

        final mealFoods = <MealFood>[];
        for (final entry in foodsWithQuantities.entries) {
          final foodData = entry.value;
          mealFoods.add(MealFood(
            mealFoodId: 0, // Will be generated by database
            mealId: createdMeal.mealId!,
            foodId: foodData['food_id'] as int,
            quantity: (foodData['quantity'] as num).toDouble(),
            unit: foodData['unit'] as String? ?? 'g',
          ));
        }

        try {
          await _mealFoodRepository.createMealFoods(mealFoods);
          developer.log('✅ All ${mealFoods.length} foods saved successfully to MealFood table');
        } catch (e) {
          developer.log('❌ ERROR: Foods were not saved to MealFood table: $e');
          developer.log('❌ Stack trace: ${StackTrace.current}');

          // Check if it's a duplicate key error (schema issue, not transactional)
          if (e.toString().contains('duplicate key') || e.toString().contains('23505')) {
            developer.log('⚠️ WARNING: Duplicate key constraint violation detected');
            developer.log('📋 This usually means the MealFood table has incorrect unique constraints');
            developer.log('💡 Expected: unique constraint on (meal_id, food_id)');
            developer.log('❌ Found: unique constraint on food_id only');
            developer.log('🔧 ACTION REQUIRED: Fix the MealFood table constraints in Supabase');

            // Don't rollback for schema errors - keep the meal, but fail the operation
            throw Exception('Database Schema Error: MealFood table has incorrect unique constraint. '
                'Expected unique(meal_id, food_id) but found unique(food_id). '
                'Please fix the constraint in Supabase and try again.');
          } else {
            // For other errors, attempt rollback
            developer.log('❌ Attempting to rollback: deleting meal ${createdMeal.mealId} to maintain data consistency...');

            try {
              await _repository.deleteMeal(createdMeal.mealId!);
              developer.log('✅ Meal rolled back successfully');
            } catch (rollbackError) {
              developer.log('⚠️ WARNING: Failed to rollback meal deletion: $rollbackError');
            }

            // Re-throw the original error
            throw Exception('Failed to save food items for meal: $e');
          }
        }
      }

      return createdMeal.mealId ?? 0;
    } catch (e) {
      developer.log('❌ ERROR in MealService.logMeal: $e');
      developer.log('❌ Error Type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Get all meals logged by a user
  Future<List<MealLog>> getUserMeals(int userId) async {
    try {
      final meals = await _repository.getMealsByUser(userId);
      developer.log('Retrieved ${meals.length} meals for user $userId');

      // Also fetch and log daily nutrition goals
      await _logDailyNutritionGoals(userId);

      return meals;
    } catch (e) {
      developer.log('Error in MealService.getUserMeals: $e');
      rethrow;
    }
  }

  /// Fetch and log user's daily nutrition goals
  Future<void> _logDailyNutritionGoals(int userId) async {
    try {
      developer.log('📋 Fetching daily nutrition goals for user $userId');

      final goals = await _dailyGoalsRepository.getDailyGoalsByUserId(userId);

      if (goals == null) {
        developer.log('⚠️ No daily nutrition goals found for user $userId');
        return;
      }

      developer.log('✅ Daily Nutrition Goals for user $userId:');
      developer.log('   ├─ Target Calories: ${goals.targetCalories} kcal');
      developer.log('   ├─ Target Protein: ${goals.targetProtein} g');
      developer.log('   ├─ Target Carbs: ${goals.targetCarbs} g');
      developer.log('   └─ Target Fat: ${goals.targetFat} g');
    } catch (e) {
      developer.log('⚠️ Error fetching daily nutrition goals: $e');
    }
  }

  /// Get a specific meal by ID
  Future<MealLog?> getMealById(int mealId) async {
    try {
      final meal = await _repository.getMealById(mealId);
      developer.log('Retrieved meal with ID: $mealId');
      return meal;
    } catch (e) {
      developer.log('Error in MealService.getMealById: $e');
      rethrow;
    }
  }

  /// Update an existing meal with new foods and recalculate nutrition
  Future<MealLog> updateMeal({
    required int mealId,
    required String mealType,
    required DateTime mealDate,
    required int userId,
    Map<int, Map<String, dynamic>>? foodsWithQuantities,
    String? mealName,
  }) async {
    try {
      developer.log('🟨 MealService.updateMeal START');
      developer.log('👤 Meal ID: $mealId');
      developer.log('🍽️ Meal Type: $mealType');
      developer.log('📅 Meal Date: $mealDate');
      developer.log('📝 Meal Name: $mealName');
      developer.log('📊 Foods provided: ${foodsWithQuantities?.length ?? 0}');

      // If foods are provided, delete old meal foods and recalculate nutrition
      if (foodsWithQuantities != null && foodsWithQuantities.isNotEmpty) {
        developer.log('💾 Updating meal foods...');

        // Delete old meal foods
        try {
          await _mealFoodRepository.deleteMealFoodsByMealId(mealId);
          developer.log('✅ Deleted old meal foods');
        } catch (e) {
          developer.log('⚠️ Error deleting old meal foods: $e');
          // Continue anyway
        }

        // Calculate new nutrition
        developer.log('💾 Calculating new meal nutrition...');
        double totalCalories = 0.0;
        double totalProteins = 0.0;
        double totalCarbs = 0.0;
        double totalFats = 0.0;

        try {
          final allFoods = await _foodRepository.getFoodsByUser(userId);
          final foodMap = {for (var food in allFoods) food.foodId: food};
          developer.log('📚 Loaded ${foodMap.length} foods from database');

          for (final entry in foodsWithQuantities.entries) {
            final foodId = entry.key;
            final foodData = entry.value;
            final quantity = (foodData['quantity'] as num).toDouble();

            developer.log('🔍 Looking up food ID: $foodId');
            developer.log('   Quantity: $quantity grams');

            final food = foodMap[foodId];

            if (food == null) {
              developer.log('❌ Food ID $foodId not found in user foods.');
              continue;
            }

            developer.log('✓ Found food: ${food.foodName}');

            final foodCalories = (food.caloriesPer100g / 100.0) * quantity;
            final foodProteins = (food.proteinPer100g / 100.0) * quantity;
            final foodCarbs = (food.carbsPer100g / 100.0) * quantity;
            final foodFats = (food.fatPer100g / 100.0) * quantity;

            totalCalories += foodCalories;
            totalProteins += foodProteins;
            totalCarbs += foodCarbs;
            totalFats += foodFats;

            developer.log('📝 ${food.foodName}: $quantity g');
            developer.log('   ├─ Calories: ${foodCalories.toStringAsFixed(2)} kcal');
            developer.log('   ├─ Protein: ${foodProteins.toStringAsFixed(2)} g');
            developer.log('   ├─ Carbs: ${foodCarbs.toStringAsFixed(2)} g');
            developer.log('   └─ Fat: ${foodFats.toStringAsFixed(2)} g');
          }
        } catch (e) {
          developer.log('❌ Error calculating nutrition: $e');
          totalCalories = 0.0;
          totalProteins = 0.0;
          totalCarbs = 0.0;
          totalFats = 0.0;
        }

        developer.log('✅ Total calculated nutrition:');
        developer.log('   ├─ Calories: ${totalCalories.toStringAsFixed(2)} kcal');
        developer.log('   ├─ Protein: ${totalProteins.toStringAsFixed(2)} g');
        developer.log('   ├─ Carbs: ${totalCarbs.toStringAsFixed(2)} g');
        developer.log('   └─ Fat: ${totalFats.toStringAsFixed(2)} g');

        // Create updated meal with new nutrition values
        final meal = MealLog(
          mealId: mealId,
          mealType: mealType,
          mealDate: mealDate,
          userId: userId,
          totalCalories: totalCalories > 0 ? totalCalories : null,
          totalProteins: totalProteins > 0 ? totalProteins : null,
          totalCarbs: totalCarbs > 0 ? totalCarbs : null,
          totalFats: totalFats > 0 ? totalFats : null,
          mealName: mealName,
        );

        developer.log('💾 Updating meal with new nutrition data...');
        final updatedMeal = await _repository.updateMeal(meal);
        developer.log('✅ Meal updated successfully with new nutrition');

        // Save new meal foods
        developer.log('💾 Saving new meal foods...');
        final mealFoods = <MealFood>[];
        for (final entry in foodsWithQuantities.entries) {
          final foodData = entry.value;
          mealFoods.add(MealFood(
            mealFoodId: 0,
            mealId: mealId,
            foodId: foodData['food_id'] as int,
            quantity: (foodData['quantity'] as num).toDouble(),
            unit: foodData['unit'] as String? ?? 'g',
          ));
        }

        try {
          await _mealFoodRepository.createMealFoods(mealFoods);
          developer.log('✅ All ${mealFoods.length} foods saved successfully');
        } catch (e) {
          developer.log('❌ ERROR: Foods were not saved: $e');
          throw Exception('Failed to save food items for meal: $e');
        }

        return updatedMeal;
      } else {
        // No foods provided, just update basic info (type and date)
        developer.log('⚠️ No foods provided. Updating basic meal info only.');
        final meal = MealLog(
          mealId: mealId,
          mealType: mealType,
          mealDate: mealDate,
          userId: userId,
        );

        final updatedMeal = await _repository.updateMeal(meal);
        developer.log('✅ Meal basic info updated via service: $mealId');
        return updatedMeal;
      }
    } catch (e) {
      developer.log('❌ Error in MealService.updateMeal: $e');
      rethrow;
    }
  }

  /// Delete a meal
  Future<void> deleteMeal(int mealId) async {
    try {
      developer.log('🔵 MealService.deleteMeal START for meal $mealId');

      // First, delete all meal foods associated with this meal
      developer.log('🗑️ Deleting associated meal foods...');
      await _mealFoodRepository.deleteMealFoodsByMealId(mealId);
      developer.log('✅ Meal foods deleted');

      // Then delete the meal itself
      developer.log('🗑️ Deleting meal record...');
      await _repository.deleteMeal(mealId);
      developer.log('✅ Meal deleted via service: $mealId');
    } catch (e) {
      developer.log('❌ Error in MealService.deleteMeal: $e');
      rethrow;
    }
  }

  /// Calculate total calories for a meal based on its foods
  Future<double> calculateMealCalories(int mealId) async {
    try {
      developer.log('🔵 Calculating calories for meal $mealId');

      // Get all foods for this meal
      final mealFoods = await _mealFoodRepository.getMealFoodsByMealId(mealId);
      developer.log('📊 Found ${mealFoods.length} foods in meal');

      if (mealFoods.isEmpty) {
        developer.log('⚠️ No foods found for meal $mealId');
        return 0.0;
      }

      double totalCalories = 0.0;

      // For each food, get its calorie data and calculate
      for (final mealFood in mealFoods) {
        try {
          // Fetch the food details to get calories per 100g
          final foodList = await _foodRepository.getFoodsByUser(0);
          final food = foodList.firstWhere(
            (f) => f.foodId == mealFood.foodId,
            orElse: () => Food(
              foodId: 0,
              userId: 0,
              foodName: 'Unknown',
              category: 'Other',
              caloriesPer100g: 0.0,
              proteinPer100g: 0.0,
              carbsPer100g: 0.0,
              fatPer100g: 0.0,
            ),
          );

          // Calculate calories for this food based on quantity
          // Formula: (caloriesPer100g / 100) * quantity
          final caloriesForFood = (food.caloriesPer100g / 100.0) * mealFood.quantity;
          totalCalories += caloriesForFood;

          developer.log('📝 ${food.foodName}: ${mealFood.quantity}g = ${caloriesForFood.toStringAsFixed(1)} kcal');
        } catch (e) {
          developer.log('⚠️ Error calculating calories for food ${mealFood.foodId}: $e');
          // Continue with other foods
        }
      }

      developer.log('✅ Total meal calories: ${totalCalories.toStringAsFixed(1)} kcal');
      return totalCalories;
    } catch (e) {
      developer.log('❌ Error in calculateMealCalories: $e');
      return 0.0;
    }
  }

  /// Get meal with calculated calories
  Future<Map<String, dynamic>> getMealWithCalories(int mealId) async {
    try {
      final meal = await _repository.getMealById(mealId);
      final calories = await calculateMealCalories(mealId);

      return {
        'meal': meal,
        'calories': calories,
      };
    } catch (e) {
      developer.log('Error in getMealWithCalories: $e');
      rethrow;
    }
  }
}


