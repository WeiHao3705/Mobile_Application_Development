import 'package:flutter/material.dart';

class HomeDailyProgressCard extends StatelessWidget {
  const HomeDailyProgressCard({
    super.key,
    required this.title,
    required this.currentValue,
    required this.targetValue,
    required this.displayUnit,
    required this.icon,
    required this.iconColor,
    required this.progress,
    required this.isLoading,
    this.progressColor,
  });

  final String title;
  final int currentValue;
  final int targetValue;
  final String displayUnit;
  final IconData icon;
  final Color iconColor;
  final double progress; // 0.0 to 1.0 (can exceed 1.0 if exceeded goal)
  final bool isLoading;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final displayProgress = progress.clamp(0.0, 1.0);

    final headerText = Column(
      crossAxisAlignment: isPortrait ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: isPortrait ? TextAlign.center : TextAlign.start,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$currentValue / $targetValue $displayUnit',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    final headerIcon = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 28),
    );

    return Card(
      elevation: 2,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portrait: icon above text. Landscape: icon beside text.
            if (isPortrait)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  headerIcon,
                  const SizedBox(height: 10),
                  Center(child: headerText),
                ],
              )
            else
              Row(
                children: [
                  headerIcon,
                  const SizedBox(width: 12),
                  Expanded(child: headerText),
                ],
              ),
            const SizedBox(height: 16),

            // Progress bar
            if (isLoading)
              const SizedBox(
                height: 8,
                child: LinearProgressIndicator(),
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  minHeight: 12,
                  value: displayProgress,
                  backgroundColor: theme.colorScheme.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressColor ??
                        (progress > 1.0
                            ? Colors.green // Exceeded goal
                            : progress > 0.75
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${(displayProgress * 100).toStringAsFixed(0)}% of today\'s goal',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

