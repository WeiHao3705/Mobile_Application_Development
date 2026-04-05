class MealLog{
  final int? mealId;
  final String mealType;
  final DateTime mealDate;
  final int userId;
  final double? totalCalories;

  MealLog({
    this.mealId,
    required this.mealType,
    required this.mealDate,
    required this.userId,
    this.totalCalories,
  });

  factory MealLog.fromJson(Map<String, dynamic> json){
    final mealDateValue = json['meal_date'];
    DateTime parsedDate;

    if (mealDateValue is String) {
      parsedDate = DateTime.parse(mealDateValue);
    } else if (mealDateValue is DateTime) {
      parsedDate = mealDateValue;
    } else {
      parsedDate = DateTime.now();
    }

    return MealLog(
      mealId: json['meal_id'] as int?,
      mealType: json['meal_type'] as String? ?? 'Custom',
      mealDate: parsedDate,
      userId: json['user_id'] as int? ?? 0,
      totalCalories: (json['total_calories'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson(){
    return {
      if (mealId != null) 'meal_id': mealId,
      'meal_type': mealType,
      'meal_date': mealDate.toIso8601String(),
      'user_id': userId,
      if (totalCalories != null) 'total_calories': totalCalories,
    };
  }

}