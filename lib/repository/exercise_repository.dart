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
    required List<String> secondaryMuscles,
    required String equipment,
    String? instruction,
    String? imageUrl,
    String? videoUrl,
  }) async {
    // Generate a simple unique ID for the required `exercise_id` column
    final exerciseId = 'EX${DateTime.now().millisecondsSinceEpoch}';

    final payload = <String, dynamic>{
      // DB column: exercise_id (text, NOT NULL)
      'exercise_id': exerciseId,
      // DB column: exercise_name (varchar)
      'exercise_name': name,
      // DB column: primary_muscle (varchar)
      'primary_muscle': primaryMuscle,
      // DB column: secondary_muscle (varchar[])
      'secondary_muscle': secondaryMuscles.isNotEmpty ? secondaryMuscles : null,
      // DB column: equipment (varchar)
      'equipment': equipment,
    };

    if ((instruction ?? '').trim().isNotEmpty) {
      payload['instruction'] = instruction!.trim();
    }
    if ((imageUrl ?? '').trim().isNotEmpty) {
      payload['image'] = imageUrl!.trim();
    }
    if ((videoUrl ?? '').trim().isNotEmpty) {
      payload['video'] = videoUrl!.trim();
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

  Future<Exercise> updateExercise({
    required String exerciseId,
    required String name,
    required String primaryMuscle,
    required List<String> secondaryMuscles,
    required String equipment,
    required String howTo,
    required String imageUrl,
    String? videoUrl,
  }) async {
    final payload = <String, dynamic>{
      'exercise_name': name.trim(),
      'primary_muscle': primaryMuscle.trim(),
      'secondary_muscle': secondaryMuscles.isEmpty ? null : secondaryMuscles,
      'equipment': equipment.trim(),
      'instruction': howTo.trim(),
      'image': imageUrl.trim(),
      'video': (videoUrl ?? '').trim().isEmpty ? null : videoUrl!.trim(),
    };

    try {
      final response = await supabase
          .from('Exercise')
          .update(payload)
          .eq('id', exerciseId)
          .select()
          .single();
      return Exercise.fromJson(Map<String, dynamic>.from(response));
    } on PostgrestException catch (error) {
      if (!_isMissingColumn(error, 'id')) {
        rethrow;
      }

      final response = await supabase
          .from('Exercise')
          .update(payload)
          .eq('exercise_id', exerciseId)
          .select()
          .single();
      return Exercise.fromJson(Map<String, dynamic>.from(response));
    }
  }

  bool _isMissingColumn(PostgrestException error, String columnName) {
    final message = error.message.toLowerCase();
    return message.contains(columnName.toLowerCase()) &&
        (message.contains('schema cache') || message.contains('column'));
  }
}