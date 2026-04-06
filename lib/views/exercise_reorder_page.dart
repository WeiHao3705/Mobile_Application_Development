import 'package:flutter/material.dart';

import '../models/exercise.dart';

class ExerciseReorderPage extends StatefulWidget {
  const ExerciseReorderPage({super.key, required this.entries});

  final List<ExerciseReorderResult> entries;

  @override
  State<ExerciseReorderPage> createState() => _ExerciseReorderPageState();
}

class _ExerciseReorderPageState extends State<ExerciseReorderPage> {
  late final List<_ExerciseReorderRow> _exercises;

  @override
  void initState() {
    super.initState();
    _exercises = widget.entries
        .map((entry) => _ExerciseReorderRow(rowId: entry.rowId, exercise: entry.exercise))
        .toList();
  }

  void _save() {
    Navigator.of(context).pop(
      _exercises
          .map((row) => ExerciseReorderResult(rowId: row.rowId, exercise: row.exercise))
          .toList(),
    );
  }

  void _deleteExerciseAt(int index) {
    if (index < 0 || index >= _exercises.length) {
      return;
    }
    setState(() {
      _exercises.removeAt(index);
    });
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
        title: const Text('Rearrange Exercises'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Drag the handles up or down to reorder',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _exercises.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _exercises.removeAt(oldIndex);
                    _exercises.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final row = _exercises[index];
                  final exercise = row.exercise;
                  return Container(
                    key: ValueKey(row.rowId),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => _deleteExerciseAt(index),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(34, 34),
                            maximumSize: const Size(34, 34),
                            padding: EdgeInsets.zero,
                          ),
                          icon: const Icon(Icons.remove, size: 20),
                          tooltip: 'Delete exercise',
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              exercise.imageUrl.isNotEmpty ? NetworkImage(exercise.imageUrl) : null,
                          child: exercise.imageUrl.isEmpty
                              ? const Icon(Icons.fitness_center, color: Colors.black)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                exercise.primaryMuscle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 40,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: ReorderableDragStartListener(
                              index: index,
                              child: const Icon(
                                Icons.drag_indicator,
                                color: Colors.white54,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseReorderRow {
  _ExerciseReorderRow({
    required this.rowId,
    required this.exercise,
  });

  final String rowId;
  final Exercise exercise;
}

class ExerciseReorderResult {
  const ExerciseReorderResult({
    required this.rowId,
    required this.exercise,
  });

  final String rowId;
  final Exercise exercise;
}
