import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/meal_log.dart';
import '../repository/meal_repository.dart';
import '../repository/meal_food_repository.dart';
import '../repository/food_repository.dart';
import '../services/meal_service.dart';
import '../services/image_upload_service.dart';
import '../services/image_picker_service.dart';
import '../repository/daily_goals_repository.dart';
import 'dart:developer' as developer;
import 'dart:io';

class MealController extends ChangeNotifier {
  late final MealService _service;
  late final ImageUploadService _imageUploadService;
  final ImagePickerService _imagePickerService = ImagePickerService();

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

      // ImageUploadService now gets fresh client dynamically
      // This ensures it always has the current session
      _imageUploadService = ImageUploadService();
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

  // Image upload state
  File? _selectedMealImage;
  File? get selectedMealImage => _selectedMealImage;

  String? _mealImageUrl;
  String? get mealImageUrl => _mealImageUrl;

  bool _isUploadingImage = false;
  bool get isUploadingImage => _isUploadingImage;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  /// Get calories for a specific meal
  double getMealCalories(int mealId) {
    return _mealCalories[mealId] ?? 0.0;
  }

  // ============ IMAGE UPLOAD METHODS ============

  /// Pick image from camera
  Future<bool> pickImageFromCamera() async {
    _errorMessage = '';
    notifyListeners();

    try {
      developer.log('📷 Picking image from camera...');
      final imageFile = await _imagePickerService.pickImageFromCamera();

      if (imageFile == null) {
        developer.log('⚠️ No image captured');
        return false;
      }

      // Validate image file
      if (!ImagePickerService.validateImageFile(file: imageFile)) {
        _errorMessage = 'Invalid image file or file size exceeds 10MB';
        developer.log('❌ $_errorMessage');
        notifyListeners();
        return false;
      }

      _selectedMealImage = imageFile;
      _mealImageUrl = null; // Clear previous URL
      developer.log('✅ Image selected from camera: ${imageFile.path}');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to pick image: ${e.toString()}';
      developer.log('❌ $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  /// Pick image from gallery
  Future<bool> pickImageFromGallery() async {
    _errorMessage = '';
    notifyListeners();

    try {
      developer.log('🖼️ Picking image from gallery...');
      final imageFile = await _imagePickerService.pickImageFromGallery();

      if (imageFile == null) {
        developer.log('⚠️ No image selected');
        return false;
      }

      // Validate image file
      if (!ImagePickerService.validateImageFile(file: imageFile)) {
        _errorMessage = 'Invalid image file or file size exceeds 10MB';
        developer.log('❌ $_errorMessage');
        notifyListeners();
        return false;
      }

      _selectedMealImage = imageFile;
      _mealImageUrl = null; // Clear previous URL
      developer.log('✅ Image selected from gallery: ${imageFile.path}');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to pick image: ${e.toString()}';
      developer.log('❌ $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  /// Upload selected image to Supabase Storage
  Future<bool> uploadMealImage({required int userId}) async {
    if (_selectedMealImage == null) {
      _errorMessage = 'No image selected';
      developer.log('❌ $_errorMessage');
      return false;
    }

    _isUploadingImage = true;
    _errorMessage = '';
    notifyListeners();

    try {
      developer.log('📤 Starting meal image upload...');
      developer.log('👤 User ID: $userId');

      _mealImageUrl = await _imageUploadService.uploadMealImage(
        imageFile: _selectedMealImage!,
        userId: userId,
        mealDate: DateTime.now(),
      );

      developer.log('✅ Image uploaded successfully');
      developer.log('🔗 Image URL: $_mealImageUrl');
      notifyListeners();
      return true;
    } on StorageException catch (e) {
      _errorMessage = 'Storage error: ${e.message}';
      developer.log('❌ $_errorMessage');
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to upload image: ${e.toString()}';
      developer.log('❌ $_errorMessage');
      notifyListeners();
      return false;
    } finally {
      _isUploadingImage = false;
      notifyListeners();
    }
  }

  /// Clear selected image
  void clearSelectedImage() {
    _selectedMealImage = null;
    _mealImageUrl = null;
    developer.log('🧹 Selected meal image cleared');
    notifyListeners();
  }

  /// Log meal with optional image
  Future<bool> logMealWithImage({
    required int userId,
    required String mealType,
    required DateTime mealDate,
    required Map<int, Map<String, dynamic>> foodsWithQuantities,
    String? mealName,
    String? imageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    _isSuccess = false;
    notifyListeners();

    try {
      developer.log('🟨 MealController.logMealWithImage START');
      developer.log('👤 User ID: $userId');
      developer.log('🍽️ Meal Type: $mealType');
      developer.log('📊 Foods: ${foodsWithQuantities.length}');
      developer.log('📷 Image URL: ${imageUrl ?? "None"}');

      int? mealId;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        // Log meal with image
        mealId = await _service.logMealWithImage(
          userId: userId,
          mealType: mealType,
          mealDate: mealDate,
          foodsWithQuantities: foodsWithQuantities,
          imageUrl: imageUrl,
          mealName: mealName,
        );
      } else {
        // Log meal without image
        mealId = await _service.logMeal(
          userId: userId,
          mealType: mealType,
          mealDate: mealDate,
          foodsWithQuantities: foodsWithQuantities,
          mealName: mealName,
        );
      }

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
      return false;
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      developer.log('❌ Exception in MealController: $_errorMessage');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to log meal. Please try again.';
      developer.log('❌ Unexpected error in MealController: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ END IMAGE UPLOAD METHODS ============


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
    String? mealName,
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
      developer.log('📝 Meal Name: $mealName');

      final mealId = await _service.logMeal(
        userId: userId,
        mealType: mealType,
        mealDate: mealDate,
        foodsWithQuantities: foodsWithQuantities,
        mealName: mealName,
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
    String? mealName,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      developer.log('🟨 MealController.updateMeal START');
      developer.log('👤 Meal ID: $mealId');
      developer.log('📊 Foods provided: ${foodsWithQuantities?.length ?? 0}');
      developer.log('📝 Meal Name: $mealName');

      final updatedMeal = await _service.updateMeal(
        mealId: mealId,
        mealType: mealType,
        mealDate: mealDate,
        userId: userId,
        foodsWithQuantities: foodsWithQuantities,
        mealName: mealName,
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

