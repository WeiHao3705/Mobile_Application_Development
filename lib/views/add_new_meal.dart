import 'package:flutter/material.dart';
import 'package:mobile_application_development/theme/app_colors.dart';
import 'package:mobile_application_development/models/food.dart';
import 'package:mobile_application_development/views/widgets/custom_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/food_controller.dart';
import '../controllers/meal_controller.dart';
import 'add_new_food.dart';
import 'edit_food.dart';

class _SelectedItem {
  _SelectedItem({required this.food, required this.qty});
  final Food food;
  int qty;
}



class AddNewMealPage extends StatefulWidget {
  final AuthController authController;

  const AddNewMealPage({
    super.key,
    required this.authController,
  });

  @override
  State<AddNewMealPage> createState() => _AddNewMealPageState();
}

class _AddNewMealPageState extends State<AddNewMealPage> {
  String _activeCategory = 'All';
  String _searchQuery   = '';
  final Map<int, _SelectedItem> _selected = {};
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _noteCtrl   = TextEditingController();
  bool _showToast = false;
  int _selectedNavIndex = 2; // Diet tab (3rd item, 0-indexed)

  // Meal type selection - will be set in initState based on current time
  late String _selectedMealType;
  static const List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  // Batch deletion state
  bool _isBatchDeleteMode = false;
  final Set<int> _selectedForDeletion = {};

  @override
  void initState() {
    super.initState();
    // Load all foods via controller
    Future.microtask(() {
      context.read<FoodController>().fetchAllFoods();
    });

    // Auto-assign meal type based on current time
    _selectedMealType = _getDefaultMealType();
  }

  String _getDefaultMealType() {
    final now = DateTime.now();
    final hour = now.hour;
    final offset = now.timeZoneOffset;

    if (hour >= 5 && hour < 11) {
      return 'Breakfast';
    } else if (hour >= 11 && hour < 15) {
      return 'Lunch';
    } else if (hour >= 15 && hour < 18) {
      return 'Snacks';
    } else if (hour >= 18 && hour < 22) {
      return 'Dinner';
    } else {
      return 'Snacks';
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

    // If a new food was added, refresh the list
    if (result == true) {
      if (mounted) {
        context.read<FoodController>().fetchAllFoods();
      }
    }
  }

  Future<void> _navigateToEditFood(Food food) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditFoodView(
          food: food,
          authController: widget.authController,
        ),
      ),
    );

    // If food was edited, refresh the list
    if (result == true && mounted) {
      await context.read<FoodController>().fetchAllFoods();
    }
  }

  void _toggleBatchDeleteMode() {
    setState(() {
      _isBatchDeleteMode = !_isBatchDeleteMode;
      if (!_isBatchDeleteMode) {
        _selectedForDeletion.clear();
      }
    });
  }

  void _toggleFoodSelection(int foodId) {
    setState(() {
      if (_selectedForDeletion.contains(foodId)) {
        _selectedForDeletion.remove(foodId);
      } else {
        _selectedForDeletion.add(foodId);
      }
    });
  }

  Future<void> _deleteBatchFoods() async {
    if (_selectedForDeletion.isEmpty) return;

    final count = _selectedForDeletion.length;

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text(
          'Delete Multiple Foods?',
          style: TextStyle(color: AppColors.white),
        ),
        content: Text(
          'Are you sure you want to delete $count selected food(s)? This action cannot be undone.',
          style: const TextStyle(color: AppColors.lavender),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lime)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!shouldDelete) return;

    // Delete foods
    final foodController = context.read<FoodController>();
    int successCount = 0;
    int failureCount = 0;

    for (final foodId in _selectedForDeletion) {
      try {
        final success = await foodController.deleteFood(foodId);
        if (success) {
          successCount++;
        } else {
          failureCount++;
        }
      } catch (e) {
        failureCount++;
      }
    }

    if (context.mounted) {
      _selectedForDeletion.clear();
      _isBatchDeleteMode = false;

      // Refresh the food list
      await foodController.fetchAllFoods();

      // Show result message
      String message = '';
      if (failureCount == 0) {
        message = '✓ $successCount food(s) deleted successfully!';
      } else {
        message = '⚠️ Deleted $successCount, failed $failureCount';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: failureCount == 0 ? Colors.green : Colors.orange,
        ),
      );

      setState(() {});
    }
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  List<Food> get _allFoods => context.read<FoodController>().userFoods;

  List<Food> get _filtered => _allFoods.where((f) {
    final matchCat = _activeCategory == 'All' || f.category == _activeCategory;
    final matchQ   = _searchQuery.isEmpty || f.foodName.toLowerCase().contains(_searchQuery.toLowerCase());
    return matchCat && matchQ;
  }).toList();

  /// Calculate total calories: each qty increment = 100g
  /// Formula: (caloriesPer100g / 100) * (qty * 100g)
  double get _totalKcal => _selected.values.fold(0.0, (s, i) => s + ((i.food.caloriesPer100g / 100.0) * (i.qty * 100.0)));
  
  /// Calculate total protein: each qty increment = 100g
  double get _totalProtein => _selected.values.fold(0.0, (s, i) => s + ((i.food.proteinPer100g / 100.0) * (i.qty * 100.0)));
  
  /// Calculate total carbs: each qty increment = 100g
  double get _totalCarbs => _selected.values.fold(0.0, (s, i) => s + ((i.food.carbsPer100g / 100.0) * (i.qty * 100.0)));
  
  /// Calculate total fat: each qty increment = 100g
  double get _totalFat => _selected.values.fold(0.0, (s, i) => s + ((i.food.fatPer100g / 100.0) * (i.qty * 100.0)));

  void _changeQty(int id, int delta) {
    setState(() {
      if (!_selected.containsKey(id)) {
        final food = _allFoods.firstWhere((f) => f.foodId == id);
        _selected[id] = _SelectedItem(food: food, qty: 0);
      }
      _selected[id]!.qty += delta;
      if (_selected[id]!.qty <= 0) _selected.remove(id);
    });
  }

  Future<void> _logMeal() async {
    if (_selected.isEmpty) return;

    // Get the current user
    final authController = widget.authController;
    if (authController.currentUser == null) {
      _showErrorSnackbar('User not logged in');
      return;
    }

    final userId = authController.currentUser!.id;
    if (userId == null) {
      _showErrorSnackbar('Invalid user ID');
      return;
    }

    // Prepare foods with quantities
    final foodsWithQuantities = <int, Map<String, dynamic>>{};
    for (final entry in _selected.entries) {
      // Convert qty multiplier to grams (each increment = 100g)
      final quantityInGrams = entry.value.qty * 100.0;

      foodsWithQuantities[entry.key] = {
        'food_id': entry.key,
        'quantity': quantityInGrams, // Convert to grams for calorie calculation
        'unit': 'g', // Default unit is grams
      };
    }

    // Show loading state
    if (!mounted) return;
    _showLoadingDialog();

    try {
      // Log the meal
      final mealController = context.read<MealController>();
      final success = await mealController.logMeal(
        userId: int.parse(userId.toString()),
        mealType: _selectedMealType, // Use selected meal type
        mealDate: DateTime.now(),
        foodsWithQuantities: foodsWithQuantities,
      );

      if (!mounted) return;

      // Close loading dialog safely
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (success) {
        // Show success toast and reset form
        setState(() => _showToast = true);
        _searchCtrl.clear();
        _noteCtrl.clear();
        _selected.clear();

        Future.delayed(const Duration(milliseconds: 2200), () {
          if (mounted) {
            setState(() => _showToast = false);
            // Pop back to previous screen
            Navigator.of(context).pop(true);
          }
        });
      } else {
        _showErrorSnackbar(mealController.errorMessage);
      }
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      _showErrorSnackbar('Error saving meal: ${e.toString()}');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: AppColors.cardBg,
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.lime),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Saving meal...',
                style: TextStyle(color: AppColors.lavender),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppColors.white),
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Consumer<FoodController>(
          builder: (context, foodController, _) {
            // Get foods from the controller parameter (which is being watched)
            final allFoods = foodController.userFoods;

            // Compute categories from the foods
            final categories = {'All'};
            for (var food in allFoods) {
              categories.add(food.category);
            }
            final categoriesList = categories.toList();

            // Filter foods based on search and category
            final filtered = allFoods.where((f) {
              final matchCat = _activeCategory == 'All' || f.category == _activeCategory;
              final matchQ   = _searchQuery.isEmpty || f.foodName.toLowerCase().contains(_searchQuery.toLowerCase());
              return matchCat && matchQ;
            }).toList();

            return Stack(
              children: [
                if (foodController.isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.lime),
                  )
                else if (foodController.errorMessage.isNotEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(foodController.errorMessage, style: const TextStyle(color: AppColors.slateGray, fontSize: 14)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => foodController.fetchAllFoods(),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.lime),
                          child: const Text('Retry', style: TextStyle(color: AppColors.nearBlack)),
                        ),
                      ],
                    ),
                  )
                else
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 28, 18, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 18),
                        _buildMealTypeSelector(),
                        const SizedBox(height: 14),
                        _buildSearchBar(),
                        const SizedBox(height: 12),
                        _buildCategoryChips(categoriesList),
                        const SizedBox(height: 14),
                        _buildFoodList(filtered, allFoods),
                        if (_selected.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _buildSelectedSummary(),
                        ],
                        const SizedBox(height: 14),
                        _buildNoteField(),
                        const SizedBox(height: 16),
                        _buildLogButton(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                if (_showToast) _buildToast(),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    if (_isBatchDeleteMode) {
      return Row(
        children: [
          GestureDetector(
            onTap: _toggleBatchDeleteMode,
            child: _iconBtn(
              child: const Icon(Icons.close, color: AppColors.lime, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Delete ${_selectedForDeletion.length} food(s)',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          if (_selectedForDeletion.isNotEmpty)
            GestureDetector(
              onTap: _deleteBatchFoods,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.delete, color: Colors.red, size: 14),
                    SizedBox(width: 4),
                    Text('Delete All',
                      style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: _iconBtn(
            child: const Icon(Icons.chevron_left, color: AppColors.lime, size: 18),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Add New Meal',
            style: const TextStyle(
              color: AppColors.lavender,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        // Batch delete mode toggle
        GestureDetector(
          onTap: _toggleBatchDeleteMode,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.15),
              border: Border.all(color: AppColors.yellow.withOpacity(0.6)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.delete_outline, color: AppColors.yellow, size: 13),
                SizedBox(width: 3),
                Text('Delete',
                  style: TextStyle(color: AppColors.yellow, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: _navigateToAddFood,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lime.withOpacity(0.15),
              border: Border.all(color: AppColors.lime.withOpacity(0.6)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add, color: AppColors.lime, size: 13),
                SizedBox(width: 3),
                Text('Add New Food',
                  style: TextStyle(color: AppColors.lime, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
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


  // ── Meal Type Selector ─────────────────────────────────────────────────────

  Widget _buildMealTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meal Type',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _mealTypes.map((mealType) {
              final isSelected = _selectedMealType == mealType;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMealType = mealType;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.lime : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AppColors.lime : AppColors.lavender.withOpacity(0.4),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getMealTypeEmoji(mealType),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          mealType,
                          style: TextStyle(
                            color: isSelected ? AppColors.nearBlack : AppColors.lavender,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getMealTypeEmoji(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '🥣';
      case 'lunch':
        return '🍽️';
      case 'dinner':
        return '🍖';
      case 'snacks':
        return '🍿';
      default:
        return '🍴';
    }
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        border: Border.all(color: AppColors.lavender.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: AppColors.white, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Search foods or meals...',
          hintStyle: TextStyle(color: Color(0xFF5A5A7A), fontSize: 14),
          contentPadding: EdgeInsets.symmetric(horizontal: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ── Category Chips ─────────────────────────────────────────────────────────

  Widget _buildCategoryChips(List<String> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isActive = _activeCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _activeCategory = cat),
            child: Container(
              margin: const EdgeInsets.only(right: 7),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.lime : Colors.transparent,
                border: Border.all(
                  color: isActive ? AppColors.lime : AppColors.lavender.withOpacity(0.4),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isActive ? AppColors.nearBlack : AppColors.lavender,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Food List ──────────────────────────────────────────────────────────────

  Widget _buildFoodList(List<Food> filtered, List<Food> allFoods) {
    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No foods found', style: TextStyle(color: AppColors.slateGray, fontSize: 14)),
        ),
      );
    }
    return Column(
      children: filtered.map((food) => _FoodRow(
        food: food,
        selected: _selected[food.foodId],
        onAdd:    () => _changeQty(food.foodId, 1),
        onRemove: () => _changeQty(food.foodId, -1),
        authController: widget.authController,
        isBatchDeleteMode: _isBatchDeleteMode,
        isSelectedForDelete: _selectedForDeletion.contains(food.foodId),
        onSelectForDelete: () => _toggleFoodSelection(food.foodId),
        onEditFood: () => _navigateToEditFood(food),
      )).toList(),
    );
  }

  // ── Selected Summary ───────────────────────────────────────────────────────

  Widget _buildSelectedSummary() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.lavender.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Selected Items', style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              Text('${_totalKcal.toStringAsFixed(0)} kcal', style: const TextStyle(color: AppColors.lime, fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MacroSummaryChip(label: 'PROTEIN', value: '${_totalProtein.toStringAsFixed(1)}g', valueColor: AppColors.lavender, bgColor: Color(0x1AB3A0FF)),
              const SizedBox(width: 8),
              _MacroSummaryChip(label: 'CARBS',   value: '${_totalCarbs.toStringAsFixed(1)}g',   valueColor: AppColors.lime,     bgColor: Color(0x12EBFF45)),
              const SizedBox(width: 8),
              _MacroSummaryChip(label: 'FAT',     value: '${_totalFat.toStringAsFixed(1)}g',     valueColor: AppColors.slateGray, bgColor: Color(0x2664748B)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Note Field ─────────────────────────────────────────────────────────────

  Widget _buildNoteField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        border: Border.all(color: AppColors.lavender.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _noteCtrl,
        maxLines: 3,
        minLines: 2,
        style: const TextStyle(color: AppColors.white, fontSize: 13),
        decoration: const InputDecoration(
          hintText: 'Add a note (e.g. homemade, restaurant name)...',
          hintStyle: TextStyle(color: Color(0xFF5A5A7A), fontSize: 13),
          contentPadding: EdgeInsets.all(14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ── Log Button ─────────────────────────────────────────────────────────────

  Widget _buildLogButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lime,
          foregroundColor: AppColors.nearBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _logMeal,
        child: const Text('Log Meal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
    );
  }

  // ── Toast ──────────────────────────────────────────────────────────────────

  Widget _buildToast() {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.lime,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '✓ Meal logged successfully!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.nearBlack, fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

// ─── Food Row Widget ───────────────────────────────────────────────────────────

class _FoodRow extends StatelessWidget {
  const _FoodRow({
    required this.food,
    required this.selected,
    required this.onAdd,
    required this.onRemove,
    required this.authController,
    required this.isBatchDeleteMode,
    required this.isSelectedForDelete,
    required this.onSelectForDelete,
    required this.onEditFood,
  });

  final Food food;
  final _SelectedItem? selected;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final AuthController authController;
  final bool isBatchDeleteMode;
  final bool isSelectedForDelete;
  final VoidCallback onSelectForDelete;
  final VoidCallback onEditFood;

  void _showFoodOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                food.foodName,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Edit option
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.lime),
              title: const Text(
                'Edit Food',
                style: TextStyle(color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToEditFood(context);
              },
            ),
            // Delete option
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Food',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
      ),
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

  void _navigateToEditFood(BuildContext context) {
    onEditFood(); // Call parent's callback to handle navigation and refresh
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text(
          'Delete Food?',
          style: TextStyle(color: AppColors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${food.foodName}"? This action cannot be undone.',
          style: const TextStyle(color: AppColors.lavender),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lime)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFood(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFood(BuildContext context) async {
    final foodController = context.read<FoodController>();
    final success = await foodController.deleteFood(food.foodId);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${food.foodName} deleted'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${foodController.errorMessage}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = selected != null;

    // In batch delete mode, show checkbox instead of +/- buttons
    if (isBatchDeleteMode) {
      return GestureDetector(
        onTap: onSelectForDelete,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelectedForDelete ? Colors.red.withOpacity(0.1) : Colors.transparent,
            border: Border.all(
              color: isSelectedForDelete ? Colors.red : AppColors.lavender.withOpacity(0.35),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: isSelectedForDelete,
                onChanged: (_) => onSelectForDelete(),
                activeColor: Colors.red,
                checkColor: Colors.white,
              ),
              const SizedBox(width: 8),
              // Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _getCategoryEmoji(food.category),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 10),
              // Name + category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.foodName, style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(food.category, style: const TextStyle(color: AppColors.fatBar, fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              // Nutrition info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${food.caloriesPer100g.toStringAsFixed(0)} kcal', style: const TextStyle(color: AppColors.lime, fontSize: 13, fontWeight: FontWeight.w800)),
                  Text('P${food.proteinPer100g.toStringAsFixed(0)} C${food.carbsPer100g.toStringAsFixed(0)} F${food.fatPer100g.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppColors.fatBar, fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Normal mode - show +/- buttons
    return GestureDetector(
      onLongPress: () => _showFoodOptions(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lime.withOpacity(0.05) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.lime : AppColors.lavender.withOpacity(0.35),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Category emoji icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                _getCategoryEmoji(food.category),
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 10),
            // Name + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(food.foodName, style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${selected!.qty}x',
                            style: const TextStyle(color: AppColors.nearBlack, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(food.category, style: const TextStyle(color: AppColors.fatBar, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            // Kcal + macros per 100g
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${food.caloriesPer100g.toStringAsFixed(0)} kcal', style: const TextStyle(color: AppColors.lime, fontSize: 13, fontWeight: FontWeight.w800)),
                Text('P${food.proteinPer100g.toStringAsFixed(0)} C${food.carbsPer100g.toStringAsFixed(0)} F${food.fatPer100g.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.fatBar, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(width: 8),
            // +/- buttons
            Column(
              children: [
                _QtyButton(
                  icon: Icons.add,
                  onTap: onAdd,
                  highlight: !isSelected,
                ),
                if (isSelected) ...[
                  const SizedBox(height: 4),
                  _QtyButton(icon: Icons.remove, onTap: onRemove),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Qty Button ────────────────────────────────────────────────────────────────

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap, this.highlight = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: highlight ? AppColors.lime.withOpacity(0.15) : AppColors.lavender.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: highlight ? AppColors.lime : AppColors.lavender),
      ),
    );
  }
}

// ─── Macro Summary Chip ────────────────────────────────────────────────────────

class _MacroSummaryChip extends StatelessWidget {
  const _MacroSummaryChip({required this.label, required this.value, required this.valueColor, required this.bgColor});

  final String label;
  final String value;
  final Color valueColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.slateGray, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
