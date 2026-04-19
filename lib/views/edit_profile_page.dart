import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/auth_controller.dart';

class EditProfilePage extends StatefulWidget {
  static const routeName = '/edit-profile';

  const EditProfilePage({super.key, required this.authController});

  final AuthController authController;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _fullNameController;
  late TextEditingController _heightController;
  late TextEditingController _currentWeightController;
  late TextEditingController _targetWeightController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = widget.authController.currentUser;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _heightController = TextEditingController(text: user?.height?.toString() ?? '');
    _currentWeightController = TextEditingController(text: user?.currentWeight?.toString() ?? '');
    _targetWeightController = TextEditingController(text: user?.targetWeight?.toString() ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _heightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  String _friendlyProfileError(String rawMessage) {
    final raw = rawMessage.toLowerCase();

    if (raw.contains('duplicate') ||
        raw.contains('unique') ||
        raw.contains('already') ||
        raw.contains('violates')) {
      return 'This username is already in use. Please choose another one.';
    }
    if (raw.contains('network') || raw.contains('socket') || raw.contains('timeout')) {
      return 'Network issue detected. Please check your connection and try again.';
    }
    if (raw.contains('permission') || raw.contains('row-level security')) {
      return 'Unable to update your profile right now. Please try again later.';
    }

    return 'Unable to update profile right now. Please try again.';
  }

  Future<bool> _isUsernameAvailable(String newUsername) async {
    final trimmedUsername = newUsername.trim().toLowerCase();
    final user = widget.authController.currentUser;

    // If username hasn't changed (case-insensitive), it's available
    if (trimmedUsername == (user?.username ?? '').toLowerCase()) {
      return true;
    }

    try {
      final response = await Supabase.instance.client
          .from('User')
          .select('user_id')
          .ilike('username', trimmedUsername) // ilike for case-insensitive comparison
          .maybeSingle();

      return response == null; // Username is available if no record found
    } catch (_) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to verify username right now. Please try again.')),
      );
      return false;
    }
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = widget.authController.currentUser;
      if (user == null || user.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User session invalid. Please login again.')),
        );
        return;
      }

      final newUsername = _usernameController.text.trim();

      // Check if username is available (if it was changed)
      if (newUsername != user.username) {
        final isAvailable = await _isUsernameAvailable(newUsername);
        if (!isAvailable) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Username is already taken. Please choose another.')),
          );
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
      }

      final updatedUser = user.copyWith(
        username: newUsername,
        fullName: _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
        height: double.tryParse(_heightController.text.trim()),
        currentWeight: double.tryParse(_currentWeightController.text.trim()),
        targetWeight: double.tryParse(_targetWeightController.text.trim()),
      );

      // Update the user in the database
      await Supabase.instance.client
          .from('User')
          .update({
            'username': newUsername,
            'full_name': _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
            'height': double.tryParse(_heightController.text.trim()),
            'current_weight': double.tryParse(_currentWeightController.text.trim()),
            'target_weight': double.tryParse(_targetWeightController.text.trim()),
          })
          .eq('user_id', user.id);

      // Update the session
      widget.authController.updateSessionUser(updatedUser);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyProfileError(error.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  InputDecoration _profileInputDecoration(ThemeData theme, String labelText) {
    final errorColor = theme.colorScheme.error;
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
      errorStyle: TextStyle(color: errorColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          user?.email ?? 'N/A',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Editable Username field
                Text(
                  'Username',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  decoration: _profileInputDecoration(theme, 'Username'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (value.trim().length > 20) {
                      return 'Username must be less than 20 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Editable fields
                Text(
                  'Full Name',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fullNameController,
                  decoration: _profileInputDecoration(theme, 'Full Name'),
                  validator: (value) {
                    // Full name is optional
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                Text(
                  'Height (cm)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _profileInputDecoration(theme, 'Height in cm'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                Text(
                  'Current Weight (kg)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _currentWeightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _profileInputDecoration(theme, 'Current weight in kg'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                Text(
                  'Target Weight (kg)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _targetWeightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _profileInputDecoration(theme, 'Target weight in kg'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

