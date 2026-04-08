import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/exercise.dart';

class ExerciseRepository {
  ExerciseRepository({required this.supabase});

  final SupabaseClient supabase;

  Future<List<Exercise>> getAllExercises() async {
    final response = await supabase.from('Exercise').select();

    return (response as List)
        .map((item) => Exercise.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Exercise> createExercise({
    required String name,
    required String primaryMuscle,
    required String muscleGroup,
    required String equipment,
    required String howTo,
    String? imageUrl,
    String? secondaryMuscle,
    String? videoUrl,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'primary_muscle': primaryMuscle,
      'muscle_group': muscleGroup,
      'equipment': equipment,
      'instruction': howTo,
    };

    if ((imageUrl ?? '').trim().isNotEmpty) {
      payload['image_url'] = imageUrl!.trim();
    }
    if ((secondaryMuscle ?? '').trim().isNotEmpty) {
      payload['secondary_muscle'] = secondaryMuscle!.trim();
    }
    if ((videoUrl ?? '').trim().isNotEmpty) {
      payload['video_url'] = videoUrl!.trim();
    }

    final response = await supabase.from('Exercise').insert(payload).select().single();
    return Exercise.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> deleteExercise(String exerciseId) async {
    try {
      await supabase.from('Exercise').delete().eq('id', exerciseId);
    } on PostgrestException catch (error) {
      if (_isMissingColumn(error, 'id')) {
        await supabase.from('Exercise').delete().eq('exercise_id', exerciseId);
        return;
      }
      rethrow;
    }
  }

  bool _isMissingColumn(PostgrestException error, String columnName) {
    final message = error.message.toLowerCase();
    return message.contains(columnName.toLowerCase()) &&
        (message.contains('schema cache') || message.contains('column'));
  }
}