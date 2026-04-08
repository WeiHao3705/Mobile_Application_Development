import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../controllers/food_controller.dart';
import '../controllers/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import 'widgets/custom_bottom_nav_bar.dart';

class AddNewFoodView extends StatefulWidget {
  final AuthController authController;

  const AddNewFoodView({
    Key? key,
    required this.authController,
  }) : super(key: key);

  @override
  State<AddNewFoodView> createState() => _AddNewFoodViewState();
}

class _AddNewFoodViewState extends State<AddNewFoodView> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  int _selectedNavIndex = 2; // Diet tab (3rd item, 0-indexed)

  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _servingSizeController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: _iconBtn(
              child: const Icon(Icons.chevron_left, color: AppColors.lime, size: 18),
            ),
          ),
        ),
        title: const Text(
          'Add New Food',
          style: TextStyle(
            color: AppColors.lavender,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
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
                'Nutrition per Serving',
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
                  final emoji = category.split(' ')[0];
                  final label = category.split(' ').skip(1).join(' ');
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                        // Clear custom category if switching away from Other
                        if (category != '➕ Other') {
                          _customCategoryController.clear();
                        }
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            emoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? AppColors.yellow : Colors.white,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Custom Category Input (shown when "Other" is selected)
              if (_selectedCategory == '➕ Other') ...[
                const SizedBox(height: 16),
                _buildLabel('CUSTOM CATEGORY'),
                _buildTextField(
                  controller: _customCategoryController,
                  hint: 'e.g. Supplements, Condiments',
                ),
              ],
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
                    'Save Food',
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
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == 2) {
      // Already on Diet tab, no need to navigate
      return;
    }

    // Navigate to the selected tab
    Navigator.of(context).pop();
    Navigator.of(context).pushReplacementNamed('/main');
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.purple),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildMacroCard({
    required String label,
    required TextEditingController controller,
    required Color color,
    required String icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: TextStyle(color: color, fontSize: 8),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'g',
                style: TextStyle(color: color, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              border: InputBorder.none,
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({required Widget child}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lavender.withOpacity(0.55)),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  String _getCategoryEmoji(String categoryName) {
    // Map category names to their emojis
    const categoryMap = {
      'Grains': '🌾',
      'Protein': '🍗',
      'Dairy': '🥛',
      'Fruits': '🍎',
      'Veggies': '🥬',
      'Snacks': '🍿',
      'Drinks': '🥤',
    };

    // Check if it's a predefined category
    for (var entry in categoryMap.entries) {
      if (categoryName.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // For "Other" or custom categories, use a generic icon
    return '➕';
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
    if (_selectedCategory == '➕ Other' && _customCategoryController.text.isEmpty) {
      _showErrorSnackBar('Please enter a custom category name');
      return;
    }
    if (_servingSizeController.text.isEmpty) {
      _showErrorSnackBar('Please enter a serving size');
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

      final servingSize = double.parse(_servingSizeController.text);
      final calories = double.parse(_caloriesController.text);
      // Use 0 as default if empty
      final protein = _proteinController.text.isEmpty ? 0.0 : double.parse(_proteinController.text);
      final carbs = _carbsController.text.isEmpty ? 0.0 : double.parse(_carbsController.text);
      final fat = _fatController.text.isEmpty ? 0.0 : double.parse(_fatController.text);

      final categoryName = _selectedCategory == '➕ Other'
          ? _customCategoryController.text.trim()
          : _selectedCategory!.split(' ').skip(1).join(' ');

      final foodController = context.read<FoodController>();
      final userId = int.tryParse(currentUser.id?.toString() ?? '');
      if (userId == null) {
        _showErrorSnackBar('Invalid user ID. Please login again.');
        return;
      }

      developer.log('DEBUG: Attempting to save food with userId: $userId, category: $categoryName');

      final success = await foodController.createFood(
        foodName: _foodNameController.text.trim(),
        category: categoryName,
        servingSize: servingSize,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        userId: userId,
      );

      developer.log('DEBUG: Save result - $success');
      developer.log('DEBUG: Controller error - ${foodController.errorMessage}');

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Food saved successfully!'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.yellow,
          ),
        );

        _foodNameController.clear();
        _servingSizeController.clear();
        _caloriesController.clear();
        _proteinController.clear();
        _carbsController.clear();
        _fatController.clear();
        _selectedCategory = null;

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context, true);  // Return true to indicate success
          }
        });
      } else {
        developer.log('DEBUG: Food controller error message: ${foodController.errorMessage}');
        _showErrorSnackBar(foodController.errorMessage.isNotEmpty
            ? foodController.errorMessage
            : 'Error saving food. Please try again.');
      }
    } on FormatException catch (e) {
      developer.log('DEBUG: FormatException - $e');
      _showErrorSnackBar('Please enter valid numbers in all fields');
    } catch (e) {
      developer.log('DEBUG: Unexpected error - $e');
      developer.log('DEBUG: Error type - ${e.runtimeType}');
      _showErrorSnackBar('Error saving food. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
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
    _customCategoryController.dispose();
    super.dispose();
  }
}

