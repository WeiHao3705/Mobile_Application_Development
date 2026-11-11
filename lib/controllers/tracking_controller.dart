import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class TrackingController {
  /// Fixes less accurate than this (meters) are ignored: they mostly add
  /// phantom distance from GPS jitter.
  static const double _maxAccuracyMeters = 25;

  /// Movement smaller than this (meters) is treated as standing still.
  static const double _minMoveMeters = 3;

  /// Jumps implying more than this speed (m/s, about 54 km/h) are GPS glitches.
  static const double _maxSpeedMetersPerSecond = 15;

  /// Altitude must change by this many meters before it counts as climbing.
  static const double _elevationThresholdMeters = 3;

  // Tracking State
  int elapsedSeconds = 0;
  double totalDistance = 0.0;
  double currentPace = 0.0;
  int caloriesBurned = 0;
  int totalSteps = 0;
  int elevationGain = 0;
  DateTime? sessionStartTime;
  LatLng? currentLocation;
  final List<LatLng> locationHistory = [];

  /// Accuracy (meters) of the latest GPS fix, or null before the first one.
  double? lastAccuracy;

  /// True while recent fixes are too inaccurate to be used (e.g. indoors).
  bool hasWeakSignal = false;

  bool isSessionActive = false;
  bool _hasStarted = false; // Track if session has been initialized
  StreamSubscription<Position>? _positionStream;
  Timer? _timer;

  // Elapsed time comes from a stopwatch so it stays correct even if the OS
  // delays timer ticks while the app is in the background.
  final Stopwatch _stopwatch = Stopwatch();

  Position? _lastAcceptedPosition;
  double? _elevationBaseline;

  void startTracking(
    Function(int) onElapsedSecondsChanged,
    Function(double) onCurrentPaceChanged,
    Function(LatLng, List<LatLng>, double, int, int, int) onLocationUpdated,
    int caloriesPerKM,
    LatLng initialLocation, {
    void Function(Object error)? onLocationError,
  }) {
    if (!_hasStarted) {
      // First time starting - initialize everything
      _hasStarted = true;
      currentLocation = initialLocation;
      if (locationHistory.isEmpty || locationHistory.last != initialLocation) {
        locationHistory.add(initialLocation);
      }
      sessionStartTime = DateTime.now();
      elapsedSeconds = 0;
      totalDistance = 0.0;
      elevationGain = 0;
      _elevationBaseline = null;
      _stopwatch.reset();
    }

    // Resume tracking (can be called multiple times)
    isSessionActive = true;
    _stopwatch.start();

    // Start the elapsed time timer (never leave a previous one running).
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isSessionActive) {
        elapsedSeconds = _stopwatch.elapsed.inSeconds;
        onElapsedSecondsChanged(elapsedSeconds);
        if (elapsedSeconds > 0 && totalDistance >= 0.02) {
          currentPace = (elapsedSeconds / 60) / totalDistance;
          onCurrentPaceChanged(currentPace);
        } else {
          currentPace = 0;
          onCurrentPaceChanged(currentPace);
        }
      }
    });

    _startLocationTracking(
      onLocationUpdated,
      caloriesPerKM,
      onLocationError,
    );
  }

  void stopTracking() {
    isSessionActive = false;
    _stopwatch.stop();
    _timer?.cancel();
    // Stop GPS while paused to save battery. The next fix after resuming only
    // re-anchors the route, so ground covered while paused is not counted.
    _positionStream?.cancel();
    _positionStream = null;
    _lastAcceptedPosition = null;
  }

  LocationSettings _buildLocationSettings() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
        intervalDuration: const Duration(seconds: 2),
        // A foreground service keeps GPS running with the screen off.
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Tracking your activity',
          notificationText: 'FitTrack is recording your route.',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.fitness,
        distanceFilter: 3,
        pauseLocationUpdatesAutomatically: false,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 3,
    );
  }

  void _startLocationTracking(
    Function(LatLng, List<LatLng>, double, int, int, int) onLocationUpdated,
    int caloriesPerKM,
    void Function(Object error)? onLocationError,
  ) {
    _positionStream?.cancel();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: _buildLocationSettings(),
    ).listen(
      (Position position) {
        if (!isSessionActive) return;
        _handlePosition(position, onLocationUpdated, caloriesPerKM);
      },
      onError: (Object error) {
        // GPS switched off or permission revoked mid-session.
        hasWeakSignal = true;
        onLocationError?.call(error);
      },
    );
  }

  /// Feeds one GPS fix through the same filtering as the live stream.
  @visibleForTesting
  void handlePositionForTesting(
    Position position, {
    int caloriesPerKM = 0,
    void Function(LatLng, List<LatLng>, double, int, int, int)? onUpdated,
  }) {
    isSessionActive = true;
    _handlePosition(
      position,
      onUpdated ?? (_, _, _, _, _, _) {},
      caloriesPerKM,
    );
  }

  void _handlePosition(
    Position position,
    Function(LatLng, List<LatLng>, double, int, int, int) onLocationUpdated,
    int caloriesPerKM,
  ) {
    lastAccuracy = position.accuracy;

    // Ignore inaccurate fixes.
    if (position.accuracy > _maxAccuracyMeters) {
      hasWeakSignal = true;
      return;
    }
    hasWeakSignal = false;

    final newLocation = LatLng(position.latitude, position.longitude);
    final previous = _lastAcceptedPosition;

    if (previous != null) {
      final meters = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        newLocation.latitude,
        newLocation.longitude,
      );

      // Standing still: GPS wobble should not count as movement.
      if (meters < math.max(_minMoveMeters, position.accuracy / 2)) {
        return;
      }

      // Impossible jump: treat as a glitch and wait for the next fix.
      final seconds =
          position.timestamp.difference(previous.timestamp).inMilliseconds /
              1000;
      if (seconds > 0 && meters / seconds > _maxSpeedMetersPerSecond) {
        return;
      }

      totalDistance += meters / 1000;
    }

    _lastAcceptedPosition = position;
    currentLocation = newLocation;
    locationHistory.add(newLocation);

    _updateElevation(position.altitude);

    totalSteps = (totalDistance * 1000 * 1.3).toInt();
    caloriesBurned = _calculateCalories(caloriesPerKM);

    onLocationUpdated(
      newLocation,
      locationHistory,
      totalDistance,
      totalSteps,
      elevationGain,
      caloriesBurned,
    );
  }

  /// Counts climbing only when altitude rises by a meaningful amount, because
  /// raw GPS altitude is noisy and would otherwise inflate the total.
  void _updateElevation(double altitude) {
    final baseline = _elevationBaseline;
    if (baseline == null) {
      _elevationBaseline = altitude;
      return;
    }

    final delta = altitude - baseline;
    if (delta >= _elevationThresholdMeters) {
      elevationGain += delta.round();
      _elevationBaseline = altitude;
    } else if (delta <= -_elevationThresholdMeters) {
      _elevationBaseline = altitude;
    }
  }

  int _calculateCalories(int caloriesPerKM) {
    return (totalDistance * caloriesPerKM).toInt();
  }

  String formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String formatPace(double pace) {
    if (pace == 0) return "0:00";

    // Cap the display at 99:59 so the UI doesn't break if they stand still
    if (pace >= 100) return "99:59";

    int minutes = pace.toInt();
    int seconds = ((pace - minutes) * 60).toInt();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Reset session state (call when ending a session)
  void resetSession() {
    _hasStarted = false;
    elapsedSeconds = 0;
    totalDistance = 0.0;
    currentPace = 0.0;
    caloriesBurned = 0;
    totalSteps = 0;
    elevationGain = 0;
    _elevationBaseline = null;
    _lastAcceptedPosition = null;
    lastAccuracy = null;
    hasWeakSignal = false;
    _stopwatch
      ..stop()
      ..reset();
    sessionStartTime = null;
    currentLocation = null;
    locationHistory.clear();
  }

  /// Cleanup resources
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    resetSession();
  }
}
