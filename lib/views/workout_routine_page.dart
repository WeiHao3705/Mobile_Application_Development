import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/exercise.dart';
import '../repository/workout_record_repository.dart';
import 'exercise_detail_page.dart';
import 'exercise_explore_page.dart';
import 'save_workout_page.dart';

class WorkoutRoutineExerciseSeed {
  const WorkoutRoutineExerciseSeed({
    required this.exercise,
    this.setCount = 1,
    this.repsText = '12',
    this.weightText = '',
    this.notes = '',
  });

  final Exercise exercise;
  final int setCount;
  final String repsText;
  final String weightText;
  final String notes;
}

String _formatRestDuration(Duration value) {
  final minutes = value.inMinutes;
  final seconds = value.inSeconds.remainder(60);
  return '${minutes.toString().padLeft(2, '0')}min ${seconds.toString().padLeft(2, '0')}s';
}

class WorkoutRoutinePage extends StatefulWidget {
  const WorkoutRoutinePage({
    super.key,
    required this.userId,
    this.initialExercises = const <WorkoutRoutineExerciseSeed>[],
  });

  final int userId;
  final List<WorkoutRoutineExerciseSeed> initialExercises;

  @override
  State<WorkoutRoutinePage> createState() => _WorkoutRoutinePageState();
}

class _WorkoutRoutinePageState extends State<WorkoutRoutinePage> {
  late final DateTime _startedAt;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  final List<Exercise> _selectedExercises = <Exercise>[];
  final Map<int, _RoutineExerciseDraft> _exerciseDrafts = <int, _RoutineExerciseDraft>{};
  int _setRowCounter = 0;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    if (widget.initialExercises.isNotEmpty) {
      _selectedExercises.addAll(widget.initialExercises.map((seed) => seed.exercise));
    }
    _syncExerciseDrafts(widget.initialExercises);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _elapsed = DateTime.now().difference(_startedAt);
        for (final draft in _exerciseDrafts.values) {
          draft.tickRestTimer();
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final draft in _exerciseDrafts.values) {
      draft.dispose();
    }
    super.dispose();
  }

  String _nextSetRowId() {
    _setRowCounter += 1;
    return '${DateTime.now().millisecondsSinceEpoch}_$_setRowCounter';
  }

  bool _isBodyweightExercise(Exercise exercise) {
    return exercise.isBodyweight;
  }

  void _syncExerciseDrafts([List<WorkoutRoutineExerciseSeed>? seeds]) {
    final existingDrafts = _exerciseDrafts.values.toList();
    for (final draft in existingDrafts) {
      draft.dispose();
    }
    _exerciseDrafts.clear();

    for (var index = 0; index < _selectedExercises.length; index += 1) {
      final seed = seeds != null && index < seeds.length ? seeds[index] : null;
      final draft = _RoutineExerciseDraft(
        firstRowId: _nextSetRowId(),
        notesText: seed?.notes ?? '',
        repsText: seed?.repsText ?? '12',
        weightText: seed?.weightText ?? '',
      );

      final setCount = seed?.setCount ?? 1;
      for (var rowIndex = 1; rowIndex < setCount; rowIndex += 1) {
        draft.addSetRow(
          rowId: _nextSetRowId(),
          repsText: seed?.repsText ?? '12',
          weightText: seed?.weightText ?? '',
        );
      }

      _exerciseDrafts[index] = draft;
    }
  }

  int _completedSetCount() {
    var count = 0;
    for (final draft in _exerciseDrafts.values) {
      for (final setRow in draft.setRows) {
        if (setRow.isCompleted) {
          count += 1;
        }
      }
    }
    return count;
  }

  double _trainingVolume() {
    var total = 0.0;
    for (var exerciseIndex = 0; exerciseIndex < _selectedExercises.length; exerciseIndex += 1) {
      final exercise = _selectedExercises[exerciseIndex];
      if (_isBodyweightExercise(exercise)) {
        continue;
      }

      final draft = _exerciseDrafts[exerciseIndex];
      if (draft == null) {
        continue;
      }

      for (final setRow in draft.setRows) {
        if (!setRow.isCompleted) {
          continue;
        }

        final reps = int.tryParse(setRow.repsController.text.trim()) ?? 0;
        final weight = double.tryParse(setRow.weightController.text.trim()) ?? 0;
        total += reps * weight;
      }
    }
    return total;
  }

  String _formatWorkoutDuration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    final seconds = value.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _pickRoutineDuration() async {
    final picked = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      builder: (context) {
        var currentDuration = _elapsed;

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
                        'Select Duration',
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
                    mode: CupertinoTimerPickerMode.hms,
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
      _startedAt = DateTime.now().subtract(picked);
      _elapsed = picked;
    });
  }

  Future<void> _addExercise() async {
    final selectedExercises = await Navigator.of(context).push<List<Exercise>>(
      MaterialPageRoute<List<Exercise>>(
        builder: (_) => ExerciseExplorePage(
          selectable: true,
          initialSelectedExerciseIds: _selectedExercises.map((exercise) => exercise.id).toSet(),
        ),
      ),
    );

    if (selectedExercises == null) {
      return;
    }

    setState(() {
      _selectedExercises
        ..clear()
        ..addAll(selectedExercises);
      _syncExerciseDrafts();
    });
  }

  void _addSetRow(int exerciseIndex) {
    final draft = _exerciseDrafts[exerciseIndex];
    if (draft == null) {
      return;
    }

    final templateRow = draft.setRows.isNotEmpty ? draft.setRows.first : null;
    setState(() {
      draft.addSetRow(
        rowId: _nextSetRowId(),
        repsText: templateRow?.repsController.text.trim() ?? '',
        weightText: templateRow?.weightController.text.trim() ?? '',
      );
    });
  }

  void _removeSetRow(int exerciseIndex, String rowId) {
    final draft = _exerciseDrafts[exerciseIndex];
    if (draft == null || draft.setRows.length <= 1) {
      return;
    }

    setState(() => draft.removeSetRow(rowId));
  }

  void _toggleSetCompleted(int exerciseIndex, String rowId) {
    final draft = _exerciseDrafts[exerciseIndex];
    if (draft == null) {
      return;
    }

    setState(() {
      final becameCompleted = draft.toggleSetCompleted(rowId);
      if (becameCompleted) {
        draft.startRestCountdown();
      }
    });
  }

  Future<void> _pickRestTime(int exerciseIndex) async {
    final draft = _exerciseDrafts[exerciseIndex];
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

  List<WorkoutRecordDetailInput> _buildRecordDetails() {
    final details = <WorkoutRecordDetailInput>[];

    for (var index = 0; index < _selectedExercises.length; index += 1) {
      final exercise = _selectedExercises[index];
      final draft = _exerciseDrafts[index];
      if (draft == null) {
        continue;
      }

      final completedSets = draft.setRows.where((row) => row.isCompleted).toList();
      if (completedSets.isEmpty) {
        continue;
      }

      final firstSet = completedSets.first;
      details.add(
        WorkoutRecordDetailInput(
          exerciseName: exercise.name,
          orderIndex: index,
          sets: completedSets.length,
          reps: int.tryParse(firstSet.repsController.text.trim()) ?? 0,
          weight: _isBodyweightExercise(exercise)
              ? 0
              : int.tryParse(firstSet.weightController.text.trim()) ?? 0,
          notes: draft.notesController.text.trim(),
        ),
      );
    }

    return details;
  }

  Future<void> _openSaveWorkoutPage() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SaveWorkoutPage(
          userId: widget.userId,
          duration: _elapsed,
          trainingVolume: _trainingVolume(),
          numOfSets: _completedSetCount(),
          savedAt: DateTime.now(),
          details: _buildRecordDetails(),
        ),
      ),
    );

    if (saved == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasExercises = _selectedExercises.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Workout Routine'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _openSaveWorkoutPage,
            child: Text(
              'Complete',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickRoutineDuration,
                    child: _WorkoutStatTile(
                      label: 'Duration',
                      value: _formatWorkoutDuration(_elapsed),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _WorkoutStatTile(
                    label: 'Training Volume',
                    value: '${_trainingVolume().toStringAsFixed(0)} kg',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _WorkoutStatTile(
                    label: 'Sets',
                    value: '${_completedSetCount()}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: hasExercises
                  ? ListView.builder(
                      itemCount: _selectedExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = _selectedExercises[index];
                        final draft = _exerciseDrafts[index]!;

                        return Padding(
                          key: ObjectKey(draft),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RoutineExerciseCard(
                            exercise: exercise,
                            draft: draft,
                            orderIndex: index + 1,
                            isBodyweight: _isBodyweightExercise(exercise),
                            onAddSet: () => _addSetRow(index),
                            onPickRestTime: () => _pickRestTime(index),
                            onRemoveSet: (rowId) => _removeSetRow(index, rowId),
                            onToggleSetCompleted: (rowId) => _toggleSetCompleted(index, rowId),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'Select a exercise to start your workout',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Exercise'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutStatTile extends StatelessWidget {
  const _WorkoutStatTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineExerciseCard extends StatelessWidget {
  const _RoutineExerciseCard({
    required this.exercise,
    required this.draft,
    required this.orderIndex,
    required this.isBodyweight,
    required this.onAddSet,
    required this.onPickRestTime,
    required this.onRemoveSet,
    required this.onToggleSetCompleted,
  });

  final Exercise exercise;
  final _RoutineExerciseDraft draft;
  final int orderIndex;
  final bool isBodyweight;
  final VoidCallback onAddSet;
  final VoidCallback onPickRestTime;
  final ValueChanged<String> onRemoveSet;
  final ValueChanged<String> onToggleSetCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canDeleteSet = draft.setRows.length > 1;

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
              ],
            ),
          ),
          const SizedBox(height: 12),
          _RoutineInputField(
            label: 'Notes',
            controller: draft.notesController,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
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
                    'Rest Timer: ${_formatRestDuration(draft.visibleRestDuration)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                  width: 44,
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
                const SizedBox(width: 8),
                const Icon(Icons.check_circle_outline, color: Colors.white54, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final entry in draft.setRows.asMap().entries) ...[
            _RoutineSetRowEditor(
              index: entry.key + 1,
              rowDraft: entry.value,
              isBodyweight: isBodyweight,
              canDelete: canDeleteSet,
              onDelete: () => onRemoveSet(entry.value.rowId),
              onToggleComplete: () => onToggleSetCompleted(entry.value.rowId),
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

class _RoutineSetRowEditor extends StatelessWidget {
  const _RoutineSetRowEditor({
    required this.index,
    required this.rowDraft,
    required this.isBodyweight,
    required this.canDelete,
    required this.onDelete,
    required this.onToggleComplete,
  });

  final int index;
  final _RoutineSetRowDraft rowDraft;
  final bool isBodyweight;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;

  @override
  Widget build(BuildContext context) {
    final completeColor = rowDraft.isCompleted ? Colors.greenAccent : Colors.white38;

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
            width: 44,
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
              child: _RoutineInputField(
                label: 'Weight',
                controller: rowDraft.weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: _RoutineInputField(
              label: 'Rep',
              controller: rowDraft.repsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onToggleComplete,
            tooltip: rowDraft.isCompleted ? 'Mark as incomplete' : 'Mark as complete',
            icon: Icon(
              rowDraft.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: completeColor,
              size: 22,
            ),
          ),
          if (canDelete)
            IconButton(
              onPressed: onDelete,
              tooltip: 'Delete set',
              icon: const Icon(Icons.close, color: Colors.white54, size: 18),
            ),
        ],
      ),
    );
  }
}

class _RoutineInputField extends StatelessWidget {
  const _RoutineInputField({
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

class _RoutineExerciseDraft {
  _RoutineExerciseDraft({
    required String firstRowId,
    String notesText = '',
    String repsText = '12',
    String weightText = '',
  })  : notesController = TextEditingController(text: notesText),
        setRows = <_RoutineSetRowDraft>[
          _RoutineSetRowDraft(rowId: firstRowId, repsText: repsText, weightText: weightText),
        ];

  final TextEditingController notesController;
  final List<_RoutineSetRowDraft> setRows;
  Duration restDuration = const Duration(seconds: 60);
  Duration restRemaining = const Duration(seconds: 60);
  bool isRestRunning = false;

  Duration get visibleRestDuration =>
      isRestRunning || restRemaining != restDuration ? restRemaining : restDuration;

  void addSetRow({
    required String rowId,
    String repsText = '12',
    String weightText = '',
  }) {
    setRows.add(
      _RoutineSetRowDraft(
        rowId: rowId,
        repsText: repsText,
        weightText: weightText,
      ),
    );
  }

  void removeSetRow(String rowId) {
    if (setRows.length <= 1) {
      return;
    }
    final index = setRows.indexWhere((item) => item.rowId == rowId);
    if (index == -1) {
      return;
    }
    final removed = setRows.removeAt(index);
    removed.dispose();
  }

  bool toggleSetCompleted(String rowId) {
    final index = setRows.indexWhere((item) => item.rowId == rowId);
    if (index == -1) {
      return false;
    }
    return setRows[index].toggleCompleted();
  }

  void startRestCountdown() {
    restRemaining = restDuration;
    isRestRunning = true;
  }

  void setRestDuration(Duration duration) {
    restDuration = duration;
    restRemaining = duration;
    isRestRunning = false;
  }

  void tickRestTimer() {
    if (!isRestRunning) {
      return;
    }
    if (restRemaining.inSeconds <= 0) {
      restRemaining = Duration.zero;
      isRestRunning = false;
      return;
    }

    restRemaining -= const Duration(seconds: 1);
    if (restRemaining.inSeconds <= 0) {
      restRemaining = Duration.zero;
      isRestRunning = false;
    }
  }

  void dispose() {
    notesController.dispose();
    for (final row in setRows) {
      row.dispose();
    }
  }
}

class _RoutineSetRowDraft {
  _RoutineSetRowDraft({
    required this.rowId,
    String repsText = '12',
    String weightText = '',
  })  : repsController = TextEditingController(text: repsText),
        weightController = TextEditingController(text: weightText);

  final String rowId;
  final TextEditingController repsController;
  final TextEditingController weightController;
  bool isCompleted = false;

  bool toggleCompleted() {
    isCompleted = !isCompleted;
    return isCompleted;
  }

  void dispose() {
    repsController.dispose();
    weightController.dispose();
  }
}
