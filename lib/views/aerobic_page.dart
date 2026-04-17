import 'package:flutter/material.dart';
import 'package:mobile_application_development/theme/app_colors.dart';
import 'aerobic_type.dart';
import 'aerobic_detail.dart';

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

class _AerobicRecord extends StatefulWidget{
  final int userId;

  const _AerobicRecord({required this.userId});

  @override
  State<_AerobicRecord> createState() => _AerobicRecordState();
}

class _AerobicRecordState extends State<_AerobicRecord> {
  final AerobicRepository _repository = AerobicRepository();
  late Future<List<Aerobic>> _recordsFuture;
  DateTime? _selectedFilterDate;

  @override
  void initState() {
    super.initState();
    _recordsFuture = _repository.fetchUserRecords(widget.userId.toString());
  }

  void _refreshRecords() {
    setState(() {
      _recordsFuture = _repository.fetchUserRecords(widget.userId.toString());
    });
  }

  Future<void> _selectFilterDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.nearBlack,
              onSurface: AppColors.lavender,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedFilterDate = pickedDate;
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _selectedFilterDate = null;
    });
  }

  List<Aerobic> _filterRecordsByDate(List<Aerobic> records) {
    if (_selectedFilterDate == null) {
      return records;
    }

    return records.where((record) {
      return record.start_at.year == _selectedFilterDate!.year &&
          record.start_at.month == _selectedFilterDate!.month &&
          record.start_at.day == _selectedFilterDate!.day;
    }).toList();
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
                    builder: (context) => AerobicStartPage(userId: widget.userId))
                );
                if(result == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Aerobic record saved successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  // ✅ REFRESH THE RECORDS
                  _refreshRecords();
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

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Previous Record',
                style: TextStyle(
                  color: AppColors.lime,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: _selectFilterDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Filter',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Selected date filter display
        if (_selectedFilterDate != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtered: ${_selectedFilterDate!.day}/${_selectedFilterDate!.month}/${_selectedFilterDate!.year}',
                    style: const TextStyle(
                      color: AppColors.lime,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearFilter,
                    child: const Icon(Icons.close, color: AppColors.primary, size: 18),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 12),

        // ✅ NOW USES STATE VARIABLE FOR FUTURE WITH FILTERING
        FutureBuilder<List<Aerobic>>(
            future: _recordsFuture,
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

              final allRecords = snapshot.data ?? [];
              final filteredRecords = _filterRecordsByDate(allRecords);
              
              if(filteredRecords.isEmpty) {
                return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        _selectedFilterDate != null 
                          ? 'No Aerobic Records Found for ${_selectedFilterDate!.day}/${_selectedFilterDate!.month}/${_selectedFilterDate!.year}.' 
                          : 'No Aerobic Records Found.', 
                        style: const TextStyle(color: AppColors.lavender),
                        textAlign: TextAlign.center,
                      ),
                    )
                );
              }

              return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    return _ActivityCard(
                      record: filteredRecords[index],
                      resolveRouteImageUrl: _repository.resolveRouteImageUrl,

                    );
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
  final String Function(String rawValue) resolveRouteImageUrl;

  const _ActivityCard({
    required this.record,
    required this.resolveRouteImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AerobicDetailPage(record: record),
          ),
        );
      },
      child: Container(
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
                child: _buildImageSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final resolvedImageUrl = resolveRouteImageUrl(record.route_image);

    if (resolvedImageUrl.isEmpty) {
      print('⚠️  [AEROBIC-PAGE] Image URL is empty for: ${record.route_image}');
      return _buildPlaceholderMap();
    }

    print('✅ [AEROBIC-PAGE] Loading image from: $resolvedImageUrl');
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        resolvedImageUrl,
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              color: AppColors.lime,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading route image: $error | raw=${record.route_image} | resolved=$resolvedImageUrl');
          return _buildPlaceholderMap();
        },
      ),
    );
  }

  Widget _buildPlaceholderMap() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 40,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              'Route',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}