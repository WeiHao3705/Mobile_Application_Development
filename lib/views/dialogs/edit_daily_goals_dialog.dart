import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_application_development/models/daily_goals.dart';
import 'package:mobile_application_development/services/daily_goals_service.dart';
import 'package:mobile_application_development/theme/app_colors.dart';

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

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: AppColors.nutritionSubtleText,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSegmentedControl(
    String id,
    String selectedValue,
    List<String> values,
    List<String> labels,
    Function(String) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.nutritionCardBg),
        borderRadius: BorderRadius.circular(99),
        color: AppColors.nutritionDarkBg,
      ),
      child: Row(
        children: List.generate(
          values.length,
          (index) => Expanded(
            child: GestureDetector(
              onTap: () => onChanged(values[index]),
              child: Container(
                decoration: BoxDecoration(
                  color: selectedValue == values[index]
                      ? AppColors.nutritionPurple
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selectedValue == values[index]
                        ? AppColors.white
                        : AppColors.nutritionSubtleText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String unit,
    String placeholder,
  ) {
    bool allowDecimal = unit == 'kg';

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        allowDecimal
            ? FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
            : FilteringTextInputFormatter.allow(RegExp(r'^\d+'))
      ],
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.white,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.nutritionCardBg),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.nutritionCardBg, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.nutritionPurple, width: 1),
        ),
        filled: true,
        fillColor: AppColors.nutritionCardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintText: placeholder,
        hintStyle: const TextStyle(color: AppColors.nutritionSubtleText),
        suffixText: unit,
        suffixStyle: const TextStyle(color: AppColors.nutritionSubtleText, fontSize: 12),
      ),
    );
  }

  Widget _buildDropdownField(
    String selectedValue,
    List<String> values,
    Function(String) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.white,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.nutritionCardBg),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.nutritionCardBg, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.nutritionPurple, width: 1),
        ),
        filled: true,
        fillColor: AppColors.nutritionCardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: values
          .map((value) => DropdownMenuItem(
                value: value,
                child: Text(
                  value.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.white,
                  ),
                ),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      isExpanded: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.nutritionDarkBg,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily nutrition goals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _showCalculator
                    ? "We'll use these to estimate your targets"
                    : 'Tap any value to edit',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.nutritionSubtleText,
                ),
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
        // Macro Cards Grid
        Column(
          children: [
            // Calories (spans full width)
            _buildMacroCard('CALORIES', _caloriesController, 'kcal / day', true),
            const SizedBox(height: 10),
            // Protein and Carbs in a row
            Row(
              children: [
                Expanded(
                  child: _buildMacroCard('PROTEIN', _proteinController, 'g', false),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMacroCard('CARBS', _carbsController, 'g', false),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Fat (spans full width)
            _buildMacroCard('FAT', _fatController, 'g / day', true),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _showCalculator = true),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.nutritionPurple, width: 1.5),
                  foregroundColor: AppColors.nutritionPurple,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Auto-calculate',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveGoals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.nutritionPurple,
                  foregroundColor: AppColors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroCard(String label, TextEditingController controller, String unit, bool isLarge) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.nutritionCardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.nutritionSubtleText,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.03,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    label == 'CALORIES'
                        ? FilteringTextInputFormatter.allow(RegExp(r'^\d+'))
                        : FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
                  ],
                  style: TextStyle(
                    fontSize: isLarge ? 28 : 20,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: isLarge ? '2000' : '150',
                    hintStyle: TextStyle(color: AppColors.nutritionSubtleText),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.nutritionSubtleText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorMode() {
    return Column(
      children: [
        // Gender Selector
        _buildFieldLabel('Gender'),
        const SizedBox(height: 8),
        _buildSegmentedControl(
          'gender',
          _gender,
          ['male', 'female'],
          ['Male', 'Female'],
          (value) => setState(() => _gender = value),
        ),
        const SizedBox(height: 16),

        // Age, Weight, Height in 2x2 grid
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Age'),
                  const SizedBox(height: 5),
                  _buildInputField(_ageController, 'years', '25'),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Weight (kg)'),
                  const SizedBox(height: 5),
                  _buildInputField(_weightController, 'kg', '70'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFieldLabel('Height (cm)'),
        const SizedBox(height: 5),
        _buildInputField(_heightController, 'cm', '170'),
        const SizedBox(height: 16),

        // Activity Level Dropdown
        _buildFieldLabel('Activity level'),
        const SizedBox(height: 5),
        _buildDropdownField(
          _activityLevel,
          ['sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active'],
          (value) => setState(() => _activityLevel = value),
        ),
        const SizedBox(height: 16),

        // Fitness Goal Selector
        _buildFieldLabel('Goal'),
        const SizedBox(height: 8),
        _buildSegmentedControl(
          'goal',
          _fitnessGoal,
          ['lose_weight', 'maintain', 'gain_muscle'],
          ['Lose weight', 'Maintain', 'Gain muscle'],
          (value) => setState(() => _fitnessGoal = value),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _showCalculator = false),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.nutritionPurple, width: 1.5),
                  foregroundColor: AppColors.nutritionPurple,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _calculateGoals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.nutritionPurple,
                  foregroundColor: AppColors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text(
                  'Calculate',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

