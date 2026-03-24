import 'package:flutter/material.dart';
import 'package:mobile_application_development/theme/app_colors.dart';

// ─── Data Model ────────────────────────────────────────────────────────────────

class _FoodItem {
  const _FoodItem({
    required this.id,
    required this.emoji,
    required this.name,
    required this.subtitle,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.category,
  });

  final int id;
  final String emoji;
  final String name;
  final String subtitle;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
  final String category;
}

class _SelectedItem {
  _SelectedItem({required this.food, required this.qty});
  final _FoodItem food;
  int qty;
}


// ─── Sample Data ───────────────────────────────────────────────────────────────

const List<_FoodItem> _allFoods = [
  _FoodItem(id: 1, emoji: '🥣', name: 'Oatmeal',           subtitle: '1 cup cooked',    kcal: 154, protein: 5,  carbs: 27, fat: 3,  category: 'Grains'),
  _FoodItem(id: 2, emoji: '🍳', name: 'Scrambled Eggs',    subtitle: '2 large eggs',    kcal: 182, protein: 12, carbs: 1,  fat: 14, category: 'Protein'),
  _FoodItem(id: 3, emoji: '🍌', name: 'Banana',            subtitle: '1 medium',        kcal: 105, protein: 1,  carbs: 27, fat: 0,  category: 'Fruits'),
  _FoodItem(id: 4, emoji: '🥛', name: 'Greek Yogurt',      subtitle: '150g, low-fat',   kcal: 90,  protein: 15, carbs: 8,  fat: 1,  category: 'Dairy'),
  _FoodItem(id: 5, emoji: '🍞', name: 'Whole Wheat Toast', subtitle: '2 slices',        kcal: 140, protein: 6,  carbs: 26, fat: 2,  category: 'Grains'),
  _FoodItem(id: 6, emoji: '🥑', name: 'Avocado',           subtitle: '½ medium',        kcal: 120, protein: 2,  carbs: 6,  fat: 11, category: 'Veggies'),
  _FoodItem(id: 7, emoji: '🍗', name: 'Grilled Chicken',   subtitle: '100g breast',     kcal: 165, protein: 31, carbs: 0,  fat: 4,  category: 'Protein'),
  _FoodItem(id: 8, emoji: '🥦', name: 'Steamed Broccoli',  subtitle: '1 cup',           kcal: 55,  protein: 4,  carbs: 11, fat: 1,  category: 'Veggies'),
];

const List<String> _categories = ['All', 'Grains', 'Protein', 'Dairy', 'Fruits', 'Veggies'];
const List<String> _mealTypes  = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

// ─── Page ──────────────────────────────────────────────────────────────────────

class AddNewMealPage extends StatefulWidget {
  const AddNewMealPage({super.key});

  @override
  State<AddNewMealPage> createState() => _AddNewMealPageState();
}

class _AddNewMealPageState extends State<AddNewMealPage> {
  String _mealType      = 'Breakfast';
  String _activeCategory = 'All';
  String _searchQuery   = '';
  final Map<int, _SelectedItem> _selected = {};
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _noteCtrl   = TextEditingController();
  bool _showToast = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  List<_FoodItem> get _filtered => _allFoods.where((f) {
    final matchCat = _activeCategory == 'All' || f.category == _activeCategory;
    final matchQ   = _searchQuery.isEmpty || f.name.toLowerCase().contains(_searchQuery.toLowerCase());
    return matchCat && matchQ;
  }).toList();

  int get _totalKcal    => _selected.values.fold(0, (s, i) => s + i.food.kcal    * i.qty);
  int get _totalProtein => _selected.values.fold(0, (s, i) => s + i.food.protein * i.qty);
  int get _totalCarbs   => _selected.values.fold(0, (s, i) => s + i.food.carbs   * i.qty);
  int get _totalFat     => _selected.values.fold(0, (s, i) => s + i.food.fat     * i.qty);

  void _changeQty(int id, int delta) {
    setState(() {
      if (!_selected.containsKey(id)) {
        final food = _allFoods.firstWhere((f) => f.id == id);
        _selected[id] = _SelectedItem(food: food, qty: 0);
      }
      _selected[id]!.qty += delta;
      if (_selected[id]!.qty <= 0) _selected.remove(id);
    });
  }

  void _logMeal() {
    if (_selected.isEmpty) return;
    setState(() => _showToast = true);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _showToast = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 18),
                  _buildMealTypeTabs(),
                  const SizedBox(height: 14),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildCategoryChips(),
                  const SizedBox(height: 14),
                  _buildFoodList(),
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
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: _iconBtn(
            child: const Icon(Icons.chevron_left, color: AppColors.lime, size: 18),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Add New Meal',
          style: TextStyle(
            color: AppColors.lavender,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        _iconBtn(child: const Icon(Icons.search_rounded, color: AppColors.lavender, size: 14)),
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

  // ── Meal Type Tabs ─────────────────────────────────────────────────────────

  Widget _buildMealTypeTabs() {
    return Row(
      children: _mealTypes.map((type) {
        final isActive = _mealType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _mealType = type),
            child: Container(
              height: 34,
              margin: EdgeInsets.only(right: type != _mealTypes.last ? 6 : 0),
              decoration: BoxDecoration(
                color: isActive ? AppColors.lime : AppColors.white,
                borderRadius: BorderRadius.circular(17),
              ),
              alignment: Alignment.center,
              child: Text(
                type,
                style: TextStyle(
                  color: isActive ? AppColors.nearBlack : AppColors.lavender,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
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

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
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

  Widget _buildFoodList() {
    final items = _filtered;
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No foods found', style: TextStyle(color: AppColors.slateGray, fontSize: 14)),
        ),
      );
    }
    return Column(
      children: items.map((food) => _FoodRow(
        food: food,
        selected: _selected[food.id],
        onAdd:    () => _changeQty(food.id, 1),
        onRemove: () => _changeQty(food.id, -1),
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
              Text('$_totalKcal kcal', style: const TextStyle(color: AppColors.lime, fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MacroSummaryChip(label: 'PROTEIN', value: '${_totalProtein}g', valueColor: AppColors.lavender, bgColor: Color(0x1AB3A0FF)),
              const SizedBox(width: 8),
              _MacroSummaryChip(label: 'CARBS',   value: '${_totalCarbs}g',   valueColor: AppColors.lime,     bgColor: Color(0x12EBFF45)),
              const SizedBox(width: 8),
              _MacroSummaryChip(label: 'FAT',     value: '${_totalFat}g',     valueColor: AppColors.slateGray, bgColor: Color(0x2664748B)),
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
    return Positioned(
      bottom: 90,
      left: 18,
      right: 18,
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
  });

  final _FoodItem food;
  final _SelectedItem? selected;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected != null;
    return Container(
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
          // Emoji icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(food.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          // Name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(food.name, style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w700)),
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
                Text(food.subtitle, style: const TextStyle(color: AppColors.fatBar, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // Kcal + macros
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${food.kcal} kcal', style: const TextStyle(color: AppColors.lime, fontSize: 13, fontWeight: FontWeight.w800)),
              Text('P${food.protein} C${food.carbs} F${food.fat}', style: const TextStyle(color: AppColors.fatBar, fontSize: 10, fontWeight: FontWeight.w600)),
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
