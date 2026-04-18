class WeightLog {
  const WeightLog({
    this.weightLogId,
    required this.userId,
    required this.weight,
    required this.date,
  });

  final int? weightLogId;
  final int userId;
  final double weight;
  final DateTime date;

  factory WeightLog.fromMap(Map<String, dynamic> map) {
    return WeightLog(
      weightLogId: _toNullableInt(map['weight_log_id'] ?? map['weightLogId']),
      userId: _toInt(map['user_id'] ?? map['userId']),
      weight: _toDouble(map['weight']) ?? 0,
      date: _toDate(map['date']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return <String, dynamic>{
      'user_id': userId,
      'weight': weight,
      'date': _formatDateOnly(date),
    };
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

  static DateTime? _toDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) {
      return null;
    }
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String _formatDateOnly(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
