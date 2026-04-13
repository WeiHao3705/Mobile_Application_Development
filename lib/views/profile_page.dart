import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/auth_controller.dart';
import '../models/auth_user.dart';
import '../models/daily_goals.dart';
import '../repository/daily_goals_repository.dart';
import '../services/user_session_service.dart';
import '../views/dialogs/edit_daily_goals_dialog.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late DailyGoalsRepository _dailyGoalsRepository;
  final SimpleSessionService _sessionService = SimpleSessionService();
  DailyGoals? _dailyGoals;
  bool _isLoadingGoals = false;

  @override
  void initState() {
    super.initState();
    _dailyGoalsRepository = DailyGoalsRepository(
      supabase: Supabase.instance.client,
    );
    _loadDailyGoals();
  }

  Future<void> _loadDailyGoals() async {
    final userId = widget.authController.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoadingGoals = true);

    try {
      final goals = await _dailyGoalsRepository.getDailyGoalsByUserId(
        int.parse(userId.toString()),
      );

      setState(() {
        _dailyGoals = goals;
        _isLoadingGoals = false;
      });
    } catch (e) {
      setState(() => _isLoadingGoals = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading goals: $e')),
      );
    }
  }

  Future<void> _editDailyGoals() async {
    final userId = widget.authController.currentUser?.id;
    if (userId == null) return;

    final user = widget.authController.currentUser;

    // Use default goals if none exist
    final currentGoals = _dailyGoals ??
        DailyGoals(
          dailyGoalsId: 0,
          userId: int.parse(userId.toString()),
          targetCalories: 2000,
          targetProtein: 150,
          targetCarbs: 200,
          targetFat: 67,
        );

    showDialog(
      context: context,
      builder: (context) => EditDailyGoalsDialog(
        currentGoals: currentGoals,
        userId: int.parse(userId.toString()),
        onSave: _saveDailyGoals,
        userWeight: user?.currentWeight != null ? user!.currentWeight!.toDouble() : null,
        userHeight: user?.height != null ? user!.height!.toDouble() : null,
      ),
    );
  }

  Future<void> _saveDailyGoals(DailyGoals updatedGoals) async {
    try {
      if (_dailyGoals == null) {
        // Create new daily goals
        final newGoals = await _dailyGoalsRepository.createDailyGoals(updatedGoals);
        setState(() => _dailyGoals = newGoals);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Daily goals created successfully')),
        );
      } else {
        // Update existing daily goals
        final newGoals = await _dailyGoalsRepository.updateDailyGoals(updatedGoals);
        setState(() => _dailyGoals = newGoals);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Daily goals updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error saving goals: $e')),
      );
    }
  }

  String _displayName(LoginUser? user) {
    return user?.fullName ?? user?.username ?? 'User';
  }

  String _displayEmail(LoginUser? user) {
    return user?.email ?? 'No email available';
  }

  String _displayMetric(num? value, String unit) {
    if (value == null) {
      return '--';
    }
    return '${value.toString()} $unit';
  }

  String _displayBmi(LoginUser? user) {
    final heightCm = user?.height;
    final weightKg = user?.currentWeight;

    if (heightCm == null || weightKg == null || heightCm == 0) {
      return '--';
    }

    final heightM = heightCm / 100;
    final bmi = weightKg / (heightM * heightM);
    return bmi.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.secondary,
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _displayName(user),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _displayEmail(user),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      user?.isAdmin == true ? 'Admin' : 'Member',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Stats Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Stats',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ProfileStat(
                            label: 'Weight',
                            value: _displayMetric(user?.currentWeight, 'kg'),
                            icon: Icons.monitor_weight,
                            color: theme.colorScheme.tertiary,
                          ),
                          _ProfileStat(
                            label: 'Height',
                            value: _displayMetric(user?.height, 'cm'),
                            icon: Icons.height,
                            color: theme.colorScheme.secondary,
                          ),
                          _ProfileStat(
                            label: 'BMI',
                            value: _displayBmi(user),
                            icon: Icons.analytics,
                            color: theme.colorScheme.tertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Goals Section
                  Text(
                    'Fitness Goals',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Editable Daily Goals Card
                  GestureDetector(
                    onTap: _editDailyGoals,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Daily Nutrition Goals',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  Icons.edit,
                                  color: theme.colorScheme.secondary,
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_isLoadingGoals)
                              const Center(
                                child: CircularProgressIndicator(),
                              )
                            else
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.6,
                                children: [
                                  _DailyGoalItem(
                                    label: '🔥 Calories',
                                    value: '${_dailyGoals?.targetCalories ?? 2000}',
                                    unit: 'kcal',
                                  ),
                                  _DailyGoalItem(
                                    label: '🥚 Protein',
                                    value: '${(_dailyGoals?.targetProtein ?? 150).toStringAsFixed(0)}',
                                    unit: 'g',
                                  ),
                                  _DailyGoalItem(
                                    label: '🌾 Carbs',
                                    value: '${(_dailyGoals?.targetCarbs ?? 200).toStringAsFixed(0)}',
                                    unit: 'g',
                                  ),
                                  _DailyGoalItem(
                                    label: '🧈 Fat',
                                    value: '${(_dailyGoals?.targetFat ?? 67).toStringAsFixed(0)}',
                                    unit: 'g',
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to edit or auto-calculate',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _GoalItem(
                    title: 'Daily Steps Goal',
                    value: '10,000 steps',
                    icon: Icons.directions_walk,
                    iconColor: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(height: 8),
                  _GoalItem(
                    title: 'Target Weight',
                    value: _displayMetric(user?.targetWeight, 'kg'),
                    icon: Icons.fitness_center,
                    iconColor: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 24),

                  // Account Options
                  Text(
                    'Account',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _OptionItem(
                    title: 'Edit Profile',
                    icon: Icons.edit,
                    onTap: () {},
                  ),
                  _OptionItem(
                    title: 'Notifications',
                    icon: Icons.notifications,
                    onTap: () {},
                  ),
                  _OptionItem(
                    title: 'Privacy & Security',
                    icon: Icons.privacy_tip,
                    onTap: () {},
                  ),
                  _OptionItem(
                    title: 'Help & Support',
                    icon: Icons.help,
                    onTap: () {},
                  ),
                  _OptionItem(
                    title: 'Logout',
                    icon: Icons.logout,
                    onTap: () async {
                      await _sessionService.clearSession();
                      widget.authController.logout();
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        LoginPage.routeName,
                        (route) => false,
                      );
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _GoalItem extends StatelessWidget {
  const _GoalItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}

class _OptionItem extends StatelessWidget {
  const _OptionItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? Colors.red : null;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: color ?? theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _DailyGoalItem extends StatelessWidget {
  const _DailyGoalItem({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.all(11),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

