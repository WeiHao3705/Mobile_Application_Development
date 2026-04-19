import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../repository/workout_record_repository.dart';

class WorkoutRecordDetailPage extends StatefulWidget {
  const WorkoutRecordDetailPage({super.key, required this.record});

  final WorkoutRecordSummary record;

  @override
  State<WorkoutRecordDetailPage> createState() => _WorkoutRecordDetailPageState();
}

class _WorkoutRecordDetailPageState extends State<WorkoutRecordDetailPage> {
  late final WorkoutRecordRepository _repository;
  late final Future<List<WorkoutRecordDetailRow>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _repository = WorkoutRecordRepository(supabase: Supabase.instance.client);
    _detailsFuture = _repository.getRecordDetails(widget.record.recordId);
  }

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}min ${seconds.toString().padLeft(2, '0')}s';
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

  Future<void> _deleteRecord() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Delete Record', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this workout record?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _repository.deleteRecord(widget.record.recordId);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  List<String> _buildImageCandidates(String rawUrl) {
    final value = rawUrl.trim();
    if (value.isEmpty) return const <String>[];

    final uri = Uri.tryParse(value);
    final path = uri?.path ?? '';
    final out = <String>[value];

    String? toCanonical(String prefix) {
      if (!path.contains(prefix)) return null;
      final tail = path.split(prefix).last;
      if (tail.isEmpty) return null;
      return '$supabaseUrl/storage/v1/object/public/$tail';
    }

    for (final prefix in const <String>[
      '/v1/object/public/',
      '/object/public/',
      '/storage/v1/object/public/',
    ]) {
      final candidate = toCanonical(prefix);
      if (candidate != null && !out.contains(candidate)) {
        out.add(candidate);
      }
    }

    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = widget.record;

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
          'Workout Record',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _deleteRecord,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<WorkoutRecordDetailRow>>(
          future: _detailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load workout record: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final details = snapshot.data ?? const <WorkoutRecordDetailRow>[];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  record.recordTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'When: ${_formatCreatedAt(record.createdAt)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        label: 'Duration',
                        value: _formatDuration(Duration(seconds: record.duration)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryTile(
                        label: 'Training Volume',
                        value: '${record.trainingVolume} kg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _SummaryTile(
                  label: 'Sets',
                  value: '${record.numOfSets}',
                ),
                const SizedBox(height: 16),
                if (record.recordImage != null && record.recordImage!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _RecordImage(
                      candidates: _buildImageCandidates(record.recordImage!),
                    ),
                  ),
                if (record.recordImage != null && record.recordImage!.isNotEmpty)
                  const SizedBox(height: 16),
                Text(
                  'Exercises',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (details.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Text(
                      'No exercise details were saved with this workout.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                else
                  ...details.map(
                    (detail) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DetailCard(detail: detail),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RecordImage extends StatefulWidget {
  const _RecordImage({required this.candidates});

  final List<String> candidates;

  @override
  State<_RecordImage> createState() => _RecordImageState();
}

class _RecordImageState extends State<_RecordImage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.candidates.isEmpty || _index >= widget.candidates.length) {
      return Container(
        height: 190,
        width: double.infinity,
        color: const Color(0xFF111111),
        alignment: Alignment.center,
        child: const Text('Unable to load image', style: TextStyle(color: Colors.white70)),
      );
    }

    final url = widget.candidates[_index];
    return Image.network(
      url,
      key: ValueKey<String>(url),
      height: 190,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        if (_index < widget.candidates.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _index += 1);
          });
          return Container(
            height: 190,
            width: double.infinity,
            color: const Color(0xFF111111),
          );
        }

        return Container(
          height: 190,
          width: double.infinity,
          color: const Color(0xFF111111),
          alignment: Alignment.center,
          child: const Text('Unable to load image', style: TextStyle(color: Colors.white70)),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.detail});

  final WorkoutRecordDetailRow detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.fitness_center, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                detail.exerciseName,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            _ColumnHeader(label: 'Set'),
            SizedBox(width: 24),
            _ColumnHeader(label: 'KG'),
            SizedBox(width: 24),
            _ColumnHeader(label: 'Reps'),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  '${detail.sets}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 64,
                child: Text(
                  '${detail.weight}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Text(
                detail.reps.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (detail.notes.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Notes',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail.notes,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ],
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 16,
        ),
      ),
    );
  }
}