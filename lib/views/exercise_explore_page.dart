import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/exercise.dart';
import '../repository/exercise_repository.dart';
import 'exercise_detail_page.dart';

class ExerciseExplorePage extends StatefulWidget {
  const ExerciseExplorePage({super.key});

  @override
  State<ExerciseExplorePage> createState() => _ExerciseExplorePageState();
}

class _ExerciseExplorePageState extends State<ExerciseExplorePage> {
  late final ExerciseRepository _repository;
  late Future<List<Exercise>> _exercisesFuture;
  final TextEditingController _searchController = TextEditingController();

  String _selectedEquipment = 'All Equipment';
  String _selectedMuscle = 'All Muscles';

  @override
  void initState() {
    super.initState();
    _repository = ExerciseRepository(supabase: Supabase.instance.client);
    _exercisesFuture = _repository.getAllExercises();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openExerciseDetail(Exercise exercise) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExerciseDetailPage(exercise: exercise),
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
        foregroundColor: theme.colorScheme.primary,
        surfaceTintColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back to Workout',
        ),
        title: Text(
          'Exercise',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<List<Exercise>>(
          future: _exercisesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: theme.colorScheme.primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load exercises: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final allExercises = snapshot.data ?? const <Exercise>[];
            final filteredExercises = _filterExercises(allExercises);
            final equipmentOptions = _buildOptions(
              allExercises.map((item) => item.equipment),
              defaultValue: 'All Equipment',
            );
            final muscleOptions = _buildOptions(
              allExercises.map((item) => item.primaryMuscle),
              defaultValue: 'All Muscles',
            );

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SearchField(controller: _searchController),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _FilterButton(
                              title: _selectedEquipment,
                              onTap: () => _showOptionPicker(
                                title: 'Equipment',
                                options: equipmentOptions,
                                onSelected: (value) {
                                  setState(() => _selectedEquipment = value);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FilterButton(
                              title: _selectedMuscle,
                              onTap: () => _showOptionPicker(
                                title: 'Muscles',
                                options: muscleOptions,
                                onSelected: (value) {
                                  setState(() => _selectedMuscle = value);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'All Exercises',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filteredExercises.isEmpty
                      ? const _EmptyExerciseState()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filteredExercises.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.white12, height: 1),
                          itemBuilder: (context, index) {
                            return _ExerciseListTile(
                              exercise: filteredExercises[index],
                              onTap: () => _openExerciseDetail(filteredExercises[index]),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<String> _buildOptions(
    Iterable<String> values, {
    required String defaultValue,
  }) {
    final set = <String>{defaultValue};
    for (final value in values) {
      if (value.trim().isNotEmpty) {
        set.add(value);
      }
    }
    return set.toList();
  }

  List<Exercise> _filterExercises(List<Exercise> source) {
    final query = _searchController.text.trim().toLowerCase();

    return source.where((exercise) {
      final matchEquipment = _selectedEquipment == 'All Equipment' ||
          exercise.equipment == _selectedEquipment;
      final matchMuscle =
          _selectedMuscle == 'All Muscles' || exercise.primaryMuscle == _selectedMuscle;
      final matchSearch = query.isEmpty ||
          exercise.name.toLowerCase().contains(query) ||
          exercise.primaryMuscle.toLowerCase().contains(query);

      return matchEquipment && matchMuscle && matchSearch;
    }).toList();
  }

  Future<void> _showOptionPicker({
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final option in options)
                ListTile(
                  title: Text(
                    option,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.of(context).pop(option),
                ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      onSelected(selected);
    }
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search exercise',
        hintStyle: const TextStyle(color: Colors.white60),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF111111),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          title,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}

class _ExerciseListTile extends StatelessWidget {
  const _ExerciseListTile({
    required this.exercise,
    required this.onTap,
  });

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.white,
        backgroundImage:
            exercise.imageUrl.isNotEmpty ? NetworkImage(exercise.imageUrl) : null,
        child: exercise.imageUrl.isEmpty
            ? const Icon(Icons.fitness_center, color: Colors.black)
            : null,
      ),
      title: Text(
        exercise.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        exercise.primaryMuscle,
        style: const TextStyle(color: Colors.white60, fontSize: 14),
      ),
      trailing: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white70),
        ),
        child: Icon(Icons.north_east, color: Theme.of(context).colorScheme.primary, size: 18),
      ),
    );
  }
}

class _EmptyExerciseState extends StatelessWidget {
  const _EmptyExerciseState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'No exercises found in Supabase exercise table.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

