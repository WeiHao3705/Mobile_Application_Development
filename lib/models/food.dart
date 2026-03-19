class Food {
  final int foodId;
  final String foodName;
  final int caloriesPer100g;
  final int proteinPer100g;
  final int fatPer100g;
  final int carbsPer100g;
  final int userId;

  Food({
    required this.foodId,
    required this.foodName,
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
      caloriesPer100g: json['calories_per_100g'],
      proteinPer100g: json['protein_per_100g'],
      fatPer100g: json['fat_per_100g'],
      carbsPer100g: json['carbs_per_100g'],
      userId: json['user_id']
    );
  }

  Map<String, dynamic> toJson(){
    return{
      'food_id': foodId,
      'food_name': foodName,
      'calories_per_100g': caloriesPer100g,
      'protein_per_100g': proteinPer100g,
      'fat_per_100g': fatPer100g,
      'carbs_per_100g': carbsPer100g,
      'user_id': userId
    };
  }

}