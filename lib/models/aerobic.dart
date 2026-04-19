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
  final String route_image;
  final String userId;
  final bool is_archived;

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
    required this.route_image,
    required this.userId,
    this.is_archived = false,
  });

  factory Aerobic.fromJson(Map<String, dynamic> json) {
    // Parse timestamps directly without timezone conversion
    // Database stores the actual local device time, so use it as-is
    DateTime parseDateTime(String? dateString) {
      if (dateString == null || dateString.isEmpty) return DateTime.now();
      try {
        // Parse directly without any timezone conversion
        // Remove the 'Z' if it exists to treat it as local time
        final cleanedDate = dateString.replaceAll('Z', '');
        final parsedTime = DateTime.parse(cleanedDate);
        print('Parsed time: $parsedTime');
        return parsedTime;
      } catch (e) {
        print('Error parsing date: $dateString - $e');
        return DateTime.now();
      }
    }

    return Aerobic(
      id: json['aerobic_id'] ?? '',
      activity_type: json['activity_type'] ?? 'Unknown',
      location: json['location'] ?? 'Unknown Location',
      total_distance: (json['total_distance'] as num?)?.toDouble() ?? 0.0,
      average_pace: (json['average_pace'] as num?)?.toInt() ?? 0,
      calories_burned: (json['calories_burned'] as num?)?.toInt() ?? 0,
      total_step: (json['total_step'] as num?)?.toInt() ?? 0,
      elevation_gain: (json['elevation_gain'] as num?)?.toInt() ?? 0,
      start_at: parseDateTime(json['start_at']),
      end_at: parseDateTime(json['end_at']),
      moving_time: (json['moving_time'] as num?)?.toInt() ?? 0,
      route_image: json['route_image'] ?? '',
      userId: json['user_id']?.toString() ?? '',
      is_archived: json['is_archived'] as bool? ?? false,
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
    "route_image": route_image,
    "user_id": userId,
    "is_archived": is_archived,
  };

  String get formattedDistance => "${total_distance.toStringAsFixed(2)} km";

  String get formattedDuration {
    int minutes = moving_time ~/ 60;
    int seconds = moving_time % 60;
    return "${minutes}m ${seconds}s";
  }

  String get formattedDate {
    final hour = start_at.hour.toString().padLeft(2, '0');
    final minute = start_at.minute.toString().padLeft(2, '0');
    final second = start_at.second.toString().padLeft(2, '0');
    return "${start_at.day}/${start_at.month}/${start_at.year} At $hour:$minute:$second";
  }
}