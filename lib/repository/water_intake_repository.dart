import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/water_intake.dart';

class WaterIntakeRepository {
  WaterIntakeRepository({required this.supabase});

  final SupabaseClient supabase;

  Future<WaterIntake?> getByUserId(int userId, {DateTime? day}) {
    return getByUserIdAndDate(userId, day ?? DateTime.now());
  }

  Future<WaterIntake?> getByUserIdAndDate(int userId, DateTime day) async {
    final response = await supabase
        .from('WaterIntake')
        .select()
        .eq('user_id', userId)
        .eq('date', _formatDate(day))
        .order('lastUpdated', ascending: false)
        .limit(1);

    if (response.isEmpty) {
      return null;
    }

    return WaterIntake.fromMap(Map<String, dynamic>.from(response.first));
  }

  Future<WaterIntake> getOrCreateByUserIdAndDate({
    required int userId,
    required DateTime day,
    required double defaultTargetAmount,
    String? userGender,
  }) async {
    final existing = await getByUserIdAndDate(userId, day);
    if (existing != null) {
      return existing;
    }

    // Fixed daily target by gender:
    // Female: 2.7L (2700ml), Male: 3.7L (3700ml)
    final targetAmount = _calculateHydrationTarget(userGender);

    return createForUser(
      userId: userId,
      targetAmount: targetAmount,
      day: day,
    );
  }

  double _calculateHydrationTarget(String? gender) {
    final normalizedGender = gender?.trim().toLowerCase() ?? 'male';
    if (normalizedGender == 'female' || normalizedGender == 'f') {
      return 2700;
    }
    return 3700;
  }

  Future<List<WaterIntake>> getHistoryByUserId(
    int userId, {
    int limit = 90,
  }) async {
    final response = await supabase
        .from('WaterIntake')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .order('lastUpdated', ascending: false)
        .limit(limit);

    return response
        .map((row) => WaterIntake.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<WaterIntake> createForUser({
    required int userId,
    required double targetAmount,
    DateTime? day,
  }) async {
    final targetDay = day ?? DateTime.now();
    final response = await supabase
        .from('WaterIntake')
        .insert(
          WaterIntake(
            userId: userId,
            currentAmount: 0,
            targetAmount: targetAmount,
            lastUpdated: DateTime.now(),
            date: targetDay,
          ).toInsertMap(),
        )
        .select()
        .single();

    return WaterIntake.fromMap(Map<String, dynamic>.from(response));
  }

  Future<WaterIntake> save(WaterIntake waterIntake) async {
    if (waterIntake.waterIntakeId == null) {
      final response = await supabase
          .from('WaterIntake')
          .insert(waterIntake.toInsertMap())
          .select()
          .single();

      return WaterIntake.fromMap(Map<String, dynamic>.from(response));
    }

    final response = await supabase
        .from('WaterIntake')
        .update(waterIntake.toUpdateMap())
        .eq('water_intake_id', waterIntake.waterIntakeId as Object)
        .select()
        .single();

    return WaterIntake.fromMap(Map<String, dynamic>.from(response));
  }

  String _formatDate(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
