import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repository/workout_record_repository.dart';

class SaveWorkoutPage extends StatefulWidget {
  const SaveWorkoutPage({
    super.key,
    required this.userId,
    required this.duration,
    required this.trainingVolume,
    required this.numOfSets,
    required this.savedAt,
    required this.details,
  });

  final int userId;
  final Duration duration;
  final double trainingVolume;
  final int numOfSets;
  final DateTime savedAt;
  final List<WorkoutRecordDetailInput> details;

  @override
  State<SaveWorkoutPage> createState() => _SaveWorkoutPageState();
}

class _SaveWorkoutPageState extends State<SaveWorkoutPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late final WorkoutRecordRepository _recordRepository;
  String? _imageUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _recordRepository = WorkoutRecordRepository(supabase: Supabase.instance.client);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatSavedAt(DateTime value) {
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

    final day = value.day;
    final month = months[value.month - 1];
    final year = value.year;
    final isPm = value.hour >= 12;
    final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = isPm ? 'PM' : 'AM';
    return '$day $month $year $hour12:$minute $period';
  }

  Future<void> _showImageSourcePicker() async {
    final controller = TextEditingController(text: _imageUrl ?? '');
    final imageUrl = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text('Upload Image', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Paste image URL',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted || imageUrl == null) {
      return;
    }

    setState(() {
      _imageUrl = imageUrl.isEmpty ? null : imageUrl;
    });
  }

  Future<void> _saveWorkout() async {
    if (_isSaving) {
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter workout title.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final mergedDetails = widget.details
          .map(
            (detail) => WorkoutRecordDetailInput(
              exerciseName: detail.exerciseName,
              orderIndex: detail.orderIndex,
              sets: detail.sets,
              reps: detail.reps,
              weight: detail.weight,
              notes: _descriptionController.text.trim().isEmpty
                  ? detail.notes
                  : _descriptionController.text.trim(),
            ),
          )
          .toList();

      await _recordRepository.createRecordWithDetails(
        userId: widget.userId,
        title: title,
        image: _imageUrl,
        createdAt: widget.savedAt,
        duration: widget.duration.inSeconds,
        trainingVolume: widget.trainingVolume.round(),
        numOfSets: widget.numOfSets,
        details: mergedDetails,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout saved.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save workout: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text('Delete Workout', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Delete this workout draft?',
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
        );
      },
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Save Workout'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveWorkout,
            child: Text(
              _isSaving ? 'Saving...' : 'Save',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Workout title',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF111111),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _WorkoutMetaTile(
                    label: 'Duration',
                    value: _formatDuration(widget.duration),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _WorkoutMetaTile(
                    label: 'Training Volume',
                    value: '${widget.trainingVolume.toStringAsFixed(0)} kg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _WorkoutMetaTile(
              label: 'When',
              value: _formatSavedAt(widget.savedAt),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _showImageSourcePicker,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                  image: _imageUrl == null
                      ? null
                      : DecorationImage(
                          image: NetworkImage(_imageUrl!),
                          fit: BoxFit.cover,
                        ),
                ),
                child: _imageUrl == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined, color: Colors.white70, size: 32),
                          SizedBox(height: 8),
                          Text('Image (click to upload image)', style: TextStyle(color: Colors.white70)),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF111111),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _deleteWorkout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete workout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutMetaTile extends StatelessWidget {
  const _WorkoutMetaTile({
    required this.label,
    required this.value,
  });

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

