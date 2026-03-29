import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/exercise.dart';

class ExerciseRepository {
  ExerciseRepository({required this.supabase});

  final SupabaseClient supabase;

  Future<List<Exercise>> getAllExercises() async {
    // Supabase table names are case-sensitive when quoted in Postgres.
    final response = await supabase.from('Exercise').select();

    return (response as List)
        .map((item) => Exercise.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
