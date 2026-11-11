import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:mobile_application_development/theme/app_colors.dart';
import '../services/location_service.dart';

class LiveMap extends StatefulWidget {

  final int userId;

  const LiveMap({super.key, required this.userId});

  @override
  State<LiveMap> createState() => _LiveMap();
}

class _LiveMap extends State<LiveMap> {
  LatLng? _currentLocation;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  final LocationService _locationService = LocationService();

  Future<void> _getUserLocation() async {
    try {
      final location = await _locationService.getUserLocation();
      if (!mounted) return;
      setState(() {
        _currentLocation = location;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is LocationFailure
            ? e.message
            : 'Unable to get your location. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _refreshLocation() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _currentLocation = null;
    });
    _getUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Live Map'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if(_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(_errorMessage, style: const TextStyle(color: Colors.red),
            textAlign:TextAlign.center,
          ),
        ),
      );
    }

    if(_isLoading || _currentLocation == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.purple),
            SizedBox(height: 16),
            Text('Loading...', style: TextStyle(color: AppColors.purple)),
          ],
        ),
      );
    }

    return Container(
      height: 500,
      width: double.infinity,
      color: Colors.red,
      child:FlutterMap(
        options: MapOptions(
          initialCenter: _currentLocation!,
          initialZoom: 20.0,
        ),
        children: [
          // shows the map in background
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'MyFitnessApp',
          ),
          // the pointer shows the user's current location
          MarkerLayer(
            markers: [
              Marker(
                  point: _currentLocation!,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.circle,
                    color: AppColors.lime,
                    size: 20,
                  )
              )
            ],
          ),
        ],
      ),
    );
  }
}