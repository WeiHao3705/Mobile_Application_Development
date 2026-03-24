class MealFood{
  final int mealFoodId;
  final int mealId;
  final int foodId;
  final double quantity;
  final String unit;

  MealFood({
    required this.mealFoodId,
    required this.mealId,
    required this.foodId,
    required this.quantity,
    required this.unit
  });

  factory MealFood.fromJson(Map<String, dynamic> json){
    return MealFood(
      mealFoodId: json['meal_food_id'],
      mealId: json['meal_id'],
      foodId: json['food_id'],
      quantity: json['quantity'],
      unit: json['unit']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meal_food_id': mealFoodId,
      'meal_id': mealId,
      'food_id': foodId,
      'quantity': quantity,
      'unit': unit
    };
  }

}