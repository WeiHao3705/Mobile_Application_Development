import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
        currentIndex: selectedIndex,
        onTap: onTap,
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
            icon: Icon(selectedIndex == 0 ? Icons.home : Icons.home_outlined),
            label: 'Home',
            backgroundColor: theme.colorScheme.primary,
          ),
          BottomNavigationBarItem(
            icon: Icon(selectedIndex == 1
                ? Icons.fitness_center
                : Icons.fitness_center_outlined),
            label: 'Exercise',
            backgroundColor: theme.colorScheme.primary,
          ),
          BottomNavigationBarItem(
            icon: Icon(selectedIndex == 2
                ? Icons.restaurant
                : Icons.restaurant_outlined),
            label: 'Diet',
            backgroundColor: theme.colorScheme.primary,
          ),
          BottomNavigationBarItem(
            icon: Icon(selectedIndex == 3 ? Icons.person : Icons.person_outlined),
            label: 'Profile',
            backgroundColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

