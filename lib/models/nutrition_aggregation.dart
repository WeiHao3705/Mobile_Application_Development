import 'meal_log.dart';

/// Represents aggregated nutrition data for a single day
class DailyAggregation {
  final DateTime date;
  final List<MealLog> meals;
  final double totalCalories;
  final double totalProteins;
  final double totalCarbs;
  final double totalFats;
  final double calorieGoal;
  final double proteinGoal;
  final double carbsGoal;
  final double fatGoal;

  DailyAggregation({
    required this.date,
    required this.meals,
    required this.totalCalories,
    required this.totalProteins,
    required this.totalCarbs,
    required this.totalFats,
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
  });

  /// Deviation from goal (negative = under, positive = over)
  double get calorieDeviation => totalCalories - calorieGoal;
  double get proteinDeviation => totalProteins - proteinGoal;
  double get carbsDeviation => totalCarbs - carbsGoal;
  double get fatDeviation => totalFats - fatGoal;

  /// Percentage of goal achieved
  double get caloriePercentage => (totalCalories / calorieGoal * 100).clamp(0, 200);
  double get proteinPercentage => (totalProteins / proteinGoal * 100).clamp(0, 200);
  double get carbsPercentage => (totalCarbs / carbsGoal * 100).clamp(0, 200);
  double get fatPercentage => (totalFats / fatGoal * 100).clamp(0, 200);

  /// Check if the day is on track
  bool get isOnTrack {
    const tolerance = 0.1; // 10% tolerance
    return caloriePercentage >= (100 - tolerance * 100) && caloriePercentage <= (100 + tolerance * 100);
  }
}

/// Represents aggregated nutrition data for a week (7 days)
class WeeklyAggregation {
  final DateTime startDate;
  final DateTime endDate;
  final List<DailyAggregation> dailyData;
  final double avgDailyCalories;
  final double avgDailyProteins;
  final double avgDailyCarbs;
  final double avgDailyFats;
  final double weeklyCalorieGoal;
  final double weeklyProteinGoal;
  final double weeklyCarbsGoal;
  final double weeklyFatGoal;

  WeeklyAggregation({
    required this.startDate,
    required this.endDate,
    required this.dailyData,
    required this.avgDailyCalories,
    required this.avgDailyProteins,
    required this.avgDailyCarbs,
    required this.avgDailyFats,
    required this.weeklyCalorieGoal,
    required this.weeklyProteinGoal,
    required this.weeklyCarbsGoal,
    required this.weeklyFatGoal,
  });

  /// Total calories for the week
  double get totalCalories => avgDailyCalories * dailyData.length;
  double get totalProteins => avgDailyProteins * dailyData.length;
  double get totalCarbs => avgDailyCarbs * dailyData.length;
  double get totalFats => avgDailyFats * dailyData.length;

  /// Deviation from weekly goal
  double get weeklyCalorieDeviation => totalCalories - weeklyCalorieGoal;
  double get proteinDeviationAvg => avgDailyProteins - (weeklyProteinGoal / 7);
  double get carbsDeviationAvg => avgDailyCarbs - (weeklyCarbsGoal / 7);
  double get fatDeviationAvg => avgDailyFats - (weeklyFatGoal / 7);

  /// Get calorie trend (list of calories for chart)
  List<double> get caloriesList => dailyData.map((d) => d.totalCalories).toList();

  /// Get day labels for chart
  List<String> get dayLabels {
    final labels = <String>[];
    for (int i = 0; i < dailyData.length; i++) {
      final date = startDate.add(Duration(days: i));
      final day = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][date.weekday - 1];
      labels.add(day);
    }
    return labels;
  }
}

/// Represents aggregated nutrition data for a month (30 days)
class MonthlyAggregation {
  final DateTime startDate;
  final DateTime endDate;
  final List<DailyAggregation> dailyData;
  final double totalCalories;
  final double totalProteins;
  final double totalCarbs;
  final double totalFats;
  final double avgDailyCalories;
  final double avgDailyProteins;
  final double avgDailyCarbs;
  final double avgDailyFats;
  final double monthlyCalorieGoal;
  final double monthlyProteinGoal;
  final double monthlyCarbsGoal;
  final double monthlyFatGoal;

  MonthlyAggregation({
    required this.startDate,
    required this.endDate,
    required this.dailyData,
    required this.totalCalories,
    required this.totalProteins,
    required this.totalCarbs,
    required this.totalFats,
    required this.avgDailyCalories,
    required this.avgDailyProteins,
    required this.avgDailyCarbs,
    required this.avgDailyFats,
    required this.monthlyCalorieGoal,
    required this.monthlyProteinGoal,
    required this.monthlyCarbsGoal,
    required this.monthlyFatGoal,
  });

  /// Deviation from monthly goal
  double get monthlyCalorieDeviation => totalCalories - monthlyCalorieGoal;
  double get proteinDeviationAvg => avgDailyProteins - (monthlyProteinGoal / dailyData.length);
  double get carbsDeviationAvg => avgDailyCarbs - (monthlyCarbsGoal / dailyData.length);
  double get fatDeviationAvg => avgDailyFats - (monthlyFatGoal / dailyData.length);

  /// Get percentage of goal
  double get caloriePercentage => (totalCalories / monthlyCalorieGoal * 100).clamp(0, 200);
  double get proteinPercentage => (totalProteins / monthlyProteinGoal * 100).clamp(0, 200);
  double get carbsPercentage => (totalCarbs / monthlyCarbsGoal * 100).clamp(0, 200);
  double get fatPercentage => (totalFats / monthlyFatGoal * 100).clamp(0, 200);

  /// Find nutrients with highest deviation (over/underconsumed)
  List<NutrientHighlight> getNutrientHighlights() {
    final highlights = [
      NutrientHighlight(
        name: 'Protein',
        actual: avgDailyProteins,
        goal: monthlyProteinGoal / dailyData.length,
        unit: 'g',
      ),
      NutrientHighlight(
        name: 'Carbs',
        actual: avgDailyCarbs,
        goal: monthlyCarbsGoal / dailyData.length,
        unit: 'g',
      ),
      NutrientHighlight(
        name: 'Fat',
        actual: avgDailyFats,
        goal: monthlyFatGoal / dailyData.length,
        unit: 'g',
      ),
    ];

    // Sort by deviation magnitude
    highlights.sort((a, b) => b.deviationPercentage.abs().compareTo(a.deviationPercentage.abs()));
    return highlights;
  }
}

/// Represents a nutrient with its deviation from goal
class NutrientHighlight {
  final String name;
  final double actual;
  final double goal;
  final String unit;

  NutrientHighlight({
    required this.name,
    required this.actual,
    required this.goal,
    required this.unit,
  });

  double get deviation => actual - goal;
  double get deviationPercentage => (deviation / goal * 100);
  bool get isOver => actual > goal;

  String get deviationString => '${isOver ? '+' : ''}${deviation.toStringAsFixed(1)}$unit';
  String get percentageString => '${deviationPercentage.toStringAsFixed(1)}%';
}

