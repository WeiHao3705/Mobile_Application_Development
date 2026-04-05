class DailyGoals {
  final int dailyGoalsId;
  final int userId;
  final int? targetCalories;
  final double? targetProtein;
  final double? targetCarbs;
  final double? targetFat;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DailyGoals({
    required this.dailyGoalsId,
    required this.userId,
    this.targetCalories,
    this.targetProtein,
    this.targetCarbs,
    this.targetFat,
    this.createdAt,
    this.updatedAt,
  });

  factory DailyGoals.fromJson(Map<String, dynamic> json) {
    return DailyGoals(
      dailyGoalsId: json['daily_goals_id'],
      userId: json['user_id'],
      targetCalories: json['target_calories'],
      targetProtein: (json['target_protein'] as num?)?.toDouble(),
      targetCarbs: (json['target_carbs'] as num?)?.toDouble(),
      targetFat: (json['target_fat'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
      updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_goals_id': dailyGoalsId,
      'user_id': userId,
      'target_calories': targetCalories,
      'target_protein': targetProtein,
      'target_carbs': targetCarbs,
      'target_fat': targetFat,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Useful method to create a copy with updated values
  DailyGoals copyWith({
    int? dailyGoalsId,
    int? userId,
    int? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyGoals(
      dailyGoalsId: dailyGoalsId ?? this.dailyGoalsId,
      userId: userId ?? this.userId,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFat: targetFat ?? this.targetFat,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

