import 'package:mobile_application_development/models/daily_goals.dart';
import 'dart:developer' as developer;

class DailyGoalsService {
  /// Calculate BMR (Basal Metabolic Rate) using Mifflin-St Jeor formula
  static double calculateBMR({
    required int ageYears,
    required double weightKg,
    required double heightCm,
    required String gender,
  }) {
    developer.log('📊 Calculating BMR...');
    developer.log('   Age: $ageYears, Weight: $weightKg kg, Height: $heightCm cm, Gender: $gender');

    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears) - 161;
    }

    developer.log('✅ BMR: ${bmr.toStringAsFixed(2)} kcal/day');
    return bmr;
  }

  /// Calculate TDEE (Total Daily Energy Expenditure)
  static double calculateTDEE({
    required double bmr,
    required String activityLevel,
  }) {
    developer.log('📊 Calculating TDEE...');
    developer.log('   BMR: ${bmr.toStringAsFixed(2)}, Activity Level: $activityLevel');

    final activityFactors = {
      'sedentary': 1.2,           // Little or no exercise
      'lightly_active': 1.375,    // Exercise 1-3 days/week
      'moderately_active': 1.55,  // Exercise 3-5 days/week
      'very_active': 1.725,       // Exercise 6-7 days/week
      'extremely_active': 1.9,    // Physical job or training twice daily
    };

    final factor = activityFactors[activityLevel.toLowerCase()] ?? 1.55;
    final tdee = bmr * factor;

    developer.log('✅ TDEE: ${tdee.toStringAsFixed(2)} kcal/day');
    return tdee;
  }

  /// Adjust calories based on fitness goal
  static int adjustCaloriesForGoal({
    required int tdeeCalories,
    required String fitnessGoal,
  }) {
    developer.log('📊 Adjusting calories for goal: $fitnessGoal');

    int adjusted;
    if (fitnessGoal.toLowerCase() == 'lose_weight') {
      adjusted = (tdeeCalories * 0.85).toInt(); // 15% deficit
      developer.log('✅ Adjusted (Lose Weight): $adjusted kcal (85% of TDEE)');
    } else if (fitnessGoal.toLowerCase() == 'gain_muscle') {
      adjusted = (tdeeCalories * 1.10).toInt(); // 10% surplus
      developer.log('✅ Adjusted (Gain Muscle): $adjusted kcal (110% of TDEE)');
    } else {
      adjusted = tdeeCalories;
      developer.log('✅ Adjusted (Maintain): $adjusted kcal (100% of TDEE)');
    }

    return adjusted;
  }

  /// Calculate macro distribution
  static Map<String, double> calculateMacros({
    required int targetCalories,
    required String fitnessGoal,
  }) {
    developer.log('📊 Calculating macros for $targetCalories kcal...');

    // Default: 40% carbs, 30% protein, 30% fat
    double proteinPercentage = 0.30;
    double carbPercentage = 0.40;
    double fatPercentage = 0.30;

    if (fitnessGoal.toLowerCase() == 'gain_muscle') {
      proteinPercentage = 0.35; // Higher protein for muscle building
      carbPercentage = 0.45;
      fatPercentage = 0.20;
      developer.log('   Goal: Gain Muscle');
    } else if (fitnessGoal.toLowerCase() == 'lose_weight') {
      proteinPercentage = 0.35; // Higher protein to preserve muscle
      carbPercentage = 0.35;
      fatPercentage = 0.30;
      developer.log('   Goal: Lose Weight');
    } else {
      developer.log('   Goal: Maintain');
    }

    final protein = (targetCalories * proteinPercentage / 4).roundToDouble();
    final carbs = (targetCalories * carbPercentage / 4).roundToDouble();
    final fat = (targetCalories * fatPercentage / 9).roundToDouble();

    developer.log('✅ Protein: ${protein.toStringAsFixed(1)}g (${(proteinPercentage * 100).toStringAsFixed(0)}%)');
    developer.log('✅ Carbs: ${carbs.toStringAsFixed(1)}g (${(carbPercentage * 100).toStringAsFixed(0)}%)');
    developer.log('✅ Fat: ${fat.toStringAsFixed(1)}g (${(fatPercentage * 100).toStringAsFixed(0)}%)');

    return {
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  /// Main method to calculate all daily goals
  static DailyGoals calculateDailyGoals({
    required int userId,
    required int ageYears,
    required double weightKg,
    required double heightCm,
    required String gender,
    required String activityLevel,
    required String fitnessGoal,
  }) {
    developer.log('🔵 DailyGoalsService.calculateDailyGoals START');
    developer.log('👤 User ID: $userId');

    final bmr = calculateBMR(
      ageYears: ageYears,
      weightKg: weightKg,
      heightCm: heightCm,
      gender: gender,
    );

    final tdee = calculateTDEE(bmr: bmr, activityLevel: activityLevel);
    final targetCalories = adjustCaloriesForGoal(
      tdeeCalories: tdee.toInt(),
      fitnessGoal: fitnessGoal,
    );

    final macros = calculateMacros(
      targetCalories: targetCalories,
      fitnessGoal: fitnessGoal,
    );

    final goals = DailyGoals(
      dailyGoalsId: 0, // Will be assigned by database
      userId: userId,
      targetCalories: targetCalories,
      targetProtein: macros['protein'],
      targetCarbs: macros['carbs'],
      targetFat: macros['fat'],
    );

    developer.log('✅ DailyGoals calculated successfully');
    return goals;
  }
}

