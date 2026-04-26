import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class TrackingController {
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
  double lastElevation = 0.0;

  bool isSessionActive = false;
  bool _hasStarted = false; // Track if session has been initialized
  StreamSubscription<Position>? _positionStream;
  Timer? _timer;

  void startTracking(
    Function(int) onElapsedSecondsChanged,
    Function(double) onCurrentPaceChanged,
    Function(LatLng, List<LatLng>, double, int, int, int) onLocationUpdated,
    int caloriesPerKM,
    LatLng initialLocation,
  ) {
    if (!_hasStarted) {
      // First time starting - initialize everything
      _hasStarted = true;
      currentLocation = initialLocation;
      locationHistory.add(initialLocation);
      sessionStartTime = DateTime.now();
      elapsedSeconds = 0;
      totalDistance = 0.0;
      elevationGain = 0;
      lastElevation = 0.0;
    }

    // Resume tracking (can be called multiple times)
    isSessionActive = true;

    // Start the elapsed time timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isSessionActive) {
        elapsedSeconds++;
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
    );
  }

  void stopTracking() {
    isSessionActive = false;
    _timer?.cancel();
  }

  void _startLocationTracking(
    Function(LatLng, List<LatLng>, double, int, int, int) onLocationUpdated,
    int caloriesPerKM,
  ) {
    _positionStream?.cancel();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2, // Reduced from 3 to 2 meters for better responsiveness
      ),
    ).listen((Position position) {
      if (!isSessionActive) return;

      LatLng newLocation = LatLng(position.latitude, position.longitude);
      currentLocation = newLocation;

      if (locationHistory.isNotEmpty) {
        double distanceInMeters = Geolocator.distanceBetween(
          locationHistory.last.latitude,
          locationHistory.last.longitude,
          newLocation.latitude,
          newLocation.longitude,
        );
        totalDistance += (distanceInMeters / 1000);
      }

      locationHistory.add(newLocation);

      if (position.altitude > lastElevation && lastElevation != 0.0) {
        elevationGain += (position.altitude - lastElevation).toInt();
      }
      lastElevation = position.altitude;

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
    });
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
    lastElevation = 0.0;
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

