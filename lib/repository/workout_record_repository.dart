import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutRecordDetailInput {
  const WorkoutRecordDetailInput({
    required this.exerciseName,
    required this.orderIndex,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.notes,
  });

  final String exerciseName;
  final int orderIndex;
  final int sets;
  final int reps;
  final int weight;
  final String notes;
}

class WorkoutRecordRepository {
  WorkoutRecordRepository({required this.supabase});

  final SupabaseClient supabase;

  Future<void> createRecordWithDetails({
    required int userId,
    required String title,
    required String? image,
    required DateTime createdAt,
    required int duration,
    required int trainingVolume,
    required int numOfSets,
    required List<WorkoutRecordDetailInput> details,
  }) async {
    final recordId = _generateUuidV4();

    await supabase.from('Exercise_Record').insert(<String, dynamic>{
      'record_id': recordId,
      'user_id': userId,
      'record_title': title,
      'record_image': image,
      'created_at': createdAt.toUtc().toIso8601String(),
      'duration': duration,
      'training_volume': trainingVolume,
      'num_of_sets': numOfSets,
    });

    if (details.isEmpty) {
      return;
    }

    final detailPayload = details
        .map(
          (detail) => <String, dynamic>{
            'detail_id': _generateUuidV4(),
            'record_id': recordId,
            'exercise_name': detail.exerciseName,
            'order_index': detail.orderIndex,
            'sets': detail.sets,
            'reps': detail.reps,
            'weight': detail.weight,
            'notes': detail.notes,
          },
        )
        .toList();

    await supabase.from('Exercise_Record_Details').insert(detailPayload);
  }

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String toHex(int value) => value.toRadixString(16).padLeft(2, '0');

    final hex = bytes.map(toHex).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
