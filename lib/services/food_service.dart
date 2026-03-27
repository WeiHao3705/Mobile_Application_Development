import 'package:mobile_application_development/models/food.dart';
import 'package:mobile_application_development/repository/food_repository.dart';
import 'dart:developer' as developer;

class FoodService {
  final FoodRepository _repository;

  FoodService({required FoodRepository repository}) : _repository = repository;

  /// Create a new food with automatic per-100g calculations
  Future<Food> createFood({
    required String foodName,
    required String category,
    required double servingSize,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    required int userId,
  }) async {
    try {
      developer.log('🔵 FoodService.createFood START');
      developer.log('📝 Food Name: $foodName');
      developer.log('📂 Category: $category');
      developer.log('⚖️ Serving Size: $servingSize');
      developer.log('🔥 Calories: $calories');
      developer.log('🥚 Protein: $protein');
      developer.log('🍚 Carbs: $carbs');
      developer.log('🧈 Fat: $fat');
      developer.log('👤 User ID: $userId');

      // Validate inputs
      _validateFoodInput(foodName, servingSize);

      // Calculate per 100g values
      final nutritionPer100g = _calculateNutritionPer100g(
        servingSize: servingSize,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );

      developer.log('📊 Nutrition per 100g calculated:');
      developer.log('   Calories: ${nutritionPer100g['calories']}');
      developer.log('   Protein: ${nutritionPer100g['protein']}');
      developer.log('   Carbs: ${nutritionPer100g['carbs']}');
      developer.log('   Fat: ${nutritionPer100g['fat']}');

      // Create Food object
      final food = Food(
        foodId: 0,
        foodName: foodName.trim(),
        category: category.trim(),
        caloriesPer100g: nutritionPer100g['calories']!,
        proteinPer100g: nutritionPer100g['protein']!,
        fatPer100g: nutritionPer100g['fat']!,
        carbsPer100g: nutritionPer100g['carbs']!,
        userId: userId,
      );

      developer.log('🍽️ Food object created');
      developer.log('📤 Food JSON: ${food.toJson()}');

      // Save to repository
      developer.log('💾 Calling repository.createFood()...');
      final savedFood = await _repository.createFood(food);
      developer.log('✅ Food created successfully via service: ${savedFood.foodName}');
      developer.log('🆔 Returned Food ID: ${savedFood.foodId}');
      return savedFood;
    } catch (e) {
      developer.log('❌ ERROR in FoodService.createFood: $e');
      developer.log('❌ Error Type: ${e.runtimeType}');
      developer.log('❌ Stack Trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Get all foods by user ID
  Future<List<Food>> getUserFoods(int userId) async {
    try {
      final foods = await _repository.getFoodsByUser(userId);
      developer.log('Retrieved ${foods.length} foods for user $userId');
      return foods;
    } catch (e) {
      developer.log('Error in FoodService.getUserFoods: $e');
      rethrow;
    }
  }

  /// Get all available foods
  Future<List<Food>> getAllFoods() async {
    try {
      final foods = await _repository.getAllFoods();
      developer.log('Retrieved ${foods.length} total foods');
      return foods;
    } catch (e) {
      developer.log('Error in FoodService.getAllFoods: $e');
      rethrow;
    }
  }

  /// Search foods by name
  Future<List<Food>> searchFoods(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }
      final results = await _repository.searchFoods(query);
      developer.log('Search for "$query" returned ${results.length} results');
      return results;
    } catch (e) {
      developer.log('Error in FoodService.searchFoods: $e');
      rethrow;
    }
  }

  /// Update existing food
  Future<Food> updateFood({
    required int foodId,
    required String foodName,
    required String category,
    required double caloriesPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
    required int userId,
  }) async {
    try {
      _validateFoodInput(foodName, 100); // 100g is baseline

      final food = Food(
        foodId: foodId,
        foodName: foodName.trim(),
        category: category.trim(),
        caloriesPer100g: caloriesPer100g,
        proteinPer100g: proteinPer100g,
        fatPer100g: fatPer100g,
        carbsPer100g: carbsPer100g,
        userId: userId,
      );

      final updatedFood = await _repository.updateFood(food);
      developer.log('Food updated via service: ${updatedFood.foodName}');
      return updatedFood;
    } catch (e) {
      developer.log('Error in FoodService.updateFood: $e');
      rethrow;
    }
  }

  /// Delete food by ID
  Future<void> deleteFood(int foodId) async {
    try {
      await _repository.deleteFood(foodId);
      developer.log('Food deleted via service: ID $foodId');
    } catch (e) {
      developer.log('Error in FoodService.deleteFood: $e');
      rethrow;
    }
  }

  /// Validate food input
  void _validateFoodInput(String foodName, double servingSize) {
    if (foodName.isEmpty) {
      throw Exception('Food name is required');
    }
    if (servingSize <= 0) {
      throw Exception('Serving size must be greater than 0');
    }
  }

  /// Calculate nutrition per 100g
  Map<String, double> _calculateNutritionPer100g({
    required double servingSize,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) {
    return {
      'calories': (calories / servingSize) * 100,
      'protein': (protein / servingSize) * 100,
      'carbs': (carbs / servingSize) * 100,
      'fat': (fat / servingSize) * 100,
    };
  }

  /// Calculate macronutrient percentages
  Map<String, double> calculateMacroPercentages({
    required double calories,
  }) {
    if (calories <= 0) {
      return {'protein': 0, 'carbs': 0, 'fat': 0};
    }

    // Standard macronutrient calories per gram
    const proteinCalPerGram = 4.0;
    const carbCalPerGram = 4.0;
    const fatCalPerGram = 9.0;

    return {
      'protein': (calories * 0.25) / proteinCalPerGram, // 25% of calories from protein
      'carbs': (calories * 0.50) / carbCalPerGram,       // 50% from carbs
      'fat': (calories * 0.25) / fatCalPerGram,          // 25% from fat
    };
  }
}

