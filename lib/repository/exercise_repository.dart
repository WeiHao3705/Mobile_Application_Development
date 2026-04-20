import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/exercise.dart';
import '../services/local_cache_service.dart';

class ExerciseRepository {
  ExerciseRepository({required this.supabase});

  final SupabaseClient supabase;
  final LocalCacheService _cacheService = LocalCacheService();

  Future<List<Exercise>> getAllExercises() async {
    try {
      final response = await supabase.from('Exercise').select();
      final exercises = <Exercise>[];

      for (final item in response as List) {
        try {
          exercises.add(
            Exercise.fromJson(Map<String, dynamic>.from(item as Map)),
          );
        } catch (error) {
          print('[EXERCISE-REPO] Skipping malformed exercise row: $error');
        }
      }

      if (exercises.isNotEmpty) {
        await _cacheService.saveExerciseListCache(exercises);
      }

      return exercises;
    } on SocketException {
      final cached = await _cacheService.getExerciseListCache();
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    } catch (_) {
      final cached = await _cacheService.getExerciseListCache();
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
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

    final response = await supabase
        .from('Exercise')
        .insert(payload)
        .select()
        .single();
    await _cacheService.clearExerciseListCache();
    return Exercise.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> deleteExercise(String exerciseId) async {
    try {
      await supabase.from('Exercise').delete().eq('id', exerciseId);
      await _cacheService.clearExerciseListCache();
      await _cacheService.clearExerciseMediaCacheForExercise(exerciseId);
    } on PostgrestException catch (error) {
      if (_isMissingColumn(error, 'id')) {
        await supabase.from('Exercise').delete().eq('exercise_id', exerciseId);
        await _cacheService.clearExerciseListCache();
        await _cacheService.clearExerciseMediaCacheForExercise(exerciseId);
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
      await _cacheService.clearExerciseListCache();
      await _cacheService.clearExerciseMediaCacheForExercise(exerciseId);
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
      await _cacheService.clearExerciseListCache();
      await _cacheService.clearExerciseMediaCacheForExercise(exerciseId);
      return Exercise.fromJson(Map<String, dynamic>.from(response));
    }
  }

  bool _isMissingColumn(PostgrestException error, String columnName) {
    final message = error.message.toLowerCase();
    return message.contains(columnName.toLowerCase()) &&
        (message.contains('schema cache') || message.contains('column'));
  }
}
