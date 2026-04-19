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
  StreamSubscription<Position>? _positionStream;
  Timer? _timer;

  /// Start tracking session - initializes timer and location tracking
  void startTracking(
    Function(int) onElapsedSecondsChanged,
    Function(double) onCurrentPaceChanged,
    Function(LatLng, List<LatLng>, double, int, int, int) onLocationUpdated,
    int caloriesPerKM,
    LatLng initialLocation,
  ) {
    isSessionActive = true;
    currentLocation = initialLocation;
    locationHistory.add(initialLocation);
    sessionStartTime = DateTime.now();
    elapsedSeconds = 0;
    totalDistance = 0.0;
    elevationGain = 0;
    lastElevation = 0.0;

    // Start the elapsed time timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isSessionActive) {
        elapsedSeconds++;
        onElapsedSecondsChanged(elapsedSeconds); // Call the callback to update UI
        if (elapsedSeconds > 0 && totalDistance > 0) {
          currentPace = (elapsedSeconds / 60) / totalDistance;
          onCurrentPaceChanged(currentPace);
        }
      }
    });

    _startLocationTracking(
      onLocationUpdated,
      caloriesPerKM,
    );
  }

  /// Stop tracking session
  void stopTracking() {
    isSessionActive = false;
    _timer?.cancel();
    _positionStream?.cancel();
  }

  /// Internal method to handle location stream
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

      // Notify UI with updated metrics
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

  /// Calculate calories based on distance and calories per KM
  int _calculateCalories(int caloriesPerKM) {
    return (totalDistance * caloriesPerKM).toInt();
  }

  /// Format duration in seconds to readable format (HH:MM:SS or MM:SS)
  String formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Format pace to readable format (MM:SS per KM)
  String formatPace(double pace) {
    if (pace == 0) return "0:00";

    // Cap the display at 99:59 so the UI doesn't break if they stand still
    if (pace > 5999) return "99:59";

    int minutes = pace.toInt();
    int seconds = ((pace - minutes) * 60).toInt();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Reset all tracking data
  void reset() {
    elapsedSeconds = 0;
    totalDistance = 0.0;
    currentPace = 0.0;
    caloriesBurned = 0;
    totalSteps = 0;
    elevationGain = 0;
    lastElevation = 0.0;
    locationHistory.clear();
    currentLocation = null;
    isSessionActive = false;
  }

  /// Cleanup resources
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
  }
}

