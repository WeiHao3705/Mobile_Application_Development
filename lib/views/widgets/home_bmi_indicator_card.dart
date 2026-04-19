import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class HomeBmiIndicatorCard extends StatelessWidget {
  const HomeBmiIndicatorCard({
    super.key,
    required this.bmi,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.isLoading,
    required this.errorText,
    required this.onTap,
    required this.onRetry,
  });

  final double? bmi;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final bool isLoading;
  final String? errorText;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  String _category(double value) {
    if (value < 18.5) return 'Underweight';
    if (value < 25) return 'Normal';
    if (value < 30) return 'Overweight';
    if (value < 40) return 'Obese';
    return 'Morbidly Obese';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bmiValue = (bmi ?? 10).clamp(10.0, 40.0);

    return Card(
      elevation: 2,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.monitor_weight, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'BMI Indicator',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to calculate',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isLoading)
                const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (errorText != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      errorText!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                )
              else ...[
                SizedBox(
                  height: 140,
                  child: SfRadialGauge(
                    axes: [
                      RadialAxis(
                        minimum: 10,
                        maximum: 40,
                        startAngle: 180,
                        endAngle: 0,
                        showLabels: false,
                        showTicks: false,
                        ranges: [
                          GaugeRange(startValue: 10, endValue: 18.5, color: Colors.lightBlue, startWidth: 18, endWidth: 18),
                          GaugeRange(startValue: 18.5, endValue: 25, color: Colors.green, startWidth: 18, endWidth: 18),
                          GaugeRange(startValue: 25, endValue: 30, color: Colors.yellow.shade700, startWidth: 18, endWidth: 18),
                          GaugeRange(startValue: 30, endValue: 40, color: Colors.red, startWidth: 18, endWidth: 18),
                        ],
                        pointers: [
                          NeedlePointer(
                            value: bmiValue,
                            enableAnimation: true,
                            animationType: AnimationType.ease,
                            needleLength: 0.72,
                            needleEndWidth: 5,
                            knobStyle: const KnobStyle(knobRadius: 0.08),
                          ),
                        ],
                        annotations: [
                          GaugeAnnotation(
                            angle: 90,
                            positionFactor: 0.35,
                            widget: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  bmi?.toStringAsFixed(1) ?? '--',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  bmi == null ? 'BMI' : _category(bmi!),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Age: ${age ?? '--'} years   Weight: ${weightKg?.toStringAsFixed(1) ?? '--'} kg   Height: ${heightCm?.toStringAsFixed(1) ?? '--'} cm',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to open BMI calculator',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

