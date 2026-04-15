import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../repository/exercise_repository.dart';
import '../theme/app_colors.dart';

const equipmentOptions = [
  'Bodyweight',
  'Barbell',
  'Weight plates',
  'Kettlebell',
  'Equipment',
  'Dumbbells',
  'Resistance bands',
];

const muscleOptions = [
  'Latissimus dorsi',
  'Biceps',
  'Abs',
  'Quadriceps',
  'Hamstrings',
  'Shoulders',
  'Neck',
  'Forearms',
  'Full body',
  'Triceps',
  'Upper back',
  'Glutes',
  'Lower back',
  'Calves',
  'Trapezius',
  'Chest',
];

class _StorageHttpException implements Exception {
  const _StorageHttpException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'Storage HTTP $statusCode: $body';
}

class AddExercisePage extends StatefulWidget {
  const AddExercisePage({super.key, required this.repository});

  final ExerciseRepository repository;

  @override
  State<AddExercisePage> createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _howToController = TextEditingController();

  String? _selectedEquipment;
  String? _selectedPrimaryMuscle;
  final Set<String> _selectedSecondaryMuscles = {};

  bool _isSaving = false;
  String? _imageUrl;
  String? _videoUrl;
  File? _imageFile;
  File? _videoFile;

  static const String _imageStorageBucket = 'Exercise_Image';
  static const String _videoStorageBucket = 'Exercise_Video';
  static const int _maxUploadAttempts = 3;

  bool _isGifPath(String path) {
    return path.toLowerCase().endsWith('.gif');
  }

  bool _isVideoFilePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.3gp') ||
        lower.endsWith('.m4v');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _howToController.dispose();
    super.dispose();
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
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.avi')) return 'video/x-msvideo';
    if (lower.endsWith('.mkv')) return 'video/x-matroska';
    return 'application/octet-stream';
  }

  String _buildObjectPath(File file, String prefix) {
    final rawName = file.path.split(Platform.pathSeparator).last;
    final sanitizedName = rawName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return '$prefix/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
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

  Future<String> _uploadFileAndGetUrl({
    required File file,
    required String bucketId,
    required String prefix,
  }) async {
    final storage = Supabase.instance.client.storage;
    final objectPath = _buildObjectPath(file, prefix);
    final contentType = _detectContentType(file.path);

    _StorageHttpException? lastNotFound;
    Object? lastTransientError;

    for (var attempt = 1; attempt <= _maxUploadAttempts; attempt++) {
      try {
        await _uploadViaRest(
          bucketId: bucketId,
          objectPath: objectPath,
          file: file,
          contentType: contentType,
        );
        return storage.from(bucketId).getPublicUrl(objectPath);
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
      'Bucket not found (404): $bucketId. '
      'Check Storage INSERT policy for anon/public. Last: ${lastNotFound?.body ?? 'unknown'}',
    );
  }

  String _mapUploadError(Object error) {
    if (error is _StorageHttpException) {
      final code = error.statusCode.toString();
      if (code == '404') {
        return 'Bucket not found (404). Last: ${error.body}';
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

  Future<bool?> _showUploadRecoveryDialog(String message, String fileType) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: Text('$fileType upload failed', style: const TextStyle(color: Colors.white)),
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
              child: Text('Save without $fileType'),
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
      if (source == ImageSource.camera) {
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
        return;
      }

      // pickMedia keeps GIF animation from gallery selections.
      final pickedMedia = await imagePicker.pickMedia();
      if (pickedMedia == null) {
        return;
      }

      if (_isVideoFilePath(pickedMedia.path)) {
        setState(() {
          _videoFile = File(pickedMedia.path);
          _videoUrl = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video selected and attached as exercise video.')),
          );
        }
        return;
      }

      setState(() {
        _imageFile = File(pickedMedia.path);
        _imageUrl = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image or GIF: $e')),
        );
      }
    }
  }

  Future<void> _showVideoSourcePicker() async {
    final videoPicker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.white),
              title: const Text('Record Video', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.library_add, color: Colors.white),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      XFile? pickedFile;
      if (source == ImageSource.gallery) {
        // Allow GIF selection from gallery for exercise media.
        pickedFile = await videoPicker.pickMedia();
      } else {
        pickedFile = await videoPicker.pickVideo(
          source: source,
        );
      }

      if (pickedFile != null) {
        final pickedPath = pickedFile.path;
        setState(() {
          _videoFile = File(pickedPath);
          _videoUrl = null;
        });

        if (_isGifPath(pickedPath) && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GIF selected for exercise media.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick video/GIF: $e')),
        );
      }
    }
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select equipment')),
      );
      return;
    }

    if (_selectedPrimaryMuscle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select primary muscle')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? finalImageUrl = _imageUrl;
      String? finalVideoUrl = _videoUrl;

      // Upload image if a new file is selected
      if (_imageFile != null) {
        var uploadResolved = false;
        while (!uploadResolved) {
          try {
            finalImageUrl = await _uploadFileAndGetUrl(
              file: _imageFile!,
              bucketId: _imageStorageBucket,
              prefix: 'exercise_images',
            );
            uploadResolved = true;
          } catch (error) {
            if (!mounted) {
              return;
            }

            final action = await _showUploadRecoveryDialog(
              _mapUploadError(error),
              'Image',
            );
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

      // Upload video if a new file is selected
      if (_videoFile != null) {
        var uploadResolved = false;
        while (!uploadResolved) {
          try {
            finalVideoUrl = await _uploadFileAndGetUrl(
              file: _videoFile!,
              bucketId: _videoStorageBucket,
              prefix: 'exercise_videos',
            );
            uploadResolved = true;
          } catch (error) {
            if (!mounted) {
              return;
            }

            final action = await _showUploadRecoveryDialog(
              _mapUploadError(error),
              'Video',
            );
            if (action == null) {
              return;
            }
            if (action == true) {
              finalVideoUrl = null;
              uploadResolved = true;
            }
          }
        }
      }

      await widget.repository.createExercise(
        name: _nameController.text.trim(),
        primaryMuscle: _selectedPrimaryMuscle!,
        secondaryMuscles: _selectedSecondaryMuscles.toList(),
        equipment: _selectedEquipment!,
        instruction: _howToController.text.trim(),
        imageUrl: finalImageUrl,
        videoUrl: finalVideoUrl,
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add exercise: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _discardExercise() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text('Discard Exercise', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Discard this exercise?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildEquipmentSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        isExpanded: true,
        value: _selectedEquipment,
        hint: const Text(
          'Select Equipment',
          style: TextStyle(color: AppColors.lavender),
        ),
        dropdownColor: AppColors.cardBg,
        underline: const SizedBox.shrink(),
        menuMaxHeight: 200,
        items: equipmentOptions.map((equipment) {
          return DropdownMenuItem<String>(
            value: equipment,
            child: Text(
              equipment,
              style: const TextStyle(color: AppColors.white),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedEquipment = value;
          });
        },
      ),
    );
  }

  Widget _buildPrimaryMuscleSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        isExpanded: true,
        value: _selectedPrimaryMuscle,
        hint: const Text(
          'Select Primary Muscle',
          style: TextStyle(color: AppColors.lavender),
        ),
        dropdownColor: AppColors.cardBg,
        underline: const SizedBox.shrink(),
        menuMaxHeight: 200,
        items: muscleOptions.map((muscle) {
          return DropdownMenuItem<String>(
            value: muscle,
            child: Text(
              muscle,
              style: const TextStyle(color: AppColors.white),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedPrimaryMuscle = value;
            _selectedSecondaryMuscles.remove(value);
          });
        },
      ),
    );
  }

  Widget _buildSecondaryMuscleSelector() {
    final availableMuscles =
        muscleOptions.where((m) => m != _selectedPrimaryMuscle).toList();

    return GestureDetector(
      onTap: () => _showSecondaryMusclePicker(availableMuscles),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedSecondaryMuscles.isEmpty
                  ? 'Select Secondary Muscles'
                  : '${_selectedSecondaryMuscles.length} selected',
              style: TextStyle(
                color: _selectedSecondaryMuscles.isEmpty
                    ? AppColors.lavender
                    : AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.lavender),
          ],
        ),
      ),
    );
  }

  void _showSecondaryMusclePicker(List<String> availableMuscles) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBg,
              title: const Text(
                'Select Secondary Muscles',
                style: TextStyle(color: AppColors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: availableMuscles.map((muscle) {
                    return CheckboxListTile(
                      value: _selectedSecondaryMuscles.contains(muscle),
                      title: Text(
                        muscle,
                        style: const TextStyle(color: AppColors.white),
                      ),
                      activeColor: AppColors.purple,
                      checkColor: AppColors.white,
                      side: BorderSide(
                        color: AppColors.purple.withValues(alpha: 0.5),
                      ),
                      onChanged: (checked) {
                        setDialogState(() {
                          if (checked == true) {
                            _selectedSecondaryMuscles.add(muscle);
                          } else {
                            _selectedSecondaryMuscles.remove(muscle);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done', style: TextStyle(color: AppColors.lavender)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInstructionField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.lavender),
        filled: true,
        fillColor: AppColors.inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.purple.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.purple.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lavender),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.white),
      validator: (value) {
        if ((value ?? '').trim().isEmpty) {
          return 'Required';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.lavender),
        filled: true,
        fillColor: AppColors.inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.purple.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.purple.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lavender),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.white,
        title: const Text('Add Exercise'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveExercise,
            child: Text(
              _isSaving ? 'Saving...' : 'Save',
              style: TextStyle(
                color: _isSaving ? AppColors.lavender.withValues(alpha: 0.5) : AppColors.lavender,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildField(_nameController, 'Exercise Name'),
              const SizedBox(height: 14),
              const Text(
                'Equipment',
                style: TextStyle(
                  color: AppColors.lavender,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildEquipmentSelector(),
              const SizedBox(height: 14),
              const Text(
                'Primary Muscle',
                style: TextStyle(
                  color: AppColors.lavender,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildPrimaryMuscleSelector(),
              const SizedBox(height: 14),
              const Text(
                'Secondary Muscles',
                style: TextStyle(
                  color: AppColors.lavender,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildSecondaryMuscleSelector(),
              const SizedBox(height: 14),
              const Text(
                'Instruction (Optional)',
                style: TextStyle(
                  color: AppColors.lavender,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildInstructionField(_howToController, 'Instruction', maxLines: 4),
              const SizedBox(height: 16),
              const Text(
                'Exercise Image / GIF',
                style: TextStyle(
                  color: AppColors.lavender,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showImageSourcePicker,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.4),
                    ),
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
                            Text('Tap to upload image or GIF', style: TextStyle(color: Colors.white70)),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Exercise Video / GIF',
                style: TextStyle(
                  color: AppColors.lavender,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showVideoSourcePicker,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.4),
                    ),
                  ),
                  child: _videoFile != null || _videoUrl != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              _videoFile != null
                                  ? 'Video selected'
                                  : 'Video uploaded',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam, color: Colors.white70, size: 32),
                            SizedBox(height: 8),
                            Text('Tap to upload video or GIF', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _discardExercise,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    disabledForegroundColor: Colors.redAccent.withValues(alpha: 0.5),
                    side: BorderSide(
                      color: _isSaving ? Colors.redAccent.withValues(alpha: 0.5) : Colors.redAccent,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Discard'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}




















