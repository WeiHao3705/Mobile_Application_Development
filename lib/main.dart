import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'controllers/auth_controller.dart';
import 'controllers/food_controller.dart';
import 'controllers/meal_controller.dart';
import 'theme/app_theme.dart';
import 'views/admin_dashboard_page.dart';
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
  late final Future<void> _startupFuture;

  Route<dynamic> _buildSafeRoute({
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) {
        try {
          return builder(context);
        } catch (error, stackTrace) {
          debugPrint('Route build failed for ${settings.name}: $error');
          debugPrintStack(stackTrace: stackTrace);
          return _RouteErrorScreen(routeName: settings.name);
        }
      },
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    try {
      switch (settings.name) {
        case LandingPage.routeName:
          return _buildSafeRoute(
            settings: settings,
            builder: (_) => const LandingPage(),
          );
        case LoginPage.routeName:
          return _buildSafeRoute(
            settings: settings,
            builder: (_) => LoginPage(authController: _authController),
          );
        case MainNavigation.routeName:
          if (!_authController.isLoggedIn) {
            return _buildSafeRoute(
              settings: settings,
              builder: (_) => const LandingPage(),
            );
          }
          return _buildSafeRoute(
            settings: settings,
            builder: (_) => MainNavigation(authController: _authController),
          );
        case AdminDashboardPage.routeName:
          if (!_authController.isLoggedIn) {
            return _buildSafeRoute(
              settings: settings,
              builder: (_) => const LandingPage(),
            );
          }
          if (!_authController.isAdmin) {
            return _buildSafeRoute(
              settings: settings,
              builder: (_) => MainNavigation(authController: _authController),
            );
          }
          return _buildSafeRoute(
            settings: settings,
            builder: (_) => AdminDashboardPage(authController: _authController),
          );
        case SignUpPages.routeName:
          return _buildSafeRoute(
            settings: settings,
            builder: (_) => SignUpPages(authController: _authController),
          );
        default:
          return _buildSafeRoute(
            settings: settings,
            builder: (_) => const LandingPage(),
          );
      }
    } catch (error, stackTrace) {
      debugPrint('Route generation failed for ${settings.name}: $error');
      debugPrintStack(stackTrace: stackTrace);
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => _RouteErrorScreen(routeName: settings.name),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _startupFuture = _authController.restoreSession();
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  Widget get _initialPage {
    if (!_authController.isLoggedIn) {
      return const LandingPage();
    }
    return _authController.isAdmin
        ? AdminDashboardPage(authController: _authController)
        : MainNavigation(authController: _authController);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>(
          create: (_) => _authController,
        ),
        ChangeNotifierProvider(
          create: (_) => FoodController(),
        ),
        ChangeNotifierProvider(
          create: (_) => MealController(),
        ),
      ],
      child: FutureBuilder<void>(
        future: _startupFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.dark,
              home: const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          return MaterialApp(
            title: 'FitTrack',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: _initialPage,
            onGenerateRoute: _onGenerateRoute,
            onUnknownRoute: (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => _RouteErrorScreen(routeName: settings.name),
            ),
          );
        },
      ),
    );
  }
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Unable to open route: ${routeName ?? '(unknown)'}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}