import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_colors.dart';
import 'aerobic_page.dart';
import 'workout_page.dart';

/// Hub page for regular users: lets them choose between Aerobic and Workout.
///
/// Admins still access `ExercisePage` (management) from the admin dashboard.
class ExerciseHubPage extends StatelessWidget {
  const ExerciseHubPage({super.key, required this.authController});

  final AuthController authController;

  int? get _userId {
    final currentUser = authController.currentUser;
    final id = currentUser?.id;
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '');
  }

  void _openAerobic(BuildContext context) {
    final userId = _userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AerobicPage(userId: userId),
      ),
    );
  }

  void _openWorkout(BuildContext context) {
    final userId = _userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutPage(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.white,
        title: const Text('Exercise'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Activity',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _ExerciseHubCard(
              icon: Icons.directions_run,
              title: 'Aerobic',
              subtitle: 'Track running, walking and other cardio sessions.',
              onTap: () => _openAerobic(context),
            ),
            const SizedBox(height: 12),
            _ExerciseHubCard(
              icon: Icons.fitness_center,
              title: 'Workout',
              subtitle: 'Strength workouts, plans and exercise routines.',
              onTap: () => _openWorkout(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseHubCard extends StatelessWidget {
  const _ExerciseHubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.purple.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.lavender),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.slateGray,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.lavender),
            ],
          ),
        ),
      ),
    );
  }
}

