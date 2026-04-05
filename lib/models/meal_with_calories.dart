import 'meal_log.dart';

class MealWithCalories {
  final MealLog meal;
  final double calories;

  MealWithCalories({
    required this.meal,
    required this.calories,
  });

  /// Calculate calories with optional decimal places
  String getCaloriesString({int decimalPlaces = 1}) {
    return calories.toStringAsFixed(decimalPlaces);
  }

  /// Get rounded calories
  int getCaloriesRounded() {
    return calories.round();
  }
}

