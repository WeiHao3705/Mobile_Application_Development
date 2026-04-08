class Food {
  final int foodId;
  final int userId;
  final String foodName;
  final String category;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  Food({
    required this.foodId,
    required this.userId,
    required this.foodName,
    required this.category,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      foodId: json['food_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      foodName: json['food_name'] ?? '',
      category: json['category'] ?? 'Other',
      caloriesPer100g: (json['calories_per_100g'] as num?)?.toDouble() ?? 0.0,
      proteinPer100g: (json['protein_per_100g'] as num?)?.toDouble() ?? 0.0,
      carbsPer100g: (json['carbs_per_100g'] as num?)?.toDouble() ?? 0.0,
      fatPer100g: (json['fat_per_100g'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final json = {
      'user_id': userId,
      'food_name': foodName,
      'category': category,
      'calories_per_100g': caloriesPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fat_per_100g': fatPer100g,
    };

    // Only include food_id if it's not 0 (new record) or if explicitly requested
    if (includeId && foodId != 0) {
      json['food_id'] = foodId;
    }

    return json;
  }

  /// Create a copy of this Food with optional field overrides
  Food copyWith({
    int? foodId,
    int? userId,
    String? foodName,
    String? category,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
  }) {
    return Food(
      foodId: foodId ?? this.foodId,
      userId: userId ?? this.userId,
      foodName: foodName ?? this.foodName,
      category: category ?? this.category,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
    );
  }
}