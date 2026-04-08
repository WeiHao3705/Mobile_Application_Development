import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/meal_log.dart';
import '../repository/meal_repository.dart';
import '../repository/meal_food_repository.dart';
import '../repository/food_repository.dart';
import '../services/meal_service.dart';
import '../repository/daily_goals_repository.dart';
import 'dart:developer' as developer;

class MealController extends ChangeNotifier {
  late final MealService _service;

  MealController({MealService? service}) {
    if (service != null) {
      _service = service;
    } else {
      final supabaseClient = Supabase.instance.client;
      if (supabaseClient == null) {
        throw Exception('Supabase is not initialized. Ensure Supabase.initialize() is called before creating MealController.');
      }
      final mealRepo = MealLogRepository(supabase: supabaseClient);
      final mealFoodRepo = MealFoodRepository(supabase: supabaseClient);
      final foodRepo = FoodRepository(supabase: supabaseClient);
      final dailyGoalsRepo = DailyGoalsRepository(supabase: supabaseClient);

      _service = MealService(
        repository: mealRepo,
        mealFoodRepository: mealFoodRepo,
        foodRepository: foodRepo,
        dailyGoalsRepository: dailyGoalsRepo,
      );
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<MealLog> _userMeals = [];
  List<MealLog> get userMeals => List.unmodifiable(_userMeals);

  Map<int, double> _mealCalories = {};
  Map<int, double> get mealCalories => Map.unmodifiable(_mealCalories);

  MealLog? _currentMeal;
  MealLog? get currentMeal => _currentMeal;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  /// Get calories for a specific meal
  double getMealCalories(int mealId) {
    return _mealCalories[mealId] ?? 0.0;
  }

  /// Get macro summary for a meal based on its MealLog entry
  Map<String, double> getMealMacros(int mealId) {
    final meal = _userMeals.firstWhere(
      (m) => m.mealId == mealId,
      orElse: () => MealLog(
        mealId: mealId,
        mealType: 'Unknown',
        mealDate: DateTime.now(),
        userId: 0,
      ),
    );

    return {
      'calories': meal.totalCalories ?? 0.0,
      'proteins': meal.totalProteins ?? 0.0,
      'carbs': meal.totalCarbs ?? 0.0,
      'fats': meal.totalFats ?? 0.0,
    };
  }

  /// Log a new meal with selected foods
  Future<bool> logMeal({
    required int userId,
    required String mealType,
    required DateTime mealDate,
    required Map<int, Map<String, dynamic>> foodsWithQuantities,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    _isSuccess = false;
    notifyListeners();

    try {
      developer.log('🟨 MealController.logMeal START');
      developer.log('👤 User ID: $userId');
      developer.log('🍽️ Meal Type: $mealType');
      developer.log('📊 Foods: ${foodsWithQuantities.length}');

      final mealId = await _service.logMeal(
        userId: userId,
        mealType: mealType,
        mealDate: mealDate,
        foodsWithQuantities: foodsWithQuantities,
      );

      if (mealId == null || mealId == 0) {
        _errorMessage = 'Failed to create meal. Please try again.';
        developer.log('❌ Meal creation failed: returned null or 0 ID');
        return false;
      }

      _isSuccess = true;
      developer.log('✅ Meal logged successfully with ID: $mealId');
      return true;
    } on PostgrestException catch (e) {
      _errorMessage = 'Database error: ${e.message}';
      developer.log('❌ PostgrestException in MealController: $_errorMessage');
      developer.log('❌ Exception details: $e');
      return false;
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      developer.log('❌ Exception in MealController: $_errorMessage');
      developer.log('❌ Exception details: $e');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to log meal. Please try again.';
      developer.log('❌ Unexpected error in MealController: $e');
      developer.log('❌ Error type: ${e.runtimeType}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all meals for a user
  Future<bool> fetchUserMeals(int userId) async {
    _isLoading = true;
    _errorMessage = '';
    _mealCalories.clear();
    notifyListeners();

    try {
      final meals = await _service.getUserMeals(userId);
      _userMeals = meals;
      developer.log('Fetched ${meals.length} meals for user $userId');

      // Extract calories from the meal objects (already calculated and stored in DB)
      for (final meal in meals) {
        if (meal.mealId != null && meal.mealId! > 0) {
          final calories = meal.totalCalories ?? 0.0;
          _mealCalories[meal.mealId!] = calories;
          developer.log('Meal ${meal.mealId}: ${calories.toStringAsFixed(1)} kcal (from database)');
        }
      }

      notifyListeners();
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      developer.log('Error fetching user meals: $_errorMessage');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to fetch meals. Please try again.';
      developer.log('Unexpected error fetching meals: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get a single meal by ID
  Future<bool> fetchMealById(int mealId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final meal = await _service.getMealById(mealId);
      _currentMeal = meal;
      developer.log('Fetched meal: $mealId');
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      developer.log('Error fetching meal: $_errorMessage');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to fetch meal. Please try again.';
      developer.log('Unexpected error fetching meal: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing meal with new foods and recalculate nutrition
  Future<bool> updateMeal({
    required int mealId,
    required String mealType,
    required DateTime mealDate,
    required int userId,
    Map<int, Map<String, dynamic>>? foodsWithQuantities,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      developer.log('🟨 MealController.updateMeal START');
      developer.log('👤 Meal ID: $mealId');
      developer.log('📊 Foods provided: ${foodsWithQuantities?.length ?? 0}');

      final updatedMeal = await _service.updateMeal(
        mealId: mealId,
        mealType: mealType,
        mealDate: mealDate,
        userId: userId,
        foodsWithQuantities: foodsWithQuantities,
      );

      _currentMeal = updatedMeal;

      // Update in the _userMeals list as well
      final index = _userMeals.indexWhere((meal) => meal.mealId == mealId);
      if (index != -1) {
        _userMeals[index] = updatedMeal;
        // Also update the cached calories
        if (updatedMeal.totalCalories != null) {
          _mealCalories[mealId] = updatedMeal.totalCalories!;
        }
      }

      _isSuccess = true;

      developer.log('✅ Meal updated successfully: $mealId');
      developer.log('✅ Updated nutrition - Calories: ${updatedMeal.totalCalories}');
      return true;
    } on PostgrestException catch (e) {
      _errorMessage = 'Database error: ${e.message}';
      developer.log('❌ PostgrestException in MealController: $_errorMessage');
      return false;
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      developer.log('❌ Error updating meal: $_errorMessage');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update meal. Please try again.';
      developer.log('❌ Unexpected error updating meal: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a meal
  Future<bool> deleteMeal(int mealId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _service.deleteMeal(mealId);
      _userMeals.removeWhere((meal) => meal.mealId == mealId);
      _isSuccess = true;

      developer.log('Meal deleted successfully: $mealId');
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      developer.log('Error deleting meal: $_errorMessage');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete meal. Please try again.';
      developer.log('Unexpected error deleting meal: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  /// Clear success flag
  void clearSuccess() {
    _isSuccess = false;
    notifyListeners();
  }

  /// Reset controller state
  void reset() {
    _isLoading = false;
    _errorMessage = '';
    _isSuccess = false;
    _currentMeal = null;
    notifyListeners();
  }
}

