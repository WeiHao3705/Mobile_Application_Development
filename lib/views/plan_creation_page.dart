import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/exercise.dart';
import '../models/workout_plan.dart';
import '../repository/exercise_repository.dart';
import '../repository/workout_plan_repository.dart';
import 'exercise_explore_page.dart';
import 'exercise_reorder_page.dart';

enum _ExerciseMenuAction {
  rearrange,
  change,
  delete,
}

class PlanCreationPage extends StatefulWidget {
  const PlanCreationPage({
    super.key,
    required this.userId,
    this.editingPlanId,
    this.initialPlanName,
    this.initialExerciseIds = const <String>{},
  });

  final int userId;
  final String? editingPlanId;
  final String? initialPlanName;
  final Set<String> initialExerciseIds;

  bool get isEditMode => editingPlanId != null;

  @override
  State<PlanCreationPage> createState() => _PlanCreationPageState();
}

class _PlanCreationPageState extends State<PlanCreationPage> {
  static const List<String> _detailExerciseIdColumnCandidates = <String>[
    'exercise_id',
    'exerciseId',
    'id_exercise',
  ];

  final TextEditingController _planNameController = TextEditingController();
  final List<Exercise> _selectedExercises = <Exercise>[];
  final Map<int, _ExerciseInputDraft> _exerciseDrafts =
      <int, _ExerciseInputDraft>{};
  final Map<String, Map<String, dynamic>> _existingDetailRowsByExerciseId =
      <String, Map<String, dynamic>>{};
  late final WorkoutPlanRepository _workoutPlanRepository;
  late final ExerciseRepository _exerciseRepository;
  bool _isSaving = false;
  bool _isInitializing = false;
  int _setRowCounter = 0;

  String _nextSetRowId() {
    final seconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _setRowCounter += 1;
    return '${seconds}_$_setRowCounter';
  }

  @override
  void initState() {
    super.initState();
    _workoutPlanRepository =
        WorkoutPlanRepository(supabase: Supabase.instance.client);
    _exerciseRepository = ExerciseRepository(supabase: Supabase.instance.client);

    if ((widget.initialPlanName ?? '').trim().isNotEmpty) {
      _planNameController.text = widget.initialPlanName!.trim();
    }

    if (widget.isEditMode || widget.initialExerciseIds.isNotEmpty) {
      _initializeFromExistingPlan();
    }
  }

  Future<void> _initializeFromExistingPlan() async {
    setState(() => _isInitializing = true);

    try {
      final exercises = await _exerciseRepository.getAllExercises();
      final exerciseById = {
        for (final exercise in exercises) exercise.id: exercise,
      };

      final detailRows = <Map<String, dynamic>>[];
      if (widget.isEditMode) {
        final detailsResponse = await Supabase.instance.client
            .from('Exercise_Plan_Details')
            .select('*')
            .eq('plan_id', widget.editingPlanId!)
            .order('order_index', ascending: true);

        detailRows.addAll(List<Map<String, dynamic>>.from(detailsResponse as List));
      }

      final selectedExerciseIds = <String>{...widget.initialExerciseIds};
      if (detailRows.isNotEmpty) {
        for (final row in detailRows) {
          final exerciseId = _readTextByKeys(row, _detailExerciseIdColumnCandidates);
          if (exerciseId.isNotEmpty) {
            selectedExerciseIds.add(exerciseId);
            _existingDetailRowsByExerciseId[exerciseId] = row;
          }
        }
      }

      final selectedExercises = <Exercise>[];
      if (detailRows.isNotEmpty) {
        for (final row in detailRows) {
          final exerciseId = _readTextByKeys(row, _detailExerciseIdColumnCandidates);
          final exercise = exerciseById[exerciseId];
          if (exercise != null) {
            selectedExercises.add(exercise);
          }
        }
      } else {
        selectedExercises.addAll(
          exercises.where((exercise) => selectedExerciseIds.contains(exercise.id)),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedExercises
          ..clear()
          ..addAll(selectedExercises);
        _syncExerciseDrafts(_selectedExercises);
        _hydrateDraftsFromDetails();
      });
    } catch (_) {
      // Keep edit page usable even when initial hydrate fails.
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  void _hydrateDraftsFromDetails() {
    for (final entry in _existingDetailRowsByExerciseId.entries) {
      final draft = _exerciseDrafts[entry.key];
      if (draft == null) {
        continue;
      }

      final row = entry.value;
      draft.rebuildFromExisting(
        setCount: _toInt(row['sets']),
        repsText: _toInt(row['reps']).toString(),
        weightText: _toNullableDouble(row['weight'])?.toString(),
        restDuration: Duration(seconds: _toInt(row['rest_seconds'])),
        notesText: _nullableText(row['notes']) ?? '',
      );
    }
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  double? _toNullableDouble(dynamic value) {
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

  String? _nullableText(dynamic value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  String _readTextByKeys(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final text = (row[key] ?? '').toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  @override
  void dispose() {
    _planNameController.dispose();
    for (final draft in _exerciseDrafts.values) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _chooseExercises() async {
    final selectedExercises = await Navigator.of(context).push<List<Exercise>>(
      MaterialPageRoute<List<Exercise>>(
        builder: (_) => ExerciseExplorePage(
          selectable: true,
          initialSelectedExerciseIds: _selectedExercises
              .map((exercise) => exercise.id)
              .toSet(),
        ),
      ),
    );

    if (selectedExercises != null) {
      setState(() {
        _selectedExercises
          ..clear()
          ..addAll(selectedExercises);
        _syncExerciseDrafts(_selectedExercises);
      });
    }
  }

  bool _isBodyweightExercise(Exercise exercise) {
    final equipment = exercise.equipment.toLowerCase();
    return equipment.contains('bodyweight') || equipment.contains('body weight');
  }

  void _addSetRow(String exerciseId) {
    final draft = _exerciseDrafts[exerciseId];
    if (draft == null) {
      return;
    }

    final templateRow = draft.setRows.isNotEmpty ? draft.setRows.first : null;
    setState(
      () => draft.addSetRow(
        _nextSetRowId(),
        repsText: templateRow?.repsController.text.trim(),
        weightText: templateRow?.weightController.text.trim(),
      ),
    );
  }

  void _removeSetRow(String exerciseId, String rowId) {
    final draft = _exerciseDrafts[exerciseId];
    if (draft == null) {
      return;
    }

    if (draft.setRows.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one set is required.')),
      );
      return;
    }

    setState(() => draft.removeSetRow(rowId));
  }

  Future<void> _rearrangeExercises() async {
    if (_selectedExercises.length < 2) {
      return;
    }

    final rowIdsByIndex = List<String>.generate(
      _selectedExercises.length,
      (index) => 'row_$index',
    );
    final draftByRowId = <String, _ExerciseInputDraft>{
      for (var index = 0; index < _selectedExercises.length; index += 1)
        rowIdsByIndex[index]: _exerciseDrafts[index]!,
    };

    final reorderedEntries = await Navigator.of(context).push<List<ExerciseReorderResult>>(
      MaterialPageRoute<List<ExerciseReorderResult>>(
        builder: (_) => ExerciseReorderPage(
          entries: List<ExerciseReorderResult>.generate(
            _selectedExercises.length,
            (index) => ExerciseReorderResult(
              rowId: rowIdsByIndex[index],
              exercise: _selectedExercises[index],
            ),
          ),
        ),
      ),
    );

    if (reorderedEntries == null) {
      return;
    }

    setState(() {
      _selectedExercises
        ..clear()
        ..addAll(reorderedEntries.map((entry) => entry.exercise));

      final updatedDrafts = <int, _ExerciseInputDraft>{};
      final usedRowIds = <String>{};

      for (var index = 0; index < reorderedEntries.length; index += 1) {
        final rowId = reorderedEntries[index].rowId;
        final draft = draftByRowId[rowId];
        if (draft == null) {
          continue;
        }
        usedRowIds.add(rowId);
        updatedDrafts[index] = draft;
      }

      for (final entry in draftByRowId.entries) {
        if (!usedRowIds.contains(entry.key)) {
          entry.value.dispose();
        }
      }

      _exerciseDrafts
        ..clear()
        ..addAll(updatedDrafts);
    });
  }

  int _findMatchingExerciseIndex(
    List<Exercise> previousExercises,
    Exercise exercise,
    Set<int> usedIndices,
  ) {
    for (var index = 0; index < previousExercises.length; index += 1) {
      if (usedIndices.contains(index)) {
        continue;
      }

      final previousExercise = previousExercises[index];
      if (identical(previousExercise, exercise) || previousExercise.id == exercise.id) {
        return index;
      }
    }

    return -1;
  }

  void _deleteExerciseAt(int index) {
    if (index < 0 || index >= _selectedExercises.length) {
      return;
    }

    _exerciseDrafts[index]?.dispose();
    _exerciseDrafts.remove(index);
    _selectedExercises.removeAt(index);

    // Re-index the remaining drafts
    final updatedDrafts = <int, _ExerciseInputDraft>{};
    for (var i = 0; i < _selectedExercises.length; i++) {
      if (_exerciseDrafts.containsKey(i + 1)) {
        updatedDrafts[i] = _exerciseDrafts[i + 1]!;
      }
    }
    _exerciseDrafts
      ..clear()
      ..addAll(updatedDrafts);

    setState(() {});
  }

  Future<void> _changeExerciseAt(int index) async {
    if (index < 0 || index >= _selectedExercises.length) {
      return;
    }

    final currentExercise = _selectedExercises[index];
    final selectedExercises = await Navigator.of(context).push<List<Exercise>>(
      MaterialPageRoute<List<Exercise>>(
        builder: (_) => ExerciseExplorePage(
          selectable: true,
          singleSelection: true,
          initialSelectedExerciseIds: {currentExercise.id},
        ),
      ),
    );

    if (selectedExercises == null || selectedExercises.isEmpty) {
      return;
    }

    final nextExercise = selectedExercises.first;
    if (nextExercise.id == currentExercise.id) {
      return;
    }

    setState(() {
      _selectedExercises[index] = nextExercise;
      _syncExerciseDrafts(_selectedExercises);
    });
  }

  void _syncExerciseDrafts(List<Exercise> selectedExercises) {
    _exerciseDrafts.clear();
    for (final draft in _exerciseDrafts.values) {
      draft.dispose();
    }

    for (var index = 0; index < selectedExercises.length; index += 1) {
      final exercise = selectedExercises[index];
      final detailRow = _existingDetailRowsByExerciseId[exercise.id];
      _exerciseDrafts[index] = _ExerciseInputDraft(
        firstRowId: _nextSetRowId(),
        initialSetCount: detailRow == null ? 1 : _toInt(detailRow['sets']),
        initialReps: detailRow == null ? 12 : _toInt(detailRow['reps']),
        initialWeight: detailRow == null ? null : _toNullableDouble(detailRow['weight']),
        initialRestDuration: detailRow == null
            ? const Duration(seconds: 60)
            : Duration(seconds: _toInt(detailRow['rest_seconds'])),
        initialNotes: detailRow == null ? '' : _nullableText(detailRow['notes']) ?? '',
      );
    }
  }

  Future<void> _savePlan() async {
    if (_isSaving || _isInitializing) {
      return;
    }

    final planName = _planNameController.text.trim();

    if (planName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plan name.')),
      );
      return;
    }

    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose at least one exercise.')),
      );
      return;
    }

    final payload = _selectedExercises.asMap().entries.map((entry) {
      final index = entry.key;
      final exercise = entry.value;
      final draft = _exerciseDrafts[index]!;
      final isBodyweight = _isBodyweightExercise(exercise);

      final setRows = draft.setRows.asMap().entries.map((setEntry) {
        final setDraft = setEntry.value;
        return <String, dynamic>{
          'reps': int.tryParse(setDraft.repsController.text.trim()) ?? 0,
          'weight': isBodyweight
              ? null
              : double.tryParse(setDraft.weightController.text.trim()),
        };
      }).toList();

      return WorkoutPlanDetailInput(
        exerciseId: exercise.id,
        orderIndex: index,
        sets: setRows.length,
        reps: setRows.isEmpty ? 0 : (setRows.first['reps'] as int? ?? 0),
        weight: setRows.isEmpty ? null : setRows.first['weight'] as double?,
        restSeconds: draft.restDuration.inSeconds,
        notes: draft.notesController.text.trim(),
      );
    }).toList();

    setState(() => _isSaving = true);

    try {
      if (widget.isEditMode) {
        await _workoutPlanRepository.updatePlanWithDetails(
          planId: widget.editingPlanId!,
          userId: widget.userId,
          planName: planName,
          details: payload,
        );
      } else {
        await _workoutPlanRepository.createPlanWithDetails(
          userId: widget.userId,
          planName: planName,
          details: payload,
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save plan: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickRestTime(String exerciseId) async {
    final draft = _exerciseDrafts[exerciseId];
    if (draft == null) {
      return;
    }

    final picked = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      builder: (context) {
        var currentDuration = draft.restDuration;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const Text(
                        'Select rest time',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(currentDuration),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 220,
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.ms,
                    initialTimerDuration: currentDuration,
                    backgroundColor: const Color(0xFF111111),
                    onTimerDurationChanged: (duration) {
                      currentDuration = duration;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null) {
      return;
    }

    setState(() {
      draft.setRestDuration(picked);
    });
  }

  static String _formatRestDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        title: Text(widget.isEditMode ? 'Edit Plan' : 'Create Plan'),
        actions: [
          TextButton(
            onPressed: (_isSaving || _isInitializing) ? null : _savePlan,
            child: Text(
              _isSaving ? 'Saving...' : 'Save',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan Name',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _planNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter plan name',
                  hintStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF111111),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _chooseExercises,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Choose Exercises'),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Selected Exercises (${_selectedExercises.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _isInitializing
                    ? Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : _selectedExercises.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'No exercise selected yet.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        padding: EdgeInsets.zero,
                        itemCount: _selectedExercises.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = _selectedExercises.removeAt(oldIndex);
                            _selectedExercises.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final exercise = _selectedExercises[index];
                          final draft = _exerciseDrafts[index]!;

                          return Padding(
                            // Use per-entry identity so duplicate exercise IDs can coexist.
                            key: ObjectKey(draft),
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ExerciseEditorCard(
                              exercise: exercise,
                              draft: draft,
                              orderIndex: index + 1,
                              listIndex: index,
                              totalExercises: _selectedExercises.length,
                              isBodyweight: _isBodyweightExercise(exercise),
                              onAddSet: () => _addSetRow(exercise.id),
                              onRearrange: _rearrangeExercises,
                              onChangeExercise: () => _changeExerciseAt(index),
                              onDeleteExercise: () => _deleteExerciseAt(index),
                              onPickRestTime: () => _pickRestTime(exercise.id),
                              onRemoveSet: (rowId) => _removeSetRow(exercise.id, rowId),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseEditorCard extends StatelessWidget {
  const _ExerciseEditorCard({
    required this.exercise,
    required this.draft,
    required this.orderIndex,
    required this.listIndex,
    required this.totalExercises,
    required this.isBodyweight,
    required this.onAddSet,
    required this.onRearrange,
    required this.onChangeExercise,
    required this.onDeleteExercise,
    required this.onPickRestTime,
    required this.onRemoveSet,
  });

  final Exercise exercise;
  final _ExerciseInputDraft draft;
  final int orderIndex;
  final int listIndex;
  final int totalExercises;
  final bool isBodyweight;
  final VoidCallback onAddSet;
  final VoidCallback onRearrange;
  final VoidCallback onChangeExercise;
  final VoidCallback onDeleteExercise;
  final VoidCallback onPickRestTime;
  final ValueChanged<String> onRemoveSet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canRemoveSet = draft.setRows.length > 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage:
                    exercise.imageUrl.isNotEmpty ? NetworkImage(exercise.imageUrl) : null,
                child: exercise.imageUrl.isEmpty
                    ? const Icon(Icons.fitness_center, color: Colors.black, size: 18)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$orderIndex. ${exercise.name}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PopupMenuButton<_ExerciseMenuAction>(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                color: const Color(0xFF1A1A1A),
                onSelected: (action) {
                  switch (action) {
                    case _ExerciseMenuAction.rearrange:
                      onRearrange();
                      break;
                    case _ExerciseMenuAction.change:
                      onChangeExercise();
                      break;
                    case _ExerciseMenuAction.delete:
                      onDeleteExercise();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<_ExerciseMenuAction>(
                    value: _ExerciseMenuAction.rearrange,
                    child: Text('Rearrange exercises'),
                  ),
                  PopupMenuItem<_ExerciseMenuAction>(
                    value: _ExerciseMenuAction.change,
                    child: Text('Change exercise'),
                  ),
                  PopupMenuItem<_ExerciseMenuAction>(
                    value: _ExerciseMenuAction.delete,
                    child: Text('Delete exercise'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            exercise.primaryMuscle,
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onPickRestTime,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF232323),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Rest timer: ${_PlanCreationPageState._formatRestDuration(draft.restDuration)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ExerciseInputField(
            label: 'Notes',
            controller: draft.notesController,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Text(
            'Sets',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 56,
                  child: Text(
                    'Set',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!isBodyweight) ...[
                  Expanded(
                    child: Text(
                      'Weight',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    'Rep',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final entry in draft.setRows.asMap().entries) ...[
            Dismissible(
              key: ValueKey(entry.value.rowId),
              direction: canRemoveSet
                  ? DismissDirection.startToEnd
                  : DismissDirection.none,
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Delete set',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              confirmDismiss: (_) async {
                if (!canRemoveSet) {
                  return false;
                }
                onRemoveSet(entry.value.rowId);
                return false;
              },
              child: _SetRowEditor(
                index: entry.key + 1,
                rowDraft: entry.value,
                isBodyweight: isBodyweight,
                canDelete: canRemoveSet,
                onDelete: () => onRemoveSet(entry.value.rowId),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddSet,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Set'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetRowEditor extends StatelessWidget {
  const _SetRowEditor({
    required this.index,
    required this.rowDraft,
    required this.isBodyweight,
    required this.canDelete,
    required this.onDelete,
  });

  final int index;
  final _SetRowDraft rowDraft;
  final bool isBodyweight;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (!isBodyweight) ...[
            Expanded(
              child: _ExerciseInputField(
                label: 'Weight',
                controller: rowDraft.weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: _ExerciseInputField(
              label: 'Rep',
              controller: rowDraft.repsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          if (canDelete) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onDelete,
              tooltip: 'Delete set',
              icon: const Icon(Icons.close, color: Colors.white54, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseInputField extends StatelessWidget {
  const _ExerciseInputField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF232323),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _ExerciseInputDraft {
  _ExerciseInputDraft({
    required String firstRowId,
    int initialSetCount = 1,
    int initialReps = 12,
    double? initialWeight,
    Duration initialRestDuration = const Duration(seconds: 60),
    String initialNotes = '',
  })  : setRows = <_SetRowDraft>[],
        restController = TextEditingController(text: initialRestDuration.inSeconds.toString()),
        notesController = TextEditingController(text: initialNotes),
        restDuration = initialRestDuration {
    final setCount = initialSetCount <= 0 ? 1 : initialSetCount;
    for (var index = 0; index < setCount; index += 1) {
      setRows.add(
        _SetRowDraft(
          rowId: index == 0 ? firstRowId : '${firstRowId}_$index',
          repsText: initialReps.toString(),
          weightText: initialWeight == null ? '' : initialWeight.toString(),
        ),
      );
    }
  }

  final List<_SetRowDraft> setRows;
  final TextEditingController restController;
  final TextEditingController notesController;
  Duration restDuration;

  void rebuildFromExisting({
    required int setCount,
    required String repsText,
    required String? weightText,
    required Duration restDuration,
    required String notesText,
  }) {
    for (final row in setRows) {
      row.dispose();
    }
    setRows.clear();

    this.restDuration = restDuration;
    restController.text = restDuration.inSeconds.toString();
    notesController.text = notesText;

    final safeSetCount = setCount <= 0 ? 1 : setCount;
    for (var index = 0; index < safeSetCount; index += 1) {
      setRows.add(
        _SetRowDraft(
          rowId: '${DateTime.now().millisecondsSinceEpoch}_$index',
          repsText: repsText.isEmpty ? '12' : repsText,
          weightText: weightText ?? '',
        ),
      );
    }
  }

  void setRestDuration(Duration duration) {
    restDuration = duration;
    restController.text = duration.inSeconds.toString();
  }

  void addSetRow(
    String rowId, {
    String? repsText,
    String? weightText,
  }) {
    setRows.add(
      _SetRowDraft(
        rowId: rowId,
        repsText: (repsText == null || repsText.trim().isEmpty)
            ? setRows.isNotEmpty
                ? setRows.first.repsController.text.trim()
                : '12'
            : repsText.trim(),
        weightText: weightText ?? '',
      ),
    );
  }

  void removeSetRow(String rowId) {
    if (setRows.length <= 1) {
      return;
    }
    final index = setRows.indexWhere((row) => row.rowId == rowId);
    if (index == -1) {
      return;
    }
    final row = setRows.removeAt(index);
    row.dispose();
  }

  void dispose() {
    for (final setRow in setRows) {
      setRow.dispose();
    }
    restController.dispose();
    notesController.dispose();
  }
}

class _SetRowDraft {
  _SetRowDraft({
    required this.rowId,
    String repsText = '12',
    String weightText = '',
  })  : repsController = TextEditingController(text: repsText),
        weightController = TextEditingController(text: weightText);

  final String rowId;
  final TextEditingController repsController;
  final TextEditingController weightController;

  void dispose() {
    repsController.dispose();
    weightController.dispose();
  }
}
