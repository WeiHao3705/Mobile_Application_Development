import 'package:mobile_application_development/models/nutrition_aggregation.dart';
import 'package:mobile_application_development/models/meal_log.dart';
import 'package:mobile_application_development/models/daily_goals.dart';

/// Service for aggregating nutrition data by time period
class NutritionAggregationService {
  /// Get daily aggregation for a specific date
  DailyAggregation getDailyAggregation({
    required DateTime date,
    required List<MealLog> allMeals,
    required DailyGoals? goals,
  }) {
    // Filter meals for the given date
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final meals = allMeals.where((meal) {
      return meal.mealDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          meal.mealDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
    }).toList();

    // Calculate totals
    double totalCalories = 0;
    double totalProteins = 0;
    double totalCarbs = 0;
    double totalFats = 0;

    for (final meal in meals) {
      totalCalories += meal.totalCalories ?? 0;
      totalProteins += meal.totalProteins ?? 0;
      totalCarbs += meal.totalCarbs ?? 0;
      totalFats += meal.totalFats ?? 0;
    }

    return DailyAggregation(
      date: date,
      meals: meals,
      totalCalories: totalCalories,
      totalProteins: totalProteins,
      totalCarbs: totalCarbs,
      totalFats: totalFats,
      calorieGoal: goals?.targetCalories?.toDouble() ?? 2000,
      proteinGoal: goals?.targetProtein ?? 150,
      carbsGoal: goals?.targetCarbs ?? 200,
      fatGoal: goals?.targetFat ?? 67,
    );
  }

  /// Get weekly aggregation for the last 7 days ending on the given date
  WeeklyAggregation getWeeklyAggregation({
    required DateTime endDate,
    required List<MealLog> allMeals,
    required DailyGoals? goals,
  }) {
    final startDate = endDate.subtract(const Duration(days: 6));
    final dailyData = <DailyAggregation>[];

    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      dailyData.add(getDailyAggregation(
        date: date,
        allMeals: allMeals,
        goals: goals,
      ));
    }

    // Calculate averages
    final calorieGoal = goals?.targetCalories?.toDouble() ?? 2000.0;
    final proteinGoal = goals?.targetProtein ?? 150.0;
    final carbsGoal = goals?.targetCarbs ?? 200.0;
    final fatGoal = goals?.targetFat ?? 67.0;

    final avgDailyCalories = dailyData.isEmpty
        ? 0.0
        : dailyData.fold<double>(0.0, (sum, d) => sum + d.totalCalories) / dailyData.length;
    final avgDailyProteins = dailyData.isEmpty
        ? 0.0
        : dailyData.fold<double>(0.0, (sum, d) => sum + d.totalProteins) / dailyData.length;
    final avgDailyCarbs = dailyData.isEmpty
        ? 0.0
        : dailyData.fold<double>(0.0, (sum, d) => sum + d.totalCarbs) / dailyData.length;
    final avgDailyFats = dailyData.isEmpty
        ? 0.0
        : dailyData.fold<double>(0.0, (sum, d) => sum + d.totalFats) / dailyData.length;

    return WeeklyAggregation(
      startDate: startDate,
      endDate: endDate,
      dailyData: dailyData,
      avgDailyCalories: avgDailyCalories,
      avgDailyProteins: avgDailyProteins,
      avgDailyCarbs: avgDailyCarbs,
      avgDailyFats: avgDailyFats,
      weeklyCalorieGoal: calorieGoal * 7,
      weeklyProteinGoal: proteinGoal * 7,
      weeklyCarbsGoal: carbsGoal * 7,
      weeklyFatGoal: fatGoal * 7,
    );
  }

  /// Get monthly aggregation for the last 30 days ending on the given date
  MonthlyAggregation getMonthlyAggregation({
    required DateTime endDate,
    required List<MealLog> allMeals,
    required DailyGoals? goals,
  }) {
    final startDate = endDate.subtract(const Duration(days: 29));
    final dailyData = <DailyAggregation>[];

    for (int i = 0; i < 30; i++) {
      final date = startDate.add(Duration(days: i));
      dailyData.add(getDailyAggregation(
        date: date,
        allMeals: allMeals,
        goals: goals,
      ));
    }

    // Calculate totals and averages
    final calorieGoal = goals?.targetCalories?.toDouble() ?? 2000.0;
    final proteinGoal = goals?.targetProtein ?? 150.0;
    final carbsGoal = goals?.targetCarbs ?? 200.0;
    final fatGoal = goals?.targetFat ?? 67.0;

    final totalCalories = dailyData.fold<double>(0.0, (sum, d) => sum + d.totalCalories);
    final totalProteins = dailyData.fold<double>(0.0, (sum, d) => sum + d.totalProteins);
    final totalCarbs = dailyData.fold<double>(0.0, (sum, d) => sum + d.totalCarbs);
    final totalFats = dailyData.fold<double>(0.0, (sum, d) => sum + d.totalFats);

    return MonthlyAggregation(
      startDate: startDate,
      endDate: endDate,
      dailyData: dailyData,
      totalCalories: totalCalories,
      totalProteins: totalProteins,
      totalCarbs: totalCarbs,
      totalFats: totalFats,
      avgDailyCalories: dailyData.isEmpty ? 0.0 : totalCalories / dailyData.length,
      avgDailyProteins: dailyData.isEmpty ? 0.0 : totalProteins / dailyData.length,
      avgDailyCarbs: dailyData.isEmpty ? 0.0 : totalCarbs / dailyData.length,
      avgDailyFats: dailyData.isEmpty ? 0.0 : totalFats / dailyData.length,
      monthlyCalorieGoal: calorieGoal * 30,
      monthlyProteinGoal: proteinGoal * 30,
      monthlyCarbsGoal: carbsGoal * 30,
      monthlyFatGoal: fatGoal * 30,
    );
  }
}





