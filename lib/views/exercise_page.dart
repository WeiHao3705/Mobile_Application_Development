import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/auth_controller.dart';
import '../models/exercise.dart';
import '../repository/exercise_repository.dart';
import '../theme/app_colors.dart';
import 'add_exercise_page.dart';
import 'exercise_detail_page.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  late final ExerciseRepository _repository;
  final TextEditingController _searchController = TextEditingController();

  List<Exercise> _exercises = const <Exercise>[];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _repository = ExerciseRepository(supabase: Supabase.instance.client);
    _searchController.addListener(() => setState(() {}));
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int? get _userId {
    final currentUser = widget.authController.currentUser;
    final id = currentUser?.id;
    if (id is int) {
      return id;
    }
    return int.tryParse(id?.toString() ?? '');
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final items = await _repository.getAllExercises();
      if (!mounted) {
        return;
      }
      setState(() {
        _exercises = items;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Failed to load exercises: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Exercise> get _filteredExercises {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _exercises;
    }

    return _exercises.where((exercise) {
      return exercise.name.toLowerCase().contains(query) ||
          exercise.primaryMuscle.toLowerCase().contains(query) ||
          exercise.equipment.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openAddExercisePage() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddExercisePage(repository: _repository),
      ),
    );

    if (result == true) {
      await _loadExercises();
    }
  }

  Future<void> _deleteExercise(Exercise exercise) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardBg,
            title: const Text(
              'Delete Exercise?',
              style: TextStyle(color: AppColors.white),
            ),
            content: Text(
              'Delete "${exercise.name}"? This cannot be undone.',
              style: const TextStyle(color: AppColors.lavender),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.lavender),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    try {
      await _repository.deleteExercise(exercise.id);
      await _loadExercises();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${exercise.name} deleted')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete exercise: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('Exercise Management'),
        centerTitle: true,
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Search exercise',
                  hintStyle: const TextStyle(color: AppColors.slateGray),
                  prefixIcon: const Icon(Icons.search, color: AppColors.lavender),
                  filled: true,
                  fillColor: AppColors.inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openAddExercisePage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: AppColors.white,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Exercise'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loadExercises,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.lavender,
                        side: BorderSide(color: AppColors.lavender.withValues(alpha: 0.5)),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.lavender),
                ),
              )
            else if (_errorMessage.isNotEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.slateGray),
                    ),
                  ),
                ),
              )
            else if (_filteredExercises.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No exercises found.',
                    style: TextStyle(color: AppColors.slateGray),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _filteredExercises.length,
                  separatorBuilder: (_, _) => const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (context, index) {
                    final exercise = _filteredExercises[index];
                    return ListTile(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ExerciseDetailPage(exercise: exercise),
                          ),
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.white,
                        backgroundImage: exercise.imageUrl.isNotEmpty
                            ? NetworkImage(exercise.imageUrl)
                            : null,
                        child: exercise.imageUrl.isEmpty
                            ? const Icon(Icons.fitness_center, color: AppColors.black)
                            : null,
                      ),
                      title: Text(
                        exercise.name,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${exercise.primaryMuscle} • ${exercise.equipment}',
                        style: const TextStyle(color: AppColors.slateGray),
                      ),
                      trailing: IconButton(
                        tooltip: 'Delete',
                        onPressed: () => _deleteExercise(exercise),
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _userId == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.purple,
              foregroundColor: AppColors.white,
              onPressed: _openAddExercisePage,
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
            ),
    );
  }
}