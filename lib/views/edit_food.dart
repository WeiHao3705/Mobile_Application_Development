import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../theme/app_colors.dart';
import '../controllers/food_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/food.dart';

class EditFoodView extends StatefulWidget {
  final Food food;
  final AuthController authController;

  const EditFoodView({
    Key? key,
    required this.food,
    required this.authController,
  }) : super(key: key);

  @override
  State<EditFoodView> createState() => _EditFoodViewState();
}

class _EditFoodViewState extends State<EditFoodView> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;

  late TextEditingController _foodNameController;
  late TextEditingController _servingSizeController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  final List<String> _categories = [
    '🌾 Grains',
    '🍗 Protein',
    '🥛 Dairy',
    '🍎 Fruits',
    '🥬 Veggies',
    '🍿 Snacks',
    '🥤 Drinks',
    '➕ Other',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing food data
    _foodNameController = TextEditingController(text: widget.food.foodName);
    _caloriesController = TextEditingController(text: widget.food.caloriesPer100g.toStringAsFixed(1));
    _proteinController = TextEditingController(text: widget.food.proteinPer100g.toStringAsFixed(1));
    _carbsController = TextEditingController(text: widget.food.carbsPer100g.toStringAsFixed(1));
    _fatController = TextEditingController(text: widget.food.fatPer100g.toStringAsFixed(1));
    // Set serving size to 100 by default (since we store per 100g)
    _servingSizeController = TextEditingController(text: '100');

    // Set selected category by matching category name
    _selectedCategory = _categories.firstWhere(
      (cat) => cat.contains(widget.food.category),
      orElse: () => '➕ Other',
    );
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _servingSizeController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade700),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ),
        title: const Text(
          'Edit Food',
          style: TextStyle(
            color: AppColors.purple,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.yellow),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'CUSTOM',
              style: TextStyle(
                color: AppColors.yellow,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food Name
              _buildLabel('FOOD NAME'),
              _buildTextField(
                controller: _foodNameController,
                hint: 'e.g. Homemade Granola',
              ),
              const SizedBox(height: 24),

              // Serving Size
              _buildLabel('SERVING SIZE'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _servingSizeController,
                      hint: '100',
                      isNumeric: true,
                      allowDecimal: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade700),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'g',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Nutrition per Serving
              const Text(
                'Nutrition per 100g',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Calories
              _buildLabel('CALORIES (KCAL)'),
              _buildTextField(
                controller: _caloriesController,
                hint: '0',
                isNumeric: true,
              ),
              const SizedBox(height: 20),

              // Macro Nutrients
              Row(
                children: [
                  Expanded(
                    child: _buildMacroCard(
                      label: 'PROTEIN',
                      controller: _proteinController,
                      color: AppColors.proteinColor,
                      icon: '●',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMacroCard(
                      label: 'CARBS',
                      controller: _carbsController,
                      color: AppColors.yellow,
                      icon: '●',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMacroCard(
                      label: 'FAT',
                      controller: _fatController,
                      color: AppColors.fatColor,
                      icon: '●',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Category
              const Text(
                'Category',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Category Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? AppColors.yellow : Colors.grey.shade700,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        color: isSelected
                            ? AppColors.yellow.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? AppColors.yellow : Colors.white,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveFoodData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: Colors.grey.shade700),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isNumeric = false,
    bool allowDecimal = false,
  }) {
    return TextField(
      controller: controller,
      inputFormatters: isNumeric
          ? [
              allowDecimal
                  ? FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                  : FilteringTextInputFormatter.digitsOnly,
            ]
          : [],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade600),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }

  Widget _buildMacroCard({
    required String label,
    required TextEditingController controller,
    required Color color,
    required String icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: TextStyle(color: color, fontSize: 12),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
            ],
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
              suffixText: 'g',
              suffixStyle: TextStyle(color: color),
            ),
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _saveFoodData() async {
    if (_foodNameController.text.isEmpty) {
      _showErrorSnackBar('Please enter a food name');
      return;
    }
    if (_selectedCategory == null) {
      _showErrorSnackBar('Please select a category');
      return;
    }
    if (_caloriesController.text.isEmpty) {
      _showErrorSnackBar('Please enter calories');
      return;
    }

    try {
      final currentUser = widget.authController.currentUser;

      developer.log('DEBUG: Current user - $currentUser');

      if (currentUser == null) {
        _showErrorSnackBar('User not authenticated. Please login first.');
        return;
      }

      final calories = double.parse(_caloriesController.text);
      final protein = _proteinController.text.isEmpty ? 0.0 : double.parse(_proteinController.text);
      final carbs = _carbsController.text.isEmpty ? 0.0 : double.parse(_carbsController.text);
      final fat = _fatController.text.isEmpty ? 0.0 : double.parse(_fatController.text);

      final categoryName = _selectedCategory!.split(' ').skip(1).join(' ');
      final foodController = context.read<FoodController>();
      final int userId = currentUser.id!;

      developer.log('DEBUG: Attempting to update food with foodId: ${widget.food.foodId}');

      final success = await foodController.updateFood(
        foodId: widget.food.foodId,
        foodName: _foodNameController.text.trim(),
        category: categoryName,
        caloriesPer100g: calories,
        proteinPer100g: protein,
        carbsPer100g: carbs,
        fatPer100g: fat,
        userId: userId,
      );

      developer.log('DEBUG: Update result - $success');

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Food updated successfully!'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.yellow,
          ),
        );

        if (mounted) {
          Navigator.pop(context, true);  // Return true to indicate success
        }
      } else {
        developer.log('DEBUG: Food controller error message: ${foodController.errorMessage}');
        _showErrorSnackBar(foodController.errorMessage.isNotEmpty
            ? foodController.errorMessage
            : 'Failed to update food. Please try again.');
      }
    } catch (e) {
      developer.log('DEBUG: Exception - $e');
      _showErrorSnackBar('An error occurred: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      ),
    );
  }
}

