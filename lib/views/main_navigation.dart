import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'nutrition_main_page.dart';
import 'exercise_hub_page.dart';
import 'login_page.dart';

class MainNavigation extends StatefulWidget {
  static const routeName = '/main';

  const MainNavigation({super.key, required this.authController});

  final AuthController authController;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  bool _isRedirectingToLanding = false;

  // Dark purple palette used by the bottom navigation.
  static const Color _navBackground = Color(0xFF1C1330);
  static const Color _navSelected = Color(0xFFC8A2FF);
  static const Color _navUnselected = Color(0xFF8A78A8);
  static const Color _navShadow = Color(0xFF120B1F);

  late final List<Widget> _pages = [
    HomePage(authController: widget.authController),
    ExerciseHubPage(authController: widget.authController),
    NutritionMainPage(authController: widget.authController),
    ProfilePage(authController: widget.authController),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleAuthStateChange() {
    if (!mounted || _isRedirectingToLanding || widget.authController.isLoggedIn) {
      return;
    }

    _isRedirectingToLanding = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginPage.routeName,
        (route) => false,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    widget.authController.addListener(_handleAuthStateChange);
    _handleAuthStateChange();
  }

  @override
  void didUpdateWidget(covariant MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authController != widget.authController) {
      oldWidget.authController.removeListener(_handleAuthStateChange);
      widget.authController.addListener(_handleAuthStateChange);
      _handleAuthStateChange();
    }
  }

  @override
  void dispose() {
    widget.authController.removeListener(_handleAuthStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.authController.isLoggedIn) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: _navShadow.withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: _navBackground,
          selectedItemColor: _navSelected,
          unselectedItemColor: _navUnselected,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 0 ? Icons.home : Icons.home_outlined),
              label: 'Home',
              backgroundColor: _navBackground,
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 1
                  ? Icons.fitness_center
                  : Icons.fitness_center_outlined),
              label: 'Exercise',
              backgroundColor: _navBackground,
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 2
                  ? Icons.restaurant
                  : Icons.restaurant_outlined),
              label: 'Diet',
              backgroundColor: _navBackground,
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 3 ? Icons.person : Icons.person_outlined),
              label: 'Profile',
              backgroundColor: _navBackground,
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder page for Exercise and Diet tabs
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              title == 'Exercise' ? Icons.fitness_center : Icons.restaurant,
              size: 80,
              color: theme.colorScheme.secondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '$title Page',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}