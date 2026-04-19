import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
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

class _StorageHttpException implements Exception {
  const _StorageHttpException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'Storage HTTP $statusCode: $body';
}

class _SaveWorkoutPageState extends State<SaveWorkoutPage> {
  static const String _imageBucketId = 'exercise_record_image';

  static const int _maxUploadAttempts = 3;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late final WorkoutRecordRepository _recordRepository;
  String? _imageUrl;
  File? _imageFile;
  bool _isSaving = false;
  late Duration _editableDuration;

  @override
  void initState() {
    super.initState();
    _editableDuration = widget.duration;
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

  String _buildObjectPath(File file) {
    final rawName = file.path.split(Platform.pathSeparator).last;
    final sanitizedName = rawName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return 'workout_images/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
  }

  bool _isClientConnectionError(Object error) {
    final text = error.toString();
    return text.contains('ClientException') && text.contains('Connection');
  }

  String _detectContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'application/octet-stream';
  }

  Future<void> _uploadViaRest({
    required String bucketId,
    required String objectPath,
    required File file,
    required String contentType,
  }) async {
    final encodedPath = objectPath
        .split('/')
        .map(Uri.encodeComponent)
        .join('/');
    final uri = Uri.parse('$supabaseUrl/storage/v1/object/$bucketId/$encodedPath');
    final client = HttpClient();

    try {
      final request = await client.postUrl(uri);
      request.headers.set('apikey', supabaseAnonKey);
      request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
      request.headers.set('x-upsert', 'true');
      request.headers.set(HttpHeaders.contentTypeHeader, contentType);
      final bytes = await file.readAsBytes();
      request.add(bytes);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _StorageHttpException(response.statusCode, responseBody);
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _uploadImageAndGetUrl(File file) async {
    final storage = Supabase.instance.client.storage;
    final objectPath = _buildObjectPath(file);
    final contentType = _detectContentType(file.path);

    _StorageHttpException? lastNotFound;
    Object? lastTransientError;

    for (var attempt = 1; attempt <= _maxUploadAttempts; attempt++) {
      try {
        await _uploadViaRest(
          bucketId: _imageBucketId,
          objectPath: objectPath,
          file: file,
          contentType: contentType,
        );
        return storage.from(_imageBucketId).getPublicUrl(objectPath);
      } on _StorageHttpException catch (error) {
        final code = error.statusCode.toString();
        if (code == '404') {
          lastNotFound = error;
          break;
        }
        rethrow;
      } on SocketException catch (error) {
        lastTransientError = error;
      } on TimeoutException catch (error) {
        lastTransientError = error;
      } catch (error) {
        if (_isClientConnectionError(error)) {
          lastTransientError = error;
        } else {
          rethrow;
        }
      }

      if (attempt < _maxUploadAttempts) {
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }

    if (lastTransientError != null) {
      throw lastTransientError;
    }

    throw Exception(
      'Bucket not found (404): $_imageBucketId. '
      'Check Storage INSERT policy for anon/public. Last: ${lastNotFound?.body ?? 'unknown'}',
    );
  }

  String _mapUploadError(Object error) {
    if (error is _StorageHttpException) {
      final code = error.statusCode.toString();
      if (code == '404') {
        return 'Bucket not found (404): $_imageBucketId. Last: ${error.body}';
      }
      if (code == '401' || code == '403') {
        return 'No permission to upload. Allow INSERT for anon/authenticated in Storage policies.';
      }
      return 'Storage error (HTTP $code): ${error.body}';
    }

    if (error is SocketException) {
      return 'Network error: check internet connection and try again.';
    }

    if (error is TimeoutException) {
      return 'Upload timed out. Please retry on a stable network.';
    }

    if (_isClientConnectionError(error)) {
      return 'Upload connection failed before response. Check internet access and Android INTERNET permission.';
    }

    return 'Upload failed: $error';
  }

  Future<void> _pickDuration() async {
    final picked = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      builder: (context) {
        var currentDuration = _editableDuration;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const Text(
                        'Select Duration',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(currentDuration),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 220,
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hms,
                    initialTimerDuration: currentDuration,
                    backgroundColor: const Color(0xFF111111),
                    onTimerDurationChanged: (duration) {
                      currentDuration = duration;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _editableDuration = picked;
    });
  }

  Future<bool?> _showUploadRecoveryDialog(String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text('Image upload failed', style: TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save without image'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImageSourcePicker() async {
    final imagePicker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
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
      String? finalImageUrl = _imageUrl;

      if (_imageFile != null) {
        var uploadResolved = false;
        while (!uploadResolved) {
          try {
            finalImageUrl = await _uploadImageAndGetUrl(_imageFile!);
            uploadResolved = true;
          } catch (error) {
            if (!mounted) {
              return;
            }

            final action = await _showUploadRecoveryDialog(_mapUploadError(error));
            if (action == null) {
              return;
            }
            if (action == true) {
              finalImageUrl = null;
              uploadResolved = true;
            }
          }
        }
      }

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
        image: finalImageUrl,
        createdAt: widget.savedAt,
        duration: _editableDuration.inSeconds,
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
          'Save Workout',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveWorkout,
            child: Text(
              _isSaving ? 'Saving...' : 'Save',
              style: TextStyle(
                color: _isSaving ? theme.colorScheme.primary.withValues(alpha: 0.5) : theme.colorScheme.primary,
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
                  child: GestureDetector(
                    onTap: _pickDuration,
                    child: _WorkoutMetaTile(
                      label: 'Duration',
                      value: _formatDuration(_editableDuration),
                    ),
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
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : _imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                ),
                child: _imageFile == null && _imageUrl == null
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
