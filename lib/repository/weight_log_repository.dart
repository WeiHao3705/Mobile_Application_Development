import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/weight_log.dart';

class WeightLogRepository {
  WeightLogRepository({required this.supabase});

  final SupabaseClient supabase;

  Future<List<WeightLog>> getRecentByUserId(
    int userId, {
    int limit = 30,
  }) async {
    final response = await supabase
        .from('WeightLogs')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: true)
        .limit(limit);

    return response
        .map((row) => WeightLog.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<WeightLog?> getLatestByUserId(int userId) async {
    final response = await supabase
        .from('WeightLogs')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(1);

    if (response.isEmpty) {
      return null;
    }

    return WeightLog.fromMap(Map<String, dynamic>.from(response.first));
  }

  Future<WeightLog> insertLog({
    required int userId,
    required double weight,
    required DateTime date,
  }) async {
    final response = await supabase
        .from('WeightLogs')
        .insert(
          WeightLog(userId: userId, weight: weight, date: date).toInsertMap(),
        )
        .select()
        .single();

    return WeightLog.fromMap(Map<String, dynamic>.from(response));
  }

  Future<void> updateUserCurrentWeight({
    required int userId,
    required double weight,
  }) async {
    await supabase
        .from('User')
        .update({'current_weight': weight})
        .eq('user_id', userId);
  }
}
