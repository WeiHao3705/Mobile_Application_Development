import 'package:flutter/material.dart';

import '../../models/water_intake.dart';
import '../../utils/time_formatters.dart';

class HomeHydrationProgressCard extends StatelessWidget {
  const HomeHydrationProgressCard({
    super.key,
    required this.waterIntake,
    required this.isLoading,
    required this.errorText,
    required this.onTap,
    required this.onRetry,
  });

  final WaterIntake? waterIntake;
  final bool isLoading;
  final String? errorText;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  String _formatLastUpdated(DateTime? value) {
    return formatRelativeTime(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intake = waterIntake;
    const hydrationBlue = Colors.blue;
    final lastUpdatedText = _formatLastUpdated(intake?.lastUpdated);

    return Card(
      elevation: 2,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.water_drop, color: hydrationBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Hydration Progress',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (intake != null)
                    Text(
                      '${intake.progressPercent.toStringAsFixed(1)}%',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (isLoading)
                const LinearProgressIndicator(minHeight: 8)
              else ...[
                LinearProgressIndicator(
                  minHeight: 8,
                  value: (intake?.progressRatio ?? 0).clamp(0.0, 1.0),
                  color: hydrationBlue,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 8),
                Text(
                  errorText ??
                      '${(intake?.currentAmount ?? 0).toStringAsFixed(0)} ml / ${(intake?.targetAmount ?? 0).toStringAsFixed(0)} ml',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (errorText == null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: $lastUpdatedText',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Tap to add water intake',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              if (!isLoading && errorText != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

