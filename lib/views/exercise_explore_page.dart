import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/exercise.dart';
import '../repository/exercise_repository.dart';
import '../theme/app_colors.dart';
import 'exercise_detail_page.dart';

class ExerciseExplorePage extends StatefulWidget {
  const ExerciseExplorePage({
    super.key,
    this.selectable = false,
    this.singleSelection = false,
    this.initialSelectedExerciseIds = const <String>{},
  });

  final bool selectable;
  final bool singleSelection;
  final Set<String> initialSelectedExerciseIds;

  @override
  State<ExerciseExplorePage> createState() => _ExerciseExplorePageState();
}

class _ExerciseExplorePageState extends State<ExerciseExplorePage> {
  static const String _recentSearchesStorageKey = 'exercise_recent_searches';
  static const int _maxRecentSearches = 8;

  late final ExerciseRepository _repository;
  late Future<List<Exercise>> _exercisesFuture;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _selectedEquipment = 'All Equipment';
  String _selectedMuscle = 'All Muscles';

  final Set<String> _selectedExerciseIds = <String>{};
  List<Exercise> _latestExercises = const <Exercise>[];
  List<String> _recentSearches = <String>[];

  @override
  void initState() {
    super.initState();
    _repository = ExerciseRepository(supabase: Supabase.instance.client);
    _exercisesFuture = _repository.getAllExercises();
    _selectedExerciseIds.addAll(widget.initialSelectedExerciseIds);
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchChanged);
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onSearchChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSearches = prefs.getStringList(_recentSearchesStorageKey) ?? <String>[];
    if (!mounted) {
      return;
    }
    setState(() {
      _recentSearches = savedSearches.where((value) => value.trim().isNotEmpty).toList();
    });
  }

  Future<void> _saveRecentSearch(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return;
    }

    final next = <String>[..._recentSearches];
    next.removeWhere((item) => item.toLowerCase() == normalized.toLowerCase());
    next.insert(0, normalized);
    if (next.length > _maxRecentSearches) {
      next.removeRange(_maxRecentSearches, next.length);
    }

    if (mounted) {
      setState(() {
        _recentSearches = next;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesStorageKey, next);
  }

  Future<void> _removeRecentSearch(String query) async {
    final next = _recentSearches
        .where((item) => item.toLowerCase() != query.toLowerCase())
        .toList();

    setState(() {
      _recentSearches = next;
    });

    final prefs = await SharedPreferences.getInstance();
    if (next.isEmpty) {
      await prefs.remove(_recentSearchesStorageKey);
      return;
    }
    await prefs.setStringList(_recentSearchesStorageKey, next);
  }

  List<String> _recentSearchMatches() {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _recentSearches
        : _recentSearches.where((item) => item.toLowerCase().contains(query)).toList();
    return filtered.take(3).toList();
  }

  void _useRecentSearch(String query) {
    _searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _searchFocusNode.unfocus();
    _saveRecentSearch(query);
  }

  void _openExerciseDetail(Exercise exercise) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExerciseDetailPage(exercise: exercise),
      ),
    );
  }

  void _toggleExerciseSelection(String exerciseId) {
    setState(() {
      if (widget.singleSelection) {
        _selectedExerciseIds
          ..clear()
          ..add(exerciseId);
        return;
      }

      if (_selectedExerciseIds.contains(exerciseId)) {
        _selectedExerciseIds.remove(exerciseId);
      } else {
        _selectedExerciseIds.add(exerciseId);
      }
    });
  }

  void _returnSelectedExercises() {
    final selectedExercises = _latestExercises
        .where((exercise) => _selectedExerciseIds.contains(exercise.id))
        .toList();
    Navigator.of(context).pop(selectedExercises);
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
          tooltip: 'Back to Workout',
        ),
        title: Text(
          widget.selectable
              ? (widget.singleSelection ? 'Choose Exercise' : 'Choose Exercises')
              : 'Exercise',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          if (widget.selectable)
            TextButton(
              onPressed: _returnSelectedExercises,
              child: Text(
                'Done',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
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
            _latestExercises = allExercises;
            final filteredExercises = _filterExercises(allExercises);
            final equipmentOptions = _buildOptions(
              allExercises.map((item) => item.equipment),
              defaultValue: 'All Equipment',
            );
            final muscleOptions = _buildOptions(
              allExercises.map((item) => item.primaryMuscle),
              defaultValue: 'All Muscles',
            );
            final recentMatches = _recentSearchMatches();
            final showSearchDropdown = _searchFocusNode.hasFocus && recentMatches.isNotEmpty;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        children: [
                          _SearchField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onSubmitted: _saveRecentSearch,
                          ),
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
                      if (showSearchDropdown)
                        Positioned(
                          top: 54,
                          left: 0,
                          right: 0,
                          child: TextFieldTapRegion(
                            child: _SearchHistoryDropdown(
                              items: recentMatches,
                              onTapRecentSearch: _useRecentSearch,
                              onRemoveRecentSearch: _removeRecentSearch,
                            ),
                          ),
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
                          separatorBuilder: (context, index) =>
                              const Divider(color: Colors.white12, height: 1),
                          itemBuilder: (context, index) {
                            final exercise = filteredExercises[index];
                            return _ExerciseListTile(
                              exercise: exercise,
                              selectable: widget.selectable,
                              singleSelection: widget.singleSelection,
                              isSelected: _selectedExerciseIds.contains(exercise.id),
                              onTap: () {
                                if (widget.selectable) {
                                  _toggleExerciseSelection(exercise.id);
                                  return;
                                }
                                _openExerciseDetail(exercise);
                              },
                              onOpenDetails: () => _openExerciseDetail(exercise),
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
          exercise.hasEquipment(_selectedEquipment);
      final matchMuscle =
          _selectedMuscle == 'All Muscles' || exercise.primaryMuscle == _selectedMuscle;
      final matchSearch = query.isEmpty ||
          exercise.name.toLowerCase().contains(query) ||
          exercise.primaryMuscle.toLowerCase().contains(query) ||
          exercise.equipment.toLowerCase().contains(query);

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
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    return ListTile(
                      title: Text(
                        option,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () => Navigator.of(context).pop(option),
                    );
                  },
                ),
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
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: const TextStyle(color: Colors.white),
      textInputAction: TextInputAction.search,
      onTapOutside: (_) => focusNode.unfocus(),
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: 'Search for an item...',
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

class _SearchHistoryDropdown extends StatelessWidget {
  const _SearchHistoryDropdown({
    required this.items,
    required this.onTapRecentSearch,
    required this.onRemoveRecentSearch,
  });

  final List<String> items;
  final ValueChanged<String> onTapRecentSearch;
  final ValueChanged<String> onRemoveRecentSearch;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111111),
      elevation: 14,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 170),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: items.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, color: Colors.white12),
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 8),
              title: Text(
                item,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Text(
                    'x',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  onPressed: () => onRemoveRecentSearch(item),
                  tooltip: 'Delete search',
                ),
              ),
              onTap: () => onTapRecentSearch(item),
            );
          },
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
    required this.onOpenDetails,
    required this.selectable,
    required this.singleSelection,
    required this.isSelected,
  });

  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback onOpenDetails;
  final bool selectable;
  final bool singleSelection;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectable)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                singleSelection
                    ? (isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked)
                    : (isSelected ? Icons.check_circle : Icons.radio_button_unchecked),
                color: isSelected ? theme.colorScheme.primary : Colors.white54,
                size: 22,
              ),
            ),
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            backgroundImage:
                exercise.imageUrl.isNotEmpty ? NetworkImage(exercise.imageUrl) : null,
            child: exercise.imageUrl.isEmpty
                ? const Icon(Icons.fitness_center, color: Colors.black)
                : null,
          ),
        ],
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
      trailing: InkWell(
        onTap: onOpenDetails,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white70),
          ),
          child: Icon(
            Icons.north_east,
            color: theme.colorScheme.primary,
            size: 18,
          ),
        ),
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
