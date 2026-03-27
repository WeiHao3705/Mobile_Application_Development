class Food {
  final int foodId;
  final String foodName;
  final String category;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double fatPer100g;
  final double carbsPer100g;
  final int userId;

  Food({
    required this.foodId,
    required this.foodName,
    required this.category,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
    required this.carbsPer100g,
    required this.userId
  });

  factory Food.fromJson(Map<String,dynamic> json){
    return Food(
        foodId: json['food_id'],
        foodName: json['food_name'],
        category: json['category'] ?? 'Other',
        caloriesPer100g: (json['calories_per_100g'] as num).toDouble(),
        proteinPer100g: (json['protein_per_100g'] as num).toDouble(),
        fatPer100g: (json['fat_per_100g'] as num).toDouble(),
        carbsPer100g: (json['carbs_per_100g'] as num).toDouble(),
        userId: json['user_id']
    );
  }

  Map<String, dynamic> toJson(){
    return{
      'food_name': foodName,
      'category': category,
      'calories_per_100g': caloriesPer100g,
      'protein_per_100g': proteinPer100g,
      'fat_per_100g': fatPer100g,
      'carbs_per_100g': carbsPer100g,
      'user_id': userId
    };
  }

}