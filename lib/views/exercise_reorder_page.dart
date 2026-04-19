import 'package:flutter/material.dart';

import '../models/exercise.dart';

class ExerciseReorderResult {
  const ExerciseReorderResult({
    required this.rowId,
    required this.exercise,
  });

  final String rowId;
  final Exercise exercise;
}

class ExerciseReorderPage extends StatefulWidget {
  const ExerciseReorderPage({super.key, required this.entries});

  final List<ExerciseReorderResult> entries;

  @override
  State<ExerciseReorderPage> createState() => _ExerciseReorderPageState();
}

class _ExerciseReorderPageState extends State<ExerciseReorderPage> {
  late final List<ExerciseReorderResult> _entries;
  late final List<ExerciseReorderResult> _originalEntries;
  bool _allowProgrammaticPop = false;

  @override
  void initState() {
    super.initState();
    _entries = List<ExerciseReorderResult>.from(widget.entries);
    _originalEntries = List<ExerciseReorderResult>.from(widget.entries);
  }

  bool get _hasChanges {
    if (_entries.length != _originalEntries.length) {
      return true;
    }
    for (int i = 0; i < _entries.length; i++) {
      if (_entries[i].rowId != _originalEntries[i].rowId) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasChanges) {
      return true;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text('Discard changes?', style: TextStyle(color: Colors.white)),
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
              child: const Text('Discard', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    return shouldDiscard == true;
  }

  void _save() {
    Navigator.of(context).pop(List<ExerciseReorderResult>.from(_entries));
  }

  void _deleteExerciseAt(int index) {
    if (index < 0 || index >= _entries.length) {
      return;
    }
    setState(() {
      _entries.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: _allowProgrammaticPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        final shouldDiscard = await _confirmDiscardChanges();
        if (!mounted || !shouldDiscard) {
          return;
        }

        _allowProgrammaticPop = true;
        Navigator.of(context).pop();
      },
      child: Scaffold(
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
          tooltip: 'Back',
        ),
        title: Text(
          'Rearrange Exercises',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
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
                itemCount: _entries.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _entries.removeAt(oldIndex);
                    _entries.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  final exercise = entry.exercise;
                  return Container(
                    key: ValueKey(entry.rowId),
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
    ),
    );
  }
}