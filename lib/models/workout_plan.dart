class WorkoutPlan {
  const WorkoutPlan({
    required this.planId,
    required this.planName,
    required this.exercises,
    this.description,
    this.createdAt,
  });

  final String planId;
  final String planName;
  final String? description;
  final DateTime? createdAt;
  final List<WorkoutPlanExercise> exercises;
}

class WorkoutPlanExercise {
  const WorkoutPlanExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.orderIndex,
  });

  final String exerciseId;
  final String exerciseName;
  final int orderIndex;
}

class WorkoutPlanDetailInput {
  const WorkoutPlanDetailInput({
    required this.exerciseId,
    required this.orderIndex,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.weight,
    this.notes,
  });

  final String exerciseId;
  final int orderIndex;
  final int sets;
  final int reps;
  final int restSeconds;
  final double? weight;
  final String? notes;

  Map<String, dynamic> toInsertMap(
    String planId, {
    required int userId,
    String exerciseIdColumn = 'exercise_id',
  }) {
    return <String, dynamic>{
      'plan_id': planId,
      'user_id': userId,
      exerciseIdColumn: exerciseId,
      'order_index': orderIndex,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'rest_seconds': restSeconds,
      'notes': notes,
    };
  }
}
