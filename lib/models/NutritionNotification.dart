class NutritionNotification{
  final int notificationId;
  final String title;
  final String message;
  final String status;
  final DateTime createdAt;
  final int userId;

  NutritionNotification({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.userId
  });

  factory NutritionNotification.fromJson(Map<String, dynamic> json){
    return NutritionNotification(
      notificationId: json['notification_id'],
      title: json['title'],
      message: json['message'],
      status: json['status'],
      createdAt: json['created_at'],
      userId: json['user_id']
    );
  }

  Map<String, dynamic> toJson(){
    return{
      'notification_id': notificationId,
      'title': title,
      'message': message,
      'status': status,
      'created_at': createdAt,
      'user_id': userId
    };
  }

}