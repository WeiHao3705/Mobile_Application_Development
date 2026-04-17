import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/auth_controller.dart';
import '../repository/workout_record_repository.dart';
import 'workout_record_list_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.authController});

  final AuthController authController;

  int? get _userId {
    final currentUser = authController.currentUser;
    final id = currentUser?.id;
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

    final repository = WorkoutRecordRepository(supabase: Supabase.instance.client);
    return repository.getLatestRecordForUser(userId);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedTextColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FitTrack'),
        centerTitle: false,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
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
                            value: '420',
                            color: theme.colorScheme.secondary,
                          ),
                          _StatItem(
                            icon: Icons.directions_walk,
                            label: 'Steps',
                            value: '6,543',
                            color: theme.colorScheme.tertiary,
                          ),
                          _StatItem(
                            icon: Icons.fitness_center,
                            label: 'Workouts',
                            value: '2',
                            color: theme.colorScheme.secondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.play_circle_filled,
                      label: 'Start Workout',
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.restaurant,
                      label: 'Log Meal',
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
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
              _WorkoutItem(
                title: 'Morning Run',
                subtitle: '30 min • 250 calories',
                icon: Icons.directions_run,
                iconColor: theme.colorScheme.tertiary,
              ),
              const SizedBox(height: 8),
              FutureBuilder<WorkoutRecordSummary?>(
                future: _loadLatestStrengthTrainingRecord(),
                builder: (context, snapshot) {
                  final record = snapshot.data;
                  final isLoading = snapshot.connectionState == ConnectionState.waiting;
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
              const SizedBox(height: 8),
              _WorkoutItem(
                title: 'Yoga Session',
                subtitle: '20 min • 90 calories',
                icon: Icons.self_improvement,
                iconColor: theme.colorScheme.tertiary,
              ),
            ],
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
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
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

