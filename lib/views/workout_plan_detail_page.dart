import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/exercise.dart';
import '../models/workout_plan.dart';
import 'exercise_detail_page.dart';
import 'workout_routine_page.dart';

class WorkoutPlanDetailPage extends StatefulWidget {
  const WorkoutPlanDetailPage({super.key, required this.plan});

  final WorkoutPlan plan;

  @override
  State<WorkoutPlanDetailPage> createState() => _WorkoutPlanDetailPageState();
}

class _WorkoutPlanDetailPageState extends State<WorkoutPlanDetailPage> {
  static const List<String> _exerciseIdColumnCandidates = <String>[
    'exercise_id',
    'exerciseId',
    'id_exercise',
  ];

  late final Future<List<_ExercisePlanDetailView>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadDetails();
  }

  Future<List<_ExercisePlanDetailView>> _loadDetails() async {
    final supabase = Supabase.instance.client;

    final detailResponse = await supabase
        .from('Exercise_Plan_Details')
        .select('*')
        .eq('plan_id', widget.plan.planId)
        .order('order_index', ascending: true);

    final detailRows = List<Map<String, dynamic>>.from(detailResponse as List);
    if (detailRows.isEmpty) {
      return const <_ExercisePlanDetailView>[];
    }

    final exerciseIds = detailRows
        .map((row) => _readTextByKeys(row, _exerciseIdColumnCandidates))
        .where((id) => id.isNotEmpty)
        .toSet();

    final exerciseById = <String, Map<String, dynamic>>{};
    if (exerciseIds.isNotEmpty) {
      final exerciseResponse = await supabase
          .from('Exercise')
          .select('*')
          .inFilter('exercise_id', exerciseIds.toList());

      for (final row in List<Map<String, dynamic>>.from(exerciseResponse as List)) {
        final exerciseId = (row['exercise_id'] ?? '').toString().trim();
        if (exerciseId.isNotEmpty) {
          exerciseById[exerciseId] = row;
        }
      }
    }

    return detailRows.map((row) {
      final exerciseId = _readTextByKeys(row, _exerciseIdColumnCandidates);
      final exerciseRow = exerciseById[exerciseId];
      final exerciseName = _readFirstNonEmpty(
        exerciseRow,
        const ['exercise_name', 'name', 'title'],
        fallback: exerciseId,
      );
      final imageUrl = _readFirstNonEmpty(exerciseRow, const ['image', 'image_url', 'thumbnail_url']);
      final equipment = _readFirstNonEmpty(exerciseRow, const ['equipment', 'equipment_name', 'tool']);
      final isBodyweight = _isBodyweightExercise(equipment);

      Exercise? parsedExercise;
      if (exerciseRow != null) {
        try {
          parsedExercise = Exercise.fromJson(exerciseRow);
        } catch (_) {}
      }

      parsedExercise ??= Exercise(
        id: exerciseId,
        name: exerciseName,
        imageUrl: imageUrl,
        equipment: equipment,
        primaryMuscle: '',
        secondaryMuscles: const <String>[],
        howTo: '',
      );

      return _ExercisePlanDetailView(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        imageUrl: imageUrl,
        sets: _toInt(row['sets']),
        reps: _toInt(row['reps']),
        weight: _toNullableDouble(row['weight']),
        isBodyweight: isBodyweight,
        fullExercise: parsedExercise,
      );
    }).toList();
  }

  static String _readTextByKeys(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final text = (row[key] ?? '').toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static String _readFirstNonEmpty(
    Map<String, dynamic>? row,
    List<String> keys, {
    String fallback = '',
  }) {
    if (row == null) {
      return fallback;
    }

    for (final key in keys) {
      final text = (row[key] ?? '').toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }

    return fallback;
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static bool _isBodyweightExercise(String equipment) {
    final normalized = equipment.toLowerCase();
    return normalized.contains('bodyweight') || normalized.contains('body weight');
  }

  static String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'N/A';
    }

    final local = dateTime.toLocal();
    final date =
        '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  void _startPlan() {
    _detailsFuture.then((details) async {
      if (!mounted) {
        return;
      }

      final seeds = details
          .map(
            (detail) => WorkoutRoutineExerciseSeed(
              exercise: Exercise(
                id: detail.exerciseId,
                name: detail.exerciseName,
                primaryMuscle: detail.isBodyweight ? 'Bodyweight' : 'Unknown Muscle',
                equipment: detail.isBodyweight ? 'Bodyweight' : 'Unknown Equipment',
                imageUrl: detail.imageUrl,
                secondaryMuscles: const <String>[],
                howTo: 'No instructions provided.',
              ),
              setCount: detail.sets <= 0 ? 1 : detail.sets,
              repsText: detail.reps.toString(),
              weightText: detail.isBodyweight || detail.weight == null ? '' : detail.weight!.toStringAsFixed(detail.weight! % 1 == 0 ? 0 : 1),
            ),
          )
          .toList();

      final didSave = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => WorkoutRoutinePage(
            userId: widget.plan.userId,
            initialExercises: seeds,
          ),
        ),
      );

      if (didSave == true && mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Plan Details',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: FutureBuilder<List<_ExercisePlanDetailView>>(
          future: _detailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load plan details: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final details = snapshot.data ?? const <_ExercisePlanDetailView>[];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.plan.planName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Created at: ${_formatDateTime(widget.plan.createdAt)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _startPlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Start Plan'),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Exercise',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...details.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ExerciseDetailCard(
                          index: entry.key + 1,
                          detail: entry.value,
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExerciseDetailCard extends StatelessWidget {
  const _ExerciseDetailCard({required this.index, required this.detail});

  final int index;
  final _ExercisePlanDetailView detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showWeightColumn = !detail.isBodyweight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ExerciseDetailPage(exercise: detail.fullExercise),
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage: detail.imageUrl.isNotEmpty ? NetworkImage(detail.imageUrl) : null,
                child: detail.imageUrl.isEmpty
                    ? const Icon(Icons.fitness_center, color: Colors.black, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  detail.exerciseName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const _ColumnHeader(label: 'Set'),
            const SizedBox(width: 24),
            if (showWeightColumn) ...[
              const _ColumnHeader(label: 'KG'),
              const SizedBox(width: 24),
            ],
            const _ColumnHeader(label: 'Reps'),
          ],
        ),
        const SizedBox(height: 8),
        for (var setIndex = 1; setIndex <= detail.sets; setIndex += 1)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: setIndex.isEven ? const Color(0xFF1F1F1F) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    '$setIndex',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (showWeightColumn) ...[
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 64,
                    child: Text(
                      detail.weight == null
                          ? '—'
                          : detail.weight!.toStringAsFixed(detail.weight! % 1 == 0 ? 0 : 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 24),
                Text(
                  detail.reps.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _ExercisePlanDetailView {
  const _ExercisePlanDetailView({
    required this.exerciseId,
    required this.exerciseName,
    required this.imageUrl,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.isBodyweight,
    required this.fullExercise,
  });

  final String exerciseId;
  final String exerciseName;
  final String imageUrl;
  final int sets;
  final int reps;
  final double? weight;
  final bool isBodyweight;
  final Exercise fullExercise;
}