import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '../models/exercise.dart';
import '../repository/exercise_repository.dart';

class ExerciseDetailPage extends StatefulWidget {
  const ExerciseDetailPage({
    super.key,
    required this.exercise,
    this.isAdmin = false,
    this.repository,
  });

  final Exercise exercise;
  final bool isAdmin;
  final ExerciseRepository? repository;

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  late Exercise _exercise;
  late final ExerciseRepository _repository;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _exercise = widget.exercise;
    _repository = widget.repository ?? ExerciseRepository(supabase: Supabase.instance.client);
  }

  Future<void> _openEditDialog() async {
    final nameController = TextEditingController(text: _exercise.name);
    final primaryMuscleController = TextEditingController(text: _exercise.primaryMuscle);
    final secondaryMuscleController = TextEditingController(
      text: _exercise.secondaryMuscles.join(', '),
    );
    final equipmentController = TextEditingController(text: _exercise.equipment);
    final howToController = TextEditingController(text: _exercise.howTo);
    final imageUrlController = TextEditingController(text: _exercise.imageUrl);
    final videoUrlController = TextEditingController(text: _exercise.videoUrl ?? '');

    try {
      final didSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Exercise'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(
                    controller: primaryMuscleController,
                    decoration: const InputDecoration(labelText: 'Primary Muscle'),
                  ),
                  TextField(
                    controller: secondaryMuscleController,
                    decoration: const InputDecoration(labelText: 'Secondary Muscle(s) (comma-separated)'),
                  ),
                  TextField(
                    controller: equipmentController,
                    decoration: const InputDecoration(labelText: 'Equipment'),
                  ),
                  TextField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(labelText: 'Image URL'),
                  ),
                  TextField(
                    controller: videoUrlController,
                    decoration: const InputDecoration(labelText: 'Video URL (optional)'),
                  ),
                  TextField(
                    controller: howToController,
                    decoration: const InputDecoration(labelText: 'How To'),
                    minLines: 3,
                    maxLines: 6,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

      if (didSave != true) {
        return;
      }

      final name = nameController.text.trim();
      final primaryMuscle = primaryMuscleController.text.trim();
      final equipment = equipmentController.text.trim();
      final howTo = howToController.text.trim();
      final imageUrl = imageUrlController.text.trim();
      final secondaryMuscles = secondaryMuscleController.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();

      if (name.isEmpty ||
          primaryMuscle.isEmpty ||
          equipment.isEmpty ||
          howTo.isEmpty ||
          imageUrl.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields.')),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final updated = await _repository.updateExercise(
          exerciseId: _exercise.id,
          name: name,
          primaryMuscle: primaryMuscle,
          secondaryMuscles: secondaryMuscles,
          equipment: equipment,
          howTo: howTo,
          imageUrl: imageUrl,
          videoUrl: videoUrlController.text.trim(),
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _exercise = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise updated successfully.')),
        );
        Navigator.of(context).pop(true);
      } catch (error) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save exercise: $error')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    } finally {
      nameController.dispose();
      primaryMuscleController.dispose();
      secondaryMuscleController.dispose();
      equipmentController.dispose();
      howToController.dispose();
      imageUrlController.dispose();
      videoUrlController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
        title: const Text('Exercise Detail'),
        actions: [
          if (widget.isAdmin)
            IconButton(
              onPressed: _isSaving ? null : _openEditDialog,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.edit),
              tooltip: 'Edit Exercise',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExerciseMediaPanel(
              videoUrl: _exercise.videoUrl,
              imageUrl: _exercise.imageUrl,
            ),
            const SizedBox(height: 20),
            _DetailRow(label: 'Exercise Name', value: _exercise.name),
            _DetailRow(label: 'Primary Muscle', value: _exercise.primaryMuscle),
            _DetailRow(label: 'Secondary Muscle', value: _exercise.secondaryMuscleText),
            _DetailRow(label: 'Equipment', value: _exercise.equipment),
            _DetailRow(label: 'How To Do', value: _exercise.howTo),
          ],
        ),
      ),
    );
  }
}

class _VideoPanel extends StatefulWidget {
  const _VideoPanel({required this.videoUrl});

  final String? videoUrl;

  @override
  State<_VideoPanel> createState() => _VideoPanelState();
}

class _ExerciseMediaPanel extends StatelessWidget {
  const _ExerciseMediaPanel({
    required this.videoUrl,
    required this.imageUrl,
  });

  final String? videoUrl;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasVideo = (videoUrl ?? '').trim().isNotEmpty;
    if (hasVideo) {
      return _VideoPanel(videoUrl: videoUrl);
    }

    final trimmedImageUrl = imageUrl.trim();
    if (trimmedImageUrl.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const AspectRatio(
          aspectRatio: 16 / 9,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 64, color: Colors.white54),
              SizedBox(height: 8),
              Text('No media available', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        color: const Color(0xFF111111),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            trimmedImageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, error, stackTrace) {
              return const Center(
                child: Text(
                  'Failed to load media',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VideoPanelState extends State<_VideoPanel> {
  VideoPlayerController? _controller;
  bool _isInitializing = false;
  String? _errorMessage;
  bool _renderAsImageFallback = false;
  int _loadToken = 0;

  bool _isGifUrl(String url) {
    final uri = Uri.tryParse(url);
    final path = (uri?.path ?? url).toLowerCase();
    return path.endsWith('.gif');
  }

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant _VideoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _initController();
    }
  }

  Future<void> _initController() async {
    final url = widget.videoUrl?.trim();
    if (url == null || url.isEmpty) return;
    if (_isGifUrl(url)) {
      // GIF is rendered by Image.network in build().
      setState(() {
        _isInitializing = false;
        _errorMessage = null;
      });
      return;
    }

    final token = ++_loadToken;
    var stage = 'prepare';

    setState(() {
      _isInitializing = true;
      _errorMessage = null;
      _renderAsImageFallback = false;
    });

    VideoPlayerController? controller;
    try {
      final uri = Uri.tryParse(url);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        throw const FormatException('Invalid video URL');
      }

      stage = 'create-controller';
      controller = VideoPlayerController.networkUrl(uri);

      // Keep init timeout, but do not block UI on play() completion.
      stage = 'initialize';
      await controller
          .initialize()
          .timeout(const Duration(seconds: 15));

      if (!mounted || token != _loadToken) {
        await controller.dispose();
        return;
      }

      controller.setLooping(true);

      setState(() {
        _controller = controller;
      });

      stage = 'autoplay';
      unawaited(
        controller.play().catchError((error) {
          if (!mounted || token != _loadToken) {
            return;
          }
          setState(() {
            _errorMessage = 'Auto-play failed. Tap video to play. Error: $error';
          });
        }),
      );
    } on TimeoutException catch (error) {
      await controller?.dispose();
      if (mounted && token == _loadToken) {
        setState(() {
          _controller = null;
          _errorMessage = 'Video timeout during $stage: $error';
          _renderAsImageFallback = true;
        });
      }
    } catch (error) {
      await controller?.dispose();
      if (mounted && token == _loadToken) {
        final playerError = controller?.value.errorDescription;
        setState(() {
          _controller = null;
          _errorMessage = playerError == null
              ? 'Failed during $stage: $error'
              : 'Failed during $stage: $playerError';
          _renderAsImageFallback = true;
        });
      }
    } finally {
      if (mounted && token == _loadToken) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _disposeController() {
    _loadToken++;
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = (widget.videoUrl ?? '').trim();
    final hasUrl = url.isNotEmpty;
    final isGif = hasUrl && _isGifUrl(url);
    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized;
    final isPlaying = isReady && controller.value.isPlaying;

    if (!hasUrl) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(14),
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.videocam_off,
                size: 64,
                color: Colors.white54,
              ),
              SizedBox(height: 8),
              Text(
                'No video available',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (isGif || _renderAsImageFallback) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          color: const Color(0xFF111111),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, error, stackTrace) {
                      return const Center(
                        child: Text(
                          'Failed to load GIF',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'GIF/IMG',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final aspectRatio = isReady ? controller.value.aspectRatio : 16 / 9;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
      ),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isReady)
              GestureDetector(
                onTap: () {
                  final c = controller;
                  if (!c.value.isInitialized) return;
                  setState(() {
                    if (c.value.isPlaying) {
                      c.pause();
                    } else {
                      c.play();
                    }
                  });
                },
                child: VideoPlayer(controller),
              )
            else if (_isInitializing)
              const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
            else
              const Center(
                child: Text(
                  'No video available',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            if (isReady)
              Positioned(
                bottom: 8,
                child: Text(
                  isPlaying ? 'Playing (looping)' : 'Paused - tap to play',
                  style: TextStyle(
                    color: Colors.white70,
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ),
            if (isReady)
              Positioned(
                bottom: 40,
                right: 12,
                child: Icon(
                  Icons.loop,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

