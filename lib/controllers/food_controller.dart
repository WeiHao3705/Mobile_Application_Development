import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food.dart';
import '../repository/food_repository.dart';
import '../services/food_service.dart';
import 'dart:developer' as developer;

class FoodController extends ChangeNotifier {
  late final FoodService _service;

  FoodController({FoodRepository? repository, FoodService? service}) {
    try {
      final repo = repository ?? FoodRepository(supabase: Supabase.instance.client);
      _service = service ?? FoodService(repository: repo);
      developer.log('✅ FoodController initialized successfully');
    } catch (e) {
      developer.log('❌ FoodController initialization error: $e');
      // Initialize with a default service that can be used later
      _service = FoodService(repository: repository ?? FoodRepository(supabase: Supabase.instance.client));
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<Food> _userFoods = [];
  List<Food> get userFoods => List.unmodifiable(_userFoods);

  Food? _currentFood;
  Food? get currentFood => _currentFood;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  // CREATE - Save new food
  Future<bool> createFood({
    required String foodName,
    required String category,
    required double servingSize,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    required int userId,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    _isSuccess = false;
    notifyListeners();

    try {
      developer.log('🟨 FoodController.createFood START');
      developer.log('👤 User ID: $userId');

      final food = await _service.createFood(
        foodName: foodName,
        category: category,
        servingSize: servingSize,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        userId: userId,
      );

      _currentFood = food;
      _isSuccess = true;
      developer.log('✅ Food created successfully via controller: ${food.foodName}');
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      developer.log('❌ Exception in FoodController: $_errorMessage');
      developer.log('❌ Exception details: $e');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to save food. Please try again.';
      developer.log('❌ Unexpected error in FoodController: $e');
      developer.log('❌ Error type: ${e.runtimeType}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // READ - Get foods by user
  Future<bool> fetchUserFoods(String userId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final foods = await _service.getUserFoods(int.parse(userId));
      _userFoods = foods;
      developer.log('Fetched ${foods.length} foods for user $userId');
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      developer.log('Error fetching user foods: $_errorMessage');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to fetch foods. Please try again.';
      developer.log('Unexpected error fetching foods: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // READ - Get all foods (for discovery)
  Future<bool> fetchAllFoods() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final foods = await _service.getAllFoods();
      _userFoods = foods;
      developer.log('Fetched ${foods.length} foods from database');
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      developer.log('Error fetching all foods: $_errorMessage');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to fetch foods. Please try again.';
      developer.log('Unexpected error fetching all foods: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // UPDATE - Update existing food
  Future<bool> updateFood({
    required int foodId,
    required String foodName,
    required String category,
    required double caloriesPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
    required int userId,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final updatedFood = await _service.updateFood(
        foodId: foodId,
        foodName: foodName,
        category: category,
        caloriesPer100g: caloriesPer100g,
        proteinPer100g: proteinPer100g,
        carbsPer100g: carbsPer100g,
        fatPer100g: fatPer100g,
        userId: userId,
      );

      _currentFood = updatedFood;

      // Update in the _userFoods list as well
      final index = _userFoods.indexWhere((food) => food.foodId == foodId);
      if (index != -1) {
        _userFoods[index] = updatedFood;
      }

      _isSuccess = true;

      developer.log('Food updated successfully: ${updatedFood.foodName}');
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      developer.log('Error updating food: $_errorMessage');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update food. Please try again.';
      developer.log('Unexpected error updating food: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // DELETE - Delete food
  Future<bool> deleteFood(int foodId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _service.deleteFood(foodId);
      _userFoods.removeWhere((food) => food.foodId == foodId);
      _isSuccess = true;

      developer.log('Food deleted successfully: $foodId');
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      developer.log('Error deleting food: $_errorMessage');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete food. Please try again.';
      developer.log('Unexpected error deleting food: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // SEARCH - Search foods by name
  Future<bool> searchFoods(String query) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final foods = await _service.searchFoods(query);
      _userFoods = foods;
      developer.log('Search returned ${foods.length} results for: $query');
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      developer.log('Error searching foods: $_errorMessage');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to search foods. Please try again.';
      developer.log('Unexpected error searching: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Clear success flag
  void clearSuccess() {
    _isSuccess = false;
    notifyListeners();
  }

  // Reset controller state
  void reset() {
    _isLoading = false;
    _errorMessage = '';
    _isSuccess = false;
    _currentFood = null;
    notifyListeners();
  }
}

