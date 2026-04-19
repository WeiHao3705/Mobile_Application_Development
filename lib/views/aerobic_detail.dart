import 'package:flutter/material.dart';
import 'package:mobile_application_development/theme/app_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
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
  File? _capturedPhoto; // Store the captured photo
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    currentRecord = widget.record;
    _loadSnapPhotoFromDatabase();
  }

  Future<void> _loadSnapPhotoFromDatabase() async {
    // If the record has a snap_photo URL, load it
    if (currentRecord.snap_photo.isNotEmpty) {
      try {
        final resolver = AerobicRepository();
        final photoUrl = resolver.resolveSnapPhotoUrl(currentRecord.snap_photo);
        if (photoUrl.isNotEmpty) {
          // Download and cache the image
          final response = await http.get(Uri.parse(photoUrl)).timeout(
            const Duration(seconds: 10),
          );
          if (response.statusCode == 200 && mounted) {
            final tempDir = await getTemporaryDirectory();
            final fileName = 'snap_${currentRecord.id}_loaded.png';
            final file = File('${tempDir.path}/$fileName');
            await file.writeAsBytes(response.bodyBytes);

            if (mounted) {
              setState(() {
                _capturedPhoto = file;
              });
            }
          }
        }
      } catch (e) {
        print('Error loading snap photo from database: $e');
      }
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final photoFile = File(pickedFile.path);
        
        setState(() {
          _capturedPhoto = photoFile;
        });

        // Upload to database
        try {
          print('📤 Saving snap photo to database...');
          final photoUrl = await _repository.uploadSnapPhoto(currentRecord.id, photoFile);
          
          // Update currentRecord with the new snap_photo URL
          setState(() {
            currentRecord = Aerobic(
              id: currentRecord.id,
              activity_type: currentRecord.activity_type,
              location: currentRecord.location,
              total_distance: currentRecord.total_distance,
              average_pace: currentRecord.average_pace,
              calories_burned: currentRecord.calories_burned,
              total_step: currentRecord.total_step,
              elevation_gain: currentRecord.elevation_gain,
              start_at: currentRecord.start_at,
              end_at: currentRecord.end_at,
              moving_time: currentRecord.moving_time,
              route_image: currentRecord.route_image,
              userId: currentRecord.userId,
              is_archived: currentRecord.is_archived,
              snap_photo: photoUrl,
            );
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo captured and saved successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (uploadError) {
          print('Error uploading photo to database: $uploadError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Photo captured but failed to save: $uploadError'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error capturing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _capturedPhoto = null;
    });
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.nearBlack,
        title: const Text(
          'Delete Photo?',
          style: TextStyle(color: AppColors.lavender),
        ),
        content: const Text(
          'Are you sure you want to remove this photo? This action cannot be undone.',
          style: TextStyle(color: AppColors.lavender, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _removePhoto();
            },
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenPhoto() {
    if (_capturedPhoto == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            // Full screen image
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: Image.file(
                  _capturedPhoto!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                  ? 'Record archived successfully' 
                  : 'Record restored successfully',
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

  Future<void> _shareWorkout() async {
    try {
      final shareText = _formatShareText();
      print('Preparing to share workout details');
      
      // Try to download and share the route image
      List<XFile> files = [];
      
      if (currentRecord.route_image.isNotEmpty) {
        try {
          print('Downloading route image...');
          final imageFile = await _loadRouteImage();
          if (imageFile != null) {
            files.add(imageFile);
            print('Route image downloaded successfully');
          }
        } catch (e) {
          print('Could not download image, will share text only: $e');
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
      
      print('Exercise shared successfully');
    } catch (e) {
      print('Error sharing exercise: $e');
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

  Future<XFile?> _loadRouteImage() async {
    try {
      final resolver = AerobicRepository();
      final imageUrl = resolver.resolveRouteImageUrl(currentRecord.route_image);
      
      if (imageUrl.isEmpty) {
        print('Image URL is empty');
        return null;
      }

      print('Downloading image from: $imageUrl');
      
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

        return XFile(file.path, mimeType: 'image/png');
      } else {
        print('Failed to download image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error downloading image: $e');
      return null;
    }
  }

  // Format workout data for sharing
  String _formatShareText() {
    final duration = currentRecord.formattedDuration;
    final pace = _formatPace(currentRecord.average_pace);
    
    return '''
    ${currentRecord.activity_type.toUpperCase()} WORKOUT
    
    Location: ${currentRecord.location}
    Date: ${currentRecord.formattedDate}
    
    PERFORMANCE METRICS:
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    Distance: ${currentRecord.total_distance.toStringAsFixed(2)} km
    Duration: $duration
    Average Pace: $pace
    Calories Burned: ${currentRecord.calories_burned} kcal
    Steps: ${currentRecord.total_step}
    Elevation Gain: ${currentRecord.elevation_gain} m
    
    Moving Time: ${currentRecord.moving_time} seconds
    
    Start Time: ${currentRecord.start_at.hour.toString().padLeft(2, '0')}:${currentRecord.start_at.minute.toString().padLeft(2, '0')}
    End Time: ${currentRecord.end_at.hour.toString().padLeft(2, '0')}:${currentRecord.end_at.minute.toString().padLeft(2, '0')}
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
                    // Archive/Unarchive Button
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
                    GestureDetector(
                      onTap: currentRecord.is_archived ? null : _shareWorkout,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: currentRecord.is_archived 
                                ? AppColors.lavender.withValues(alpha: 0.3)
                                : AppColors.primary,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.share,
                          color: currentRecord.is_archived 
                              ? AppColors.lavender.withValues(alpha: 0.3)
                              : AppColors.primary,
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
              const SizedBox(height: 20),

              // Photo Capture Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session Photo',
                      style: TextStyle(
                        color: AppColors.lavender,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPhotoCaptureContainer(),
                  ],
                ),
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
                  print('Error loading detail route image: $error | raw=${currentRecord.route_image} | resolved=$resolvedImageUrl');
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

  Widget _buildPhotoCaptureContainer() {
    return GestureDetector(
      onTap: _capturedPhoto == null && !currentRecord.is_archived ? _capturePhoto : null,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.nearBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _capturedPhoto != null
                ? AppColors.primary
                : (currentRecord.is_archived 
                    ? AppColors.lavender.withValues(alpha: 0.2)
                    : AppColors.lavender.withValues(alpha: 0.5)),
            width: 2,
          ),
        ),
        child: _capturedPhoto == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 48,
                      color: currentRecord.is_archived
                          ? AppColors.lavender.withValues(alpha: 0.3)
                          : AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentRecord.is_archived ? 'Archived - No Edit' : 'Tap to Add Photo',
                      style: TextStyle(
                        color: currentRecord.is_archived
                            ? AppColors.lavender.withValues(alpha: 0.3)
                            : AppColors.lavender,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  // Tappable image for full-screen view
                  GestureDetector(
                    onTap: !currentRecord.is_archived ? _showFullScreenPhoto : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _capturedPhoto!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  // Gray overlay for archived records
                  if (currentRecord.is_archived)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black.withValues(alpha: 0.6),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock,
                                color: AppColors.lavender.withValues(alpha: 0.7),
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Archived',
                                style: TextStyle(
                                  color: AppColors.lavender.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Delete button only shows for non-archived records
                  if (!currentRecord.is_archived)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _showDeleteConfirmation,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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