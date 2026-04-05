import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_application_development/models/daily_goals.dart';
import 'package:mobile_application_development/services/daily_goals_service.dart';

class EditDailyGoalsDialog extends StatefulWidget {
  final DailyGoals currentGoals;
  final int userId;
  final Function(DailyGoals) onSave;
  final double? userWeight;
  final double? userHeight;

  const EditDailyGoalsDialog({
    required this.currentGoals,
    required this.userId,
    required this.onSave,
    this.userWeight,
    this.userHeight,
  });

  @override
  State<EditDailyGoalsDialog> createState() => _EditDailyGoalsDialogState();
}

class _EditDailyGoalsDialogState extends State<EditDailyGoalsDialog> {
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  // For auto-calculation
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  String _gender = 'male';
  String _activityLevel = 'moderately_active';
  String _fitnessGoal = 'maintain';
  bool _showCalculator = false;

  @override
  void initState() {
    super.initState();
    _caloriesController = TextEditingController(
      text: widget.currentGoals.targetCalories?.toString() ?? '',
    );
    _proteinController = TextEditingController(
      text: widget.currentGoals.targetProtein?.toStringAsFixed(1) ?? '',
    );
    _carbsController = TextEditingController(
      text: widget.currentGoals.targetCarbs?.toStringAsFixed(1) ?? '',
    );
    _fatController = TextEditingController(
      text: widget.currentGoals.targetFat?.toStringAsFixed(1) ?? '',
    );

    _ageController = TextEditingController();
    _weightController = TextEditingController(
      text: widget.userWeight != null ? widget.userWeight.toString() : '',
    );
    _heightController = TextEditingController(
      text: widget.userHeight != null ? widget.userHeight.toString() : '',
    );
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _calculateGoals() {
    // Validation: Check if fields are empty
    if (_ageController.text.isEmpty || _weightController.text.isEmpty || _heightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    // Validation: Check if values are valid numbers
    if (age == null || weight == null || height == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please enter valid numbers only'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation: Check realistic ranges
    if (age < 10 || age > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Age must be between 10 and 120 years'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (weight < 30 || weight > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Weight must be between 30 and 300 kg'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (height < 100 || height > 250) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Height must be between 100 and 250 cm'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final calculated = DailyGoalsService.calculateDailyGoals(
        userId: widget.userId,
        ageYears: age,
        weightKg: weight,
        heightCm: height,
        gender: _gender,
        activityLevel: _activityLevel,
        fitnessGoal: _fitnessGoal,
      );

      _caloriesController.text = calculated.targetCalories?.toString() ?? '';
      _proteinController.text = calculated.targetProtein?.toStringAsFixed(1) ?? '';
      _carbsController.text = calculated.targetCarbs?.toStringAsFixed(1) ?? '';
      _fatController.text = calculated.targetFat?.toStringAsFixed(1) ?? '';

      setState(() => _showCalculator = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Goals calculated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveGoals() {
    final calories = int.tryParse(_caloriesController.text);
    final protein = double.tryParse(_proteinController.text);
    final carbs = double.tryParse(_carbsController.text);
    final fat = double.tryParse(_fatController.text);

    if (calories == null || protein == null || carbs == null || fat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please fill all nutrition goals'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedGoals = widget.currentGoals.copyWith(
      targetCalories: calories,
      targetProtein: protein,
      targetCarbs: carbs,
      targetFat: fat,
      updatedAt: DateTime.now(),
    );

    widget.onSave(updatedGoals);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎯 Daily Nutrition Goals',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (!_showCalculator) ...[
                _buildEditMode(),
              ] else ...[
                _buildCalculatorMode(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditMode() {
    return Column(
      children: [
        _buildGoalInput('🔥 Calories', _caloriesController, 'kcal'),
        const SizedBox(height: 12),
        _buildGoalInput('🥚 Protein', _proteinController, 'g'),
        const SizedBox(height: 12),
        _buildGoalInput('🌾 Carbs', _carbsController, 'g'),
        const SizedBox(height: 12),
        _buildGoalInput('🧈 Fat', _fatController, 'g'),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _showCalculator = true),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7F77DD), width: 1.5),
                  foregroundColor: const Color(0xFFAFA9EC),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Auto Calculate'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveGoals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7F77DD),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalculatorMode() {
    return Column(
      children: [
        const Text(
          'Enter your details to calculate optimal goals',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        _buildInputField('Age', _ageController, 'years'),
        const SizedBox(height: 12),
        _buildInputField('Weight', _weightController, 'kg'),
        const SizedBox(height: 12),
        _buildInputField('Height', _heightController, 'cm'),
        const SizedBox(height: 12),
        _buildDropdown(
          'Gender',
          _gender,
          ['male', 'female'],
          (value) => setState(() => _gender = value),
        ),
        const SizedBox(height: 12),
        _buildDropdown(
          'Activity Level',
          _activityLevel,
          ['sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active'],
          (value) => setState(() => _activityLevel = value),
        ),
        const SizedBox(height: 12),
        _buildDropdown(
          'Fitness Goal',
          _fitnessGoal,
          ['lose_weight', 'maintain', 'gain_muscle'],
          (value) => setState(() => _fitnessGoal = value),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            // Back button — outline style
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _showCalculator = false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7F77DD), width: 1.5),
                  foregroundColor: const Color(0xFFAFA9EC),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Calculate button — filled style
            Expanded(
              child: ElevatedButton(
                onPressed: _calculateGoals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7F77DD),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: const Text(
                  'Calculate',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalInput(
    String label,
    TextEditingController controller,
    String unit,
  ) {
    // Calories are integers, others are decimals
    bool isCalories = unit == 'kcal';

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        // Only allow digits and decimal point (except for calories)
        isCalories
            ? FilteringTextInputFormatter.allow(RegExp(r'^\d+'))
            : FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        hintText: isCalories ? 'e.g., 2000' : 'e.g., 150.5',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String unit,
  ) {
    // Determine if decimal is allowed based on field type
    bool allowDecimal = unit == 'kg'; // Only weight allows decimals

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        // Only allow digits and decimal point (for weight)
        allowDecimal
            ? FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
            : FilteringTextInputFormatter.allow(RegExp(r'^\d+'))
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        hintText: allowDecimal ? 'e.g., 75.5' : 'e.g., 30',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item.replaceAll('_', ' ')),
              ))
          .toList(),
      onChanged: (newValue) {
        if (newValue != null) onChanged(newValue);
      },
    );
  }
}

