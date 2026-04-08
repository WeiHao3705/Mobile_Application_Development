import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../services/user_session_service.dart';
import '../theme/app_colors.dart';
import 'aerobic_page.dart';
import 'exercise_page.dart';
import 'login_page.dart';
import 'main_navigation.dart';

class AdminDashboardPage extends StatelessWidget {
  static const routeName = '/admin-dashboard';

  const AdminDashboardPage({super.key, required this.authController});

  final AuthController authController;

  void _openAerobic(BuildContext context) {
    final userId = authController.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    final userIdInt = userId is int ? userId : int.tryParse(userId.toString());
    if (userIdInt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid user ID')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AerobicPage(userId: userIdInt),
      ),
    );
  }

  void _openExerciseManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExercisePage(authController: authController),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await SimpleSessionService().clearSession();
    authController.logout();
    if (!context.mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginPage.routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = authController.currentUser;

    if (!authController.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 56, color: AppColors.lavender),
                const SizedBox(height: 16),
                Text(
                  'Admin access required',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your account does not have admin privileges.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: AppColors.white,
                  ),
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    MainNavigation.routeName,
                    (route) => false,
                  ),
                  child: const Text('Go to App'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.white,
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.purple.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${user?.fullName ?? user?.username ?? 'Admin'}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.lime,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user?.email ?? 'No email',
                    style: const TextStyle(color: AppColors.lavender),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Role: Administrator',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _AdminActionCard(
            title: 'Aerobic',
            subtitle: 'Open aerobic workout section',
            icon: Icons.directions_run,
            onTap: () => _openAerobic(context),
          ),
          const SizedBox(height: 12),
          _AdminActionCard(
            title: 'Exercise Management',
            subtitle: 'Go to exercise management tools',
            icon: Icons.fitness_center,
            onTap: () => _openExerciseManagement(context),
          ),
          const SizedBox(height: 12),
          _AdminActionCard(
            title: 'Logout',
            subtitle: 'Sign out of this admin session',
            icon: Icons.logout,
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.purple.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.lavender),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.slateGray),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.lavender),
        onTap: onTap,
      ),
    );
  }
}





