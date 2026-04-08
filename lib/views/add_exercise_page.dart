import 'package:flutter/material.dart';

import '../repository/exercise_repository.dart';
import '../theme/app_colors.dart';

const equipmentOptions = [
  'Bodyweight',
  'Barbell',
  'Weight plates',
  'Kettlebell',
  'Equipment',
  'Dumbbells',
  'Resistance bands',
];

const muscleOptions = [
  'Latissimus dorsi',
  'Biceps',
  'Abs',
  'Quadriceps',
  'Hamstrings',
  'Shoulders',
  'Neck',
  'Forearms',
  'Full body',
  'Triceps',
  'Upper back',
  'Glutes',
  'Lower back',
  'Calves',
  'Trapezius',
  'Chest',
];

class AddExercisePage extends StatefulWidget {
  const AddExercisePage({super.key, required this.repository});

  final ExerciseRepository repository;

  @override
  State<AddExercisePage> createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _howToController = TextEditingController();

  String? _selectedEquipment;
  String? _selectedPrimaryMuscle;
  final Set<String> _selectedSecondaryMuscles = {};

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _howToController.dispose();
    super.dispose();
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select equipment')),
      );
      return;
    }

    if (_selectedPrimaryMuscle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select primary muscle')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.repository.createExercise(
        name: _nameController.text.trim(),
        primaryMuscle: _selectedPrimaryMuscle!,
        muscleGroup: _selectedSecondaryMuscles.join(', '),
        equipment: _selectedEquipment!,
        howTo: _howToController.text.trim(),
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add exercise: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildEquipmentDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        isExpanded: true,
        value: _selectedEquipment,
        hint: const Text(
          'Select Equipment',
          style: TextStyle(color: AppColors.lavender),
        ),
        dropdownColor: AppColors.cardBg,
        underline: const SizedBox.shrink(),
        menuMaxHeight: 200,
        items: equipmentOptions.map((equipment) {
          return DropdownMenuItem<String>(
            value: equipment,
            child: Text(
              equipment,
              style: const TextStyle(color: AppColors.white),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedEquipment = value;
          });
        },
      ),
    );
  }

  Widget _buildPrimaryMuscleSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        isExpanded: true,
        value: _selectedPrimaryMuscle,
        hint: const Text(
          'Select Primary Muscle',
          style: TextStyle(color: AppColors.lavender),
        ),
        dropdownColor: AppColors.cardBg,
        underline: const SizedBox.shrink(),
        menuMaxHeight: 200,
        items: muscleOptions.map((muscle) {
          return DropdownMenuItem<String>(
            value: muscle,
            child: Text(
              muscle,
              style: const TextStyle(color: AppColors.white),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedPrimaryMuscle = value;
            _selectedSecondaryMuscles.remove(value);
          });
        },
      ),
    );
  }

  Widget _buildSecondaryMuscleSelector() {
    final availableMuscles =
        muscleOptions.where((m) => m != _selectedPrimaryMuscle).toList();

    return GestureDetector(
      onTap: () => _showSecondaryMusclePicker(availableMuscles),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedSecondaryMuscles.isEmpty
                  ? 'Select Secondary Muscles'
                  : '${_selectedSecondaryMuscles.length} selected',
              style: TextStyle(
                color: _selectedSecondaryMuscles.isEmpty
                    ? AppColors.lavender
                    : AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.lavender),
          ],
        ),
      ),
    );
  }

  void _showSecondaryMusclePicker(List<String> availableMuscles) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBg,
              title: const Text(
                'Select Secondary Muscles',
                style: TextStyle(color: AppColors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: availableMuscles.map((muscle) {
                    return CheckboxListTile(
                      value: _selectedSecondaryMuscles.contains(muscle),
                      title: Text(
                        muscle,
                        style: const TextStyle(color: AppColors.white),
                      ),
                      activeColor: AppColors.purple,
                      checkColor: AppColors.white,
                      side: BorderSide(
                        color: AppColors.purple.withValues(alpha: 0.5),
                      ),
                      onChanged: (checked) {
                        setDialogState(() {
                          if (checked == true) {
                            _selectedSecondaryMuscles.add(muscle);
                          } else {
                            _selectedSecondaryMuscles.remove(muscle);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done', style: TextStyle(color: AppColors.lavender)),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Widget _buildField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.white),
      validator: (value) {
        if ((value ?? '').trim().isEmpty) {
          return 'Required';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.lavender),
        filled: true,
        fillColor: AppColors.inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.purple.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.purple.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lavender),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.white,
        title: const Text('Add Exercise'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildField(_nameController, 'Exercise Name'),
              const SizedBox(height: 14),
              const Text(
                'Equipment',
                style: TextStyle(
                  color: AppColors.lavender,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildEquipmentDropdown(),
              const SizedBox(height: 14),
              const Text(
                'Primary Muscle',
                style: TextStyle(
                  color: AppColors.lavender,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildPrimaryMuscleSelector(),
              const SizedBox(height: 14),
              const Text(
                'Secondary Muscles',
                style: TextStyle(
                  color: AppColors.lavender,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildSecondaryMuscleSelector(),
              const SizedBox(height: 14),
              _buildField(_howToController, 'Instruction', maxLines: 4),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Exercise'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}









