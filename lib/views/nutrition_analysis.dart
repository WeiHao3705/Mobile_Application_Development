import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_application_development/theme/app_colors.dart';
import 'package:mobile_application_development/views/widgets/custom_bottom_nav_bar.dart';
import 'package:mobile_application_development/controllers/meal_controller.dart';
import 'package:mobile_application_development/services/nutrition_aggregation_service.dart';
import 'package:mobile_application_development/models/nutrition_aggregation.dart';
import 'package:mobile_application_development/models/meal_log.dart';
import 'package:mobile_application_development/repository/daily_goals_repository.dart';

void main() {
  runApp(const NutritionApp());
}

class NutritionApp extends StatelessWidget {
  const NutritionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrition Analysis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.nutritionDarkBg,
      ),
      home: const NutritionScreen(),
    );
  }
}

class NutritionScreen extends StatefulWidget {
  final int? initialNavIndex;

  const NutritionScreen({super.key, this.initialNavIndex});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 1; // Weekly selected by default
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  int _selectedNavIndex = 2; // Default to Diet (nutrition) tab

  // Data models
  final NutritionAggregationService _aggregationService = NutritionAggregationService();
  late DailyGoalsRepository _dailyGoalsRepository;

  DailyAggregation? _dailyAggregation;
  WeeklyAggregation? _weeklyAggregation;
  MonthlyAggregation? _monthlyAggregation;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialNavIndex ?? 2;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    final client = Supabase.instance.client;
    if (client != null) {
      _dailyGoalsRepository = DailyGoalsRepository(supabase: client);
    }

    // Load data in next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAggregationData();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Load and aggregate nutrition data for daily/weekly/monthly views
  Future<void> _loadAggregationData() async {
    try {
      setState(() => _isLoading = true);

      final mealController = context.read<MealController>();
      final now = DateTime.now();

      // Get current user's daily goals - always fetch fresh data
      var goals;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        try {
          goals = await _dailyGoalsRepository.getDailyGoalsByUserId(int.parse(userId));
        } catch (e) {
          print('⚠️ Could not load daily goals: $e');
          goals = null;
        }
      }

      // Generate aggregations
      final daily = _aggregationService.getDailyAggregation(
        date: now,
        allMeals: mealController.userMeals,
        goals: goals,
      );

      final weekly = _aggregationService.getWeeklyAggregation(
        endDate: now,
        allMeals: mealController.userMeals,
        goals: goals,
      );

      final monthly = _aggregationService.getMonthlyAggregation(
        endDate: now,
        allMeals: mealController.userMeals,
        goals: goals,
      );

      if (!mounted) return;

      setState(() {
        _dailyAggregation = daily;
        _weeklyAggregation = weekly;
        _monthlyAggregation = monthly;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading aggregation data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
    // Navigate to the appropriate page based on index
    // This will be handled by the parent navigation context
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.nutritionDarkBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTabBar(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                              color: AppColors.nutritionNeonGreen,
                            ),
                          ),
                        )
                      else if (_selectedTab == 0)
                        _buildDailyContent()
                      else if (_selectedTab == 1)
                        _buildWeeklyContent()
                      else
                        _buildMonthlyContent(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTap: _onNavTapped,
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.chevron_left, color: AppColors.nutritionNeonGreen, size: 26),
          ),
          const SizedBox(width: 4),
          const Text(
            'Nutrition Analysis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.nutritionCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: ['Daily', 'Weekly', 'Monthly'].asMap().entries.map((e) {
            final isSelected = e.key == _selectedTab;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.nutritionNeonGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    e.value,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.nutritionDarkBg
                          : AppColors.nutritionSubtleText,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _macroLegendRow(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ===== DAILY TAB CONTENT =====
  Widget _buildDailyContent() {
    if (_dailyAggregation == null) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildDailySummaryCard(_dailyAggregation!),
        const SizedBox(height: 14),
        _buildDailyMacroCard(_dailyAggregation!),
        const SizedBox(height: 14),
        _buildDailyMealsCard(_dailyAggregation!),
      ],
    );
  }

  Widget _buildDailySummaryCard(DailyAggregation daily) {
    final percentOfGoal = (daily.totalCalories / daily.calorieGoal * 100).clamp(0, 200);
    final isOnTrack = daily.isOnTrack;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.nutritionCardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Today\'s Summary',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: (isOnTrack ? AppColors.nutritionNeonGreen : Color(0xFFFF6B6B)).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  isOnTrack ? 'On track' : 'Off track',
                  style: TextStyle(
                    color: isOnTrack ? AppColors.nutritionNeonGreen : Color(0xFFFF6B6B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consumed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Goal: ${daily.calorieGoal.toStringAsFixed(0)} kcal',
                    style: TextStyle(color: AppColors.nutritionSubtleText, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${daily.totalCalories.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.nutritionNeonGreen,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${percentOfGoal.toStringAsFixed(0)}% of goal',
                    style: TextStyle(
                      color: AppColors.nutritionSubtleText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (percentOfGoal / 200).clamp(0, 1),
              backgroundColor: AppColors.nutritionProgressBg,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.nutritionNeonGreen),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMacroCard(DailyAggregation daily) {
    final totalMacros = daily.totalProteins + daily.totalCarbs + daily.totalFats;
    final proteinPct = totalMacros > 0 ? daily.totalProteins / totalMacros : 0;
    final carbsPct = totalMacros > 0 ? daily.totalCarbs / totalMacros : 0;
    final fatPct = totalMacros > 0 ? daily.totalFats / totalMacros : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.nutritionCardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macro Breakdown',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    segments: [
                      (carbsPct.toDouble(), AppColors.nutritionNeonGreen),
                      (proteinPct.toDouble(), AppColors.nutritionPurple),
                      (fatPct.toDouble(), AppColors.nutritionCyan),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _macroLegendRow(
                      AppColors.nutritionNeonGreen,
                      'Carbs',
                      '${daily.totalCarbs.toStringAsFixed(0)}g',
                    ),
                    const SizedBox(height: 14),
                    _macroLegendRow(
                      AppColors.nutritionPurple,
                      'Protein',
                      '${daily.totalProteins.toStringAsFixed(0)}g',
                    ),
                    const SizedBox(height: 14),
                    _macroLegendRow(
                      AppColors.nutritionCyan,
                      'Fat',
                      '${daily.totalFats.toStringAsFixed(0)}g',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMealsCard(DailyAggregation daily) {
    if (daily.meals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.nutritionCardBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meals Consumed',
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Icon(Icons.restaurant_outlined, color: AppColors.nutritionSubtleText, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'No meals logged',
                    style: TextStyle(color: AppColors.nutritionSubtleText, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.nutritionCardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meals Consumed (${daily.meals.length})',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...daily.meals.map((meal) => _buildMealTile(meal)).toList(),
        ],
      ),
    );
  }

  Widget _buildMealTile(MealLog meal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.nutritionDarkBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.mealType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${meal.mealDate.hour}:${meal.mealDate.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: AppColors.nutritionSubtleText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(meal.totalCalories ?? 0).toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        color: AppColors.nutritionNeonGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _miniMacroIndicator('P', meal.totalProteins ?? 0, 'g'),
                const SizedBox(width: 12),
                _miniMacroIndicator('C', meal.totalCarbs ?? 0, 'g'),
                const SizedBox(width: 12),
                _miniMacroIndicator('F', meal.totalFats ?? 0, 'g'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMacroIndicator(String label, double value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.nutritionSubtleText, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          '${value.toStringAsFixed(0)}$unit',
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ===== WEEKLY TAB CONTENT =====
  Widget _buildWeeklyContent() {
    if (_weeklyAggregation == null) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildWeeklyCalorieTrendCard(_weeklyAggregation!),
        const SizedBox(height: 14),
        _buildWeeklyMacroCard(_weeklyAggregation!),
        const SizedBox(height: 14),
        _buildWeeklyDeviationCard(_weeklyAggregation!),
      ],
    );
  }

  Widget _buildWeeklyCalorieTrendCard(WeeklyAggregation weekly) {
    final avgPercentage = (weekly.avgDailyCalories / (weekly.weeklyCalorieGoal / 7) * 100).clamp(0, 200);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      decoration: BoxDecoration(
        color: AppColors.nutritionCardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Weekly Calorie Trend',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.nutritionNeonGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: AppColors.nutritionNeonGreen, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      '${avgPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.nutritionNeonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${weekly.avgDailyCalories.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          Text(
            'kcal avg per day',
            style: TextStyle(
              color: AppColors.nutritionSubtleText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: CustomPaint(
              painter: _CalorieChartPainter(data: weekly.caloriesList),
              size: const Size(double.infinity, 110),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekly.dayLabels
                .map((d) => Text(
              d,
              style: TextStyle(
                color: AppColors.nutritionSubtleText,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildWeeklyMacroCard(WeeklyAggregation weekly) {
    final totalMacros = weekly.avgDailyProteins + weekly.avgDailyCarbs + weekly.avgDailyFats;
    final proteinPct = totalMacros > 0 ? weekly.avgDailyProteins / totalMacros : 0;
    final carbsPct = totalMacros > 0 ? weekly.avgDailyCarbs / totalMacros : 0;
    final fatPct = totalMacros > 0 ? weekly.avgDailyFats / totalMacros : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.nutritionCardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Average Macro Distribution',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    segments: [
                      (carbsPct.toDouble(), AppColors.nutritionNeonGreen),
                      (proteinPct.toDouble(), AppColors.nutritionPurple),
                      (fatPct.toDouble(), AppColors.nutritionCyan),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _macroLegendRow(
                      AppColors.nutritionNeonGreen,
                      'Carbs',
                      '${weekly.avgDailyCarbs.toStringAsFixed(0)}g',
                    ),
                    const SizedBox(height: 14),
                    _macroLegendRow(
                      AppColors.nutritionPurple,
                      'Protein',
                      '${weekly.avgDailyProteins.toStringAsFixed(0)}g',
                    ),
                    const SizedBox(height: 14),
                    _macroLegendRow(
                      AppColors.nutritionCyan,
                      'Fat',
                      '${weekly.avgDailyFats.toStringAsFixed(0)}g',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyDeviationCard(WeeklyAggregation weekly) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.nutritionCardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Deviation from Goal',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ...weekly.dailyData.asMap().entries.map((entry) {
            final day = entry.value;
            final dayLabel = weekly.dayLabels[entry.key];
            final deviation = day.totalCalories - day.calorieGoal;
            final isOver = deviation > 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 35,
                    child: Text(
                      dayLabel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (day.totalCalories / (day.calorieGoal * 1.5)).clamp(0, 1),
                        backgroundColor: AppColors.nutritionProgressBg,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOver ? Color(0xFFFF6B6B) : AppColors.nutritionNeonGreen,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${isOver ? '+' : ''}${deviation.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: isOver ? Color(0xFFFF6B6B) : AppColors.nutritionNeonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        textBaseline: TextBaseline.alphabetic,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ===== MONTHLY TAB CONTENT =====
  Widget _buildMonthlyContent() {
    if (_monthlyAggregation == null) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildMonthlySummaryCard(_monthlyAggregation!),
        const SizedBox(height: 14),
        _buildMonthlyMacroCard(_monthlyAggregation!),
        const SizedBox(height: 14),
        _buildMonthlyHighlightsCard(_monthlyAggregation!),
      ],
    );
  }

  Widget _buildMonthlySummaryCard(MonthlyAggregation monthly) {
    final percentOfGoal = (monthly.totalCalories / monthly.monthlyCalorieGoal * 100).clamp(0, 200);
    final isOnTrack = percentOfGoal >= 90 && percentOfGoal <= 110;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.nutritionCardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Monthly Summary',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: (isOnTrack ? AppColors.nutritionNeonGreen : Color(0xFFFF6B6B)).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  isOnTrack ? 'On track' : 'Off track',
                  style: TextStyle(
                    color: isOnTrack ? AppColors.nutritionNeonGreen : Color(0xFFFF6B6B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Consumed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Goal: ${monthly.monthlyCalorieGoal.toStringAsFixed(0)} kcal',
                    style: TextStyle(color: AppColors.nutritionSubtleText, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${monthly.totalCalories.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.nutritionNeonGreen,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${percentOfGoal.toStringAsFixed(0)}% of goal',
                    style: TextStyle(
                      color: AppColors.nutritionSubtleText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (percentOfGoal / 200).clamp(0, 1),
              backgroundColor: AppColors.nutritionProgressBg,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.nutritionNeonGreen),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyMacroCard(MonthlyAggregation monthly) {
    final totalMacros = monthly.avgDailyProteins + monthly.avgDailyCarbs + monthly.avgDailyFats;
    final proteinPct = totalMacros > 0 ? monthly.avgDailyProteins / totalMacros : 0;
    final carbsPct = totalMacros > 0 ? monthly.avgDailyCarbs / totalMacros : 0;
    final fatPct = totalMacros > 0 ? monthly.avgDailyFats / totalMacros : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.nutritionCardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Average Daily Macros',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    segments: [
                      (carbsPct.toDouble(), AppColors.nutritionNeonGreen),
                      (proteinPct.toDouble(), AppColors.nutritionPurple),
                      (fatPct.toDouble(), AppColors.nutritionCyan),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _macroLegendRow(
                      AppColors.nutritionNeonGreen,
                      'Carbs',
                      '${monthly.avgDailyCarbs.toStringAsFixed(0)}g',
                    ),
                    const SizedBox(height: 14),
                    _macroLegendRow(
                      AppColors.nutritionPurple,
                      'Protein',
                      '${monthly.avgDailyProteins.toStringAsFixed(0)}g',
                    ),
                    const SizedBox(height: 14),
                    _macroLegendRow(
                      AppColors.nutritionCyan,
                      'Fat',
                      '${monthly.avgDailyFats.toStringAsFixed(0)}g',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyHighlightsCard(MonthlyAggregation monthly) {
    final highlights = monthly.getNutrientHighlights();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.nutritionCardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrient Insights',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ...highlights.take(3).map((highlight) {
            final isOver = highlight.isOver;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.nutritionDarkBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isOver ? Color(0xFFFF6B6B) : AppColors.nutritionNeonGreen).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            highlight.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isOver ? Color(0xFFFF6B6B) : AppColors.nutritionNeonGreen).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isOver ? '+${highlight.percentageString}' : highlight.percentageString,
                            style: TextStyle(
                              color: isOver ? Color(0xFFFF6B6B) : AppColors.nutritionNeonGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Avg: ${highlight.actual.toStringAsFixed(1)}${highlight.unit}',
                          style: TextStyle(color: AppColors.nutritionSubtleText, fontSize: 12),
                        ),
                        const Spacer(),
                        Text(
                          'Goal: ${highlight.goal.toStringAsFixed(1)}${highlight.unit}',
                          style: TextStyle(color: AppColors.nutritionSubtleText, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_outlined, color: AppColors.nutritionSubtleText, size: 60),
            const SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(color: AppColors.nutritionSubtleText, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Custom Painters (Top-level classes) ---

class _CalorieChartPainter extends CustomPainter {
  final List<double> data;
  _CalorieChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final minVal = data.reduce(min);
    final maxVal = data.reduce(max);
    final range = maxVal - minVal;

    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final x = i * size.width / (data.length - 1);
      final y = size.height - ((data[i] - minVal) / (range > 0 ? range : 1)) * (size.height * 0.8) - size.height * 0.05;
      points.add(Offset(x, y));
    }

    // Build smooth path using cubic bezier
    final linePath = Path();
    final fillPath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, size.height);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset(
        points[i].dx + (points[i + 1].dx - points[i].dx) / 2,
        points[i].dy,
      );
      final cp2 = Offset(
        points[i].dx + (points[i + 1].dx - points[i].dx) / 2,
        points[i + 1].dy,
      );
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
    }

    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    // Fill gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.nutritionNeonGreen.withValues(alpha: 0.35),
          AppColors.nutritionNeonGreen.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Line stroke
    final linePaint = Paint()
      ..color = AppColors.nutritionNeonGreen
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    // Highlight dot on last point
    final dotPaint = Paint()..color = AppColors.nutritionNeonGreen;
    canvas.drawCircle(points.last, 5, dotPaint);
    canvas.drawCircle(
      points.last,
      5,
      Paint()
        ..color = AppColors.nutritionNeonGreen.withValues(alpha: 0.3)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonutChartPainter extends CustomPainter {
  final List<(double, Color)>? segments;

  _DonutChartPainter({this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 14.0;

    final segs = segments ?? [
      (0.50, AppColors.nutritionNeonGreen),   // Carbs 50%
      (0.25, AppColors.nutritionPurple),      // Protein 25%
      (0.25, AppColors.nutritionCyan),        // Fat 25%
    ];

    double startAngle = -pi / 2;
    const gap = 0.03;

    for (final seg in segs) {
      final sweepAngle = seg.$1 * 2 * pi - gap;
      final paint = Paint()
        ..color = seg.$2
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle + gap;
    }

    // Center text
    final tp = TextPainter(
      text: const TextSpan(
        text: 'Total\n',
        style: TextStyle(
          color: AppColors.nutritionSubtleText,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(
            text: '100%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
