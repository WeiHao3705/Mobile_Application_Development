import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import 'aerobic_page.dart';
import 'workout_page.dart';

class ExercisePage extends StatelessWidget {
  const ExercisePage({super.key, required this.authController});

  final AuthController authController;

  int? get _userId {
    final currentUser = authController.currentUser;
    final id = currentUser?.id;
    if (id is int) {
      return id;
    }
    return int.tryParse(id?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Exercise'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.fitness_center,
                size: 80,
                color: Colors.white54,
              ),
              const SizedBox(height: 32),
              Text(
                'Choose Your Exercise Type',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              // Aerobic Button
              ElevatedButton(
                onPressed: () {
                  final userId = _userId;
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User ID not available')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AerobicPage(userId: userId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                ),
                child: Text(
                  'Aerobic',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 48),
              // Workout Button
              ElevatedButton(
                onPressed: () {
                  final userId = _userId;
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please log in again to open Workout.')),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutPage(userId: userId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                ),
                child: Text(
                  'Workout',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),

            ],
          )
      ),
    );
  }
}