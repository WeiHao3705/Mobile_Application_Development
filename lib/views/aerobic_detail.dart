import 'package:flutter/material.dart';
import 'package:mobile_application_development/theme/app_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/aerobic.dart';
import '../repository/aerobic_repository.dart';

class AerobicDetailPage extends StatefulWidget {
  final Aerobic record;

  const AerobicDetailPage({super.key, required this.record});

  @override
  State<AerobicDetailPage> createState() => _AerobicDetailPageState();
}

class _AerobicDetailPageState extends State<AerobicDetailPage> {
  final AerobicRepository _repository = AerobicRepository();
  late Aerobic currentRecord;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    currentRecord = widget.record;
  }

  Future<void> _toggleArchiveRecord() async {
    setState(() {
      isLoading = true;
    });

    try {
      final updatedRecord = await _repository.updateAerobicArchiveStatus(
        currentRecord.id,
        !currentRecord.is_archived,
      );
      
      setState(() {
        currentRecord = updatedRecord;
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentRecord.is_archived 
                  ? '✅ Record archived successfully' 
                  : '✅ Record restored successfully',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ✅ NEW: Share the workout details
  Future<void> _shareWorkout() async {
    try {
      final shareText = _formatShareText();
      print('📤 [SHARE] Preparing to share workout details');
      
      // Try to download and share the route image
      List<XFile> files = [];
      
      if (currentRecord.route_image.isNotEmpty) {
        try {
          print('📤 [SHARE] Downloading route image...');
          final imageFile = await _downloadRouteImage();
          if (imageFile != null) {
            files.add(imageFile);
            print('✅ [SHARE] Route image downloaded successfully');
          }
        } catch (e) {
          print('⚠️  [SHARE] Could not download image, will share text only: $e');
        }
      }
      
      // Share with or without image
      if (files.isNotEmpty) {
        await Share.shareXFiles(
          files,
          text: shareText,
          subject: '${currentRecord.activity_type} Exercise - ${currentRecord.formattedDate}',
        );
      } else {
        await Share.share(
          shareText,
          subject: '${currentRecord.activity_type} Exercise - ${currentRecord.formattedDate}',
        );
      }
      
      print('✅ [SHARE] Exercise shared successfully');
    } catch (e) {
      print('❌ [SHARE] Error sharing exercise: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ✅ NEW: Download route image from URL
  Future<XFile?> _downloadRouteImage() async {
    try {
      final resolver = AerobicRepository();
      final imageUrl = resolver.resolveRouteImageUrl(currentRecord.route_image);
      
      if (imageUrl.isEmpty) {
        print('⚠️  [SHARE] Image URL is empty');
        return null;
      }

      print('📥 [SHARE] Downloading image from: $imageUrl');
      
      // Download the image
      final response = await http.get(Uri.parse(imageUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        // Get temporary directory
        final tempDir = await getTemporaryDirectory();
        final fileName = 'route_${currentRecord.id}_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${tempDir.path}/$fileName');

        // Write the image bytes to file
        await file.writeAsBytes(response.bodyBytes);
        print('✅ [SHARE] Image saved to: ${file.path}');

        return XFile(file.path, mimeType: 'image/png');
      } else {
        print('❌ [SHARE] Failed to download image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ [SHARE] Error downloading image: $e');
      return null;
    }
  }

  // ✅ NEW: Format workout data for sharing
  String _formatShareText() {
    final duration = currentRecord.formattedDuration;
    final pace = _formatPace(currentRecord.average_pace);
    
    return '''
🏃 ${currentRecord.activity_type.toUpperCase()} WORKOUT

📍 Location: ${currentRecord.location}
📅 Date: ${currentRecord.formattedDate}

📊 PERFORMANCE METRICS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Distance: ${currentRecord.total_distance.toStringAsFixed(2)} km
Duration: $duration
Average Pace: $pace
Calories Burned: ${currentRecord.calories_burned} kcal
Steps: ${currentRecord.total_step}
Elevation Gain: ${currentRecord.elevation_gain} m

👟 Footwear: ${currentRecord.footwear}
⏱️ Moving Time: ${currentRecord.moving_time} seconds

🕐 Start Time: ${currentRecord.start_at.hour.toString().padLeft(2, '0')}:${currentRecord.start_at.minute.toString().padLeft(2, '0')}
🕐 End Time: ${currentRecord.end_at.hour.toString().padLeft(2, '0')}:${currentRecord.end_at.minute.toString().padLeft(2, '0')}
    '''.trim();
  }

  @override
  Widget build(BuildContext context) {
    final record = currentRecord;
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
                    // ✅ Archive/Unarchive Button
                    GestureDetector(
                      onTap: isLoading ? null : _toggleArchiveRecord,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: record.is_archived ? AppColors.lime : AppColors.lavender.withValues(alpha: 0.55),
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.lime),
                                ),
                              )
                            : Icon(
                                record.is_archived ? Icons.unarchive : Icons.archive,
                                color: record.is_archived ? AppColors.lime : AppColors.lavender,
                                size: 18,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ✅ NEW: Share Button
                    GestureDetector(
                      onTap: _shareWorkout,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.share,
                          color: AppColors.primary,
                          size: 18,
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
    // Don't load image for archived records
    if (currentRecord.is_archived) {
      print('📦 [AEROBIC-DETAIL] Record is archived, showing placeholder instead of loading image');
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: _buildPlaceholderImage(),
      );
    }

    final resolver = AerobicRepository();
    final resolvedImageUrl = resolver.resolveRouteImageUrl(currentRecord.route_image);

    if (resolvedImageUrl.isEmpty) {
      print('⚠️  [AEROBIC-DETAIL] Image URL is empty for: ${currentRecord.route_image}');
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
                  print('❌ Error loading detail route image: $error | raw=${currentRecord.route_image} | resolved=$resolvedImageUrl');
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
          currentRecord.activity_type.toUpperCase(),
          style: const TextStyle(
            color: AppColors.lime,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currentRecord.location,
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
          currentRecord.formattedDate,
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
        'value': '${currentRecord.total_distance.toStringAsFixed(2)} km',
        'icon': Icons.directions_run,
      },
      {
        'label': 'Duration',
        'value': currentRecord.formattedDuration,
        'icon': Icons.timer,
      },
      {
        'label': 'Average Pace',
        'value': _formatPace(currentRecord.average_pace),
        'icon': Icons.speed,
      },
      {
        'label': 'Calories Burned',
        'value': '${currentRecord.calories_burned} kcal',
        'icon': Icons.local_fire_department,
      },
      {
        'label': 'Steps',
        'value': currentRecord.total_step.toString(),
        'icon': Icons.transfer_within_a_station,
      },
      {
        'label': 'Elevation Gain',
        'value': '${currentRecord.elevation_gain} m',
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
        _buildDetailRow('Footwear', currentRecord.footwear),
        const SizedBox(height: 8),
        _buildDetailRow('Moving Time', '${currentRecord.moving_time} seconds'),
        const SizedBox(height: 8),
        _buildDetailRow(
          'Start Time',
          '${currentRecord.start_at.hour.toString().padLeft(2, '0')}:${currentRecord.start_at.minute.toString().padLeft(2, '0')}',
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          'End Time',
          '${currentRecord.end_at.hour.toString().padLeft(2, '0')}:${currentRecord.end_at.minute.toString().padLeft(2, '0')}',
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
