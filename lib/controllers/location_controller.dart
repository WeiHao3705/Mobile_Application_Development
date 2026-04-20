import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationController {
  /// Format location with state information
  String _withState(String base, String? state) {
    final location = base.trim();
    final stateText = (state ?? '').trim();

    if (location.isEmpty) {
      return stateText;
    }
    if (stateText.isEmpty) {
      return location;
    }
    if (location.toLowerCase().contains(stateText.toLowerCase())) {
      return location;
    }

    return '$location, $stateText';
  }

  /// Normalize location token for comparison
  String _normalizeLocationToken(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Check if a location token is generic/administrative
  bool _isGenericLocationToken(String value, {String? state}) {
    final normalized = _normalizeLocationToken(value);
    final normalizedState = _normalizeLocationToken(state ?? '');

    if (normalized.isEmpty || RegExp(r'^\d{5}$').hasMatch(normalized)) {
      return true;
    }

    const generic = <String>{
      'malaysia',
      'w p kuala lumpur',
      'wp kuala lumpur',
      'wilayah persekutuan kuala lumpur',
      'federal territory',
      'federal territory of kuala lumpur',
      'administrative area',
    };

    if (generic.contains(normalized)) {
      return true;
    }

    if (normalizedState.isNotEmpty && normalized == normalizedState) {
      return true;
    }

    return false;
  }

  /// Get location from Nominatim reverse geocoding
  Future<String> getLocationFromNominatim(double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
        ),
        headers: {
          'User-Agent': 'com.hermen.aerobic/1.0',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          print('=== NOMINATIM ADDRESS DETAILS ===');
          print('Full address map: $address');

          final state = address['state']?.toString().trim() ??
              address['region']?.toString().trim() ??
              address['state_district']?.toString().trim() ??
              '';

          // Try to get location names from Nominatim
          final locationParts = <String>[];
          
          // Extended priority order - check for specific building identifiers first
          final priorityFields = [
            'house_name',      // "PV9 Residence"
            'shop_name',       // Shop names
            'building',        // Building names
            'amenity',         // Parks, gyms, cafes
            'shop',            // Retail locations
            'leisure',         // Recreation areas
            'parking',         // Parking areas
            'restaurant',      // Restaurants
            'cafe',            // Cafes
            'public_building', // Government buildings
            'historic',        // Historical sites
            'tourism',         // Tourist sites
            'road',            // Street names
            'neighbourhood',   // Neighborhoods
            'suburb',          // Suburbs
            'village',         // Villages
            'city_district'    // City districts
          ];
          
          for (String field in priorityFields) {
            if (address[field] != null && address[field].toString().isNotEmpty) {
              final value = address[field].toString().trim();
              if (value.length > 1 &&
                  !_isGenericLocationToken(value, state: state) &&
                  !locationParts.contains(value)) {
                locationParts.add(value);
                print('✓ Found $field: $value');
              }
            }
          }

          // If all specific fields were generic, try city/town/county as base.
          if (locationParts.isEmpty) {
            final areaCandidates = [
              address['suburb']?.toString().trim(),
              address['neighbourhood']?.toString().trim(),
              address['quarter']?.toString().trim(),
              address['city']?.toString().trim(),
              address['town']?.toString().trim(),
              address['county']?.toString().trim(),
            ];

            for (final candidate in areaCandidates) {
              if (candidate != null &&
                  candidate.isNotEmpty &&
                  !_isGenericLocationToken(candidate, state: state)) {
                locationParts.add(candidate);
                break;
              }
            }
          }

          final result = locationParts.join(', ');
          print('Nominatim address parts result: $result');
          print('========================');
          if (result.isNotEmpty) {
            return _withState(result, state);
          }

          if (state.isNotEmpty) {
            return state;
          }
        }

        // Last Nominatim fallback: parse display name and keep first non-generic part.
        if (data['display_name'] != null && data['display_name'].toString().isNotEmpty) {
          final displayName = data['display_name'].toString().trim();
          print('📍 Nominatim display_name fallback: $displayName');

          final parts = displayName.split(',').map((e) => e.trim()).toList();
          for (final part in parts) {
            if (!_isGenericLocationToken(part)) {
              return part;
            }
          }
        }
      }
      
      return '';
    } catch (e) {
      print('❌ Error with Nominatim: $e');
      return '';
    }
  }

  Future<String> getLocationAddress(double latitude, double longitude) async {
    try {
      if (latitude == 0 || longitude == 0) {
        return 'Location Unknown';
      }

      final nominatimResult = await getLocationFromNominatim(latitude, longitude);
      if (nominatimResult.isNotEmpty && nominatimResult.length > 2) {
        // Accept Nominatim result even if it's not super specific - it's better than nothing
        return nominatimResult;
      }

      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final state = place.administrativeArea?.trim();
        
        final addressParts = <String>[];
        bool hasSpecificLocation = false;
        
        if (place.name != null && place.name!.isNotEmpty) {
          final name = place.name!.trim();
          
          final isGeneric = name == place.administrativeArea ||
                           name == place.locality || 
                           name.contains('W.P.') ||
                           name.contains('Kuala Lumpur') ||
                           name.contains('Selangor') ||
                           name.contains('Malaysia') ||
                           name == place.subAdministrativeArea ||
                           name.length < 3;
          
          if (!isGeneric) {
            addressParts.add(name);
            hasSpecificLocation = true;
          }
        }
        
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          final subLocality = place.subLocality!.trim();
          final isGeneric = subLocality.contains('W.P.') || 
                           subLocality.contains('Kuala Lumpur') ||
                           subLocality.length < 2;
          
          if (!isGeneric && !addressParts.contains(subLocality)) {
            addressParts.add(subLocality);
            hasSpecificLocation = true;
          }
        }
        
        if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
          final street = place.thoroughfare!.trim();
          if (!addressParts.contains(street) && street.length > 3) {
            addressParts.add(street);
            hasSpecificLocation = true;
          }
        }
        
        // 4. Building number with street
        if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
          final building = place.subThoroughfare!.trim();
          if (!addressParts.contains(building)) {
            addressParts.add(building);
            hasSpecificLocation = true;
          }
        }

        // Remove duplicates
        final uniqueAddress = addressParts
            .where((part) => part.isNotEmpty)
            .toSet()
            .toList()
            .join(', ');
        
        // If we found something specific, return it
        if (hasSpecificLocation && uniqueAddress.isNotEmpty) {
          return _withState(uniqueAddress, state);
        }
        
        String fallbackAddress = '';
        
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          final subLocality = place.subLocality!.trim();
          if (subLocality.length > 2) {
            fallbackAddress = subLocality;
            fallbackAddress = _withState(fallbackAddress, state);
            print('Fallback: Using sub-locality + state: $fallbackAddress');
          }
        }
        
        if (fallbackAddress.isEmpty && place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
          final street = place.thoroughfare!.trim();
          if (street.length > 2) {
            fallbackAddress = street;
            fallbackAddress = _withState(fallbackAddress, state);
            print('Fallback: Using street + state: $fallbackAddress');
          }
        }
        
        if (fallbackAddress.isEmpty && place.name != null && place.name!.isNotEmpty) {
          final name = place.name!.trim();
          if (name.length > 2 && !name.contains('W.P.')) {
            fallbackAddress = name;
            fallbackAddress = _withState(fallbackAddress, state);
            print('Fallback: Using name + state: $fallbackAddress');
          }
        }
        
        if (fallbackAddress.isEmpty && place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
          final subAdmin = place.subAdministrativeArea!.trim();
          if (subAdmin.length > 2 && !subAdmin.contains('W.P.')) {
            fallbackAddress = subAdmin;
            fallbackAddress = _withState(fallbackAddress, state);
            print('Fallback: Using district + state: $fallbackAddress');
          }
        }
        
        if (fallbackAddress.isEmpty && place.locality != null && place.locality!.isNotEmpty) {
          final locality = place.locality!.trim();
          if (locality.length > 2) {
            fallbackAddress = locality;
            fallbackAddress = _withState(fallbackAddress, state);
            print('Fallback: Using locality + state: $fallbackAddress');
          }
        }
        
        if (fallbackAddress.isEmpty) {
          final lat = latitude.toStringAsFixed(4);
          final lng = longitude.toStringAsFixed(4);
          fallbackAddress = '$lat, $lng';
          print('No location data found anywhere, using coordinates: $fallbackAddress');
        }

        return fallbackAddress;
      }

      return 'Location Unknown';
    } catch (e) {
      print('Error getting location address: $e');
      return 'Tracked via GPS';
    }
  }
}
