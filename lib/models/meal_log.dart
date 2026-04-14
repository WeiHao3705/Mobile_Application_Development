class MealLog {
  final int? mealId;
  final String mealType;
  final DateTime mealDate;
  final int userId;
  final double? totalCalories;
  final double? totalProteins;
  final double? totalCarbs;
  final double? totalFats;
  final String? mealName;

  MealLog({
    this.mealId,
    required this.mealType,
    required this.mealDate,
    required this.userId,
    this.totalCalories,
    this.totalProteins,
    this.totalCarbs,
    this.totalFats,
    this.mealName,
  });

  factory MealLog.fromJson(Map<String, dynamic> json) {
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
      totalProteins: (json['total_proteins'] as num?)?.toDouble(),
      totalCarbs: (json['total_carbs'] as num?)?.toDouble(),
      totalFats: (json['total_fats'] as num?)?.toDouble(),
      mealName: json['meal_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (mealId != null) 'meal_id': mealId,
      'meal_type': mealType,
      'meal_date': mealDate.toIso8601String(),
      'user_id': userId,
      if (totalCalories != null) 'total_calories': totalCalories,
      if (totalProteins != null) 'total_proteins': totalProteins,
      if (totalCarbs != null) 'total_carbs': totalCarbs,
      if (totalFats != null) 'total_fats': totalFats,
      if (mealName != null) 'meal_name': mealName,
    };
  }

  MealLog copyWith({
    int? mealId,
    String? mealType,
    DateTime? mealDate,
    int? userId,
    double? totalCalories,
    double? totalProteins,
    double? totalCarbs,
    double? totalFats,
    String? mealName,
  }) {
    return MealLog(
      mealId: mealId ?? this.mealId,
      mealType: mealType ?? this.mealType,
      mealDate: mealDate ?? this.mealDate,
      userId: userId ?? this.userId,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProteins: totalProteins ?? this.totalProteins,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFats: totalFats ?? this.totalFats,
      mealName: mealName ?? this.mealName,
    );
  }

  bool hasCompleteMacros() {
    return totalCalories != null &&
        totalProteins != null &&
        totalCarbs != null &&
        totalFats != null;
  }

  String getFormattedDate() {
    return "${mealDate.year}-${mealDate.month.toString().padLeft(2, '0')}-${mealDate.day.toString().padLeft(2, '0')}";
  }

  String getFormattedTime() {
    return "${mealDate.hour.toString().padLeft(2, '0')}:${mealDate.minute.toString().padLeft(2, '0')}";
  }

  @override
  String toString() {
    return 'MealLog(mealId: $mealId, mealType: $mealType, mealDate: $mealDate, userId: $userId, '
        'totalCalories: $totalCalories, totalProteins: $totalProteins, totalCarbs: $totalCarbs, '
        'totalFats: $totalFats, mealName: $mealName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MealLog &&
        other.mealId == mealId &&
        other.mealType == mealType &&
        other.mealDate == mealDate &&
        other.userId == userId &&
        other.totalCalories == totalCalories &&
        other.totalProteins == totalProteins &&
        other.totalCarbs == totalCarbs &&
        other.totalFats == totalFats &&
        other.mealName == mealName;
  }

  @override
  int get hashCode {
    return Object.hash(mealId, mealType, mealDate, userId, totalCalories,
        totalProteins, totalCarbs, totalFats, mealName);
  }
}
