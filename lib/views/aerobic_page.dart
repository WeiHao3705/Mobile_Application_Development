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

  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {

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
              _TabSection(
                isArchivePage: _showArchived,
                onTapChanged: (bool isArchived) {
                  setState(() {
                    _showArchived = isArchived;
                  });
                }
              ),
              const SizedBox(height: 20),
              // ✅ Show different widget based on tab selection
              if (!_showArchived)
                _PreviousRecordsWidget(userId: widget.userId)
              else
                _ArchivedRecordsWidget(userId: widget.userId),
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

  final bool isArchivePage;
  final ValueChanged<bool> onTapChanged;

  const _TabSection({required this.isArchivePage, required this.onTapChanged});

  @override
  Widget build(BuildContext context){
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onTapChanged(false),
            child: Container(
            height: 34,
            decoration: BoxDecoration(
            color: !isArchivePage ? AppColors.white : AppColors.lavender.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: !isArchivePage ? AppColors.white : AppColors.lavender.withValues(alpha: 0.5),
            ),
            ),
            alignment: Alignment.center,
            child: Text('MonthlySnapshot',
            style: TextStyle(
            color: !isArchivePage ? AppColors.purple : AppColors.lavender,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      )
    )
      ),
      const SizedBox(width: 6),

      Expanded(
        child: GestureDetector(
        onTap: () => onTapChanged(true),
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            color: isArchivePage ? AppColors.lime : AppColors.lavender.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isArchivePage ? AppColors.lime : AppColors.lavender.withValues(alpha: 0.5),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            'Archived',
            style: TextStyle(
              color: isArchivePage ? AppColors.nearBlack : AppColors.lavender,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        )
      ),

        )
      ]
    );
  }
}

class _PreviousRecordsWidget extends StatefulWidget{
  final int userId;

  const _PreviousRecordsWidget({required this.userId});

  @override
  State<_PreviousRecordsWidget> createState() => _PreviousRecordsWidgetState();
}

class _PreviousRecordsWidgetState extends State<_PreviousRecordsWidget> {
  final AerobicRepository _repository = AerobicRepository();
  late Future<List<Aerobic>> _recordsFuture;
  late Future<List<String>> _activityTypesFuture;
  DateTime? _selectedFilterDate;
  String? _selectedActivityType; // Add activity type filter

  @override
  void initState() {
    super.initState();
    _recordsFuture = _repository.fetchUserRecords(widget.userId);
    _activityTypesFuture = _repository.fetchDistinctActivityTypes(widget.userId);
  }

  void _refreshRecords() {
    setState(() {
      _recordsFuture = _repository.fetchUserRecords(widget.userId);
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

  void _clearActivityTypeFilter() {
    setState(() {
      _selectedActivityType = null;
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

  List<Aerobic> _filterRecordsByActivityType(List<Aerobic> records) {
    if (_selectedActivityType == null || _selectedActivityType!.isEmpty) {
      return records;
    }

    return records.where((record) {
      return record.activity_type.toLowerCase() == _selectedActivityType!.toLowerCase();
    }).toList();
  }

  List<Aerobic> _applyAllFilters(List<Aerobic> records) {
    var filtered = records;
    filtered = _filterRecordsByDate(filtered);
    filtered = _filterRecordsByActivityType(filtered);
    return filtered;
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
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
                            'Date',
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
                  const SizedBox(width: 8),
                  // Activity Type Filter Button
                  FutureBuilder<List<String>>(
                    future: _activityTypesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }

                      final activityTypes = snapshot.data ?? [];
                      final dropdownItems = [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'All',
                            style: TextStyle(
                              color: AppColors.lavender,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        ...activityTypes.map((type) => DropdownMenuItem<String?>(
                          value: type,
                          child: Text(
                            type,
                            style: const TextStyle(
                              color: AppColors.lavender,
                              fontSize: 12,
                            ),
                          ),
                        )),
                      ];

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String?>(
                          value: _selectedActivityType,
                          underline: const SizedBox(),
                          isDense: true,
                          hint: const Row(
                            children: [
                              Icon(Icons.category, color: AppColors.primary, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Type',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          dropdownColor: AppColors.nearBlack,
                          items: dropdownItems,
                          onChanged: (value) {
                            setState(() {
                              _selectedActivityType = value;
                            });
                          },
                          style: const TextStyle(
                            color: AppColors.lime,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
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

              // Filter to show only non-archived records
              final nonArchivedRecords = allRecords.where((record) => !record.is_archived).toList();
              
              // Apply all filters (date and activity type)
              final filteredRecords = _applyAllFilters(nonArchivedRecords);

              if (filteredRecords.isEmpty) {
                String emptyMessage;
                if (_selectedFilterDate != null) {
                  emptyMessage = 'No Aerobic Records Found for ${_selectedFilterDate!.day}/${_selectedFilterDate!.month}/${_selectedFilterDate!.year}.';
                } else {
                  emptyMessage = 'No Aerobic Records Found.';
                }

                return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        emptyMessage,
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
                      onDetailClose: _refreshRecords,
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
  final bool isArchived;
  final VoidCallback onDetailClose; // Add callback for when detail page closes

  const _ActivityCard({
    required this.record,
    required this.resolveRouteImageUrl,
    this.isArchived = false,
    required this.onDetailClose, // Require the callback
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
        ).then((_) {
          // Refresh records when returning from detail page
          onDetailClose();
        });
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
    //For archived records, skip image loading and show placeholder directly
    if (isArchived) {
      return _buildPlaceholderMap();
    }

    final resolvedImageUrl = resolveRouteImageUrl(record.route_image);

    if (resolvedImageUrl.isEmpty) {
      print('[AEROBIC-PAGE] Image URL is empty for: ${record.route_image}');
      return _buildPlaceholderMap();
    }

    print('[AEROBIC-PAGE] Loading image from: $resolvedImageUrl');
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
          print('Error loading route image: $error | raw=${record.route_image} | resolved=$resolvedImageUrl');
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
          ],
        ),
      ),
    );
  }
}

class _ArchivedRecordsWidget extends StatefulWidget {
  final int userId;

  const _ArchivedRecordsWidget({required this.userId});

  @override
  State<_ArchivedRecordsWidget> createState() => _ArchivedRecordsWidgetState();
}

class _ArchivedRecordsWidgetState extends State<_ArchivedRecordsWidget> {
  final AerobicRepository _repository = AerobicRepository();
  late Future<List<Aerobic>> _recordsFuture;
  late Future<List<String>> _activityTypesFuture;
  DateTime? _selectedFilterDate;
  String? _selectedActivityType; // Add activity type filter

  @override
  void initState() {
    super.initState();
    _recordsFuture = _repository.fetchArchivedRecords(widget.userId);
    _activityTypesFuture = _repository.fetchDistinctActivityTypes(widget.userId);
  }

  void _refreshRecords() {
    setState(() {
      _recordsFuture = _repository.fetchArchivedRecords(widget.userId);
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

  void _clearActivityTypeFilter() {
    setState(() {
      _selectedActivityType = null;
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

  List<Aerobic> _filterRecordsByActivityType(List<Aerobic> records) {
    if (_selectedActivityType == null || _selectedActivityType!.isEmpty) {
      return records;
    }

    return records.where((record) {
      return record.activity_type.toLowerCase() == _selectedActivityType!.toLowerCase();
    }).toList();
  }

  List<Aerobic> _applyAllFilters(List<Aerobic> records) {
    var filtered = records;
    filtered = _filterRecordsByDate(filtered);
    filtered = _filterRecordsByActivityType(filtered);
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Archived Records',
                style: TextStyle(
                  color: AppColors.lime,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
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
                            'Date',
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
                  const SizedBox(width: 8),
                  // Activity Type Filter Button
                  FutureBuilder<List<String>>(
                    future: _activityTypesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }

                      final activityTypes = snapshot.data ?? [];
                      final dropdownItems = [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'All',
                            style: TextStyle(
                              color: AppColors.lavender,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        ...activityTypes.map((type) => DropdownMenuItem<String?>(
                          value: type,
                          child: Text(
                            type,
                            style: const TextStyle(
                              color: AppColors.lavender,
                              fontSize: 12,
                            ),
                          ),
                        )),
                      ];

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String?>(
                          value: _selectedActivityType,
                          underline: const SizedBox(),
                          isDense: true,
                          hint: const Row(
                            children: [
                              Icon(Icons.category, color: AppColors.primary, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Type',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          dropdownColor: AppColors.nearBlack,
                          items: dropdownItems,
                          onChanged: (value) {
                            setState(() {
                              _selectedActivityType = value;
                            });
                          },
                          style: const TextStyle(
                            color: AppColors.lime,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
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

        FutureBuilder<List<Aerobic>>(
            future: _recordsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.lime));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading records: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red)),
                );
              }

              final allRecords = snapshot.data ?? [];

              // These are already archived records, apply all filters
              final filteredRecords = _applyAllFilters(allRecords);

              if (filteredRecords.isEmpty) {
                String emptyMessage;
                if (_selectedFilterDate != null) {
                  emptyMessage = 'No archived records found for ${_selectedFilterDate!.day}/${_selectedFilterDate!.month}/${_selectedFilterDate!.year}.';
                } else {
                  emptyMessage = 'No archived records.';
                }

                return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        emptyMessage,
                        style: const TextStyle(color: AppColors.lavender),
                        textAlign: TextAlign.center,
                      ),
                    ));
              }

              return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    return _ActivityCard(
                      record: filteredRecords[index],
                      resolveRouteImageUrl: _repository.resolveRouteImageUrl,
                      isArchived: true,
                      onDetailClose: _refreshRecords,
                    );
                  });
            })
      ],
    );
  }
}