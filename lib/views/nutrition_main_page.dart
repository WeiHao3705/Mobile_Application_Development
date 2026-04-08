import 'package:flutter/material.dart';
import 'package:mobile_application_development/views/add_new_meal.dart';
import 'package:mobile_application_development/views/edit_meal.dart';
import 'package:mobile_application_development/views/nutrition_analysis.dart';
import 'package:mobile_application_development/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';
import '../controllers/meal_controller.dart';
import '../models/daily_goals.dart';
import '../repository/daily_goals_repository.dart';

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
    // Defer initial meal loading to after first frame when providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserMeals();
      }
    });
  }

  Future<void> _loadUserMeals() async {
    final userId = widget.authController.currentUser?.id;
    if (userId != null) {
      if (!mounted) return;
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
                // Use Consumer to rebuild when AuthController changes (user logs in)
                Consumer<AuthController>(
                  builder: (context, authController, _) {
                    return _AnalyticsCard(
                      key: ValueKey(authController.currentUser?.id),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Consumer<AuthController>(
                  builder: (context, authController, _) {
                    return _MacrosSection(
                      key: ValueKey(authController.currentUser?.id),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _AddMealButton(
                  authController: widget.authController,
                  onMealAdded: _loadUserMeals,
                ),
                const SizedBox(height: 14),
                _RecentMealsSection(
                  authController: widget.authController,
                  onSeeAll: () {
                    setState(() {
                      _selectedTabIndex = 1;
                    });
                  },
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

class _AnalyticsCard extends StatefulWidget {
  const _AnalyticsCard({super.key});

  @override
  State<_AnalyticsCard> createState() => _AnalyticsCardState();
}

class _AnalyticsCardState extends State<_AnalyticsCard> {
  late DailyGoalsRepository _dailyGoalsRepository;
  DailyGoals? _dailyGoals;
  bool _isLoading = false;
  int? _lastLoadedUserId;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    if (client == null) {
      print('❌ Supabase client is null in _AnalyticsCardState.initState');
      return;
    }
    _dailyGoalsRepository = DailyGoalsRepository(
      supabase: client,
    );
    // Defer loading to next frame when context is fully ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDailyGoals();
      }
    });
  }

  Future<void> _loadDailyGoals() async {
    if (!mounted) return;
    final authController = context.read<AuthController>();
    final userId = authController.currentUser?.id;

    if (userId == null) {
      print('❌ User ID is null in _AnalyticsCardState');
      return;
    }

    try {
      int userIdInt;
      if (userId is int) {
        userIdInt = userId;
      } else {
        userIdInt = int.parse(userId.toString());
      }

      // Skip loading if we already loaded for this user
      if (_lastLoadedUserId == userIdInt && _dailyGoals != null) {
        return;
      }

      print('🔍 Loading daily goals for calories - user: $userIdInt');

      final goals = await _dailyGoalsRepository.getDailyGoalsByUserId(userIdInt);

      print('📦 Analytics - Fetched goals: $goals');
      print('📦 Analytics - Target calories: ${goals?.targetCalories}');

      if (!mounted) return;

      setState(() {
        _dailyGoals = goals;
        _lastLoadedUserId = userIdInt;
      });
    } catch (e) {
      print('❌ Error loading daily goals in Analytics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MealController>(
      builder: (context, mealController, _) {
        // Get today's date (start of day)
        final today = DateTime.now();
        final startOfToday = DateTime(today.year, today.month, today.day);
        final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59);

        // Filter meals to only include today's meals
        final todaysMeals = mealController.userMeals.where((meal) {
          final mealDate = meal.mealDate;
          return mealDate.isAfter(startOfToday.subtract(const Duration(seconds: 1))) &&
                 mealDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
        }).toList();

        // Calculate total calories from today's meals only
        double totalCaloriesConsumed = 0.0;
        for (final meal in todaysMeals) {
          final calories = meal.totalCalories ?? 0.0;
          totalCaloriesConsumed += calories;
        }

        // Get daily goal target from daily goals (default 2000 if not set)
        final int targetCalories = _dailyGoals?.targetCalories ?? 2000;

        // Calculate remaining calories
        final remainingCalories = targetCalories - totalCaloriesConsumed.toInt();

        // Calculate progress percentage
        final progressPercentage = (totalCaloriesConsumed / targetCalories).clamp(0.0, 1.0);
        final progressPercent = (progressPercentage * 100).toInt();

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NutritionScreen(),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 150),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
            children: [
              // ...existing code...
          // ANALYTICS label with bar chart icon
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: AppColors.lime, size: 13),
                const SizedBox(width: 4),
                const Text(
                  'ANALYTICS',
                  style: TextStyle(
                    color: AppColors.lime,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Dark circle - Shows consumed / target
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.nearBlack,
                    borderRadius: BorderRadius.circular(55),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        totalCaloriesConsumed.toInt().toString(),
                        style: const TextStyle(
                          color: AppColors.lightGray,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 0.95,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '/ $targetCalories KCAL',
                        style: const TextStyle(
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

                // Right side: title + kcal left + progress bar
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Goal',
                        style: TextStyle(
                          color: AppColors.lightGray,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 0.95,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${remainingCalories.clamp(0, remainingCalories)} kcal left',
                        style: const TextStyle(
                          color: AppColors.lime,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressPercentage,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lime),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Labels with calculated percentages
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$progressPercent% done',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${100 - progressPercent}% left',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      )),
      );
      },
    );
  }
}

class _MacrosSection extends StatefulWidget {
  const _MacrosSection({super.key});

  @override
  State<_MacrosSection> createState() => _MacrosSectionState();
}

class _MacrosSectionState extends State<_MacrosSection> {
  late final DailyGoalsRepository _dailyGoalsRepository;
  DailyGoals? _dailyGoals;
  int? _lastLoadedUserId;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    if (client == null) {
      print('❌ Supabase client is null in _MacrosSectionState.initState');
      return;
    }
    _dailyGoalsRepository = DailyGoalsRepository(
      supabase: client,
    );
    // Defer loading to next frame when context is fully ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDailyGoals();
      }
    });
  }

  Future<void> _loadDailyGoals() async {
    if (!mounted) return;
    final authController = context.read<AuthController>();
    final userId = authController.currentUser?.id;
    if (userId == null) return;

    try {
      final userIdInt = userId is int ? userId : int.parse(userId.toString());

      // Skip loading if we already loaded for this user
      if (_lastLoadedUserId == userIdInt && _dailyGoals != null) {
        return;
      }

      final goals = await _dailyGoalsRepository.getDailyGoalsByUserId(userIdInt);
      if (!mounted) return;

      setState(() {
        _dailyGoals = goals;
        _lastLoadedUserId = userIdInt;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Error loading daily goals in MacrosSection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MealController>(
      builder: (context, mealController, _) {
        // Get today's date (start of day)
        final today = DateTime.now();
        final startOfToday = DateTime(today.year, today.month, today.day);
        final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59);

        // Filter meals to only include today's meals
        final todaysMeals = mealController.userMeals.where((meal) {
          final mealDate = meal.mealDate;
          return mealDate.isAfter(startOfToday.subtract(const Duration(seconds: 1))) &&
              mealDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
        }).toList();

        // Calculate total macros from today's meals
        double totalProteins = 0.0;
        double totalCarbs = 0.0;
        double totalFats = 0.0;

        for (final meal in todaysMeals) {
          totalProteins += meal.totalProteins ?? 0.0;
          totalCarbs += meal.totalCarbs ?? 0.0;
          totalFats += meal.totalFats ?? 0.0;
        }

        // Use database goals, with sensible defaults until the fetch completes
        final proteinGoal = _dailyGoals?.targetProtein ?? 120.0;
        final carbsGoal = _dailyGoals?.targetCarbs ?? 250.0;
        final fatsGoal = _dailyGoals?.targetFat ?? 65.0;

        // Calculate progress as percentage
        final proteinProgress = (totalProteins / proteinGoal).clamp(0.0, 1.0);
        final carbsProgress = (totalCarbs / carbsGoal).clamp(0.0, 1.0);
        final fatsProgress = (totalFats / fatsGoal).clamp(0.0, 1.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: 'Macros'),
            const SizedBox(height: 8),
            _MacroItem(
              name: 'Protein',
              consumed: '${totalProteins.toStringAsFixed(1)}g',
              total: '${proteinGoal.toStringAsFixed(0)}g',
              progress: proteinProgress,
              barColor: AppColors.proteinBar,
            ),
            const SizedBox(height: 8),
            _MacroItem(
              name: 'Carbs',
              consumed: '${totalCarbs.toStringAsFixed(1)}g',
              total: '${carbsGoal.toStringAsFixed(0)}g',
              progress: carbsProgress,
            ),
            const SizedBox(height: 8),
            _MacroItem(
              name: 'Fat',
              consumed: '${totalFats.toStringAsFixed(1)}g',
              total: '${fatsGoal.toStringAsFixed(0)}g',
              progress: fatsProgress,
              barColor: AppColors.fatBar,
            ),
          ],
        );
      },
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
            ),
          );
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
  final VoidCallback onSeeAll;

  const _RecentMealsSection({
    required this.authController,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onSeeAll,
          child: const Row(
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
            ],
          ),
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

            // Get meals from the last 3 days
            final now = DateTime.now();
            final threeDaysAgo = now.subtract(const Duration(days: 3));

            final last3DaysMeals = mealController.userMeals.where((meal) {
              return meal.mealDate.isAfter(threeDaysAgo);
            }).toList();

            if (last3DaysMeals.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.lavender.withOpacity(0.7)),
                ),
                child: const Center(
                  child: Text(
                    'No meals logged in the last 3 days!',
                    style: TextStyle(
                      color: AppColors.slateGray,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }

            // Sort by date descending and take the latest 3 meals
            final recentMeals = List.from(last3DaysMeals)
              ..sort((a, b) => b.mealDate.compareTo(a.mealDate))
              ..take(3).toList();

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

  const _MealTile({this.meal});

  String _getMealEmoji(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '🥣';
      case 'lunch':
        return '🍽️';
      case 'dinner':
        return '🍖';
      case 'snack':
      case 'snacks':
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
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _MealLogSection extends StatefulWidget {
  final AuthController authController;

  const _MealLogSection({
    required this.authController,
  });

  @override
  State<_MealLogSection> createState() => _MealLogSectionState();
}

class _MealLogSectionState extends State<_MealLogSection> {
  String _filterMode = 'all'; // 'today' or 'all'
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Meal Log',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  _filterMode = value;
                  if (value != 'date') {
                    _selectedDate = null;
                  }
                });
                if (value == 'date') {
                  _showDatePicker();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'today',
                  child: Text('Today'),
                ),
                const PopupMenuItem<String>(
                  value: 'all',
                  child: Text('All Meals'),
                ),
                const PopupMenuItem<String>(
                  value: 'date',
                  child: Text('Select Date'),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.lime.withOpacity(0.15),
                  border: Border.all(color: AppColors.lime.withOpacity(0.6)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.filter_list, color: AppColors.lime, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Filter',
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
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddNewMealPage(
                      authController: widget.authController,
                    ),
                  ),
                ).then((_) {
                  // Refresh meals after adding
                  context.read<MealController>().fetchUserMeals(
                    int.parse(widget.authController.currentUser?.id?.toString() ?? '0'),
                  );
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.lime.withOpacity(0.15),
                  border: Border.all(color: AppColors.lime.withOpacity(0.6)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.add, color: AppColors.lime, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Add',
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
        if (_filterMode == 'date' && _selectedDate != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Meals on ${_formatDateLabel(_selectedDate!)}',
              style: const TextStyle(
                color: AppColors.lime,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
                                authController: widget.authController,
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

            // Filter meals based on selected filter mode
            List<dynamic> filteredMeals = [];

            if (_filterMode == 'all') {
              // Show all meals
              filteredMeals = mealController.userMeals;
            } else if (_filterMode == 'date' && _selectedDate != null) {
              // Show meals for selected date
              final startOfDate = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
              final endOfDate = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59, 59);

              filteredMeals = mealController.userMeals.where((meal) {
                final mealDate = meal.mealDate;
                return mealDate.isAfter(startOfDate.subtract(const Duration(seconds: 1))) &&
                       mealDate.isBefore(endOfDate.add(const Duration(seconds: 1)));
              }).toList();
            } else {
              // Default: Show today's meals
              final today = DateTime.now();
              final startOfToday = DateTime(today.year, today.month, today.day);
              final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59);

              filteredMeals = mealController.userMeals.where((meal) {
                final mealDate = meal.mealDate;
                return mealDate.isAfter(startOfToday.subtract(const Duration(seconds: 1))) &&
                       mealDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
              }).toList();
            }

            // If no meals match filter, show empty state
            if (filteredMeals.isEmpty) {
              String emptyMessage = 'No meals logged today';
              if (_filterMode == 'all') {
                emptyMessage = 'No meals logged yet';
              } else if (_filterMode == 'date' && _selectedDate != null) {
                emptyMessage = 'No meals logged on ${_formatDateLabel(_selectedDate!)}';
              }

              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      emptyMessage,
                      style: const TextStyle(
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
                                authController: widget.authController,
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

            final sortedMeals = List.from(filteredMeals)
              ..sort((a, b) => b.mealDate.compareTo(a.mealDate));

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedMeals.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final meal = sortedMeals[index];
                return _MealLogTile(
                  meal: meal,
                  authController: widget.authController,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'Today';
    } else if (dateDay == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _MealLogTile extends StatelessWidget {
  final dynamic meal;
  final AuthController authController;

  const _MealLogTile({
    required this.meal,
    required this.authController,
  });

  String _getMealEmoji(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '🥣';
      case 'lunch':
        return '🍽️';
      case 'dinner':
        return '🍖';
      case 'snack':
      case 'snacks':
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

  Future<void> _editMeal(BuildContext context, MealController mealController) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMealView(
          meal: meal,
          authController: authController,
        ),
      ),
    );

    // Refresh meals if meal was updated
    if (result == true && context.mounted) {
      final userId = authController.currentUser?.id;
      if (userId != null) {
        await mealController.fetchUserMeals(int.parse(userId.toString()));
      }
    }
  }

  Future<void> _deleteMeal(BuildContext context, MealController mealController) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F2E),
        title: const Text(
          'Delete Meal?',
          style: TextStyle(color: AppColors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this meal? This cannot be undone.',
          style: TextStyle(color: AppColors.lavender),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lime)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    if (!context.mounted) return;

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deleting meal...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Delete the meal
    final success = await mealController.deleteMeal(meal.mealId ?? 0);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Meal deleted'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${mealController.errorMessage}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
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
                  color: Colors.white,
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
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editMeal(context, mealController);
                  } else if (value == 'delete') {
                    _deleteMeal(context, mealController);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: AppColors.lime, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert, color: AppColors.lime, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }
}


