import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../theme/app_colors.dart';
import '../controllers/meal_controller.dart';
import '../controllers/food_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/meal_log.dart';
import '../models/food.dart';
import '../repository/meal_food_repository.dart';
import 'add_new_food.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _SelectedMealFood {
  _SelectedMealFood({required this.food, required this.quantity});
  final Food food;
  double quantity;
}

class EditMealView extends StatefulWidget {
  final MealLog meal;
  final AuthController authController;

  const EditMealView({
    Key? key,
    required this.meal,
    required this.authController,
  }) : super(key: key);

  @override
  State<EditMealView> createState() => _EditMealViewState();
}

class _EditMealViewState extends State<EditMealView> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, _SelectedMealFood> _selected = {};
  late TextEditingController _mealTypeController;
  late DateTime _selectedDate;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = true;

  static const List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
  late String _selectedMealType;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.meal.mealType;
    _selectedDate = widget.meal.mealDate;
    _mealTypeController = TextEditingController(text: _selectedMealType);

    // Load meal foods on init
    _loadMealFoods();
  }

  Future<void> _loadMealFoods() async {
    try {
      developer.log('🔵 Loading existing meal foods for meal ${widget.meal.mealId}');

      if (widget.meal.mealId == null || widget.meal.mealId! <= 0) {
        developer.log('⚠️ No meal ID available, skipping load');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // Get meal food repository
      final supabaseClient = Supabase.instance.client;
      final mealFoodRepo = MealFoodRepository(supabase: supabaseClient);
      final foodController = context.read<FoodController>();

      // Fetch existing meal foods
      final mealFoods = await mealFoodRepo.getMealFoodsByMealId(widget.meal.mealId!);
      developer.log('📊 Found ${mealFoods.length} foods in this meal');

      if (mealFoods.isEmpty) {
        developer.log('ℹ️ No foods found in this meal');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // Load user foods to get food details
      final allFoods = foodController.userFoods;
      if (allFoods.isEmpty) {
        developer.log('⚠️ User foods not loaded, fetching...');
        await foodController.fetchAllFoods();
      }

      // Map meal foods to _selected
      final Map<int, _SelectedMealFood> selectedFoods = {};

      for (final mealFood in mealFoods) {
        developer.log('🔍 Processing food ID: ${mealFood.foodId}, Quantity: ${mealFood.quantity}g');

        // Find the food from foodController
        Food? foundFood;
        try {
          foundFood = foodController.userFoods.firstWhere(
            (f) => f.foodId == mealFood.foodId,
          );
        } catch (e) {
          developer.log('❌ Food ID ${mealFood.foodId} not found in user foods');
          continue;
        }

        if (foundFood != null) {
          selectedFoods[mealFood.foodId] = _SelectedMealFood(
            food: foundFood,
            quantity: mealFood.quantity,
          );
          developer.log('✅ Added ${foundFood.foodName} (${mealFood.quantity}g) to selected foods');
        }
      }

      if (mounted) {
        setState(() {
          _selected.addAll(selectedFoods);
          _isLoading = false;
        });
      }

      developer.log('✅ Finished loading ${selectedFoods.length} meal foods');
    } catch (e) {
      developer.log('❌ Error loading meal foods: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading meal: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _mealTypeController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      // Keep the time but change the date
      final pickedDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
      setState(() => _selectedDate = pickedDateTime);
    }
  }

  void _showTimePicker() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _navigateToAddFood() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddNewFoodView(
          authController: widget.authController,
        ),
      ),
    );

    if (result == true && mounted) {
      context.read<FoodController>().fetchAllFoods();
    }
  }

  void _updateMeal() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one food to the meal')),
      );
      return;
    }

    // Prepare foods with quantities
    final Map<int, Map<String, dynamic>> foodsWithQuantities = {};
    for (final entry in _selected.entries) {
      foodsWithQuantities[entry.key] = {
        'food_id': entry.key,
        'quantity': entry.value.quantity,
        'unit': 'g',
      };
    }

    final mealController = context.read<MealController>();

    try {
      // Update meal with new foods and recalculate nutrition
      final success = await mealController.updateMeal(
        mealId: widget.meal.mealId ?? 0,
        mealType: _selectedMealType,
        mealDate: _selectedDate,
        userId: widget.meal.userId,
        foodsWithQuantities: foodsWithQuantities,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Meal updated successfully!'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.lime,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${mealController.errorMessage}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          'Edit Meal',
          style: TextStyle(
            color: AppColors.purple,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.lime))
          : Consumer<MealController>(
              builder: (context, mealController, _) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Meal Type Selection
                        _buildLabel('MEAL TYPE'),
                        Wrap(
                          spacing: 8,
                          children: _mealTypes.map((type) {
                            final isSelected = _selectedMealType == type;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedMealType = type);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.yellow
                                        : Colors.grey.shade700,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: isSelected
                                      ? AppColors.yellow.withOpacity(0.1)
                                      : Colors.transparent,
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.yellow
                                        : Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Date & Time Selection
                        _buildLabel('DATE & TIME'),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _showDatePicker,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade700,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color(0xFF2A2A2A),
                                  ),
                                  child: Text(
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _showTimePicker,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade700,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color(0xFF2A2A2A),
                                  ),
                                  child: Text(
                                    '${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Foods Section
                        Row(
                          children: [
                            const Text(
                              'Foods',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _navigateToAddFood,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lime.withOpacity(0.2),
                                  border: Border.all(
                                    color: AppColors.lime.withOpacity(0.6),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, color: AppColors.lime, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Add Food',
                                      style: TextStyle(
                                        color: AppColors.lime,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Selected Foods List
                        if (_selected.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade700),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'No foods added. Tap "Add Food" to add items.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        else
                          Consumer<FoodController>(
                            builder: (context, foodController, _) {
                              // Calculate macros
                              double totalProtein = 0;
                              double totalCarbs = 0;
                              double totalFats = 0;

                              for (final selectedFood in _selected.values) {
                                final quantity = selectedFood.quantity;
                                totalProtein +=
                                    (selectedFood.food.proteinPer100g / 100) *
                                        quantity;
                                totalCarbs +=
                                    (selectedFood.food.carbsPer100g / 100) *
                                        quantity;
                                totalFats += (selectedFood.food.fatPer100g / 100) *
                                    quantity;
                              }

                              return Column(
                                children: [
                                  ..._selected.entries.map((entry) {
                                    final food = entry.value.food;
                                    final quantity = entry.value.quantity;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _buildFoodItem(
                                        food: food,
                                        quantity: quantity,
                                        onQuantityChanged: (newQty) {
                                          setState(() {
                                            entry.value.quantity = newQty;
                                          });
                                        },
                                        onRemove: () {
                                          setState(() {
                                            _selected.remove(entry.key);
                                          });
                                        },
                                      ),
                                    );
                                  }).toList(),
                                  const SizedBox(height: 16),
                                  // Macro Summary
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.lavender.withOpacity(0.3),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: AppColors.cardBg,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Meal Macros',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            _buildMacroDisplay(
                                              label: 'Protein',
                                              value: totalProtein.toStringAsFixed(1),
                                              unit: 'g',
                                              color: AppColors.proteinColor,
                                            ),
                                            _buildMacroDisplay(
                                              label: 'Carbs',
                                              value: totalCarbs.toStringAsFixed(1),
                                              unit: 'g',
                                              color: AppColors.yellow,
                                            ),
                                            _buildMacroDisplay(
                                              label: 'Fat',
                                              value: totalFats.toStringAsFixed(1),
                                              unit: 'g',
                                              color: AppColors.fatColor,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        const SizedBox(height: 32),

                        // Foods Selector (Add more foods)
                        Consumer<FoodController>(
                          builder: (context, foodController, _) {
                            if (foodController.isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.lime,
                                ),
                              );
                            }

                            final allFoods = foodController.userFoods;
                            final filteredFoods = allFoods
                                .where((food) =>
                                    food.foodName
                                        .toLowerCase()
                                        .contains(_searchQuery.toLowerCase()) &&
                                    !_selected.containsKey(food.foodId))
                                .toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Add Foods to Meal',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _searchCtrl,
                                  onChanged: (value) {
                                    setState(() => _searchQuery = value);
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Search foods...',
                                    prefixIcon: const Icon(Icons.search,
                                        color: Colors.grey),
                                    filled: true,
                                    fillColor: const Color(0xFF2A2A2A),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (filteredFoods.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade700,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'No foods available',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ...filteredFoods.map((food) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _buildFoodSelector(food),
                                    );
                                  }).toList(),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: mealController.isLoading
                                ? null
                                : _updateMeal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.lime,
                              foregroundColor: AppColors.nearBlack,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: mealController.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.nearBlack,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Update Meal',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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

  Widget _buildFoodItem({
    required Food food,
    required double quantity,
    required ValueChanged<double> onQuantityChanged,
    required VoidCallback onRemove,
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
              Expanded(
                child: Text(
                  food.foodName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.close, color: Colors.red, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildQuantityInput(
                  value: quantity,
                  onChanged: onQuantityChanged,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(food.caloriesPer100g / 100 * quantity).toStringAsFixed(0)} kcal',
                style: const TextStyle(
                  color: AppColors.lime,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityInput({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              final newValue = (value - 50).clamp(0, double.infinity).toDouble();
              onChanged(newValue);
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.remove, color: Colors.grey, size: 16),
            ),
          ),
          Expanded(
            child: TextField(
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              controller: TextEditingController(text: value.toStringAsFixed(0))
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: value.toStringAsFixed(0).length),
                ),
              onChanged: (newValue) {
                if (newValue.isNotEmpty) {
                  onChanged(double.tryParse(newValue) ?? value);
                }
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              onChanged(value + 50);
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.add, color: Colors.grey, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodSelector(Food food) {
    return GestureDetector(
      onTap: () {
        _showAddFoodDialog(food);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lime.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.foodName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${food.caloriesPer100g.toStringAsFixed(0)} kcal per 100g',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lime.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.add, color: AppColors.lime, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFoodDialog(Food food) {
    final quantityController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          'Add ${food.foodName}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quantity (grams)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '100',
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lime)),
          ),
          TextButton(
            onPressed: () {
              final quantity = double.tryParse(quantityController.text) ?? 100;
              setState(() {
                _selected[food.foodId] =
                    _SelectedMealFood(food: food, quantity: quantity);
              });
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: AppColors.lime)),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroDisplay({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$label $unit',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
