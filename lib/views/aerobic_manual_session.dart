import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/aerobic.dart';
import '../repository/aerobic_repository.dart';
import '../theme/app_colors.dart';
import '../utils/manual_session_calculator.dart';

/// A session without GPS: for treadmills, indoor tracks, swimming pools and
/// any other place where satellite tracking does not work. The user times the
/// session and then types in how far they went.
class AerobicManualSession extends StatefulWidget {
  const AerobicManualSession({
    super.key,
    required this.userId,
    required this.activityType,
    required this.caloriesPerKM,
    this.approximateLocationName,
  });

  final int userId;
  final String activityType;
  final int caloriesPerKM;

  /// Optional place name from a rough location fix, used as the venue default.
  final String? approximateLocationName;

  @override
  State<AerobicManualSession> createState() => _AerobicManualSessionState();
}

class _AerobicManualSessionState extends State<AerobicManualSession> {
  final AerobicRepository _repository = AerobicRepository();
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _lapsController = TextEditingController();
  final TextEditingController _lapLengthController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();

  late ManualDistanceMode _mode;
  bool _enteringDetails = false;
  bool _isSaving = false;

  bool get _isSwimming => widget.activityType.toLowerCase().contains('swim');

  int get _elapsedSeconds => _stopwatch.elapsed.inSeconds;

  @override
  void initState() {
    super.initState();
    _mode = _isSwimming ? ManualDistanceMode.laps : ManualDistanceMode.kilometers;
    _lapLengthController.text = _isSwimming ? '25' : '400';
    final name = widget.approximateLocationName?.trim() ?? '';
    _venueController.text = name.isNotEmpty ? name : 'Indoor';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    _distanceController.dispose();
    _lapsController.dispose();
    _lapLengthController.dispose();
    _minutesController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _ticker?.cancel();
    } else {
      _stopwatch.start();
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
    setState(() {});
  }

  void _finishTiming() {
    _stopwatch.stop();
    _ticker?.cancel();
    if (_elapsedSeconds >= 30) {
      _minutesController.text = (_elapsedSeconds / 60).toStringAsFixed(1);
    }
    setState(() => _enteringDetails = true);
  }

  double? _parse(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.'));
  }

  ManualSessionStats? _currentStats() {
    final minutes = _parse(_minutesController);
    return ManualSessionStats.calculate(
      mode: _mode,
      kilometers: _parse(_distanceController),
      laps: _parse(_lapsController),
      lapLengthMeters: _parse(_lapLengthController),
      durationSeconds: minutes == null ? 0 : (minutes * 60).round(),
      caloriesPerKm: widget.caloriesPerKM,
      countSteps: !_isSwimming,
    );
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.nearBlack,
        title: const Text(
          'Discard Session?',
          style: TextStyle(color: AppColors.lavender),
        ),
        content: const Text(
          'Your timer and anything you entered will be lost.',
          style: TextStyle(color: AppColors.lavender, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep', style: TextStyle(color: AppColors.primary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _save() async {
    final stats = _currentStats();
    if (stats == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a distance and a duration greater than zero.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final venue = _venueController.text.trim();

      await _repository.createAerobicRecord(
        Aerobic(
          id: '',
          activity_type: widget.activityType,
          location: venue.isEmpty ? 'Indoor' : venue,
          total_distance: stats.distanceKm,
          average_pace: (stats.averagePace * 100).toInt(),
          calories_burned: stats.caloriesBurned,
          total_step: stats.steps,
          elevation_gain: 0,
          start_at: now.subtract(Duration(seconds: stats.durationSeconds)),
          end_at: now,
          moving_time: stats.durationSeconds,
          // No route was recorded; the history screens show a placeholder.
          route_image: '',
          userId: widget.userId.toString(),
          is_archived: false,
        ),
      );

      if (!mounted) return;
      final navigator = Navigator.of(context);
      navigator.pop(); // this screen
      navigator.pop(true); // start page, back to the aerobic list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatClock(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '${h.toString().padLeft(2, '0')}:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final hasProgress = _elapsedSeconds > 0 || _enteringDetails;

    return PopScope(
      canPop: !hasProgress,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final discard = await _confirmDiscard();
        if (discard) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.lavender,
          title: Text(
            '${widget.activityType.toUpperCase()} · INDOOR',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        body: SafeArea(
          child: _enteringDetails ? _buildDetailsForm() : _buildTimer(),
        ),
      ),
    );
  }

  Widget _buildTimer() {
    final running = _stopwatch.isRunning;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Spacer(),
          Text(
            _formatClock(_elapsedSeconds),
            style: const TextStyle(
              color: AppColors.lime,
              fontSize: 64,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSwimming
                ? 'Time your swim, then enter your laps.'
                : 'Time your workout, then enter the distance.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.lavender),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _toggleTimer,
              icon: Icon(running ? Icons.pause : Icons.play_arrow),
              label: Text(
                running ? 'PAUSE' : (_elapsedSeconds > 0 ? 'RESUME' : 'START'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.nearBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _finishTiming,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.lime,
                side: const BorderSide(color: AppColors.lime),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _elapsedSeconds > 0
                    ? 'FINISH & ENTER DETAILS'
                    : 'SKIP TIMER, ENTER DETAILS',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsForm() {
    final stats = _currentStats();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<ManualDistanceMode>(
          segments: [
            const ButtonSegment(
              value: ManualDistanceMode.kilometers,
              label: Text('Distance (km)'),
            ),
            ButtonSegment(
              value: ManualDistanceMode.laps,
              label: Text(_isSwimming ? 'Laps / lengths' : 'Laps'),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (value) => setState(() => _mode = value.first),
        ),
        const SizedBox(height: 16),
        if (_mode == ManualDistanceMode.kilometers)
          _field(
            controller: _distanceController,
            label: 'Distance (km)',
            hint: 'e.g. 5.0',
          )
        else ...[
          _field(
            controller: _lapsController,
            label: _isSwimming ? 'Number of laps / lengths' : 'Number of laps',
            hint: 'e.g. 10',
          ),
          const SizedBox(height: 12),
          _field(
            controller: _lapLengthController,
            label: _isSwimming ? 'Length of the pool (m)' : 'Length of one lap (m)',
            hint: _isSwimming ? 'e.g. 25' : 'e.g. 400',
          ),
        ],
        const SizedBox(height: 12),
        _field(
          controller: _minutesController,
          label: 'Duration (minutes)',
          hint: 'e.g. 30',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _venueController,
          style: const TextStyle(color: Colors.white),
          decoration: _decoration('Place', 'e.g. Bukit Jalil Stadium'),
        ),
        const SizedBox(height: 20),
        _buildPreview(stats),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.nearBlack,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.nearBlack,
                    strokeWidth: 2,
                  ),
                )
              : const Text('SAVE SESSION',
                  style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        TextButton(
          onPressed: _isSaving ? null : () => setState(() => _enteringDetails = false),
          child: const Text('Back to timer'),
        ),
      ],
    );
  }

  Widget _buildPreview(ManualSessionStats? stats) {
    final style = const TextStyle(color: AppColors.lavender, height: 1.6);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.nearBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lavender.withValues(alpha: 0.25)),
      ),
      child: stats == null
          ? Text('Fill in the distance and duration to see a summary.',
              style: style)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Distance: ${stats.distanceKm.toStringAsFixed(2)} km',
                    style: style),
                Text('Pace: ${stats.averagePace.toStringAsFixed(1)} min/km',
                    style: style),
                Text('Calories: ${stats.caloriesBurned} kcal', style: style),
              ],
            ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(label, hint),
      onChanged: (_) => setState(() {}),
    );
  }

  InputDecoration _decoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.lavender),
      hintStyle: TextStyle(color: AppColors.lavender.withValues(alpha: 0.4)),
      filled: true,
      fillColor: AppColors.inputBg,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.lavender.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lime),
      ),
    );
  }
}
