class MealFood{
  final int? mealFoodId;
  final int mealId;
  final int foodId;
  final double quantity;
  final String unit;

  MealFood({
    this.mealFoodId,
    required this.mealId,
    required this.foodId,
    required this.quantity,
    required this.unit
  });

  factory MealFood.fromJson(Map<String, dynamic> json){
    return MealFood(
      mealFoodId: json['meal_food_id'] as int?,
      mealId: json['meal_id'] as int? ?? 0,
      foodId: json['food_id'] as int? ?? 0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'g'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (mealFoodId != null) 'meal_food_id': mealFoodId,
      'meal_id': mealId,
      'food_id': foodId,
      'quantity': quantity,
      'unit': unit
    };
  }

}