import 'package:flutter/material.dart';
import 'package:mobile_application_development/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AerobicPage extends StatefulWidget{
  const AerobicPage({super.key});

  @override
  State<AerobicPage> createState() => _AerobicPageState();
}

class _AerobicPageState extends State<AerobicPage> {
  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

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
        // appBar: AppBar(
        //   title: const Text('Aerobic'),
        //   centerTitle: true,
        //   backgroundColor: theme.colorScheme.primary,
        //   foregroundColor: theme.colorScheme.onPrimary,
        //   elevation: 0,
        // )
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
    DateTime date = DateTime.parse(json['start_at']).toLocal();
    String formattedDate = "${date.day} ${date.month} ${date.year} At ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    int totalSeconds = json['moving_time'] as int;
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    String formattedDuration = "${minutes}m ${seconds}s";

   return AerobicExercise(
     location: json['location'] ?? 'Unknown Location',
     activityType: json['activity_type'] ?? 'Activity',
     dateTime: formattedDate,
     distance: json['total_distance'] ?? '0.0 km',
     duration: formattedDuration,
     routeImageUrl: json['route_image'],
   );
  }
}

class _AerobicRecord extends StatelessWidget{

  final String userId;

  const _AerobicRecord({required this.userId});

  //fetch the data from supabase
  Future<List<AerobicExercise>> _fetchUserRecords() async {
    try {
      final response = await Supabase.instance.client
          .from('AerobicExercise')
          .select()
          .eq('user_id', userId)
          .order('start_at', ascending: false);

      return (response as List).map((data) => AerobicExercise.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user records: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

            final records = snapshot.data!;
            if(records == null || records.isEmpty) {
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
      height: 120,
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
                ),
              ),
            )
          ],
        ),
      )
    );
  }
}