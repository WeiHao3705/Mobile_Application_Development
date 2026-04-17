import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_application_development/theme/app_colors.dart';
import '../services/location_service.dart';

import 'live_map.dart';
import '../repository/aerobic_activity_repository.dart';
import 'aerobic_session_run.dart';

import 'package:flutter_map/flutter_map.dart';

class AerobicStartPage extends StatefulWidget {

  final int userId;
  const AerobicStartPage({super.key, required this.userId});

  @override
  State<AerobicStartPage> createState() => _AerobicStartPageState();
}

class _AerobicStartPageState extends State<AerobicStartPage> {

  final LocationService _locationService = LocationService();
  final AerobicRepository _aerobicActivityRepository = AerobicRepository();

  // used to check the map status
  LatLng? _currentLocation;
  bool _isLoadingMap = false;
  String _mapError = '';
  int caloriesPerKM = 0;

  String? _selectedActivity;
  bool _isLoadingActivities = true;

  // Used to store the activity type from db
  List<String> _activityTypes = [];
  List<Map<String, dynamic>> _activitiesData = [];

  @override
  void initState() {
    super.initState();
    _fetchActivityType();
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isLoadingMap = true;
      _mapError = '';
    });

    try {
      final latLng = await _locationService.getUserLocation();
      setState(() {
        _currentLocation = latLng;
        _isLoadingMap = false;
      });
    } catch (e) {
      setState(() {
        _mapError = e.toString();
        _isLoadingMap = false;
      });
    }
  }

  // fetch the activity type from db
  Future<void> _fetchActivityType() async {
    final data = await _aerobicActivityRepository.fetchAerobicActivity();

    setState(() {
      if(data.isNotEmpty) {
        _activitiesData = data;
        _activityTypes = data.map((item) => item['aerobic_name'] as String).toList();
      } else {
        _activitiesData = [
          {'aerobic_name': 'Run', 'calories_per_km': 100},
          {'aerobic_name': 'Walk', 'calories_per_km': 50},
          {'aerobic_name': 'Ride', 'calories_per_km': 40},
        ];
        _activityTypes = ['RUNNING', 'WALKING', 'RIDING'];
      }
      // Set default value to RUNNING if it exists
      _selectedActivity = "RUNNING";
      _isLoadingActivities = false;
    });
  }

  void _startSession() {
    if(_selectedActivity == null || _currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an activity and location first.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final selectedData = _activitiesData.firstWhere(
        (activity) => activity['aerobic_name'] == _selectedActivity,
      orElse: () => {'aerobic_name': _selectedActivity, 'calories_per_km': 60},
    );

    // The question marks (?) make it safe, and the ?? 60 provides a backup!
    int caloriesPerKM = (selectedData['calories_per_km'] as num?)?.toInt() ?? 60;
    print(caloriesPerKM);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AerobicSessionRun(
          userId: widget.userId,
          activityType: _selectedActivity!,
          startLocation: _currentLocation!,
          caloriesPerKM: caloriesPerKM,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(10.0),
              child: _Header(),
            ),
            const SizedBox(height: 8),
            _buildDropdownSelector(),
            const SizedBox(height: 8),
            Expanded(child: _buildMapArea()),

            _buildBottomControls(),
            // ElevatedButton(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => LiveMap(userId: widget.userId)),
            //     );
            //   },
            //   child: const Text('Start Map'),
            // ),

          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSelector() {
    if (_isLoadingActivities) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: CircularProgressIndicator(color: AppColors.lime)),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppColors.black,
        border: Border.all(color: AppColors.lime, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedActivity,
          isExpanded: true,
          dropdownColor: AppColors.nearBlack, // Dark background for the dropdown menu
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.lime, size: 30),
          hint: const Text(
            'Select your activity...',
            style: TextStyle(color: AppColors.lavender, fontSize: 16),
          ),
          items: _activityTypes.map((String activity) {
            return DropdownMenuItem<String>(
              value: activity,
              child: Text(
                activity,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedActivity = newValue;
            });
            // TRIGGER THE MAP LOCATION AFTER SELECTION
            if (_currentLocation == null) {
              _getUserLocation();
            }
          },
        ),
      ),
    );
  }

  Widget _buildMapArea() {
    if(_mapError.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(_mapError, style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
          ),
        )
      );
    }

    if (_isLoadingMap || _currentLocation == null) {
      return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.lime),
              SizedBox(height: 16),
              Text('Locating you...', style: TextStyle(color: AppColors.lavender)),
            ],
          )
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: _currentLocation!,
        initialZoom: 18.0,
        minZoom: 11.0,
        maxZoom: 20.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.hermen.aerobic', // Make sure this is unique
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _currentLocation!,
              width: 40,
              height: 40,
              child: const Icon(Icons.circle, color: AppColors.lime, size: 24),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.black,
        border: Border(top: BorderSide(color: AppColors.lavender.withValues(alpha: 0.2))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            // Reset Location Button
            Expanded(
              flex: 1,
              child: OutlinedButton(
                // Only allow reset if the map is actually trying to show
                onPressed: _selectedActivity != null ? _getUserLocation : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: _selectedActivity != null ? AppColors.lime : Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Icon(Icons.my_location, color: _selectedActivity != null ? AppColors.lime : Colors.grey),
              ),
            ),
            const SizedBox(width: 10),
            // Start Session Button
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: _startSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.nearBlack,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'START SESSION',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget{
  const _Header();

  @override
  Widget build(BuildContext context){
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: _iconBtn(
            child: const Icon(Icons.chevron_left, color: AppColors.lime, size: 18),
          ),
        ),
        const SizedBox(width: 3),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: const Text(
            'Choose Your Exercise',
            style: TextStyle(
              color: AppColors.lavender,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        )
      ],
    );
  }
  Widget _iconBtn({required Widget child}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lavender.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

