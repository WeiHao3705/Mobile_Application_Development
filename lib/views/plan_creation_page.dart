import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/exercise.dart';
import '../models/workout_plan.dart';
import '../repository/exercise_repository.dart';
import '../repository/workout_plan_repository.dart';
import 'exercise_detail_page.dart';
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
  final List<_ExercisePlanEntry> _selectedExerciseEntries = <_ExercisePlanEntry>[];
  final Map<String, _ExerciseInputDraft> _exerciseDrafts = <String, _ExerciseInputDraft>{};
  late final WorkoutPlanRepository _workoutPlanRepository;
  late final ExerciseRepository _exerciseRepository;
  bool _isSaving = false;
  bool _isInitializing = false;
  bool _hasUnsavedChanges = false;
  bool _isTrackingChanges = false;
  int _setRowCounter = 0;
  int _exerciseRowCounter = 0;
  String _initialPlanName = '';
  List<String> _initialExerciseOrder = const <String>[];

  String _nextSetRowId() {
    final seconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _setRowCounter += 1;
    return '${seconds}_$_setRowCounter';
  }

  String _nextExerciseRowId() {
    final seconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _exerciseRowCounter += 1;
    return 'exercise_${seconds}_$_exerciseRowCounter';
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

    _planNameController.addListener(_updateUnsavedChanges);

    if (widget.isEditMode || widget.initialExerciseIds.isNotEmpty) {
      _initializeFromExistingPlan();
    } else {
      _captureInitialSnapshot();
    }
  }

  void _captureInitialSnapshot() {
    _initialPlanName = _planNameController.text.trim();
    _initialExerciseOrder = _selectedExerciseEntries
        .map((entry) => entry.exercise.id)
        .toList(growable: false);
    _hasUnsavedChanges = false;
    _isTrackingChanges = true;
  }

  void _updateUnsavedChanges() {
    if (!_isTrackingChanges) {
      return;
    }

    final currentPlanName = _planNameController.text.trim();
    final currentExerciseOrder = _selectedExerciseEntries
        .map((entry) => entry.exercise.id)
        .toList(growable: false);

    final hasPlanNameChange = currentPlanName != _initialPlanName;
    final hasExerciseSelectionChange =
        currentExerciseOrder.length != _initialExerciseOrder.length ||
            currentExerciseOrder.asMap().entries.any(
              (entry) => entry.value != _initialExerciseOrder[entry.key],
            );

    _hasUnsavedChanges = hasPlanNameChange || hasExerciseSelectionChange;
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text(
            'Discard changes?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'You have unsaved changes. Do you want to discard them and leave this page?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Discard',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    return discard == true;
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

      final selectedEntries = <_ExercisePlanEntry>[];
      if (detailRows.isNotEmpty) {
        for (final row in detailRows) {
          final exerciseId = _readTextByKeys(row, _detailExerciseIdColumnCandidates);
          final exercise = exerciseById[exerciseId];
          if (exercise == null) {
            continue;
          }
          selectedEntries.add(
            _ExercisePlanEntry(
              rowId: _nextExerciseRowId(),
              exercise: exercise,
              detailRow: row,
            ),
          );
        }
      } else {
        selectedEntries.addAll(
          exercises
              .where((exercise) => widget.initialExerciseIds.contains(exercise.id))
              .map(
                (exercise) => _ExercisePlanEntry(
                  rowId: _nextExerciseRowId(),
                  exercise: exercise,
                ),
              ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedExerciseEntries
          ..clear()
          ..addAll(selectedEntries);
        _syncExerciseDrafts(_selectedExerciseEntries);
      });
      _captureInitialSnapshot();
    } catch (_) {
      // Keep edit page usable even when initial hydrate fails.
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
        if (!_isTrackingChanges) {
          _captureInitialSnapshot();
        }
      }
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
    _planNameController.removeListener(_updateUnsavedChanges);
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
          initialSelectedExerciseIds: _selectedExerciseEntries
              .map((entry) => entry.exercise.id)
              .toSet(),
        ),
      ),
    );

    if (selectedExercises != null) {
      setState(() {
        _selectedExerciseEntries
          ..clear()
          ..addAll(
            selectedExercises.map(
              (exercise) => _ExercisePlanEntry(
                rowId: _nextExerciseRowId(),
                exercise: exercise,
              ),
            ),
          );
        _syncExerciseDrafts(_selectedExerciseEntries);
      });
      _updateUnsavedChanges();
    }
  }

  bool _isBodyweightExercise(Exercise exercise) {
    return exercise.isBodyweight;
  }

  void _addSetRow(String rowId) {
    final draft = _exerciseDrafts[rowId];
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

  void _removeSetRow(String rowId, String setRowId) {
    final draft = _exerciseDrafts[rowId];
    if (draft == null) {
      return;
    }

    if (draft.setRows.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one set is required.')),
      );
      return;
    }

    setState(() => draft.removeSetRow(setRowId));
  }

  Future<void> _rearrangeExercises() async {
    if (_selectedExerciseEntries.length < 2) {
      return;
    }

    final rowIdsByIndex = List<String>.generate(
      _selectedExerciseEntries.length,
      (index) => _selectedExerciseEntries[index].rowId,
    );
    final entryByRowId = <String, _ExercisePlanEntry>{
      for (final entry in _selectedExerciseEntries) entry.rowId: entry,
    };

    final reorderedEntries = await Navigator.of(context).push<List<ExerciseReorderResult>>(
      MaterialPageRoute<List<ExerciseReorderResult>>(
        builder: (_) => ExerciseReorderPage(
          entries: List<ExerciseReorderResult>.generate(
            _selectedExerciseEntries.length,
            (index) => ExerciseReorderResult(
              rowId: rowIdsByIndex[index],
              exercise: _selectedExerciseEntries[index].exercise,
            ),
          ),
        ),
      ),
    );

    if (reorderedEntries == null) {
      return;
    }

    setState(() {
      _selectedExerciseEntries
        ..clear()
        ..addAll(
          reorderedEntries.map((entry) {
            final original = entryByRowId[entry.rowId];
            return original == null
                ? _ExercisePlanEntry(rowId: entry.rowId, exercise: entry.exercise)
                : original.copyWith(exercise: entry.exercise);
          }),
        );
    });
    _updateUnsavedChanges();
  }

  void _deleteExerciseAt(int index) {
    if (index < 0 || index >= _selectedExerciseEntries.length) {
      return;
    }

    final entry = _selectedExerciseEntries.removeAt(index);
    _exerciseDrafts.remove(entry.rowId)?.dispose();
    setState(() {});
    _updateUnsavedChanges();
  }

  Future<void> _changeExerciseAt(int index) async {
    if (index < 0 || index >= _selectedExerciseEntries.length) {
      return;
    }

    final currentEntry = _selectedExerciseEntries[index];
    final selectedExercises = await Navigator.of(context).push<List<Exercise>>(
      MaterialPageRoute<List<Exercise>>(
        builder: (_) => ExerciseExplorePage(
          selectable: true,
          singleSelection: true,
          initialSelectedExerciseIds: {currentEntry.exercise.id},
        ),
      ),
    );

    if (selectedExercises == null || selectedExercises.isEmpty) {
      return;
    }

    final nextExercise = selectedExercises.first;
    if (nextExercise.id == currentEntry.exercise.id) {
      return;
    }

    setState(() {
      _selectedExerciseEntries[index] = currentEntry.copyWith(exercise: nextExercise);
      _exerciseDrafts[currentEntry.rowId]?.dispose();
      _exerciseDrafts[currentEntry.rowId] = _ExerciseInputDraft(
        firstRowId: _nextSetRowId(),
        initialSetCount: 1,
        initialReps: 12,
        initialWeight: null,
        initialRestDuration: const Duration(seconds: 60),
        initialNotes: '',
      );
    });
    _updateUnsavedChanges();
  }

  void _syncExerciseDrafts(List<_ExercisePlanEntry> selectedEntries) {
    final previousDrafts = _exerciseDrafts.values.toList();
    _exerciseDrafts.clear();
    for (final draft in previousDrafts) {
      draft.dispose();
    }

    for (final entry in selectedEntries) {
      final detailRow = entry.detailRow;
      final initialSetCount = detailRow == null ? 1 : _toInt(detailRow['sets']);
      _exerciseDrafts[entry.rowId] = _ExerciseInputDraft(
        firstRowId: _nextSetRowId(),
        initialSetCount: initialSetCount,
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

    if (_selectedExerciseEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose at least one exercise.')),
      );
      return;
    }

    final payload = _selectedExerciseEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final exercise = entry.value.exercise;
      final draft = _exerciseDrafts[entry.value.rowId]!;
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
      _isTrackingChanges = false;
      _hasUnsavedChanges = false;
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

  Future<void> _pickRestTime(String rowId) async {
    final draft = _exerciseDrafts[rowId];
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

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _isSaving) {
          return;
        }
        final shouldDiscard = await _confirmDiscardChanges();
        if (!mounted || !shouldDiscard) {
          return;
        }
        _isTrackingChanges = false;
        Navigator.of(this.context).pop();
      },
      child: Scaffold(
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
                'Selected Exercises (${_selectedExerciseEntries.length})',
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
                      : _selectedExerciseEntries.isEmpty
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
                          itemCount: _selectedExerciseEntries.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) {
                                newIndex -= 1;
                              }
                              final item = _selectedExerciseEntries.removeAt(oldIndex);
                              _selectedExerciseEntries.insert(newIndex, item);
                            });
                            _updateUnsavedChanges();
                          },
                          itemBuilder: (context, index) {
                            final entry = _selectedExerciseEntries[index];
                            final draft = _exerciseDrafts[entry.rowId]!;

                            return Padding(
                              key: ValueKey(entry.rowId),
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ExerciseEditorCard(
                                exercise: entry.exercise,
                                draft: draft,
                                orderIndex: index + 1,
                                listIndex: index,
                                totalExercises: _selectedExerciseEntries.length,
                                isBodyweight: _isBodyweightExercise(entry.exercise),
                                onAddSet: () => _addSetRow(entry.rowId),
                                onRearrange: _rearrangeExercises,
                                onChangeExercise: () => _changeExerciseAt(index),
                                onDeleteExercise: () => _deleteExerciseAt(index),
                                onPickRestTime: () => _pickRestTime(entry.rowId),
                                onRemoveSet: (rowId) => _removeSetRow(entry.rowId, rowId),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
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
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ExerciseDetailPage(exercise: exercise),
                ),
              );
            },
            child: Row(
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

class _ExercisePlanEntry {
  const _ExercisePlanEntry({
    required this.rowId,
    required this.exercise,
    this.detailRow,
  });

  final String rowId;
  final Exercise exercise;
  final Map<String, dynamic>? detailRow;

  _ExercisePlanEntry copyWith({
    Exercise? exercise,
    Map<String, dynamic>? detailRow,
  }) {
    return _ExercisePlanEntry(
      rowId: rowId,
      exercise: exercise ?? this.exercise,
      detailRow: detailRow ?? this.detailRow,
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
