import 'package:flutter/material.dart';
import 'package:mobile_application_development/theme/app_colors.dart';
import '../models/aerobic.dart';
import '../repository/aerobic_repository.dart';

class AerobicDetailPage extends StatelessWidget {
  final Aerobic record;

  const AerobicDetailPage({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.lavender.withValues(alpha: 0.55),
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.chevron_left,
                          color: AppColors.lime,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Session Details',
                        style: TextStyle(
                          color: AppColors.lavender,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Route Image at the top
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildImageSection(),
              ),
              const SizedBox(height: 24),

              // Activity Information Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Activity Type and Location
                    _buildInfoHeader(),
                    const SizedBox(height: 20),

                    // Performance Metrics (2x3 Grid)
                    _buildMetricsGrid(),
                    const SizedBox(height: 24),

                    // Additional Details
                    _buildAdditionalDetails(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final resolver = AerobicRepository();
    final resolvedImageUrl = resolver.resolveRouteImageUrl(record.route_image);

    if (resolvedImageUrl.isEmpty) {
      print('⚠️  [AEROBIC-DETAIL] Image URL is empty for: ${record.route_image}');
    } else {
      print('✅ [AEROBIC-DETAIL] Loading image from: $resolvedImageUrl');
    }
    
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: resolvedImageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                resolvedImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.lime,
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Error loading detail route image: $error | raw=${record.route_image} | resolved=$resolvedImageUrl');
                  return _buildPlaceholderImage();
                },
              ),
            )
          : _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            'Route Image',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          record.activity_type.toUpperCase(),
          style: const TextStyle(
            color: AppColors.lime,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          record.location,
          style: const TextStyle(
            color: AppColors.lavender,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          record.formattedDate,
          style: const TextStyle(
            color: AppColors.lavender,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    final metrics = [
      {
        'label': 'Distance',
        'value': '${record.total_distance.toStringAsFixed(2)} km',
        'icon': Icons.directions_run,
      },
      {
        'label': 'Duration',
        'value': record.formattedDuration,
        'icon': Icons.timer,
      },
      {
        'label': 'Average Pace',
        'value': _formatPace(record.average_pace),
        'icon': Icons.speed,
      },
      {
        'label': 'Calories Burned',
        'value': '${record.calories_burned} kcal',
        'icon': Icons.local_fire_department,
      },
      {
        'label': 'Steps',
        'value': record.total_step.toString(),
        'icon': Icons.terrain,
      },
      {
        'label': 'Elevation Gain',
        'value': '${record.elevation_gain} m',
        'icon': Icons.terrain,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return _buildMetricCard(
          label: metric['label'] as String,
          value: metric['value'] as String,
          icon: metric['icon'] as IconData,
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.nearBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lavender.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.lime,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.lavender,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Information',
          style: TextStyle(
            color: AppColors.lime,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow('Footwear', record.footwear),
        const SizedBox(height: 8),
        _buildDetailRow('Moving Time', '${record.moving_time} seconds'),
        const SizedBox(height: 8),
        _buildDetailRow(
          'Start Time',
          '${record.start_at.hour.toString().padLeft(2, '0')}:${record.start_at.minute.toString().padLeft(2, '0')}',
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          'End Time',
          '${record.end_at.hour.toString().padLeft(2, '0')}:${record.end_at.minute.toString().padLeft(2, '0')}',
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.nearBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.lavender.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.lavender,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.lime,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPace(int pace) {
    int minutes = pace ~/ 100;
    int seconds = pace % 100;
    return '$minutes:${seconds.toString().padLeft(2, '0')}/km';
  }
}
