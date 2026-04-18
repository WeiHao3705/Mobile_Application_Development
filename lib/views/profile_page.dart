import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/auth_controller.dart';
import '../models/auth_user.dart';
import '../models/daily_goals.dart';
import '../repository/daily_goals_repository.dart';
import '../services/image_picker_service.dart';
import '../services/image_upload_service.dart';
import '../services/user_session_service.dart';
import '../views/dialogs/edit_daily_goals_dialog.dart';
import '../views/edit_profile_page.dart';
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
  final ImagePickerService _imagePickerService = ImagePickerService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  DailyGoals? _dailyGoals;
  bool _isLoadingGoals = false;
  bool _isUploadingProfilePhoto = false;

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

  int? _toUserId(dynamic id) {
    if (id is int) {
      return id;
    }
    return int.tryParse((id ?? '').toString());
  }

  Future<bool> _ensurePhotoPermission() async {
    PermissionStatus status;
    if (Platform.isIOS) {
      status = await Permission.photos.request();
    } else if (Platform.isAndroid) {
      status = await Permission.photos.request();
      if (!status.isGranted && !status.isLimited) {
        status = await Permission.storage.request();
      }
    } else {
      return true;
    }

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Photo permission is blocked. Open app settings to allow access.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: openAppSettings,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo permission is required to upload a profile picture.')),
      );
    }

    return false;
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    if (_isUploadingProfilePhoto) {
      return;
    }

    final hasPermission = await _ensurePhotoPermission();
    if (!hasPermission) {
      return;
    }

    final userId = _toUserId(widget.authController.currentUser?.id);
    if (userId == null || userId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to identify this account. Please login again.')),
      );
      return;
    }

    try {
      final pickedFile = await _imagePickerService.pickImageFromGallery();
      if (pickedFile == null) {
        return;
      }

      if (!ImagePickerService.validateImageFile(file: pickedFile)) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid image. Use JPG/PNG/WEBP/GIF under 10MB.'),
          ),
        );
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isUploadingProfilePhoto = true;
      });

      final photoPath = await _imageUploadService.uploadProfileImage(
        imageFile: pickedFile,
        userId: userId,
      );

      final saved = await widget.authController.updateProfilePhoto(
        userId: userId,
        profilePhotoPath: photoPath,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? 'Profile photo updated successfully.'
                : widget.authController.errorMessage,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload profile photo: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingProfilePhoto = false;
        });
      }
    }
  }

  Future<void> _showAvatarActions() async {
    if (_isUploadingProfilePhoto) {
      return;
    }

    final user = widget.authController.currentUser;
    final storedPath = user?.profilePhotoUrl?.trim() ?? '';
    final hasPhoto = storedPath.isNotEmpty;

    final selectedAction = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('View profile photo'),
                enabled: hasPhoto,
                onTap: () => Navigator.of(context).pop('view'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Change profile photo'),
                onTap: () => Navigator.of(context).pop('change'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selectedAction == null) {
      return;
    }

    if (selectedAction == 'view') {
      if (!hasPhoto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No profile photo yet.')),
        );
        return;
      }
      _showProfilePhotoPreview(storedPath);
      return;
    }

    if (selectedAction == 'change') {
      await _pickAndUploadProfilePhoto();
    }
  }

  Future<void> _showProfilePhotoPreview(String storedPath) async {
    final imageUrl = _imageUploadService.resolveProfilePhotoUrl(storedPath);
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No profile photo available.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Unable to load profile photo.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
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

  Widget _buildAvatar(LoginUser? user, ThemeData theme) {
    final storedPath = user?.profilePhotoUrl?.trim() ?? '';
    final photoUrl = _imageUploadService.resolveProfilePhotoUrl(storedPath);

    if (photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stackTrace) {
            return CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.secondary,
              child: Icon(
                Icons.person,
                size: 50,
                color: theme.colorScheme.onSecondary,
              ),
            );
          },
        ),
      );
    }

    return CircleAvatar(
      radius: 50,
      backgroundColor: theme.colorScheme.secondary,
      child: Icon(
        Icons.person,
        size: 50,
        color: theme.colorScheme.onSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.authController.currentUser;
    final mutedColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
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
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _isUploadingProfilePhoto ? null : _showAvatarActions,
                        child: _buildAvatar(user, theme),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.surface, width: 2),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: _isUploadingProfilePhoto
                            ? SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: theme.colorScheme.onPrimary,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _displayName(user),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _displayEmail(user),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      user?.isAdmin == true ? 'Admin' : 'Member',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
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
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    color: theme.colorScheme.surfaceContainerHighest,
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
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Editable Daily Goals Card
                  GestureDetector(
                    onTap: _editDailyGoals,
                    child: Card(
                      elevation: 2,
                      color: theme.colorScheme.surfaceContainerHighest,
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
                                    color: theme.colorScheme.onSurface,
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
                                color: mutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // _GoalItem(
                  //   title: 'Daily Steps Goal',
                  //   value: '10,000 steps',
                  //   icon: Icons.directions_walk,
                  //   iconColor: theme.colorScheme.tertiary,
                  // ),
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
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _OptionItem(
                    title: 'Edit Profile',
                    icon: Icons.edit,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(
                            authController: widget.authController,
                          ),
                        ),
                      );
                    },
                  ),
                  // _OptionItem(
                  //   title: 'Notifications',
                  //   icon: Icons.notifications,
                  //   onTap: () {},
                  // ),
                  // _OptionItem(
                  //   title: 'Privacy & Security',
                  //   icon: Icons.privacy_tip,
                  //   onTap: () {},
                  // ),
                  // _OptionItem(
                  //   title: 'Help & Support',
                  //   icon: Icons.help,
                  //   onTap: () {},
                  // ),
                  _OptionItem(
                    title: 'Logout',
                    icon: Icons.logout,
                    onTap: () async {
                      await _sessionService.clearSession();
                      await widget.authController.logout();
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
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
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
    final color = isDestructive ? Colors.red : theme.colorScheme.onSurface;

    return Card(
      elevation: 1,
      color: theme.colorScheme.surfaceContainerHighest,
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
          color: isDestructive
              ? Colors.red
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.all(11),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
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

