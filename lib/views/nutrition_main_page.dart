import 'dart:math';
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
  late final DailyGoalsRepository _dailyGoalsRepository;
  DailyGoals? _dailyGoals;
  int? _lastLoadedUserId;

  @override
  void initState() {
    super.initState();
    _dailyGoalsRepository = DailyGoalsRepository(
      supabase: Supabase.instance.client,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadDailyGoals();
    });
  }

  Future<void> _loadDailyGoals() async {
    if (!mounted) return;
    final authController = context.read<AuthController>();
    final userId = authController.currentUser?.id;
    if (userId == null) return;

    try {
      final userIdInt = userId is int ? userId : int.parse(userId.toString());
      if (_lastLoadedUserId == userIdInt && _dailyGoals != null) return;

      final goals = await _dailyGoalsRepository.getDailyGoalsByUserId(userIdInt);
      if (!mounted) return;

      setState(() {
        _dailyGoals = goals;
        _lastLoadedUserId = userIdInt;
      });
    } catch (e) {
      debugPrint('Error loading daily goals: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MealController>(
      builder: (context, mealController, _) {
        final today = DateTime.now();
        final startOfToday = DateTime(today.year, today.month, today.day);
        final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59);

        final todaysMeals = mealController.userMeals.where((meal) {
          return meal.mealDate.isAfter(startOfToday.subtract(const Duration(seconds: 1))) &&
              meal.mealDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
        }).toList();

        double totalCalories = 0.0;
        for (final meal in todaysMeals) {
          totalCalories += meal.totalCalories ?? 0.0;
        }

        final int targetCalories = _dailyGoals?.targetCalories ?? 2000;
        final int remaining = (targetCalories - totalCalories).toInt().clamp(0, targetCalories);
        final double progress = (totalCalories / targetCalories).clamp(0.0, 1.0);
        final int progressPct = (progress * 100).toInt();

        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NutritionScreen()),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1929),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildMainRow(
                  totalCalories: totalCalories,
                  targetCalories: targetCalories,
                  remaining: remaining,
                  progress: progress,
                  progressPct: progressPct,
                ),
                const SizedBox(height: 12),
                _buildTapHint(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'DAILY GOAL',
          style: TextStyle(
            color: Color(0xFF9588CC),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.lime.withOpacity(0.08),
            border: Border.all(color: AppColors.lime.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'ANALYTICS',
                style: TextStyle(
                  color: AppColors.lime,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainRow({
    required double totalCalories,
    required int targetCalories,
    required int remaining,
    required double progress,
    required int progressPct,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _DonutRing(
          progress: progress,
          consumed: totalCalories.toInt(),
          target: targetCalories,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daily Goal',
                style: TextStyle(
                  color: Color(0xFFEDE9F8),
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$remaining kcal left',
                style: TextStyle(
                  color: AppColors.lime,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.lime),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$progressPct% done',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${100 - progressPct}% left',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
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
    );
  }

  Widget _buildTapHint() {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0x1F9588CC)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Tap for full analytics',
            style: TextStyle(
              color: const Color(0xFF9588CC).withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '›',
            style: TextStyle(
              color: const Color(0xFF9588CC).withOpacity(0.3),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutRing extends StatelessWidget {
  final double progress;
  final int consumed;
  final int target;

  const _DonutRing({
    required this.progress,
    required this.consumed,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 106,
      height: 106,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(106, 106),
            painter: _RingPainter(progress: progress),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF12101C),
              borderRadius: BorderRadius.circular(36),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  consumed.toString(),
                  style: const TextStyle(
                    color: Color(0xFFEDE9F8),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '/ $target',
                  style: const TextStyle(
                    color: Color(0xFF4A4565),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const Text(
                  'KCAL',
                  style: TextStyle(
                    color: Color(0xFF4A4565),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;

  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 9;
    const strokeWidth = 10.0;

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = const Color(0xFFEBFF45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        progress * 2 * pi,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
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
        // ...existing code...
        final today = DateTime.now();
        final startOfToday = DateTime(today.year, today.month, today.day);
        final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59);

        final todaysMeals = mealController.userMeals.where((meal) {
          final mealDate = meal.mealDate;
          return mealDate.isAfter(startOfToday.subtract(const Duration(seconds: 1))) &&
              mealDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
        }).toList();

        // ...existing code...
        double totalProteins = 0.0;
        double totalCarbs = 0.0;
        double totalFats = 0.0;

        for (final meal in todaysMeals) {
          totalProteins += meal.totalProteins ?? 0.0;
          totalCarbs += meal.totalCarbs ?? 0.0;
          totalFats += meal.totalFats ?? 0.0;
        }

        final proteinGoal = _dailyGoals?.targetProtein ?? 120.0;
        final carbsGoal = _dailyGoals?.targetCarbs ?? 250.0;
        final fatsGoal = _dailyGoals?.targetFat ?? 65.0;

        final proteinProgress = (totalProteins / proteinGoal).clamp(0.0, 1.0);
        final carbsProgress = (totalCarbs / carbsGoal).clamp(0.0, 1.0);
        final fatsProgress = (totalFats / fatsGoal).clamp(0.0, 1.0);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1929),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMacrosHeader(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MacroCard(
                    name: 'Protein',
                    consumed: totalProteins.toInt(),
                    target: proteinGoal.toInt(),
                    progress: proteinProgress,
                    color: const Color(0xFFF86C6C),
                  ),
                  _MacroCard(
                    name: 'Carbs',
                    consumed: totalCarbs.toInt(),
                    target: carbsGoal.toInt(),
                    progress: carbsProgress,
                    color: const Color(0xFF4ECDC4),
                  ),
                  _MacroCard(
                    name: 'Fat',
                    consumed: totalFats.toInt(),
                    target: fatsGoal.toInt(),
                    progress: fatsProgress,
                    color: const Color(0xFFFFE66D),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMacrosHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'MACRONUTRIENTS',
          style: TextStyle(
            color: Color(0xFF9588CC),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.lime.withOpacity(0.08),
            border: Border.all(color: AppColors.lime.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'MACROS',
                style: TextStyle(
                  color: AppColors.lime,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String name;
  final int consumed;
  final int target;
  final double progress;
  final Color color;

  const _MacroCard({
    required this.name,
    required this.consumed,
    required this.target,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular progress indicator
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(70, 70),
                  painter: _MacroRingPainter(progress: progress, color: color),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$consumed',
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    Text(
                      '$target',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              color: Color(0xFFEDE9F8),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _MacroRingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 7.0;

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        progress * 2 * pi,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MacroRingPainter old) =>
      old.progress != progress || old.color != color;
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
          backgroundColor: AppColors.lime.withOpacity(0.15),
          foregroundColor: AppColors.lime,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppColors.lime.withOpacity(0.4), width: 1),
          ),
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
          child: Row(
            children: [
              const Text(
                'Recent Meals',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSeeAll,
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: AppColors.lime,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
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

  String _formatTileSubtitle(DateTime dateTime) {
    final now = DateTime.now();
    final isToday = dateTime.year == now.year &&
                    dateTime.month == now.month &&
                    dateTime.day == now.day;
    final time = _formatTime(dateTime);
    return isToday ? time : '${dateTime.day}/${dateTime.month} · $time';
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
                  const SizedBox(height: 3),
                  Text(
                    '08:30',
                    style: TextStyle(
                      color: AppColors.slateGray,
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
    final displayName = meal.mealName ?? meal.mealType;

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
                      displayName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatTileSubtitle(meal.mealDate),
                      style: const TextStyle(
                        color: AppColors.slateGray,
                        fontSize: 10,
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
                  fontSize: 14,
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
  bool _isBatchDeleteMode = false;
  final Set<int> _selectedForDeletion = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ROW 1 — Title + action chips always in one line
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filter popup
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() {
                      _filterMode = value;
                      if (value != 'date') _selectedDate = null;
                    });
                    if (value == 'date') _showDatePicker();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'today', child: Text('Today')),
                    const PopupMenuItem(value: 'all', child: Text('All Meals')),
                    const PopupMenuItem(value: 'date', child: Text('Select Date')),
                  ],
                  child: _toolbarIconButton(Icons.filter_list, AppColors.lime),
                ),
                const SizedBox(width: 6),
                // Toggle batch-delete mode
                GestureDetector(
                  onTap: () => setState(() {
                    _isBatchDeleteMode = !_isBatchDeleteMode;
                    if (!_isBatchDeleteMode) _selectedForDeletion.clear();
                  }),
                  child: _isBatchDeleteMode
                      ? _toolbarIconButton(Icons.close, Colors.red, isActive: true)
                      : _toolbarIconButton(Icons.delete_outline, AppColors.yellow),
                ),
                const SizedBox(width: 6),
                // Add meal (only when not in delete mode)
                if (!_isBatchDeleteMode)
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AddNewMealPage(authController: widget.authController),
                      )).then((_) {
                        context.read<MealController>().fetchUserMeals(
                          int.parse(widget.authController.currentUser?.id?.toString() ?? '0'),
                        );
                      });
                    },
                    child: _toolbarIconButton(Icons.add, AppColors.lime),
                  ),
              ],
            ),
          ],
        ),

        // ROW 2 — Only visible in batch-delete mode with selections
        if (_isBatchDeleteMode) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedForDeletion.length} meal(s) selected',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_selectedForDeletion.isNotEmpty)
                GestureDetector(
                  onTap: _deleteBatchMeals,
                  child: _toolbarChip(Icons.delete, 'Confirm delete', Colors.red),
                ),
            ],
          ),
        ],
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
                          backgroundColor: AppColors.lime.withOpacity(0.15),
                          foregroundColor: AppColors.lime,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: AppColors.lime.withOpacity(0.4), width: 1),
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
                          backgroundColor: AppColors.lime.withOpacity(0.15),
                          foregroundColor: AppColors.lime,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: AppColors.lime.withOpacity(0.4), width: 1),
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
                  isBatchDeleteMode: _isBatchDeleteMode,
                  isSelectedForDelete: _selectedForDeletion.contains(meal.mealId),
                  onSelectForDelete: () {
                    setState(() {
                      if (_selectedForDeletion.contains(meal.mealId)) {
                        _selectedForDeletion.remove(meal.mealId);
                      } else {
                        _selectedForDeletion.add(meal.mealId ?? 0);
                      }
                    });
                  },
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
          child: child!,
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

  Future<void> _deleteBatchMeals() async {
    if (_selectedForDeletion.isEmpty) return;

    final count = _selectedForDeletion.length;

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text(
          'Delete Multiple Meals?',
          style: TextStyle(color: AppColors.white),
        ),
        content: Text(
          'Are you sure you want to delete $count selected meal(s)? This action cannot be undone.',
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

    // Delete meals
    final mealController = context.read<MealController>();
    int successCount = 0;
    int failureCount = 0;

    for (final mealId in _selectedForDeletion) {
      try {
        final success = await mealController.deleteMeal(mealId);
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

      // Refresh the meal list
      final userId = widget.authController.currentUser?.id;
      if (userId != null) {
        await mealController.fetchUserMeals(int.parse(userId.toString()));
      }

      // Show result message
      String message = '';
      if (failureCount == 0) {
        message = '✓ $successCount meal(s) deleted successfully!';
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

  Widget _toolbarIconButton(IconData icon, Color color, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.3) : color.withOpacity(0.13),
        border: Border.all(
          color: isActive ? color : color.withOpacity(0.55),
          width: isActive ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _toolbarChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        border: Border.all(color: color.withOpacity(0.55)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MealLogTile extends StatelessWidget {
  final dynamic meal;
  final AuthController authController;
  final bool isBatchDeleteMode;
  final bool isSelectedForDelete;
  final VoidCallback onSelectForDelete;

  const _MealLogTile({
    required this.meal,
    required this.authController,
    this.isBatchDeleteMode = false,
    this.isSelectedForDelete = false,
    required this.onSelectForDelete,
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

  @override
  Widget build(BuildContext context) {
    final emoji = _getMealEmoji(meal.mealType);
    final dateStr = _formatDate(meal.mealDate);
    final displayName = meal.mealName ?? meal.mealType;

    return Consumer<MealController>(
      builder: (context, mealController, _) {
        final calories = mealController.getMealCalories(meal.mealId ?? 0);
        final caloriesStr = calories > 0 ? calories.toStringAsFixed(0) : '0';

        // In batch delete mode, show checkbox
        if (isBatchDeleteMode) {
          return GestureDetector(
            onTap: onSelectForDelete,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelectedForDelete ? Colors.red : Colors.white.withOpacity(0.25),
                ),
                color: isSelectedForDelete ? Colors.red.withOpacity(0.1) : AppColors.cardBg,
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelectedForDelete,
                    onChanged: (_) => onSelectForDelete(),
                    activeColor: Colors.red,
                    checkColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
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
                          displayName,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: AppColors.slateGray,
                            fontSize: 11,
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
                          fontSize: 16,
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
            ),
          );
        }

        // Normal mode - click to edit
        return GestureDetector(
          onTap: () => _editMeal(context, mealController),
          child: Container(
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
                        displayName,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: AppColors.slateGray,
                          fontSize: 11,
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
                        fontSize: 16,
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
          ),
        );
      },
    );
  }
}


