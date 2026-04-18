class WaterIntake {
  const WaterIntake({
    required this.userId,
    required this.currentAmount,
    required this.targetAmount,
    required this.lastUpdated,
    required this.date,
    this.waterIntakeId,
  });

  final int? waterIntakeId;
  final int userId;
  final double currentAmount;
  final double targetAmount;
  final DateTime? lastUpdated;
  final DateTime? date;

  factory WaterIntake.fromMap(Map<String, dynamic> map) {
    return WaterIntake(
      waterIntakeId: _toNullableInt(
        map['water_intake_id'] ?? map['waterIntakeId'],
      ),
      userId: _toInt(map['user_id'] ?? map['userId']),
      currentAmount:
          _toDouble(map['currentAmount'] ?? map['current_amount']) ?? 0,
      targetAmount: _toDouble(map['targetAmount'] ?? map['target_amount']) ?? 0,
      lastUpdated: _toNullableDateTime(
        map['lastUpdated'] ?? map['last_updated'],
      ),
      date: _toNullableDateTime(map['date']),
    );
  }

  WaterIntake copyWith({
    int? waterIntakeId,
    int? userId,
    double? currentAmount,
    double? targetAmount,
    DateTime? lastUpdated,
    DateTime? date,
  }) {
    return WaterIntake(
      waterIntakeId: waterIntakeId ?? this.waterIntakeId,
      userId: userId ?? this.userId,
      currentAmount: currentAmount ?? this.currentAmount,
      targetAmount: targetAmount ?? this.targetAmount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return <String, dynamic>{
      'user_id': userId,
      'currentAmount': currentAmount,
      'targetAmount': targetAmount,
      'lastUpdated': (lastUpdated ?? DateTime.now()).toIso8601String(),
      'date': _formatDateOnly(date ?? DateTime.now()),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return <String, dynamic>{
      'currentAmount': currentAmount,
      'targetAmount': targetAmount,
      'lastUpdated': (lastUpdated ?? DateTime.now()).toIso8601String(),
      'date': _formatDateOnly(date ?? DateTime.now()),
    };
  }

  double get progressRatio {
    if (targetAmount <= 0) {
      return 0;
    }
    final ratio = currentAmount / targetAmount;
    return ratio.clamp(0.0, 1.0);
  }

  double get progressPercent {
    if (targetAmount <= 0) {
      return 0;
    }
    return (currentAmount / targetAmount) * 100;
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString()) ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static DateTime? _toNullableDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.tryParse(value.toString());
  }

  static String _formatDateOnly(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
