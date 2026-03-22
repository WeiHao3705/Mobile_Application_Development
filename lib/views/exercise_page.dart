import 'package:flutter/material.dart';
import 'aerobic_page.dart';

class ExercisePage extends StatelessWidget{
  const ExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
              color: Colors.grey,
            ),
            const SizedBox(height: 32),
            Text(
              'Choose Your Exercise Type',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            // Aerobic Button
            ElevatedButton(onPressed: (){
              Navigator.push(
                context, MaterialPageRoute(
                  builder: (context) => const AerobicPage()),
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
            ElevatedButton(onPressed: (){
              Navigator.push(
                context, MaterialPageRoute(
                  builder: (context) => const AerobicPage()),
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