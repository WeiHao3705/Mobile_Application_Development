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
}