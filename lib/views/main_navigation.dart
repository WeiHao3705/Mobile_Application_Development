import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'exercise_page.dart';

class MainNavigation extends StatefulWidget {
  static const routeName = '/main';

  const MainNavigation({super.key, required this.authController});

  final AuthController authController;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const HomePage(),
    const ExercisePage(),
    const _PlaceholderPage(title: 'Diet'),
    ProfilePage(authController: widget.authController),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.brightness == Brightness.light
              ? Colors.white
              : theme.scaffoldBackgroundColor,
          selectedItemColor: theme.colorScheme.secondary,
          unselectedItemColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 0 ? Icons.home : Icons.home_outlined),
              label: 'Home',
              backgroundColor: theme.colorScheme.primary,
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 1
                  ? Icons.fitness_center
                  : Icons.fitness_center_outlined),
              label: 'Exercise',
              backgroundColor: theme.colorScheme.primary,
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 2
                  ? Icons.restaurant
                  : Icons.restaurant_outlined),
              label: 'Diet',
              backgroundColor: theme.colorScheme.primary,
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 3 ? Icons.person : Icons.person_outlined),
              label: 'Profile',
              backgroundColor: theme.colorScheme.primary,
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
              color: theme.colorScheme.secondary.withOpacity(0.5),
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
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
