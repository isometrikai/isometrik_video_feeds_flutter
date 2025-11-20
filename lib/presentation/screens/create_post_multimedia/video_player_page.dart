import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/model/media_edit_models.dart';
import 'package:video_player/video_player.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VideoPlayerPage extends StatefulWidget {
  final MediaEditItem mediaItem;
  final String title;
  final bool allowEditing;
  final Function(MediaEditItem)? onComplete;
  final Function()? onCancel;

  const VideoPlayerPage({
    super.key,
    required this.mediaItem,
    this.title = 'Video Player',
    this.allowEditing = true,
    this.onComplete,
    this.onCancel,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Timer? _hideControlsTimer;
  bool _showControls = true;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      final videoPath =
          widget.mediaItem.editedPath ?? widget.mediaItem.originalPath;

      if (videoPath.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video path is empty';
          _isLoading = false;
        });
        return;
      }

      _controller = VideoPlayerController.file(
        File(videoPath),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
        ),
      );

      await _controller!.initialize();

      _controller!.addListener(_videoListener);

      setState(() {
        _isInitialized = true;
        _isLoading = false;
        _totalDuration = _controller!.value.duration;
        _currentPosition = _controller!.value.position;
      });

      // Auto-play the video
      _play();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize video: $e';
        _isLoading = false;
      });
    }
  }

  void _videoListener() {
    if (_controller != null && mounted) {
      setState(() {
        _isPlaying = _controller!.value.isPlaying;
        _currentPosition = _controller!.value.position;
        _totalDuration = _controller!.value.duration;
      });
    }
  }

  void _play() {
    _controller?.play();
    setState(() {
      _isPlaying = true;
    });
    _hideControlsAfterDelay();
  }

  void _pause() {
    _controller?.pause();
    setState(() {
      _isPlaying = false;
    });
    _hideControlsAfterDelay();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _seekTo(Duration position) {
    _controller?.seekTo(position);
    _hideControlsAfterDelay();
  }

  void _seekRelative(Duration duration) {
    final newPosition = _currentPosition + duration;
    final clampedPosition = Duration(
      milliseconds:
          newPosition.inMilliseconds.clamp(0, _totalDuration.inMilliseconds),
    );
    _seekTo(clampedPosition);
  }

  void _hideControlsAfterDelay() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _hideControlsAfterDelay();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _onComplete() {
    if (widget.onComplete != null) {
      widget.onComplete!(widget.mediaItem);
    } else {
      Navigator.of(context).pop(widget.mediaItem);
    }
  }

  void _onEdit() {
    // Navigate to media edit view
    Navigator.of(context).pop(widget.mediaItem);
  }

  void _onCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: IsrStyles.primaryText16.copyWith(color: Colors.white),
        ),
        actions: [
          if (widget.allowEditing)
            TextButton(
              onPressed: _onEdit,
              child: Text(
                'Edit',
                style: IsrStyles.primaryText14.copyWith(color: Colors.white),
              ),
            ),
          TextButton(
            onPressed: _onCancel,
            child: Text(
              'Cancel',
              style: IsrStyles.primaryText14.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading video',
              style: IsrStyles.primaryText16.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: IsrStyles.primaryText14.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                  _errorMessage = null;
                });
                _initializePlayer();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GestureDetector(
      onTap: _showControlsTemporarily,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),

          // Controls overlay
          if (_showControls) _buildControlsOverlay(),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          // Top controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: _onCancel,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                const Spacer(),
                if (widget.allowEditing)
                  IconButton(
                    onPressed: _onEdit,
                    icon: const Icon(Icons.edit, color: Colors.white),
                  ),
              ],
            ),
          ),

          const Spacer(),

          // Bottom controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Progress bar
                _buildProgressBar(),
                const SizedBox(height: 16),

                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Rewind 10 seconds
                    IconButton(
                      onPressed: () =>
                          _seekRelative(const Duration(seconds: -10)),
                      icon: const Icon(Icons.replay_10,
                          color: Colors.white, size: 32),
                    ),

                    // Play/Pause
                    IconButton(
                      onPressed: _togglePlayPause,
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),

                    // Forward 10 seconds
                    IconButton(
                      onPressed: () =>
                          _seekRelative(const Duration(seconds: 10)),
                      icon: const Icon(Icons.forward_10,
                          color: Colors.white, size: 32),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Duration info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style:
                          IsrStyles.primaryText14.copyWith(color: Colors.white),
                    ),
                    Text(
                      _formatDuration(_totalDuration),
                      style:
                          IsrStyles.primaryText14.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white.withOpacity(0.3),
        thumbColor: Colors.white,
        overlayColor: Colors.white.withOpacity(0.2),
        trackHeight: 4.0,
      ),
      child: Slider(
        value: _totalDuration.inMilliseconds > 0
            ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
            : 0.0,
        onChanged: (value) {
          final position = Duration(
            milliseconds: (value * _totalDuration.inMilliseconds).round(),
          );
          _seekTo(position);
        },
      ),
    );
  }
}
