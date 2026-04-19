import 'package:flutter/material.dart';
import 'package:mobile_application_development/views/login_page.dart';
import 'package:mobile_application_development/views/sign_up_pages.dart';

class LandingPage extends StatelessWidget {
  static const routeName = '/landing';

  const LandingPage({super.key});

  Widget _buildBranding(ThemeData theme, {TextAlign textAlign = TextAlign.center}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          textAlign == TextAlign.center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Image.asset(
          'lib/Image/Logo.png',
          width: 180,
          height: 180,
          fit: BoxFit.contain, // Keep full logo visible without cropping.
        ),
        const SizedBox(height: 20),
        Text(
          'Welcome to FitTrack',
          textAlign: textAlign,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track your workouts, meals, and progress in one place.',
          textAlign: textAlign,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, LoginPage.routeName);
          },
          child: const Text('Login'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            Navigator.pushNamed(context, SignUpPages.routeName);
          },
          child: const Text('Sign Up'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: isLandscape
                        ? Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: Center(
                                  child: _buildBranding(
                                    theme,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                flex: 4,
                                child: _buildActions(context),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildBranding(theme),
                              const SizedBox(height: 40),
                              _buildActions(context),
                            ],
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
