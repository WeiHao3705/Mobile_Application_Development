import 'package:flutter/material.dart';

import '../config/supabase_config.dart';
import '../controllers/auth_controller.dart';
import '../models/app_user.dart';

class ForgotPasswordPage extends StatefulWidget {
  static const routeName = '/forgot-password';

  const ForgotPasswordPage({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}
//
class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final email = value.trim();
    return email.contains('@') && email.contains('.');
  }

  String? _readText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  String _displayAccountLabel(AppUser? account, String fallbackEmail) {
    final username = _readText(account?.data['username']);
    return username ?? fallbackEmail;
  }

  Future<void> _sendResetLink() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSending = true;
    });

    final email = _emailController.text.trim();
    AppUser? account;
    String message = 'Unable to send reset email right now.';

    try {
      account = await widget.authController.fetchUserByEmail(email);
      final success = await widget.authController.sendPasswordResetEmail(
        email: email,
        redirectTo: passwordResetRedirectUrl,
      );

      if (!mounted) {
        return;
      }

      message = success
          ? 'Reset link sent for ${_displayAccountLabel(account, email)}. Check your email inbox.'
          : widget.authController.errorMessage;
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    if (message.startsWith('Reset link sent')) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                          'Reset your password',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Enter your account email and we will send a reset link.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_isSending,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!_isValidEmail(email)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isSending ? null : _sendResetLink,
                          child: _isSending
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                )
                              : const Text('Send Reset Link'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

