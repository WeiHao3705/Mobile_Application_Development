import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/app_colors.dart';
import '../repository/aerobic_repository.dart';
import '../models/aerobic.dart';
import '../controllers/location_controller.dart';
import '../controllers/tracking_controller.dart';

class AerobicSessionRun extends StatefulWidget {
  final int userId;
  final String activityType;
  final LatLng startLocation;
  final int caloriesPerKM;

  const AerobicSessionRun({
    super.key,
    required this.userId,
    required this.activityType,
    required this.startLocation,
    required this.caloriesPerKM,
  });

  @override
  State<AerobicSessionRun> createState() => _AerobicSessionRunState();
}

class _AerobicSessionRunState extends State<AerobicSessionRun> {
  final AerobicRepository _aerobicRepository = AerobicRepository();
  final LocationController _locationController = LocationController();
  final TrackingController _trackingController = TrackingController();
  final GlobalKey _mapRepaintKey = GlobalKey();

  late MapController _mapController;  // ✅ LAZY INITIALIZATION
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();  // ✅ Initialize in initState
    _trackingController.currentLocation = widget.startLocation;
    _trackingController.locationHistory.add(widget.startLocation);
    _trackingController.sessionStartTime = DateTime.now();
    _startTracking();
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _startTracking() {
    _trackingController.startTracking(
      (elapsedSeconds) {
        // Callback for elapsed seconds
        setState(() {});
      },
      (pace) {
        // Callback for pace changes
        setState(() {});
      },
      (newLocation, locationHistory, totalDistance, totalSteps, elevationGain, caloriesBurned) {
        // Callback for location updates
        setState(() {
          _mapController.move(newLocation, _mapController.camera.zoom);
        });
      },
      widget.caloriesPerKM,
      widget.startLocation,
    );
  }

  void _stopTracking() {
    _trackingController.stopTracking();
  }

  Future<String> _getLocationAddress() async {
    return await _locationController.getLocationAddress(
      _trackingController.currentLocation!.latitude,
      _trackingController.currentLocation!.longitude,
    );
  }

  String _formatDuration(int seconds) {
    return _trackingController.formatDuration(seconds);
  }

  String _formatPace(double pace) {
    return _trackingController.formatPace(pace);
  }

  Future<String> _captureAndUploadMapScreenshot() async {
    print('🖼️ Starting map screenshot capture...');

    // Retry capture because the boundary may not be ready in the first frame.
    Uint8List? imageBytes;
    for (int attempt = 1; attempt <= 3; attempt++) {
      await Future.delayed(const Duration(milliseconds: 450));
      print('📸 Capture attempt $attempt/3');

      final boundary = _mapRepaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        print('⚠️ Map boundary not available yet');
        continue;
      }

      try {
        final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        imageBytes = byteData?.buffer.asUint8List();

        if (imageBytes != null && imageBytes.isNotEmpty) {
          print('✅ Screenshot captured successfully, size: ${imageBytes.length} bytes');
          break;
        }
      } catch (e) {
        print('⚠️ Screenshot capture attempt $attempt failed: $e');
      }
    }

    if (imageBytes == null || imageBytes.isEmpty) {
      print('❌ Route image capture failed - map not ready after 3 attempts');
      throw Exception('Route image capture failed (map not ready).');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userId = widget.userId;
    final fileName = 'route_${userId}_$timestamp.png';

    // Save to local storage first
    print('💾 Saving to local storage...');
    final localPath = await _saveImageLocally(fileName, imageBytes);
    print('✅ Saved locally at: $localPath');

    print('📤 Uploading screenshot to Supabase: $fileName');
    
    try {
      final imageUrl = await _aerobicRepository.uploadAerobicRouteImage(
        fileName,
        imageBytes,
      );

      if (imageUrl.isEmpty) {
        print('❌ Upload returned empty URL');
        print('⚠️ But local copy saved at: $localPath');
        return localPath; // Return local path if Supabase fails
      }

      print('✅ Image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('❌ Upload error: $e');
      print('⚠️ But local copy saved at: $localPath');
      return localPath; // Return local path as fallback
    }
  }

  Future<String> _saveImageLocally(String fileName, Uint8List imageBytes) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final aerobicDir = Directory('${appDir.path}/aerobic_routes');
      
      // Create directory if it doesn't exist
      if (!await aerobicDir.exists()) {
        await aerobicDir.create(recursive: true);
        print('📁 Created aerobic_routes directory');
      }

      final file = File('${aerobicDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);
      
      print('✅ Image saved locally: ${file.path}');
      return file.path;
    } catch (e) {
      print('❌ Local storage save failed: $e');
      throw Exception('Failed to save image locally: $e');
    }
  }

  void _endSession() {
    _stopTracking();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.nearBlack,
        title: const Text('End Session?', style: TextStyle(color: AppColors.lavender)),
        content: Text(
          'Distance: ${_trackingController.totalDistance.toStringAsFixed(2)} km\nDuration: ${_formatDuration(_trackingController.elapsedSeconds)}\nCalories: ${_trackingController.caloriesBurned} kcal\n\nDo you want to save this aerobic session?',
          style: const TextStyle(color: AppColors.lavender, height: 1.5),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _startTracking();
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.nearBlack,
                  ),
                  onPressed: _isSaving ? null : () async {
                    setState(() => _isSaving = true);
                    try {
                      print('\n🔵 ===== SAVE RECORD STARTED =====');
                      
                      // Step 1: Get location
                      print('Step 1: Fetching location...');
                      final locationAddress = await _getLocationAddress();
                      print('✅ Location: $locationAddress');
                      
                      // Step 2: Capture screenshot
                      print('\nStep 2: Capturing screenshot...');
                      print('📍 Current location: ${_trackingController.currentLocation}');
                      print('📍 Location history count: ${_trackingController.locationHistory.length}');
                      
                      final routeImageUrl = await _captureAndUploadMapScreenshot();
                      print('✅ Route image URL: ${routeImageUrl.isEmpty ? "EMPTY (no image saved)" : routeImageUrl}');

                      if (routeImageUrl.isEmpty) {
                        throw Exception('Unable to capture/upload route image. Please try again.');
                      }
                      
                      // Step 3: Create record
                      print('\nStep 3: Creating aerobic record...');
                      final newRecord = Aerobic(
                        id: widget.userId.toString(),
                        activity_type: widget.activityType,
                        location: locationAddress,
                        total_distance: _trackingController.totalDistance,
                        average_pace: (_trackingController.currentPace *100).toInt(),
                        calories_burned: _trackingController.caloriesBurned,
                        total_step: _trackingController.totalSteps,
                        elevation_gain: _trackingController.elevationGain,
                        start_at: _trackingController.sessionStartTime ?? DateTime.now(),
                        end_at: DateTime.now(),
                        moving_time: _trackingController.elapsedSeconds,
                        footwear: 'None',
                        route_image: routeImageUrl,
                        userId: widget.userId.toString(),
                        is_archived: false,
                      );
                      print('✅ Record created with data:');
                      print('   - Activity: ${newRecord.activity_type}');
                      print('   - Location: ${newRecord.location}');
                      print('   - Distance: ${newRecord.total_distance} km');
                      print('   - Route Image: ${newRecord.route_image.isEmpty ? "EMPTY" : "HAS URL"}');

                      // Step 4: Save to database
                      print('\nStep 4: Saving to database...');
                      await _aerobicRepository.createAerobicRecord(newRecord);
                      print('✅ Record saved to database');
                      print('🔵 ===== SAVE RECORD COMPLETED =====\n');

                      if (mounted) {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Close aerobic_session_run
                        Navigator.pop(context, true); // Close aerobic_type and return to aerobic_page
                      }
                    } catch (e) {
                      print('❌ ERROR: $e');
                      print('Stack trace: ${StackTrace.current}');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isSaving = false);
                    }
                  },
                  child: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.nearBlack,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _stopTracking();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        border:
                        Border.all(color: AppColors.lavender.withValues(alpha: 0.55)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.chevron_left, color: AppColors.lime, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.activityType.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.lavender,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _trackingController.isSessionActive ? Colors.red : AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        if (_trackingController.isSessionActive) ...[
                          const Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _trackingController.isSessionActive ? 'RECORDING' : 'PAUSED',
                          style: const TextStyle(
                            color: AppColors.nearBlack,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 6, child: _buildMapArea()),
            Expanded(flex: 4, child: _buildInfoPanel()),
          ],
        ),
      ),
    );
  }

  Widget _buildMapArea() {
    if (_trackingController.currentLocation == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.lime));
    }

    return RepaintBoundary(
      key: _mapRepaintKey,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _trackingController.currentLocation!,
          initialZoom: 18.0,
          interactionOptions:
          const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.hermen.aerobic',
          ),
          if (_trackingController.locationHistory.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _trackingController.locationHistory,
                  color: AppColors.primary,
                  strokeWidth: 6.0,
                  isDotted: false,
                  strokeJoin: StrokeJoin.round,
                  strokeCap: StrokeCap.round,
                ),
              ],
            ),
          MarkerLayer(
            markers: [
              Marker(
                point: _trackingController.currentLocation!,
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.lime,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Icon(Icons.circle, color: AppColors.lime, size: 16),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.nearBlack,
        border: Border(top: BorderSide(color: AppColors.lavender.withValues(alpha: 0.3))),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 90,
                  child: _StatCard(label: 'DURATION', value: _formatDuration(_trackingController.elapsedSeconds), unit: ''),
                ),
                SizedBox(
                  width: 90,
                  child: _StatCard(label: 'DISTANCE', value: _trackingController.totalDistance.toStringAsFixed(2), unit: 'km'),
                ),
                SizedBox(
                  width: 90,
                  child: _StatCard(label: 'PACE', value: _formatPace(_trackingController.currentPace), unit: '/km'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Row 2: Calories, Elevation, Steps
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 90,
                  child: _StatCard(label: 'CALORIES', value: _trackingController.caloriesBurned.toString(), unit: 'kcal'),
                ),
                SizedBox(
                  width: 90,
                  child: _StatCard(label: 'ELEVATION', value: _trackingController.elevationGain.toString(), unit: 'm'),
                ),
                SizedBox(
                  width: 90,
                  child: _StatCard(label: 'STEPS', value: _trackingController.totalSteps.toString(), unit: ''),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {
                    _trackingController.isSessionActive ? _stopTracking() : _startTracking();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.lime),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Icon(_trackingController.isSessionActive ? Icons.pause : Icons.play_arrow, color: AppColors.lime),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _endSession,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('FINISH EXERCISE',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _StatCard({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                  color: AppColors.lavender,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                )),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text('($unit)', style: TextStyle(color: AppColors.lime, fontSize: 10)),
            ]
          ],
        ),
      ],
    );
  }
}
