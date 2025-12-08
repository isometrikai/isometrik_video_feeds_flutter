import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/media_edit.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoPreviewWidget extends StatefulWidget {
  const VideoPreviewWidget({
    super.key,
    required this.mediaEditItem,
    required this.onRemoveMedia,
    required this.mediaEditConfig,
  });

  final MediaEditItem mediaEditItem;
  final VoidCallback onRemoveMedia;
  final MediaEditConfig mediaEditConfig;

  @override
  State<VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  VideoPlayerController? _videoController;
  bool _showPauseIcon = false;
  Timer? _pauseIconTimer;
  bool _isVideoVisible = true;
  bool _wasPlayingBeforeVisibilityChange = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(VideoPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if media item changed (after editing)
    if (oldWidget.mediaEditItem != widget.mediaEditItem) {
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoErrorListener);
    _videoController?.dispose();
    _pauseIconTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    await _disposeVideoController();
    await _createVideoController(widget.mediaEditItem);
  }

  Future<void> _disposeVideoController() async {
    if (_videoController != null) {
      _videoController!.removeListener(_videoErrorListener);
      await _videoController!.dispose();
      _videoController = null;
    }
  }

  Future<void> _createVideoController(MediaEditItem mediaItem) async {
    try {
      final videoPath = mediaItem.editedPath ?? mediaItem.originalPath;
      if (videoPath.isNotEmpty && File(videoPath).existsSync()) {
        debugPrint('Initializing video: $videoPath');

        // Check if file exists
        final file = File(videoPath);
        if (!await file.exists()) {
          debugPrint('Video file does not exist: $videoPath');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video file not found'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Dispose existing controller
        await _videoController?.dispose();

        // Create new controller
        _videoController = VideoPlayerController.file(file);

        // Add error listener
        _videoController!.addListener(_videoErrorListener);

        // Add timeout for initialization
        await _videoController!.initialize().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            debugPrint('Video initialization timeout');
            throw Exception(
                'Video initialization timeout - file may be corrupted or too large');
          },
        );

        debugPrint(
            'Video controller initialized: ${_videoController!.value.isInitialized}');

        if (_videoController!.value.isInitialized) {
          await _videoController!.setLooping(true);

          if (mounted) {
            setState(() {});
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to initialize video player'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error initializing video controller: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error loading video: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePlayPause() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _hidePauseIcon();
      } else {
        _videoController!.play();
        _showPauseIconTemporarily();
      }
      setState(() {});
    }
  }

  void _showPauseIconTemporarily() {
    setState(() {
      _showPauseIcon = true;
    });

    _pauseIconTimer?.cancel();
    _pauseIconTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showPauseIcon = false;
        });
      }
    });
  }

  void _hidePauseIcon() {
    _pauseIconTimer?.cancel();
    setState(() {
      _showPauseIcon = false;
    });
  }

  void _videoErrorListener() {
    if (_videoController != null && _videoController!.value.hasError) {
      debugPrint(
          'Video player error: ${_videoController!.value.errorDescription}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_videoController!.value.errorDescription ??
                'Unknown video error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onVisibilityChanged(VisibilityInfo visibilityInfo) {
    final isVisible = visibilityInfo.visibleFraction >= 1.0; // Fully visible

    if (_isVideoVisible != isVisible) {
      _isVideoVisible = isVisible;

      if (_videoController != null && _videoController!.value.isInitialized) {
        if (!isVisible && _videoController!.value.isPlaying) {
          // Video is not fully visible and is playing - pause it
          _wasPlayingBeforeVisibilityChange = true;
          _videoController!.pause();
          _hidePauseIcon();
        } else if (isVisible && _wasPlayingBeforeVisibilityChange) {
          // Video is fully visible again and was playing before - resume it
          _wasPlayingBeforeVisibilityChange = false;
          _videoController!.play();
          _showPauseIconTemporarily();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => VisibilityDetector(
        key: Key('video_preview_${widget.mediaEditItem.originalPath}'),
        onVisibilityChanged: _onVisibilityChanged,
        child: GestureDetector(
          onTap: _handlePlayPause,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: _videoController != null &&
                    _videoController!.value.isInitialized
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      // Video player with center crop
                      Center(
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                      // Play/Pause Icon Overlay
                      AnimatedOpacity(
                        opacity: _videoController!.value.isPlaying
                            ? (_showPauseIcon ? 1.0 : 0.0)
                            : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    color: widget.mediaEditConfig.backgroundColor,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                              color: widget.mediaEditConfig.primaryColor),
                          const SizedBox(height: 16),
                          Text(
                            'Loading video...',
                            style: TextStyle(
                                color: widget.mediaEditConfig.primaryTextColor),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      );
}
