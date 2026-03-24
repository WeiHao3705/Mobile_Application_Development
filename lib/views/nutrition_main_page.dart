import 'package:flutter/material.dart';

class NutritionMainPage extends StatelessWidget {
  const NutritionMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _NutritionColors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderSection(),
              SizedBox(height: 10),
              _TabSection(),
              SizedBox(height: 10),
              _AnalyticsCard(),
              SizedBox(height: 12),
              _MacrosSection(),
              SizedBox(height: 12),
              _AddMealButton(),
              SizedBox(height: 14),
              _RecentMealsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutritionColors {
  static const Color white = Color(0xFFFFFFFF);
  static const Color lime = Color(0xFFEBFF45);
  static const Color purple = Color(0xFF896CFE);
  static const Color lavender = Color(0xFFB3A0FF);
  static const Color nearBlack = Color(0xFF070707);
  static const Color black = Color(0xFF000000);

  // Additional colors
  static const Color slateGray = Color(0xFF94A3B8);
  static const Color lightGray = Color(0xFFF1F5F9);
  static const Color proteinBar = Color(0xFFB0A2FF);
  static const Color fatBar = Color(0xFF64748B);
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.chevron_left, color: _NutritionColors.lime, size: 20),
        const SizedBox(width: 3),
        const Text(
          'Nutrition',
          style: TextStyle(
            color: _NutritionColors.lavender,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        _iconButton(Icons.search_rounded),
        const SizedBox(width: 6),
        _iconButton(Icons.notifications_rounded),
        const SizedBox(width: 6),
        _iconButton(Icons.person_rounded),
      ],
    );
  }

  Widget _iconButton(IconData icon) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border.all(color: _NutritionColors.lavender.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: _NutritionColors.lavender, size: 14),
    );
  }
}

class _TabSection extends StatelessWidget {
  const _TabSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 34,
            decoration: BoxDecoration(
              color: _NutritionColors.lime,
              borderRadius: BorderRadius.circular(17),
            ),
            alignment: Alignment.center,
            child: const Text(
              'My Meals',
              style: TextStyle(
                color: _NutritionColors.nearBlack,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 34,
            decoration: BoxDecoration(
              color: _NutritionColors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Meal Log',
              style: TextStyle(
                color: _NutritionColors.lavender,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _NutritionColors.lavender,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            top: 0,
            right: 0,
            child: Text(
              'ANALYTICS',
              style: TextStyle(
                color: _NutritionColors.lime,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-0.50, 0.08),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: _NutritionColors.nearBlack,
                    borderRadius: BorderRadius.circular(55),
                  ),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '1,250',
                        style: TextStyle(
                          color: _NutritionColors.lightGray,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 0.95,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '/ 2,000 KCAL',
                        style: TextStyle(
                          color: _NutritionColors.slateGray,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Goal',
                      style: TextStyle(
                        color: _NutritionColors.lightGray,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 0.95,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '⚡ 750 kcal left',
                      style: TextStyle(
                        color: _NutritionColors.lime,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacrosSection extends StatelessWidget {
  const _MacrosSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionTitle(title: 'Macros'),
        SizedBox(height: 8),
        _MacroItem(name: 'Protein', consumed: '85g', total: '120g', progress: 0.71, barColor: _NutritionColors.proteinBar),
        SizedBox(height: 8),
        _MacroItem(name: 'Carbs', consumed: '140g', total: '250g', progress: 0.56),
        SizedBox(height: 8),
        _MacroItem(name: 'Fat', consumed: '42g', total: '65g', progress: 0.65, barColor: _NutritionColors.fatBar),
      ],
    );
  }
}

class _MacroItem extends StatelessWidget {
  const _MacroItem({
    required this.name,
    required this.consumed,
    required this.total,
    required this.progress,
    this.barColor = _NutritionColors.lime,
  });

  final String name;
  final String consumed;
  final String total;
  final double progress;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        border: Border.all(color: _NutritionColors.lavender),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: _NutritionColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '$consumed / $total',
                style: const TextStyle(
                  color: _NutritionColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: _NutritionColors.white.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMealButton extends StatelessWidget {
  const _AddMealButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _NutritionColors.lime,
          foregroundColor: _NutritionColors.nearBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {},
        icon: const Icon(Icons.add_circle_outline, size: 18),
        label: const Text(
          'Add New Meal',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _RecentMealsSection extends StatelessWidget {
  const _RecentMealsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionTitle(title: 'Recent Meals'),
        SizedBox(height: 8),
        _MealTile(),
      ],
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _NutritionColors.lavender.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _NutritionColors.white,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: const Text('🥣', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Oatmeal with\nBlueberries',
                  style: TextStyle(
                    color: _NutritionColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Breakfast - 08:30 AM',
                  style: TextStyle(
                    color: _NutritionColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            '320 kcal',
            style: TextStyle(
              color: _NutritionColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _NutritionColors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        const Text(
          'See all',
          style: TextStyle(
            color: _NutritionColors.lime,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}