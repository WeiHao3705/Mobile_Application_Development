import 'package:flutter/material.dart';

import '../models/exercise.dart';

class ExerciseDetailPage extends StatelessWidget {
  const ExerciseDetailPage({
    super.key,
    required this.exercise,
  });

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
        title: const Text('Exercise Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VideoPanel(videoUrl: exercise.videoUrl),
            const SizedBox(height: 20),
            _DetailRow(label: 'Exercise Name', value: exercise.name),
            _DetailRow(label: 'Primary Muscle', value: exercise.primaryMuscle),
            _DetailRow(label: 'Secondary Muscle', value: exercise.secondaryMuscle),
            _DetailRow(label: 'How To Do', value: exercise.howTo),
          ],
        ),
      ),
    );
  }
}

class _VideoPanel extends StatelessWidget {
  const _VideoPanel({required this.videoUrl});

  final String? videoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasVideo = videoUrl != null && videoUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pause_circle_filled,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              hasVideo ? 'Video loaded (paused)' : 'No video available',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

