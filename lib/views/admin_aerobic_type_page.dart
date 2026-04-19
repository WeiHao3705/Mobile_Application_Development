import 'package:flutter/material.dart';
import 'package:mobile_application_development/theme/app_colors.dart';
import '../repository/aerobic_activity_repository.dart';

class AdminAerobicTypePage extends StatefulWidget {
  const AdminAerobicTypePage({super.key});

  @override
  State<AdminAerobicTypePage> createState() => _AdminAerobicTypePageState();
}

class _AdminAerobicTypePageState extends State<AdminAerobicTypePage> {
  final AerobicRepository _repository = AerobicRepository();
  late Future<List<Map<String, dynamic>>> _activityTypesFuture;

  @override
  void initState() {
    super.initState();
    _refreshActivityTypes();
  }

  void _refreshActivityTypes() {
    setState(() {
      _activityTypesFuture = _repository.fetchAerobicActivity();
    });
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text(
          'Create New Aerobic Type',
          style: TextStyle(color: AppColors.lavender),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                labelText: 'Activity Name',
                labelStyle: const TextStyle(color: AppColors.lavender),
                hintText: 'e.g., Running, Swimming',
                hintStyle: const TextStyle(color: AppColors.lavender, fontSize: 12),
                filled: true,
                fillColor: AppColors.nearBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: caloriesController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                labelText: 'Calories Per KM',
                labelStyle: const TextStyle(color: AppColors.lavender),
                hintText: 'e.g., 100',
                hintStyle: const TextStyle(color: AppColors.lavender, fontSize: 12),
                filled: true,
                fillColor: AppColors.nearBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lavender)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.nearBlack,
            ),
            onPressed: () async {
              if (nameController.text.isEmpty || caloriesController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await _repository.createAerobicActivity(
                  nameController.text.trim(),
                  int.parse(caloriesController.text.trim()),
                );
                if (mounted) {
                  Navigator.pop(context);
                  _refreshActivityTypes();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Activity type created successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> activityType) {
    final nameController = TextEditingController(text: activityType['aerobic_name']);
    final caloriesController = TextEditingController(
      text: activityType['caloriesPerKM'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text(
          'Edit Aerobic Type',
          style: TextStyle(color: AppColors.lavender),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                labelText: 'Activity Name',
                labelStyle: const TextStyle(color: AppColors.lavender),
                filled: true,
                fillColor: AppColors.nearBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: caloriesController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                labelText: 'Calories Per KM',
                labelStyle: const TextStyle(color: AppColors.lavender),
                filled: true,
                fillColor: AppColors.nearBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lavender)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.nearBlack,
            ),
            onPressed: () async {
              if (nameController.text.isEmpty || caloriesController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await _repository.updateAerobicActivity(
                  activityType['aerobic_name'],
                  nameController.text.trim(),
                  int.parse(caloriesController.text.trim()),
                );
                if (mounted) {
                  Navigator.pop(context);
                  _refreshActivityTypes();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Activity type updated successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(Map<String, dynamic> activityType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text(
          'Delete Activity Type?',
          style: TextStyle(color: AppColors.lavender),
        ),
        content: Text(
          'Are you sure you want to delete "${activityType['aerobic_name']}"? This action cannot be undone.',
          style: const TextStyle(color: AppColors.lavender),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lavender)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: AppColors.white,
            ),
            onPressed: () async {
              try {
                await _repository.deleteAerobicActivity(activityType['aerobic_name']);
                if (mounted) {
                  Navigator.pop(context);
                  _refreshActivityTypes();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Activity type deleted successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

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
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.lavender.withValues(alpha: 0.55),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.chevron_left,
                        color: AppColors.lime,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      'Manage Aerobic Types',
                      style: TextStyle(
                        color: AppColors.lavender,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // Add and Refresh buttons side by side
              Row(
                children: [
                  // Add button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showCreateDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('ADD NEW'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.nearBlack,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Refresh button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _refreshActivityTypes,
                      icon: const Icon(Icons.refresh),
                      label: const Text('REFRESH'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lime,
                        foregroundColor: AppColors.nearBlack,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: const Text(
                  'Aerobic Types',
                  style: TextStyle(
                    color: AppColors.lime,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Activity types list
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _activityTypesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.lime),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading activity types: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final activityTypes = snapshot.data ?? [];

                  activityTypes.sort((a, b) =>
                    (a['aerobic_name'] as String).compareTo(b['aerobic_name'] as String)
                  );

                  for (int i = 0; i < activityTypes.length; i++) {
                    final activity = activityTypes[i];
                  }

                  if (activityTypes.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No aerobic types found.',
                              style: TextStyle(color: AppColors.lavender),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activityTypes.length,
                    itemBuilder: (context, index) {
                      final activity = activityTypes[index];
                      return _AerobicTypeCard(
                        activityType: activity,
                        onEdit: () => _showEditDialog(activity),
                        onDelete: () => _showDeleteConfirmDialog(activity),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AerobicTypeCard extends StatelessWidget {
  final Map<String, dynamic> activityType;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AerobicTypeCard({
    required this.activityType,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activityType['aerobic_name'].toString().toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.lime,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Calories per KM: ${activityType['caloriesPerKM']}',
                    style: const TextStyle(
                      color: AppColors.lavender,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit button
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Delete button
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

