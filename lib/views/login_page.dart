import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import 'admin_dashboard_page.dart';
import 'forgot_password_page.dart';
import 'landing_page.dart';
import 'main_navigation.dart';

class LoginPage extends StatefulWidget {
  static const routeName = '/login';

  const LoginPage({super.key, required this.authController});

  final AuthController authController;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  AuthController get _authController => widget.authController;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await _authController.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authController.errorMessage)),
      );
      return;
    }

    final targetRoute = _authController.isAdmin
        ? AdminDashboardPage.routeName
        : MainNavigation.routeName;

    Navigator.pushNamedAndRemoveUntil(
      context,
      targetRoute,
          (route) => false,
    );
  }

  void _goToLanding() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      LandingPage.routeName,
      (route) => false,
    );
  }

  Future<void> _openForgotPasswordPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ForgotPasswordPage(authController: _authController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _authController,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _authController.isLoading ? null : _goToLanding,
            ),
            title: const Text('Login'),
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
                                    'Sign in to continue',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Username',
                                      border: OutlineInputBorder(),
                                    ),
                                    textInputAction: TextInputAction.next,
                                    enabled: !_authController.isLoading,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter your username';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: const InputDecoration(
                                      labelText: 'Password',
                                      border: OutlineInputBorder(),
                                    ),
                                    obscureText: true,
                                    enabled: !_authController.isLoading,
                                    onFieldSubmitted: (_) => _handleLogin(),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _authController.isLoading
                                          ? null
                                          : _openForgotPasswordPage,
                                      child: const Text('Forgot password?'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _authController.isLoading ? null : _handleLogin,
                                    child: _authController.isLoading
                                        ? SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: theme.colorScheme.onPrimary,
                                            ),
                                          )
                                        : const Text('Login'),
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
      },
    );
  }
}

