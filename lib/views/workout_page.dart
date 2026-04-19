import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/exercise.dart';
import '../models/workout_plan.dart';
import '../repository/workout_plan_repository.dart';
import 'exercise_explore_page.dart';
import 'plan_creation_page.dart';
import 'workout_routine_page.dart';
import 'package:mobile_application_development/views/workout_plan_detail_page.dart';

enum _PlanMenuAction {
  edit,
  duplicate,
  delete,
}

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key, required this.userId});

  final int userId;

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  late final WorkoutPlanRepository _repository;
  late Future<List<WorkoutPlan>> _plansFuture;

  static const List<String> _detailExerciseIdColumnCandidates = <String>[
    'exercise_id',
    'exerciseId',
    'id_exercise',
  ];

  @override
  void initState() {
    super.initState();
    _repository = WorkoutPlanRepository(supabase: Supabase.instance.client);
    _plansFuture = _repository.getPlansForUser(widget.userId);
  }

  void _reloadPlans() {
    setState(() {
      _plansFuture = _repository.getPlansForUser(widget.userId);
    });
  }

  Future<void> _openPlanCreation() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PlanCreationPage(userId: widget.userId),
      ),
    );

    if (created == true) {
      _reloadPlans();
    }
  }

  Future<List<WorkoutRoutineExerciseSeed>> _loadPlanRoutineSeeds(WorkoutPlan plan) async {
    final supabase = Supabase.instance.client;

    final detailResponse = await supabase
        .from('Exercise_Plan_Details')
        .select('*')
        .eq('plan_id', plan.planId)
        .order('order_index', ascending: true);

    final detailRows = List<Map<String, dynamic>>.from(detailResponse as List);
    if (detailRows.isEmpty) {
      return plan.exercises
          .map(
            (exercise) => WorkoutRoutineExerciseSeed(
              exercise: Exercise(
                id: exercise.exerciseId,
                name: exercise.exerciseName,
                primaryMuscle: 'Unknown Muscle',
                equipment: 'Unknown Equipment',
                imageUrl: '',
                secondaryMuscles: const <String>[],
                howTo: 'No instructions provided.',
              ),
            ),
          )
          .toList();
    }

    final exerciseIds = detailRows
        .map((row) => _readTextByKeys(row, _detailExerciseIdColumnCandidates))
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
      final exerciseId = _readTextByKeys(row, _detailExerciseIdColumnCandidates);
      final exerciseRow = exerciseById[exerciseId];
      final exerciseName = _readFirstNonEmpty(
        exerciseRow,
        const ['exercise_name', 'name', 'title'],
        fallback: exerciseId,
      );
      final equipment = _readFirstNonEmpty(
        exerciseRow,
        const ['equipment', 'equipment_name', 'tool'],
      );
      final imageUrl = _readFirstNonEmpty(exerciseRow, const ['image', 'image_url', 'thumbnail_url']);
      final isBodyweight = _isBodyweightExercise(equipment);
      final sets = _toInt(row['sets']);
      final reps = _toInt(row['reps']);
      final weightValue = _toNullableDouble(row['weight']);

      return WorkoutRoutineExerciseSeed(
        exercise: Exercise(
          id: exerciseId,
          name: exerciseName,
          primaryMuscle: isBodyweight ? 'Bodyweight' : 'Unknown Muscle',
          equipment: isBodyweight ? 'Bodyweight' : (equipment.isEmpty ? 'Unknown Equipment' : equipment),
          imageUrl: imageUrl,
          secondaryMuscles: const <String>[],
          howTo: 'No instructions provided.',
        ),
        setCount: sets <= 0 ? 1 : sets,
        repsText: reps <= 0 ? '12' : reps.toString(),
        weightText: isBodyweight || weightValue == null
            ? ''
            : weightValue.toStringAsFixed(weightValue % 1 == 0 ? 0 : 1),
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

  Future<void> _startPlan(WorkoutPlan plan) async {
    final seeds = await _loadPlanRoutineSeeds(plan);
    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutRoutinePage(
          userId: plan.userId,
          initialExercises: seeds,
        ),
      ),
    );
  }

  Future<void> _editPlan(WorkoutPlan plan) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PlanCreationPage(
          userId: widget.userId,
          editingPlanId: plan.planId,
          initialPlanName: plan.planName,
          initialExerciseIds: plan.exercises
              .map((exercise) => exercise.exerciseId)
              .toSet(),
        ),
      ),
    );

    if (updated == true) {
      _reloadPlans();
    }
  }

  Future<void> _duplicatePlan(WorkoutPlan plan) async {
    try {
      await _repository.duplicatePlan(
        userId: widget.userId,
        sourcePlanId: plan.planId,
      );
      _reloadPlans();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to duplicate plan: $error')),
      );
    }
  }

  Future<void> _deletePlan(WorkoutPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text('Delete Plan', style: TextStyle(color: Colors.white)),
          content: Text(
            'Delete "${plan.planName}"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _repository.deletePlan(plan.planId);
      _reloadPlans();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete plan: $error')),
      );
    }
  }

  Future<void> _onPlanActionSelected(
    _PlanMenuAction action,
    WorkoutPlan plan,
  ) async {
    switch (action) {
      case _PlanMenuAction.edit:
        await _editPlan(plan);
        break;
      case _PlanMenuAction.duplicate:
        await _duplicatePlan(plan);
        break;
      case _PlanMenuAction.delete:
        await _deletePlan(plan);
        break;
    }
  }

  void _openPlanDetails(WorkoutPlan plan) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutPlanDetailPage(plan: plan),
      ),
    );
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
          'Workout',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Start',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _QuickActionTile(
              icon: Icons.add,
              title: 'Start Empty Workout',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WorkoutRoutinePage(userId: widget.userId),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              'Plans',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionTile(
                    icon: Icons.note_alt_outlined,
                    title: 'New Plan',
                    onTap: _openPlanCreation,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionTile(
                    icon: Icons.search,
                    title: 'Explore',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ExerciseExplorePage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            FutureBuilder<List<WorkoutPlan>>(
              future: _plansFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Failed to load plans: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final plans = snapshot.data ?? const <WorkoutPlan>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Plans (${plans.length})',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (plans.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.fitness_center_outlined,
                              size: 42,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No plans yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Create your first workout plan.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...plans.map(
                        (plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PlanCard(
                            plan: plan,
                            onTap: () => _openPlanDetails(plan),
                            onStart: () => _startPlan(plan),
                            onMenuActionSelected: (action) =>
                                _onPlanActionSelected(action, plan),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onTap,
    required this.onStart,
    required this.onMenuActionSelected,
  });

  final WorkoutPlan plan;
  final VoidCallback onTap;
  final Future<void> Function() onStart;
  final ValueChanged<_PlanMenuAction> onMenuActionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exerciseNames = plan.exercises.map((item) => item.exerciseName).toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.planName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  PopupMenuButton<_PlanMenuAction>(
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                    color: const Color(0xFF1A1A1A),
                    onSelected: onMenuActionSelected,
                    itemBuilder: (context) => const [
                      PopupMenuItem<_PlanMenuAction>(
                        value: _PlanMenuAction.edit,
                        child: Text('Edit'),
                      ),
                      PopupMenuItem<_PlanMenuAction>(
                        value: _PlanMenuAction.duplicate,
                        child: Text('Duplicate'),
                      ),
                      PopupMenuItem<_PlanMenuAction>(
                        value: _PlanMenuAction.delete,
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                exerciseNames.isEmpty ? 'No exercises added' : exerciseNames.join(' • '),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onStart();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text('Start Plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

