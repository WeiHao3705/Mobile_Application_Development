import 'dart:async';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  Timer? _resendTimer;
  bool _isSending = false;
  bool _resetLinkSent = false;
  int _resendSecondsLeft = 60;
  String? _sentEmail;
  String? _sentAccountLabel;

  @override
  void dispose() {
    _resendTimer?.cancel();
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

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() {
      _resendSecondsLeft = 60;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendSecondsLeft <= 1) {
        setState(() {
          _resendSecondsLeft = 0;
        });
        timer.cancel();
        return;
      }

      setState(() {
        _resendSecondsLeft -= 1;
      });
    });
  }

  Future<void> _openEmailApp() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.APP_EMAIL',
        );
        await intent.launch();
        return;
      } catch (_) {
        // Fallback below.
      }
    }

    final gmailInboxUri = Uri.parse('https://mail.google.com/mail/u/0/#inbox');
    final openedGmailWeb = await launchUrl(
      gmailInboxUri,
      mode: LaunchMode.externalApplication,
    );
//
    if (!openedGmailWeb && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open an email app. Please open your inbox manually.'),
        ),
      );
    }
  }

  Future<void> _sendResetLink({bool isResend = false}) async {
    if (!isResend) {
      final formState = _formKey.currentState;
      if (formState == null || !formState.validate()) {
        return;
      }
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSending = true;
    });

    final email = isResend
        ? (_sentEmail ?? _emailController.text.trim())
        : _emailController.text.trim();

    if (!_isValidEmail(email)) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email before resending.')),
        );
      }
      return;
    }

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

      if (success) {
        _sentEmail = email;
        _sentAccountLabel = _displayAccountLabel(account, email);
        _resetLinkSent = true;
        _startResendCountdown();

        if (isResend) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reset email sent again.')),
          );
        }
        return;
      }

      message = widget.authController.errorMessage;
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
  }

  Widget _buildResetSentView(ThemeData theme) {
    final sentEmail = _sentEmail ?? _emailController.text.trim();
    final sentLabel = _sentAccountLabel ?? sentEmail;
    final canResend = _resendSecondsLeft == 0 && !_isSending;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Check your inbox',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'We sent a reset link for $sentLabel. Open your email app to continue.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _openEmailApp,
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Open Email App'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: canResend ? () => _sendResetLink(isResend: true) : null,
                  child: _isSending
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onSurface,
                          ),
                        )
                      : Text(
                          canResend
                              ? 'Resend Email'
                              : 'Resend available in ${_resendSecondsLeft}s',
                        ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _resetLinkSent = false;
                    });
                  },
                  child: const Text('Use a different email'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: _resetLinkSent
                    ? _buildResetSentView(theme)
                    : Center(
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
            );
          },
        ),
      ),
    );
  }
}

