import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/auth_controller.dart';
import '../models/weight_log.dart';
import '../models/water_intake.dart';
import '../repository/weight_log_repository.dart';
import '../repository/water_intake_repository.dart';
import '../repository/workout_record_repository.dart';
import '../repository/aerobic_repository.dart';
import '../services/auth_session_storage.dart';
import '../utils/time_formatters.dart';
import 'add_weight_log_page.dart';
import 'add_water_intake_page.dart';
import 'workout_record_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.authController});

  final AuthController authController;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _defaultTargetAmount = 2000;

  late final WaterIntakeRepository _waterIntakeRepository;
  late final WeightLogRepository _weightLogRepository;
  late final AerobicRepository _aerobicRepository;
  final AuthSessionStorage _sessionStorage = AuthSessionStorage();

  WaterIntake? _waterIntake;
  List<WeightLog> _weightLogs = const [];
  int _todayCaloriesBurned = 0;
  int _todaySteps = 0;
  int _todayWorkoutCount = 0; // Number of workouts today
  bool _isHydrationLoading = true;
  bool _isWeightLoading = true;
  bool _isAerobicLoading = true;
  String? _hydrationError;
  String? _weightError;
  String? _aerobicError;

  int? get _userId {
    final id = widget.authController.currentUser?.id;
    if (id is int) {
      return id;
    }
    return int.tryParse(id?.toString() ?? '');
  }

  @override
  void initState() {
    super.initState();
    _waterIntakeRepository = WaterIntakeRepository(
      supabase: Supabase.instance.client,
    );
    _weightLogRepository = WeightLogRepository(
      supabase: Supabase.instance.client,
    );
    _aerobicRepository = AerobicRepository();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadHomeCards();
      }
    });
  }

  Future<void> _loadHomeCards() async {
    await Future.wait([_loadHydrationSummary(), _loadWeightTrend(), _loadTodayAerobicStats()]);
  }

  Future<void> _loadHydrationSummary() async {
    setState(() {
      _isHydrationLoading = true;
      _hydrationError = null;
    });

    try {
      final userId = await _resolveUserId();
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _isHydrationLoading = false;
          _hydrationError = 'No active user session found.';
        });
        return;
      }

      final intake = await _waterIntakeRepository.getOrCreateByUserIdAndDate(
        userId: userId,
        day: DateTime.now(),
        defaultTargetAmount: _defaultTargetAmount,
      );

      if (!mounted) return;
      setState(() {
        _waterIntake = intake;
        _isHydrationLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isHydrationLoading = false;
        _hydrationError = 'Unable to load hydration progress.';
      });
      debugPrint('Hydration load error: $error');
    }
  }

  Future<void> _loadWeightTrend() async {
    setState(() {
      _isWeightLoading = true;
      _weightError = null;
    });

    try {
      final userId = await _resolveUserId();
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _isWeightLoading = false;
          _weightError = 'No active user session found.';
        });
        return;
      }

      final logs = await _weightLogRepository.getRecentByUserId(
        userId,
        limit: 14,
      );

      if (!mounted) return;
      setState(() {
        _weightLogs = logs;
        _isWeightLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isWeightLoading = false;
        _weightError = 'Unable to load weight trend.';
      });
    }
  }

  Future<void> _loadTodayAerobicStats() async {
    setState(() {
      _isAerobicLoading = true;
      _aerobicError = null;
    });

    try {
      final userId = await _resolveUserId();
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _isAerobicLoading = false;
          _aerobicError = 'No active user session found.';
        });
        return;
      }

      // Fetch all user's aerobic records
      final records = await _aerobicRepository.fetchUserRecords(userId);
      
      // Filter records for today
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);
      
      final todayRecords = records.where((record) {
        return record.start_at.isAfter(todayStart) && record.start_at.isBefore(todayEnd);
      }).toList();

      // Calculate totals
      int totalCalories = 0;
      int totalSteps = 0;
      int workoutCount = todayRecords.length; // Count the number of workouts
      
      for (final record in todayRecords) {
        totalCalories += record.calories_burned;
        totalSteps += record.total_step;
      }

      if (!mounted) return;
      setState(() {
        _todayCaloriesBurned = totalCalories;
        _todaySteps = totalSteps;
        _todayWorkoutCount = workoutCount;
        _isAerobicLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isAerobicLoading = false;
        _aerobicError = 'Unable to load aerobic data.';
      });
      debugPrint('Aerobic stats load error: $error');
    }
  }

  Future<int?> _resolveUserId() async {
    final fromController = _userId;
    if (fromController != null) {
      return fromController;
    }

    final sessionUser = await _sessionStorage.read();
    final id = sessionUser?.id;
    if (id is int) {
      return id;
    }
    return int.tryParse(id?.toString() ?? '');
  }

  Future<WorkoutRecordSummary?> _loadLatestStrengthTrainingRecord() async {
    final userId = _userId;
    if (userId == null) {
      return null;
    }

    final repository = WorkoutRecordRepository(
      supabase: Supabase.instance.client,
    );
    return repository.getLatestRecordForUser(userId);
  }

  Future<Map<String, dynamic>?> _loadLatestAerobicExercise() async {
    final userId = _userId;
    if (userId == null) {
      return null;
    }

    try {
      final records = await _aerobicRepository.fetchUserRecords(userId);
      if (records.isEmpty) {
        return null;
      }

      // Get the most recent record (already sorted by start_at descending in the repository)
      final latest = records.first;

      return {
        'activity_type': latest.activity_type,
        'total_distance': latest.total_distance,
        'moving_time': latest.moving_time,
        'calories_burned': latest.calories_burned,
        'start_at': latest.start_at,
      };
    } catch (e) {
      debugPrint('Error loading latest aerobic exercise: $e');
      return null;
    }
  }

  String _formatAerobicDetails(Map<String, dynamic> aerobic) {
    final distance = (aerobic['total_distance'] as double).toStringAsFixed(2);
    final duration = _formatWorkoutDuration(Duration(seconds: aerobic['moving_time'] as int));
    final calories = aerobic['calories_burned'] as int;
    return '$duration • $distance km • $calories cal';
  }

  String _formatWorkoutDuration(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}min ${seconds.toString().padLeft(2, '0')}s';
  }


  void _openWorkoutRecords(BuildContext context) {
    final userId = _userId;
    if (userId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutRecordListPage(userId: userId),
      ),
    );
  }

  Future<void> _openWaterIntakePage() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            AddWaterIntakePage(authController: widget.authController),
      ),
    );

    if (result == true && mounted) {
      await _loadHydrationSummary();
    }
  }

  Future<void> _openAddWeightLogPage() async {
    final initialWeight = _weightLogs.isNotEmpty
        ? _weightLogs.last.weight
        : _toDouble(widget.authController.currentUser?.currentWeight);

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddWeightLogPage(
          authController: widget.authController,
          initialWeight: initialWeight,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadWeightTrend();
    }
  }

  double? _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedTextColor = theme.colorScheme.onSurfaceVariant.withValues(
      alpha: 0.8,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('FitTrack'),
        centerTitle: false,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadHomeCards,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let\'s crush your fitness goals today',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: mutedTextColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Daily Stats Card
                Card(
                  elevation: 2,
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Activity',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              icon: Icons.local_fire_department,
                              label: 'Calories',
                              value: _todayCaloriesBurned.toString(),
                              color: theme.colorScheme.secondary,
                            ),
                            _StatItem(
                              icon: Icons.directions_walk,
                              label: 'Steps',
                              value: _todaySteps.toString(),
                              color: theme.colorScheme.tertiary,
                            ),
                            _StatItem(
                              icon: Icons.fitness_center,
                              label: 'Workouts',
                              value: _todayWorkoutCount.toString(),
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Weight Trend Card
                _WeightTrendCard(
                  logs: _weightLogs,
                  isLoading: _isWeightLoading,
                  errorText: _weightError,
                  onTap: _openAddWeightLogPage,
                  onRetry: _loadWeightTrend,
                ),
                const SizedBox(height: 16),

                // Hydration Progress Card
                _HydrationProgressCard(
                  waterIntake: _waterIntake,
                  isLoading: _isHydrationLoading,
                  errorText: _hydrationError,
                  onTap: _openWaterIntakePage,
                  onRetry: _loadHydrationSummary,
                ),
                const SizedBox(height: 24),

                // // Quick Actions
                // Text(
                //   'Quick Actions',
                //   style: theme.textTheme.titleLarge?.copyWith(
                //     fontWeight: FontWeight.bold,
                //     color: theme.colorScheme.onSurface,
                //   ),
                // ),
                // const SizedBox(height: 12),
                // Row(
                //   children: [
                //     Expanded(
                //       child: _ActionCard(
                //         icon: Icons.play_circle_filled,
                //         label: 'Start Workout',
                //         color: theme.colorScheme.tertiary,
                //       ),
                //     ),
                //     const SizedBox(width: 12),
                //     Expanded(
                //       child: _ActionCard(
                //         icon: Icons.restaurant,
                //         label: 'Log Meal',
                //         color: theme.colorScheme.secondary,
                //       ),
                //     ),
                //   ],
                // ),
                const SizedBox(height: 24),

                // Recent Workouts
                Text(
                  'Recent Workouts',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                // Most Recent Aerobic Exercise
                FutureBuilder<Map<String, dynamic>?>(
                  future: _loadLatestAerobicExercise(),
                  builder: (context, snapshot) {
                    final aerobic = snapshot.data;
                    final isLoading =
                        snapshot.connectionState == ConnectionState.waiting;
                    final subtitle = isLoading
                        ? 'Loading latest aerobic...'
                        : aerobic == null
                        ? 'No aerobic workout yet'
                        : _formatAerobicDetails(aerobic);
                    final title = aerobic?['activity_type'] ?? 'Aerobic Exercise';

                    return _WorkoutItem(
                      title: title,
                      subtitle: subtitle,
                      icon: Icons.directions_run,
                      iconColor: theme.colorScheme.tertiary,
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Most Recent Strength Training
                FutureBuilder<WorkoutRecordSummary?>(
                  future: _loadLatestStrengthTrainingRecord(),
                  builder: (context, snapshot) {
                    final record = snapshot.data;
                    final isLoading =
                        snapshot.connectionState == ConnectionState.waiting;
                    final subtitle = isLoading
                        ? 'Loading latest workout...'
                        : record == null
                        ? 'No saved strength workout yet'
                        : '${_formatWorkoutDuration(Duration(seconds: record.duration))} • ${record.trainingVolume} kg';

                    return _WorkoutItem(
                      title: 'Strength Training',
                      subtitle: subtitle,
                      icon: Icons.fitness_center,
                      iconColor: theme.colorScheme.secondary,
                      onTap: () => _openWorkoutRecords(context),
                    );
                  },
                ),
                // const SizedBox(height: 8),
                // _WorkoutItem(
                //   title: 'Yoga Session',
                //   subtitle: '20 min • 90 calories',
                //   icon: Icons.self_improvement,
                //   iconColor: theme.colorScheme.tertiary,
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutItem extends StatelessWidget {
  const _WorkoutItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightTrendCard extends StatelessWidget {
  const _WeightTrendCard({
    required this.logs,
    required this.isLoading,
    required this.errorText,
    required this.onTap,
    required this.onRetry,
  });

  final List<WeightLog> logs;
  final bool isLoading;
  final String? errorText;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.monitor_weight, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Weight Trend',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to log',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isLoading)
                const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (errorText != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      errorText!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                )
              else if (logs.isEmpty)
                SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'No weight logs yet. Tap to add your first log.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 160,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (logs.length - 1).toDouble(),
                      minY:
                          logs
                              .map((e) => e.weight)
                              .reduce((a, b) => a < b ? a : b) -
                          1,
                      maxY:
                          logs
                              .map((e) => e.weight)
                              .reduce((a, b) => a > b ? a : b) +
                          1,
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white.withValues(alpha: 0.08),
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.white.withValues(alpha: 0.06),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(
                              value.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= logs.length) {
                                return const SizedBox.shrink();
                              }
                              final date = logs[index].date;
                              return Text(
                                '${date.day}/${date.month}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            logs.length,
                            (index) =>
                                FlSpot(index.toDouble(), logs[index].weight),
                          ),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 3,
                                  color: Colors.blue,
                                  strokeColor: Colors.white,
                                  strokeWidth: 1,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (logs.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Latest: ${logs.last.weight.toStringAsFixed(1)} kg on ${logs.last.date.day}/${logs.last.date.month}/${logs.last.date.year}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HydrationProgressCard extends StatelessWidget {
  const _HydrationProgressCard({
    required this.waterIntake,
    required this.isLoading,
    required this.errorText,
    required this.onTap,
    required this.onRetry,
  });

  final WaterIntake? waterIntake;
  final bool isLoading;
  final String? errorText;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  String _formatLastUpdated(DateTime? value) {
    return formatRelativeTime(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intake = waterIntake;
    const hydrationBlue = Colors.blue;
    final lastUpdatedText = _formatLastUpdated(intake?.lastUpdated);

    return Card(
      elevation: 2,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.water_drop, color: hydrationBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Hydration Progress',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (intake != null)
                    Text(
                      '${intake.progressPercent.toStringAsFixed(1)}%',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (isLoading)
                const LinearProgressIndicator(minHeight: 8)
              else ...[
                LinearProgressIndicator(
                  minHeight: 8,
                  value: (intake?.progressRatio ?? 0).clamp(0.0, 1.0),
                  color: hydrationBlue,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 8),
                Text(
                  errorText ??
                      '${(intake?.currentAmount ?? 0).toStringAsFixed(0)} ml / ${(intake?.targetAmount ?? 0).toStringAsFixed(0)} ml',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (errorText == null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: $lastUpdatedText',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Tap to add water intake',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              if (!isLoading && errorText != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
