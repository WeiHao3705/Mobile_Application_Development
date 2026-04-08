import 'package:flutter/material.dart';
import 'package:mobile_application_development/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'aerobic_start.dart';

class AerobicPage extends StatefulWidget{
  final int userId;
  
  const AerobicPage({super.key, required this.userId});

  @override
  State<AerobicPage> createState() => _AerobicPageState();
}

class _AerobicPageState extends State<AerobicPage> {
  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;

    print('═════════════════════════════════════════');
    print('AEROBIC PAGE - USER INFO');
    print('═════════════════════════════════════════');
    print('User ID: $userId');
    print('User ID Type: ${userId.runtimeType}');
    print('═════════════════════════════════════════');


    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 20),
              const _TabSection(),
              const SizedBox(height: 20),
              _AerobicRecord(userId: userId),
            ],
          ),
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
            'Aerobic',
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

class _TabSection extends StatelessWidget {
  const _TabSection();

  @override
  Widget build(BuildContext context){
    return Row(
      children: [
        Expanded(child:
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            alignment: Alignment.center,
            child: const Text(
              'MonthlySnapshot',
              style: TextStyle(
                color: AppColors.purple,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          )
        ),
        const SizedBox(width: 6),
        Expanded(child:
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(17),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Share All',
              style: TextStyle(
                color: AppColors.nearBlack,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          )
        )
      ]
    );
  }
}

// fetch exercise records (aerobic) from database
class AerobicExercise {
  final String location;
  final String activityType;
  final String dateTime;
  final String distance;
  final String duration;
  final String? routeImageUrl;

  AerobicExercise({
    required this.location,
    required this.activityType,
    required this.dateTime,
    required this.distance,
    required this.duration,
    this.routeImageUrl,
  });

  factory AerobicExercise.fromJson(Map<String, dynamic> json) {
    // Safe date parsing
    String formattedDate = 'Unknown Date';
    if (json['start_at'] != null) {
      try {
        DateTime date = DateTime.parse(json['start_at']).toLocal();
        formattedDate = "${date.day} ${date.month} ${date.year} At ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      } catch (e) {
        formattedDate = 'Invalid Date';
      }
    }

    // Safe duration parsing
    String formattedDuration = '0m 0s';
    if (json['moving_time'] != null) {
      try {
        int totalSeconds = json['moving_time'] as int;
        int minutes = totalSeconds ~/ 60;
        int seconds = totalSeconds % 60;
        formattedDuration = "${minutes}m ${seconds}s";
      } catch (e) {
        formattedDuration = 'Unknown Duration';
      }
    }

   return AerobicExercise(
     location: json['location'] ?? 'Unknown Location',
     activityType: json['activity_type'] ?? 'Activity',
     dateTime: formattedDate,
     distance: json['total_distance'] != null ?  "${json['total_distance']} KM" : '0.00 KM',
     duration: formattedDuration,
     routeImageUrl: json['route_image'],
   );
  }
}

class _AerobicRecord extends StatelessWidget{

  final int userId;

  const _AerobicRecord({required this.userId});

  //fetch the data from supabase
  Future<List<AerobicExercise>> _fetchUserRecords() async {
    try {
      print('═════════════════════════════════════════');
      print('FETCHING AEROBIC RECORDS');
      print('═════════════════════════════════════════');
      print('User ID: $userId');
      print('User ID Type: ${userId.runtimeType}');
      print('═════════════════════════════════════════');
      
      final response = await Supabase.instance.client
          .from('AerobicExercise')
          .select()
          .eq('user_id', userId)
          .order('start_at', ascending: false);

      print('Response received: ${response.runtimeType}');
      print('Response length: ${response is List ? response.length : 'N/A'}');
      
      // Handle response safely
      if (response is List) {
        print('Response is a List with ${response.length} items');
        final records = response.map((data) {
          if (data is Map<String, dynamic>) {
            return AerobicExercise.fromJson(data);
          }
          return null;
        }).whereType<AerobicExercise>().toList();
        print('Successfully parsed ${records.length} records');
        return records;
      }
      
      print('⚠️ Response is not a List');
      return [];
    } catch (e) {
      print('═════════════════════════════════════════');
      print('SUPABASE ERROR OCCURRED');
      print('═════════════════════════════════════════');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('═════════════════════════════════════════');
      throw Exception('Failed to fetch user records: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                    context, MaterialPageRoute(
                    builder: (context) => AerobicStartPage(userId: userId))
                );
                if(result == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Aerobic record saved successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('START NEW SESSION'),
              style: ElevatedButton.styleFrom(
                // the button is black because no navigation yet
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.nearBlack,
                padding: const EdgeInsets.symmetric(vertical:12),
                shape:RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            'Previous Record',
            style: TextStyle(
              color: AppColors.lime,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 10),
        FutureBuilder<List<AerobicExercise>>(
          future: _fetchUserRecords(),
          builder: (context, snapshot) {
            if(snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.lime,));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading records: ${snapshot.error}',
                style: const TextStyle(color: Colors.red)),
              );
            }

            final records = snapshot.data ?? [];
            if(records.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No Aerobic Records Found.', style: TextStyle(color: AppColors.lavender)),
                )
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              itemBuilder: (context, index) {
                return _ActivityCard(record: records[index]);
              }
            );
          }
        )
      ],
    );
  }
}


class _ActivityCard extends StatelessWidget{
  final AerobicExercise record;

  const _ActivityCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      height: 125,
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(left:16.0, top: 12.0, bottom: 12.0, right:8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      record.location.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.nearBlack,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.activityType,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.nearBlack,
                          ),
                        ),
                        Text(
                          record.dateTime,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.nearBlack,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Distance: ${record.distance}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.nearBlack
                      ),
                    ),
                    Text(
                      'Duration: ${record.duration}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.nearBlack
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: record.routeImageUrl != null && record.routeImageUrl!.isNotEmpty
                ? Image.network(
                  record.routeImageUrl!,
                  fit: BoxFit.cover,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholderMap(),
              )
                  : _buildPlaceholderMap(),
            ),
          ],
        ),
      )
    );
  }

  Widget _buildPlaceholderMap() {
    return Container (
      color: Colors.grey[400],
      child: const Center(
        child: Icon(Icons.map, size: 48, color: Colors.white),
      ),
    );
  }
}