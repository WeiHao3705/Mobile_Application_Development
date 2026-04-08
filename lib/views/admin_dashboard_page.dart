import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../controllers/user_controller.dart';
import 'login_page.dart';
import 'main_navigation.dart';
import 'user_list_view.dart';

class AdminDashboardPage extends StatelessWidget {
  static const routeName = '/admin-dashboard';

  const AdminDashboardPage({super.key, required this.authController});

  final AuthController authController;

  void _openUserManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UserListView(controller: UserController()),
      ),
    );
  }

  void _openMainApp(BuildContext context) {
    Navigator.pushNamed(context, MainNavigation.routeName);
  }

  void _logout(BuildContext context) {
    authController.logout();
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
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 56),
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
      appBar: AppBar(
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${user?.fullName ?? user?.username ?? 'Admin'}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(user?.email ?? 'No email'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Role: Administrator',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _AdminActionCard(
            title: 'Manage Users',
            subtitle: 'View all user profiles and refresh user data',
            icon: Icons.groups,
            onTap: () => _openUserManagement(context),
          ),
          const SizedBox(height: 12),
          _AdminActionCard(
            title: 'Open Main App',
            subtitle: 'Switch to regular app navigation and features',
            icon: Icons.dashboard,
            onTap: () => _openMainApp(context),
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
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.secondary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

