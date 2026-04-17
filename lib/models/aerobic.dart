class Aerobic {

  final String id;
  final String activity_type;
  final String location;
  final double total_distance;
  final int average_pace;
  final int calories_burned;
  final int total_step;
  final int elevation_gain;
  final DateTime start_at;
  final DateTime end_at;
  final int moving_time;
  final String footwear;
  final String route_image;
  final String userId;

  const Aerobic({
    required this.id,
    required this.activity_type,
    required this.location,
    required this.total_distance,
    required this.average_pace,
    required this.calories_burned,
    required this.total_step,
    required this.elevation_gain,
    required this.start_at,
    required this.end_at,
    required this.moving_time,
    required this.footwear,
    required this.route_image,
    required this.userId,
  });

  factory Aerobic.fromJson(Map<String, dynamic> json) {
    return Aerobic(
      id: json['aerobic_id'] ?? '',
      activity_type: json['activity_type'] ?? 'Unknown',
      location: json['location'] ?? 'Unknown Location',
      total_distance: (json['total_distance'] as num?)?.toDouble() ?? 0.0,
      average_pace: (json['average_pace'] as num?)?.toInt() ?? 0,
      calories_burned: (json['calories_burned'] as num?)?.toInt() ?? 0,
      total_step: (json['total_step'] as num?)?.toInt() ?? 0,
      elevation_gain: (json['elevation_gain'] as num?)?.toInt() ?? 0,
      start_at: json['start_at'] != null ? DateTime.parse(json['start_at']).toLocal() : DateTime.now(),
      end_at: json['end_at'] != null ? DateTime.parse(json['end_at']).toLocal() : DateTime.now(),
      moving_time: (json['moving_time'] as num?)?.toInt() ?? 0,
      footwear: json['footwear'] ?? 'None',
      route_image: json['route_image'] ?? '',
      userId: json['user_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "activity_type": activity_type,
    "location": location,
    "total_distance": total_distance,
    "average_pace": average_pace,
    "calories_burned": calories_burned,
    "total_step": total_step,
    "elevation_gain": elevation_gain,
    "start_at": start_at.toIso8601String(),
    "end_at": end_at.toIso8601String(),
    "moving_time": moving_time,
    "footwear": footwear,
    "route_image": route_image,
    "user_id": userId,
  };

  String get formattedDistance => "${total_distance.toStringAsFixed(2)} km";

  String get formattedDuration {
    int minutes = moving_time ~/ 60;
    int seconds = moving_time % 60;
    return "${minutes}m ${seconds}s";
  }

  String get formattedDate {
    return "${start_at.day}/${start_at.month}/${start_at.year} At ${start_at.hour.toString().padLeft(2, '0')}:${start_at.minute.toString().padLeft(2, '0')}";
  }
}