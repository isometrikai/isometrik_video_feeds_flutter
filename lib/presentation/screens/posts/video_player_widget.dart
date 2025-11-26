import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Separate widget for video player with visibility detection and pooling
class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({
    super.key,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.videoCacheManager,
    required this.isMuted,
    required this.onVisibilityChanged,
    this.aspectRatio,
    this.onVideoCompleted,
    this.postHelperCallBacks,
  });

  final String mediaUrl;
  final String thumbnailUrl;
  final VideoCacheManager videoCacheManager;
  final bool isMuted;
  final Function(bool isVisible) onVisibilityChanged;
  final double? aspectRatio;
  final VoidCallback? onVideoCompleted;
  final PostHelperCallBacks? postHelperCallBacks;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();

  // Static method to access state from GlobalKey
  static _VideoPlayerWidgetState? of(GlobalKey key) => key.currentState as _VideoPlayerWidgetState?;
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  IVideoPlayerController? _videoPlayerController;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isVisible = false;
  bool _isDisposed = false;
  bool _hasCompleted = false; // Track if video has already completed
  bool _isManuallyPaused = false; // Track if video was manually paused (e.g., long press)
  bool _hasLoggedWatchEvent = false; // Track if watch event has been logged
  Duration _maxWatchPosition = Duration.zero; // Track maximum watch position

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    if (_isInitializing || _isDisposed || widget.mediaUrl.isEmpty) return;

    _isInitializing = true;

    try {
      // Get cached controller or create new one
      _videoPlayerController =
          widget.videoCacheManager.getCachedMedia(widget.mediaUrl) as IVideoPlayerController?;

      if (_videoPlayerController == null) {
        // Trigger precaching which will create a new controller
        await MediaCacheFactory.precacheMedia([widget.mediaUrl], highPriority: true);
        _videoPlayerController =
            widget.videoCacheManager.getCachedMedia(widget.mediaUrl) as IVideoPlayerController?;
      }

      if (_videoPlayerController != null && !_videoPlayerController!.isInitialized) {
        await _videoPlayerController!.initialize();
      }

      if (_videoPlayerController != null && _videoPlayerController!.isInitialized) {
        await _setupVideoController();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          // Check if we should start playing immediately
          _checkInitialVisibility();
        }
      }
    } catch (e) {
      debugPrint('❌ VideoPlayerWidget: Error initializing video: $e');
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _setupVideoController() async {
    if (_videoPlayerController == null || !_videoPlayerController!.isInitialized) return;

    try {
      // Set looping to false so video can complete
      await _videoPlayerController!.setLooping(false);
      await _videoPlayerController!.setVolume(widget.isMuted ? 0.0 : 1.0);
      await _videoPlayerController!.seekTo(Duration.zero);

      // Reset completion flag, manual pause state, and analytics tracking
      _hasCompleted = false;
      _isManuallyPaused = false;
      _hasLoggedWatchEvent = false;
      _maxWatchPosition = Duration.zero;

      // Add listener for video completion
      _videoPlayerController!.addListener(_handlePlaybackProgress);

      // If widget is visible when initialized, start playing immediately
      if (_isVisible) {
        await _videoPlayerController!.play();
        widget.videoCacheManager.markAsVisible(widget.mediaUrl);
      }
    } catch (e) {
      debugPrint('❌ VideoPlayerWidget: Error setting up controller: $e');
    }
  }

  void _handlePlaybackProgress() {
    if (_isDisposed || _videoPlayerController == null || !_videoPlayerController!.isInitialized) {
      return;
    }

    final position = _videoPlayerController!.position;
    final duration = _videoPlayerController!.duration;

    // Track maximum watch position for analytics
    if (position.inMilliseconds > _maxWatchPosition.inMilliseconds) {
      _maxWatchPosition = position;
    }

    // Check if video has completed (with small threshold to account for timing)
    if (duration.inMilliseconds > 0 &&
        position.inMilliseconds >= duration.inMilliseconds - 100 &&
        !_hasCompleted) {
      _hasCompleted = true;
      // Video completed - notify callback
      widget.onVideoCompleted?.call();
      // Log watch event when video completes
      _logWatchEventIfNeeded();
    }
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (_isDisposed) return;

    final wasVisible = _isVisible;
    _isVisible = info.visibleFraction > 0.9;

    // Only notify if visibility state actually changed
    if (wasVisible != _isVisible) {
      widget.onVisibilityChanged(_isVisible);
    }

    // Control playback based on visibility (only if not manually paused)
    if (_videoPlayerController != null && _videoPlayerController!.isInitialized) {
      if (_isVisible && !_videoPlayerController!.isPlaying && !_isManuallyPaused) {
        // Video is visible - play it (only if not manually paused)
        _videoPlayerController!.play();
        widget.videoCacheManager.markAsVisible(widget.mediaUrl);
      } else if (!_isVisible && _videoPlayerController!.isPlaying) {
        // Video is not visible - pause it
        _videoPlayerController!.pause();
        widget.videoCacheManager.markAsNotVisible(widget.mediaUrl);
      }
    }
  }

  // Public methods to control playback
  void pause() {
    if (_videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        _videoPlayerController!.isPlaying) {
      _isManuallyPaused = true;
      _videoPlayerController!.pause();
    }
  }

  void play() {
    if (_videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        !_videoPlayerController!.isPlaying) {
      _isManuallyPaused = false;
      // Only play if visible
      if (_isVisible) {
        _videoPlayerController!.play();
      }
    }
  }

  // Check initial visibility after first frame
  void _checkInitialVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || !mounted) return;

      // Assume video is visible when first built (will be corrected by visibility detector)
      // This ensures video starts playing immediately on load
      if (_isInitialized &&
          _videoPlayerController != null &&
          _videoPlayerController!.isInitialized &&
          !_videoPlayerController!.isPlaying &&
          !_isManuallyPaused) {
        _isVisible = true; // Assume visible initially
        _videoPlayerController!.play();
        widget.videoCacheManager.markAsVisible(widget.mediaUrl);
      }
    });
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle mute state changes
    if (oldWidget.isMuted != widget.isMuted &&
        _videoPlayerController != null &&
        _videoPlayerController!.isInitialized) {
      _videoPlayerController!.setVolume(widget.isMuted ? 0.0 : 1.0);
    }

    // Handle media URL changes
    if (oldWidget.mediaUrl != widget.mediaUrl) {
      _isInitialized = false;
      _hasCompleted = false;
      _initializeVideoPlayer();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Log watch event when widget is disposed (user navigates away)
    _logWatchEventIfNeeded();
    if (_videoPlayerController != null && _videoPlayerController!.isInitialized) {
      _videoPlayerController!.removeListener(_handlePlaybackProgress);
      _videoPlayerController!.pause();
      widget.videoCacheManager.markAsNotVisible(widget.mediaUrl);
      // Don't dispose controller here - let cache manager handle it
    }
    super.dispose();
  }

  /// Log watch event only once per video when user leaves or video completes
  void _logWatchEventIfNeeded() async {
    // Only log if:
    // 1. Not already logged for this video
    // 2. User watched for at least 1 second
    // 3. postHelperCallBacks is provided
    if (_hasLoggedWatchEvent == false &&
        widget.postHelperCallBacks != null &&
        _videoPlayerController != null &&
        _videoPlayerController!.isInitialized) {
      try {
        final duration = _videoPlayerController!.duration;
        final watchedSeconds = _maxWatchPosition.inSeconds;
        final totalSeconds = duration.inSeconds;

        // Only log if user watched for at least 1 second
        if (watchedSeconds < 1) {
          return;
        }

        // Calculate completion rate as percentage
        final completionRate =
            totalSeconds > 0 ? ((watchedSeconds / totalSeconds) * 100).toInt() : 0;

        final eventMap = <String, dynamic>{
          'media_url': widget.mediaUrl,
          'view_source': 'feed',
          'view_completion_rate': completionRate,
          'view_duration': watchedSeconds,
          'total_duration': totalSeconds,
        };

        // Mark as logged to prevent duplicate logging
        _hasLoggedWatchEvent = true;

        // Call the callback to send analytics
        widget.postHelperCallBacks?.sendAnalyticsEvent(eventMap);
      } catch (e) {
        debugPrint('❌ Error logging watch event: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) => VisibilityDetector(
        key: Key('video_player_${widget.mediaUrl}'),
        onVisibilityChanged: _handleVisibilityChanged,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            if (_isInitialized &&
                _videoPlayerController != null &&
                _videoPlayerController!.isInitialized) ...[
              // Video is ready, show the player
              RepaintBoundary(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    child: Builder(
                      builder: (context) {
                        final size = _videoPlayerController!.videoSize;
                        final aspect = _videoPlayerController!.aspectRatio;
                        return SizedBox(
                          height: size.height,
                          width: size.width,
                          child: AspectRatio(
                            aspectRatio: aspect,
                            child: Container(
                              color: Colors.black,
                              child: Center(
                                child: RepaintBoundary(
                                  child: _videoPlayerController!.buildVideoPlayerWidget(),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Video is not ready, show thumbnail
              _getImageWidget(
                imageUrl: widget.thumbnailUrl,
                width: IsrDimens.getScreenWidth(context),
                height: IsrDimens.getScreenHeight(context),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                showError: false,
              ),
            ]
          ],
        ),
      );

  Widget _getImageWidget({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    FilterQuality filterQuality = FilterQuality.high,
    bool showError = false,
  }) {
    final isLocalUrl = imageUrl.isStringEmptyOrNull == false && Utility.isLocalUrl(imageUrl);
    return isLocalUrl
        ? AppImage.file(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            filterQuality: filterQuality,
          )
        : AppImage.network(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            filterQuality: filterQuality,
            showError: showError,
          );
  }
}
