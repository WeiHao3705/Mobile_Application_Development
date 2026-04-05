import 'package:flutter/material.dart';
import 'package:mobile_application_development/views/add_new_meal.dart';
import 'package:mobile_application_development/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/meal_controller.dart';

class NutritionMainPage extends StatefulWidget {
  final AuthController authController;

  const NutritionMainPage({
    super.key,
    required this.authController,
  });

  @override
  State<NutritionMainPage> createState() => _NutritionMainPageState();
}

class _NutritionMainPageState extends State<NutritionMainPage> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserMeals();
  }

  Future<void> _loadUserMeals() async {
    final userId = widget.authController.currentUser?.id;
    if (userId != null) {
      final mealController = context.read<MealController>();
      await mealController.fetchUserMeals(int.parse(userId.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeaderSection(),
              const SizedBox(height: 10),
              _TabSection(
                selectedTabIndex: _selectedTabIndex,
                onTabChanged: (index) {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
              ),
              const SizedBox(height: 10),
              if (_selectedTabIndex == 0) ...[
                const _AnalyticsCard(),
                const SizedBox(height: 12),
                const _MacrosSection(),
                const SizedBox(height: 12),
                _AddMealButton(
                  authController: widget.authController,
                  onMealAdded: _loadUserMeals,
                ),
                const SizedBox(height: 14),
                _RecentMealsSection(
                  authController: widget.authController,
                ),
              ] else ...[
                _MealLogSection(
                  authController: widget.authController,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 3),
        const Text(
          'Nutrition',
          style: TextStyle(
            color: AppColors.lavender,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _iconButton(IconData icon) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lavender.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.lavender, size: 14),
    );
  }
}

class _TabSection extends StatelessWidget {
  final int selectedTabIndex;
  final Function(int) onTabChanged;

  const _TabSection({
    required this.selectedTabIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onTabChanged(0),
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: selectedTabIndex == 0 ? AppColors.lime : AppColors.white,
                borderRadius: BorderRadius.circular(17),
              ),
              alignment: Alignment.center,
              child: Text(
                'My Meals',
                style: TextStyle(
                  color: selectedTabIndex == 0 ? AppColors.nearBlack : AppColors.lavender,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: GestureDetector(
            onTap: () => onTabChanged(1),
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: selectedTabIndex == 1 ? AppColors.lime : AppColors.white,
                borderRadius: BorderRadius.circular(17),
              ),
              alignment: Alignment.center,
              child: Text(
                'Meal Log',
                style: TextStyle(
                  color: selectedTabIndex == 1 ? AppColors.nearBlack : AppColors.lavender,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
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
        color: AppColors.lavender,
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
                color: AppColors.lime,
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
                    color: AppColors.nearBlack,
                    borderRadius: BorderRadius.circular(55),
                  ),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '1,250',
                        style: TextStyle(
                          color: AppColors.lightGray,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 0.95,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '/ 2,000 KCAL',
                        style: TextStyle(
                          color: AppColors.slateGray,
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
                        color: AppColors.lightGray,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 0.95,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '⚡ 750 kcal left',
                      style: TextStyle(
                        color: AppColors.lime,
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
        _MacroItem(name: 'Protein', consumed: '85g', total: '120g', progress: 0.71, barColor: AppColors.proteinBar),
        SizedBox(height: 8),
        _MacroItem(name: 'Carbs', consumed: '140g', total: '250g', progress: 0.56),
        SizedBox(height: 8),
        _MacroItem(name: 'Fat', consumed: '42g', total: '65g', progress: 0.65, barColor: AppColors.fatBar),
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
    this.barColor = AppColors.lime,
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
        border: Border.all(color: AppColors.lavender),
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
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '$consumed / $total',
                style: const TextStyle(
                  color: AppColors.white,
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
              backgroundColor: AppColors.white.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMealButton extends StatelessWidget {
  final AuthController authController;
  final VoidCallback onMealAdded;

  const _AddMealButton({
    required this.authController,
    required this.onMealAdded,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lime,
          foregroundColor: AppColors.nearBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddNewMealPage(
                authController: authController,
              ),
            )
          );

          // Reload meals if a meal was added
          if (result == true) {
            onMealAdded();
          }
        },
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
  final AuthController authController;

  const _RecentMealsSection({
    required this.authController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Recent Meals',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            Spacer(),
            Text(
              'See all',
              style: TextStyle(
                color: AppColors.lime,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Consumer<MealController>(
          builder: (context, mealController, _) {
            if (mealController.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: AppColors.lime),
              );
            }

            if (mealController.userMeals.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.lavender.withOpacity(0.7)),
                ),
                child: const Center(
                  child: Text(
                    'No meals logged yet. Start by adding a meal!',
                    style: TextStyle(
                      color: AppColors.slateGray,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }

            // Show only the most recent 3 meals
            final recentMeals = mealController.userMeals.take(3).toList();

            return Column(
              children: recentMeals.map((meal) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _MealTile(meal: meal),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _MealTile extends StatelessWidget {
  final dynamic meal;

  const _MealTile({
    this.meal,
  });

  String _getMealEmoji(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '🥣';
      case 'lunch':
        return '🍽️';
      case 'dinner':
        return '🍽️';
      case 'snack':
        return '🍿';
      default:
        return '🍴';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (meal == null) {
      // Static fallback for demo
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.lavender.withOpacity(0.7)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white,
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
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Breakfast - 08:30 AM',
                    style: TextStyle(
                      color: AppColors.white,
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
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    final emoji = _getMealEmoji(meal.mealType);
    final time = _formatTime(meal.mealDate);

    return Consumer<MealController>(
      builder: (context, mealController, _) {
        final calories = mealController.getMealCalories(meal.mealId ?? 0);
        final caloriesStr = calories > 0 ? calories.toStringAsFixed(0) : '0';

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.lavender.withOpacity(0.7)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.mealType,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${meal.mealType} - $time',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$caloriesStr kcal',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
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
            color: AppColors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        const Text(
          'See all',
          style: TextStyle(
            color: AppColors.lime,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MealLogSection extends StatelessWidget {
  final AuthController authController;

  const _MealLogSection({
    required this.authController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Meal Log',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            Spacer(),
            Text(
              'Today',
              style: TextStyle(
                color: AppColors.lime,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<MealController>(
          builder: (context, mealController, _) {
            if (mealController.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: AppColors.lime),
              );
            }

            if (mealController.userMeals.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'No meals logged yet',
                      style: TextStyle(
                        color: AppColors.lavender,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start logging your meals to track your nutrition',
                      style: TextStyle(
                        color: AppColors.slateGray,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      width: 200,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lime,
                          foregroundColor: AppColors.nearBlack,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddNewMealPage(
                                authController: authController,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text(
                          'Add Meal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            }

            // Display all meals sorted by date (newest first)
            final sortedMeals = List.from(mealController.userMeals)
              ..sort((a, b) => b.mealDate.compareTo(a.mealDate));

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedMeals.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final meal = sortedMeals[index];
                return _MealLogTile(meal: meal);
              },
            );
          },
        ),
      ],
    );
  }
}

class _MealLogTile extends StatelessWidget {
  final dynamic meal;

  const _MealLogTile({required this.meal});

  String _getMealEmoji(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '🥣';
      case 'lunch':
        return '🍽️';
      case 'dinner':
        return '🍖';
      case 'snack':
        return '🍿';
      default:
        return '🍴';
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final mealDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (mealDay == today) {
      return 'Today at $time';
    } else if (mealDay == yesterday) {
      return 'Yesterday at $time';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at $time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _getMealEmoji(meal.mealType);
    final dateStr = _formatDate(meal.mealDate);

    return Consumer<MealController>(
      builder: (context, mealController, _) {
        final calories = mealController.getMealCalories(meal.mealId ?? 0);
        final caloriesStr = calories > 0 ? calories.toStringAsFixed(0) : '0';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lavender.withOpacity(0.5)),
            color: AppColors.cardBg,
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.lime.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.mealType,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppColors.slateGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    caloriesStr,
                    style: const TextStyle(
                      color: AppColors.lime,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'kcal',
                    style: TextStyle(
                      color: AppColors.slateGray,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

