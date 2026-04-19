import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repository/workout_record_repository.dart';
import 'workout_record_detail_page.dart';

class WorkoutRecordListPage extends StatefulWidget {
  const WorkoutRecordListPage({super.key, required this.userId});

  final int userId;

  @override
  State<WorkoutRecordListPage> createState() => _WorkoutRecordListPageState();
}

class _WorkoutRecordListPageState extends State<WorkoutRecordListPage> {
  late final WorkoutRecordRepository _repository;
  late Future<List<WorkoutRecordWithDetails>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _repository = WorkoutRecordRepository(supabase: Supabase.instance.client);
    _recordsFuture = _repository.getRecordsWithDetailsForUser(widget.userId);
  }

  void _reload() {
    setState(() {
      _recordsFuture = _repository.getRecordsWithDetailsForUser(widget.userId);
    });
  }

  String _formatCreatedAt(DateTime value) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final local = value.toLocal();
    final day = local.day;
    final month = months[local.month - 1];
    final year = local.year;
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$day $month $year $hour12:$minute $period';
  }

  String _previewExercises(List<WorkoutRecordDetailRow> details) {
    if (details.isEmpty) {
      return 'No exercises recorded';
    }

    final names = details.map((detail) => detail.exerciseName).toList();
    final preview = names.take(3).join(' • ');
    if (names.length <= 3) {
      return preview;
    }

    return '$preview • +${names.length - 3} more';
  }

  Future<void> _openRecordDetail(WorkoutRecordSummary summary) async {
    final didDelete = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WorkoutRecordDetailPage(record: summary),
      ),
    );
    if (didDelete == true && mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Workout Records',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: FutureBuilder<List<WorkoutRecordWithDetails>>(
          future: _recordsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load workout records: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final records = snapshot.data ?? const <WorkoutRecordWithDetails>[];
            if (records.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No saved workout records yet.',
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final record = records[index];
                final summary = record.summary;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _openRecordDetail(summary),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.fitness_center,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  summary.recordTitle,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _previewExercises(record.details),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatCreatedAt(summary.createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.45),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}