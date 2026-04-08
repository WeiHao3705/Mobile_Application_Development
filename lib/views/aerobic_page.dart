import 'package:flutter/material.dart';
import 'package:mobile_application_development/theme/app_colors.dart';
import 'aerobic_type.dart';

// --- IMPORTANT NEW IMPORTS ---
// Make sure these paths match where you saved your files!
import '../models/aerobic.dart';
import '../repository/aerobic_repository.dart';
import '../controllers/auth_controller.dart';

class AerobicPage extends StatefulWidget{

  final int userId;

  const AerobicPage({super.key, required this.userId});

  @override
  State<AerobicPage> createState() => _AerobicPageState();
}

class _AerobicPageState extends State<AerobicPage> {
  @override
  Widget build(BuildContext context) {

    final String userId;

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
              _AerobicRecord(userId: widget.userId),
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
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
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

class _AerobicRecord extends StatelessWidget{

  // 1. Initialize your repository here!
  final AerobicRepository _repository = AerobicRepository();
  final int userId;

  _AerobicRecord({required this.userId});

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

        // 2. Change the FutureBuilder to use your Repository and Aerobic model
        FutureBuilder<List<Aerobic>>(
          // Just call the repository method here!
            future: _repository.fetchUserRecords(userId.toString()), // Converting int to String if your repository expects a String
            builder: (context, snapshot) {
              if(snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.lime));
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
  // 3. Update this to use your official Aerobic model
  final Aerobic record;

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
                            // Using your model's variable name
                            record.activity_type,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.nearBlack,
                            ),
                          ),
                          Text(
                            // Using the getter we created in the model
                            record.formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.nearBlack,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        // Using the getter we created in the model
                        'Distance: ${record.formattedDistance}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.nearBlack
                        ),
                      ),
                      Text(
                        // Using the getter we created in the model
                        'Duration: ${record.formattedDuration}',
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
                child: record.route_image.isNotEmpty
                    ? Image.network(
                  record.route_image, // Updated to match your model's variable name
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