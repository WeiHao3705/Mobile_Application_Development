class MealLog{
  final int mealId;
  final String mealType;
  final DateTime mealDate;
  final int userId;

  MealLog({
    required this.mealId,
    required this.mealType,
    required this.mealDate,
    required this.userId
  });

  factory MealLog.fromJson(Map<String, dynamic> json){
    return MealLog(
      mealId: json['meal_id'],
      mealType: json['meal_type'],
      mealDate: json['meal_date'],
      userId: json['user_id']
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'meal_id': mealId,
      'meal_type': mealType,
      'meal_date': mealDate,
      'user_id': userId
    };
  }

}