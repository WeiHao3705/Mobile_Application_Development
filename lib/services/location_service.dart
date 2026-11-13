// lib/services/location_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Why a location request failed, so screens can offer the right next step.
enum LocationFailureReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  noSignal,
}

class LocationFailure implements Exception {
  const LocationFailure(this.reason, this.message);

  final LocationFailureReason reason;
  final String message;

  /// True when the user can fix this from the device settings.
  bool get canOpenSettings =>
      reason == LocationFailureReason.serviceDisabled ||
      reason == LocationFailureReason.permissionDeniedForever;

  @override
  String toString() => message;
}

class LocationService {
  /// A cached position older than this is not trusted as a starting point.
  static const Duration _maxCachedAge = Duration(minutes: 1);

  /// A cached position less accurate than this (meters) is not trusted.
  static const double _maxCachedAccuracyMeters = 50;

  static const Duration _freshFixTimeout = Duration(seconds: 12);

  /// Indoors there is often no satellite fix, but Wi-Fi / mobile towers can
  /// still give a rough position within a few hundred meters.
  static const Duration _approximateFixTimeout = Duration(seconds: 8);

  /// Checks that GPS is on and permission is granted, asking for it if needed.
  /// Throws [LocationFailure] otherwise.
  Future<void> ensureReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure(
        LocationFailureReason.serviceDisabled,
        'Location services are turned off. Please turn on GPS.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        LocationFailureReason.permissionDenied,
        'Location permission was denied. Allow it to track your activity.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        LocationFailureReason.permissionDeniedForever,
        'Location permission is permanently denied. Enable it in the app settings.',
      );
    }
  }

  /// Returns the user's current position.
  ///
  /// A cached position is only used when it is recent and accurate; otherwise
  /// a fresh fix is requested. If the fresh fix times out, an older cached
  /// position is better than failing, so it is used as a last resort.
  Future<Position> getCurrentPosition() async {
    await ensureReady();

    final cached = await _readCachedPosition();
    if (cached != null && _isTrustworthy(cached)) {
      return cached;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _freshFixTimeout,
        ),
      );
    } catch (_) {
      // No satellite fix (for example indoors): try a rough network position.
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: _approximateFixTimeout,
          ),
        );
      } catch (_) {
        if (cached != null) {
          return cached;
        }
        throw const LocationFailure(
          LocationFailureReason.noSignal,
          'Could not find your location. Move outdoors and retry, or start an indoor session.',
        );
      }
    }
  }

  /// Requests permissions and returns the user's current LatLng.
  Future<LatLng> getUserLocation() async {
    final position = await getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  /// Opens the settings page that can fix [failure]. Returns whether a
  /// settings page could be opened.
  Future<bool> openSettingsFor(LocationFailure failure) {
    switch (failure.reason) {
      case LocationFailureReason.serviceDisabled:
        return Geolocator.openLocationSettings();
      case LocationFailureReason.permissionDeniedForever:
        return Geolocator.openAppSettings();
      case LocationFailureReason.permissionDenied:
      case LocationFailureReason.noSignal:
        return Future<bool>.value(false);
    }
  }

  Future<Position?> _readCachedPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      // Not supported on every platform (for example web).
      return null;
    }
  }

  bool _isTrustworthy(Position position) {
    final age = DateTime.now().difference(position.timestamp);
    return age <= _maxCachedAge && position.accuracy <= _maxCachedAccuracyMeters;
  }
}
