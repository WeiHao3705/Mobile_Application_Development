import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/exercise.dart';

class ExerciseDetailPage extends StatelessWidget {
  const ExerciseDetailPage({
    super.key,
    required this.exercise,
  });

  final Exercise exercise;

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VideoPanel(videoUrl: exercise.videoUrl),
            const SizedBox(height: 20),
            _DetailRow(label: 'Exercise Name', value: exercise.name),
            _DetailRow(label: 'Primary Muscle', value: exercise.primaryMuscle),
            _DetailRow(label: 'Secondary Muscle', value: exercise.secondaryMuscle),
            _DetailRow(label: 'How To Do', value: exercise.howTo),
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

class _VideoPanelState extends State<_VideoPanel> {
  VideoPlayerController? _controller;
  bool _isInitializing = false;
  String? _errorMessage;
  int _loadToken = 0;

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

    final token = ++_loadToken;
    var stage = 'prepare';

    setState(() {
      _isInitializing = true;
      _errorMessage = null;
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
    final hasUrl = (widget.videoUrl ?? '').trim().isNotEmpty;
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

