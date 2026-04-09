// lib/services/location_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {

  /// Requests permissions and returns the user's current LatLng
  Future<LatLng> getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if GPS is on
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location Services Are Disabled. Please turn on GPS');
    }

    // 2. Check Permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location Permissions Are Denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location Permissions Are Permanently Denied');
    }

    // 3. Get the Location
    Position? position;
    try {
      // Try to get a fast cached location first
      position = await Geolocator.getLastKnownPosition();
      // If no cache, force a fresh live location
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return LatLng(position.latitude, position.longitude);

    } catch (e) {
      throw Exception('Could not find GPS signal. Are you indoors?');
    }
  }
}