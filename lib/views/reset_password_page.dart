import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/auth_controller.dart';
import '../models/app_user.dart';
import '../services/password_hasher.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  static const routeName = '/reset-password';

  const ResetPasswordPage({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AppUser? _recoveredAccount;
  String? _recoveryEmail;
  String? _oldPasswordHash;
  String? _accountError;
  bool _isLoadingAccount = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadRecoveredAccount();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _readText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  String get _displayAccountLabel {
    final username = _readText(_recoveredAccount?.data['username']);
    if (username != null) {
      return username;
    }

    return _recoveryEmail ?? 'your account';
  }

  Future<void> _loadRecoveredAccount() async {
    final auth = Supabase.instance.client.auth;
    final email = _readText(auth.currentUser?.email ?? auth.currentSession?.user.email);

    if (!mounted) {
      return;
    }

    if (email == null) {
      setState(() {
        _isLoadingAccount = false;
        _accountError = 'Recovery session is missing. Please open the reset link again.';
      });
      return;
    }

    try {
      final account = await widget.authController.fetchUserByEmail(email);
      if (!mounted) {
        return;
      }

      // Fetch the old password hash from User table for validation
      String? oldPasswordHash;
      if (account != null) {
        try {
          final response = await Supabase.instance.client
              .from('User')
              .select('password')
              .ilike('email', email)
              .maybeSingle();

          if (response != null) {
            oldPasswordHash = response['password']?.toString();
          }
        } catch (_) {
          // Continue without old password hash if fetch fails
        }
      }

      setState(() {
        _recoveryEmail = email;
        _recoveredAccount = account;
        _oldPasswordHash = oldPasswordHash;
        _isLoadingAccount = false;
        _accountError = account == null
            ? 'We could not match this reset link to a saved profile. Please request a new reset link.'
            : null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _recoveryEmail = email;
        _isLoadingAccount = false;
        _accountError = 'Unable to load the account details right now. Please retry.';
      });
    }
  }

  bool _isSameAsOldPassword(String newPassword) {
    if (_oldPasswordHash == null || _oldPasswordHash!.isEmpty) {
      return false;
    }

    final newPasswordHash = PasswordHasher.hash(newPassword.trim());
    return newPasswordHash == _oldPasswordHash;
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    // Additional check: new password cannot be the same as old password
    if (_isSameAsOldPassword(_passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be different from the old password.'),
        ),
      );
      return;
    }

    if (_isLoadingAccount || _accountError != null || _recoveryEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_accountError ?? 'Recovery session is still loading. Please wait.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await widget.authController.completePasswordReset(
      newPassword: _passwordController.text,
      email: _recoveryEmail,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Password updated successfully for $_displayAccountLabel.'
              : widget.authController.errorMessage,
        ),
      ),
    );

    if (success) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginPage.routeName,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountName = _displayAccountLabel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Card(
                      color: theme.colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Set a new password',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_isLoadingAccount) ...[
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text('Loading account details...'),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Text(
                                  'You are changing the password for $accountName.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                if (_recoveryEmail != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _recoveryEmail!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                              if (_accountError != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _accountError!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _passwordController,
                                enabled: !_isSubmitting && !_isLoadingAccount && _accountError == null,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'New Password',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a new password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _confirmPasswordController,
                                enabled: !_isSubmitting && !_isLoadingAccount && _accountError == null,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm Password',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your new password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: (_isSubmitting || _isLoadingAccount || _accountError != null)
                                    ? null
                                    : _submit,
                                child: _isSubmitting
                                    ? SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      )
                                    : const Text('Update Password'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

