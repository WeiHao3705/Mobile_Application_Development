import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'controllers/auth_controller.dart';
import 'theme/app_theme.dart';
import 'views/landing_page.dart';
import 'views/login_page.dart';
import 'views/main_navigation.dart';
import 'views/sign_up_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthController _authController = AuthController();

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: LandingPage.routeName,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case LandingPage.routeName:
            return MaterialPageRoute<void>(
              builder: (_) => const LandingPage(),
              settings: settings,
            );
          case LoginPage.routeName:
            return MaterialPageRoute<void>(
              builder: (_) => LoginPage(authController: _authController),
              settings: settings,
            );
          case MainNavigation.routeName:
            return MaterialPageRoute<void>(
              builder: (_) => MainNavigation(authController: _authController),
              settings: settings,
            );
          case SignUpPages.routeName:
            return MaterialPageRoute<void>(
              builder: (_) => SignUpPages(authController: _authController),
              settings: settings,
            );
          default:
            return MaterialPageRoute<void>(
              builder: (_) => const LandingPage(),
              settings: settings,
            );
        }
      },
    );
  }
}
