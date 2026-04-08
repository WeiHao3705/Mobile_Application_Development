import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:mobile_application_development/theme/app_colors.dart';

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

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try{
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if(!serviceEnabled) {
        throw Exception('Location Services Are Disable. Please turn on GPS');
      }

      permission = await Geolocator.checkPermission();
      if(permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if(permission == LocationPermission.denied) {
          throw Exception('Location Permissions Are Denied');
        }
      }

      if(permission == LocationPermission.deniedForever) {
        throw Exception('Location Permissions Are Permanently Denied');
      }

      Position? position;

      try {
        position = await Geolocator.getLastKnownPosition();

        position ??= await Geolocator.getCurrentPosition();
      }
      catch(e) {
        throw Exception('Could not find GPS signal. Are you indoors?');
      }
      setState(() {
        _currentLocation = LatLng(position!.latitude, position.longitude);
        _isLoading = false;
      });
    } catch(e) {
      print('Location Error: $e');
      setState(() {
        _errorMessage = e.toString();
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