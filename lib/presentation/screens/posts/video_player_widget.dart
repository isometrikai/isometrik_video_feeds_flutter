import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/data/data.dart';
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
    this.videoProgressCallBack,
  });

  final String mediaUrl;
  final String thumbnailUrl;
  final VideoCacheManager videoCacheManager;
  final bool isMuted;
  final Function(bool isVisible) onVisibilityChanged;
  final double? aspectRatio;
  final VoidCallback? onVideoCompleted;
  final PostHelperCallBacks? postHelperCallBacks;
  final Function(int, int)? videoProgressCallBack;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();

  // Static method to access state from GlobalKey
  static _VideoPlayerWidgetState? of(GlobalKey key) =>
      key.currentState as _VideoPlayerWidgetState?;
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  IVideoPlayerController? _videoPlayerController;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isVisible = false;
  bool _isDisposed = false;
  bool _hasCompleted = false; // Track if video has already completed
  bool _isManuallyPaused =
      false; // Track if video was manually paused (e.g., long press)
  bool _hasLoggedWatchEvent = false; // Track if watch event has been logged
  Duration _maxWatchPosition = Duration.zero; // Track maximum watch position

  // Track video start and progress milestones
  bool _hasLoggedVideoStarted = false;
  final Set<int> _loggedProgressMilestones =
      {}; // Track which milestones (25, 50, 75, 100) have been logged

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  // @override
  // void activate() {
  //   super.activate();
  //   // Reset disposed flag when widget is reactivated (e.g., returning to tab)
  //   if (_isDisposed) {
  //     debugPrint('🔄 VideoPlayerWidget: Reactivating widget, resetting _isDisposed');
  //     _isDisposed = false;
  //     // Re-initialize video player if needed
  //     if (!_isInitialized || _videoPlayerController == null) {
  //       _initializeVideoPlayer();
  //     }
  //   }
  // }

  Future<void> _initializeVideoPlayer() async {
    if (_isInitializing || widget.mediaUrl.isEmpty) return;

    _isInitializing = true;

    try {
      // OPTIMIZATION: Try to get already cached and initialized controller first
      _videoPlayerController = widget.videoCacheManager
          .getCachedMedia(widget.mediaUrl) as IVideoPlayerController?;

      // If controller exists and is already initialized, use it directly
      if (_videoPlayerController != null &&
          _videoPlayerController!.isInitialized) {
        debugPrint(
            '✅ VideoPlayerWidget: Using cached initialized controller for: ${widget.mediaUrl}');
        await _setupVideoController();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _checkInitialVisibility();
        }
        return; // Early return - no need to initialize again
      }

      // OPTIMIZATION: If no cached controller, trigger precaching ONCE
      // precacheMedia will handle initialization internally
      if (_videoPlayerController == null) {
        debugPrint(
            '🔄 VideoPlayerWidget: Precaching video for: ${widget.mediaUrl}');
        await MediaCacheFactory.precacheMedia([widget.mediaUrl],
            highPriority: true);
        _videoPlayerController = widget.videoCacheManager
            .getCachedMedia(widget.mediaUrl) as IVideoPlayerController?;
      }

      // Setup only if controller is now initialized
      if (_videoPlayerController != null &&
          _videoPlayerController!.isInitialized) {
        await _setupVideoController();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _checkInitialVisibility();
        }
      } else {
        debugPrint(
            '⚠️ VideoPlayerWidget: Failed to initialize video: ${widget.mediaUrl}');
      }
    } catch (e) {
      debugPrint('❌ VideoPlayerWidget: Error initializing video: $e');
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _setupVideoController() async {
    // Safety check: ensure controller is valid and not disposed
    if (_videoPlayerController == null ||
        !_videoPlayerController!.isInitialized ||
        _videoPlayerController!.isDisposed) {
      return;
    }

    try {
      // Set looping to false so video can complete
      await _videoPlayerController!.setLooping(true);
      await _videoPlayerController!.setVolume(widget.isMuted ? 0.0 : 1.0);
      await _videoPlayerController!.seekTo(Duration.zero);

      // Reset completion flag, manual pause state, and analytics tracking
      _hasCompleted = false;
      _isManuallyPaused = false;
      _hasLoggedWatchEvent = false;
      _maxWatchPosition = Duration.zero;
      _hasLoggedVideoStarted = false;
      _loggedProgressMilestones.clear();

      // Add listener for video completion
      _videoPlayerController!.addListener(_handlePlaybackProgress);

      // If widget is visible when initialized, start playing immediately
      debugPrint(
          'VideoPlayerWidget:- url: ${widget.mediaUrl} - isVisible: $_isVisible');
      if (_isVisible) {
        await _videoPlayerController!.play();
        widget.videoCacheManager.markAsVisible(widget.mediaUrl);
      } else {
        await _videoPlayerController!.pause();
        widget.videoCacheManager.markAsNotVisible(widget.mediaUrl);
      }
    } catch (e) {
      debugPrint('❌ VideoPlayerWidget: Error setting up controller: $e');
    }
  }

  void _handlePlaybackProgress() {
    // Safety check: ensure widget and controller are valid and not disposed
    if (_isDisposed ||
        _videoPlayerController == null ||
        !_videoPlayerController!.isInitialized ||
        _videoPlayerController!.isDisposed) {
      return;
    }

    final position = _videoPlayerController!.position;
    final duration = _videoPlayerController!.duration;

    // Track maximum watch position for analytics
    if (position.inMilliseconds > _maxWatchPosition.inMilliseconds) {
      _maxWatchPosition = position;
    }

    widget.videoProgressCallBack
        ?.call(duration.inMilliseconds, position.inMilliseconds);

    // 1. Log "Video Started" event when video actually starts playing (position > 0)
    if (!_hasLoggedVideoStarted &&
        position.inMilliseconds > 0 &&
        widget.postHelperCallBacks != null) {
      _hasLoggedVideoStarted = true;
      _logVideoStartedEvent();
    }

    // 2. Log "Video Progress" events at 25%, 50%, 75%, 100% milestones
    if (duration.inMilliseconds > 0 && widget.postHelperCallBacks != null) {
      final progressPercentage =
          (position.inMilliseconds / duration.inMilliseconds * 100).toInt();

      // Check and log each milestone once
      final milestones = [25, 50, 75, 100];
      for (final milestone in milestones) {
        if (progressPercentage >= milestone &&
            !_loggedProgressMilestones.contains(milestone)) {
          _loggedProgressMilestones.add(milestone);
          // _logVideoProgressEvent(milestone, position, duration);
        }
      }
    }

    // 3. Check if video has completed (with small threshold to account for timing)
    if (duration.inMilliseconds > 0 &&
        position.inMilliseconds >= duration.inMilliseconds - 100 &&
        !_hasCompleted) {
      _hasCompleted = true;
      // Video completed - notify callback
      widget.onVideoCompleted?.call();
      // Log watch event when video completes
      // _logWatchEventIfNeeded();
    }
  }

  /// Log "Video Started" event when playback begins
  void _logVideoStartedEvent() {
    // Safety check: ensure controller is valid and not disposed
    if (_videoPlayerController == null ||
        !_videoPlayerController!.isInitialized ||
        _videoPlayerController!.isDisposed) {
      return;
    }

    try {
      final duration = _videoPlayerController!.duration;
      final watchedSeconds = _maxWatchPosition.inSeconds;
      final totalSeconds = duration.inSeconds;
      final viewCompletionRate = (watchedSeconds / totalSeconds * 100).toInt();
      // Only log if user watched for at least 1 second
      if (watchedSeconds < 1) {
        return;
      }

      final eventMap = <String, dynamic>{
        'view_source': 'feed',
        'status':
            _videoPlayerController?.isPlaying == true ? 'playing' : 'paused',
        'view_duration': totalSeconds,
        'view_completion_rate': viewCompletionRate,
      };

      widget.postHelperCallBacks?.sendAnalyticsEvent(
        _videoPlayerController?.isPlaying == true
            ? EventType.videoStarted.value
            : EventType.videoPaused.value,
        eventMap,
      );

      debugPrint('📹 Video Started - Duration: ${duration.inSeconds}s');
    } catch (e) {
      debugPrint('❌ Error logging Video Started event: $e');
    }
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (_isDisposed) return;

    final wasVisible = _isVisible;
    _isVisible = info.visibleFraction > 0.9;
    debugPrint(
        'VideoPlayerWidget:- url: ${widget.mediaUrl} - VisibilityFraction: ${info.visibleFraction}');

    // Only notify if visibility state actually changed
    if (wasVisible != _isVisible) {
      widget.onVisibilityChanged(_isVisible);
    }

    // Control playback based on visibility (only if not manually paused)
    // Safety check: ensure controller is valid and not disposed
    if (!_isDisposed &&
        _videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        !_videoPlayerController!.isDisposed) {
      try {
        if (_isVisible &&
            !_videoPlayerController!.isPlaying &&
            !_isManuallyPaused) {
          // Video is visible - play it (only if not manually paused)
          _videoPlayerController!.play();
          widget.videoCacheManager.markAsVisible(widget.mediaUrl);
        } else if (!_isVisible && _videoPlayerController!.isPlaying) {
          // Video is not visible - pause it
          _videoPlayerController!.pause();
          widget.videoCacheManager.markAsNotVisible(widget.mediaUrl);
        }
      } catch (e) {
        debugPrint(
            '⚠️ VideoPlayerWidget: Error in visibility change handler: $e');
      }
    } else {
      _isDisposed = false;
      _initializeVideoPlayer();
    }
  }

  // Public methods to control playback
  void pause() {
    if (_isDisposed) return; // Safety check: Don't operate on disposed widget

    // Safety check: ensure controller is valid and not disposed
    if (_videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        !_videoPlayerController!.isDisposed &&
        _videoPlayerController!.isPlaying) {
      _isManuallyPaused = true;
      _videoPlayerController!.pause();
      _logVideoStartedEvent();
    }
  }

  void play() {
    if (_isDisposed) return; // Safety check: Don't operate on disposed widget

    // Safety check: ensure controller is valid and not disposed
    if (_videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        !_videoPlayerController!.isDisposed &&
        !_videoPlayerController!.isPlaying) {
      _isManuallyPaused = false;
      // Only play if visible
      if (_isVisible) {
        _videoPlayerController!.play();
      }
      _logVideoStartedEvent();
    }
  }

  /// Seek to a specific position in the video
  Future<void> seekTo(Duration position) async {
    if (_isDisposed) return;

    if (_videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        !_videoPlayerController!.isDisposed) {
      await _videoPlayerController!.seekTo(position);
    }
  }

  /// Get the total duration of the video
  Duration? get duration {
    if (_isDisposed) return null;

    if (_videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        !_videoPlayerController!.isDisposed) {
      return _videoPlayerController!.duration;
    }
    return null;
  }

  // Check initial visibility after first frame
  void _checkInitialVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // 🔥 Force visibility recalculation immediately
      VisibilityDetectorController.instance.notifyNow();
    });
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle mute state changes
    // Note: Don't check _isDisposed here - didUpdateWidget is only called when widget is active
    if (oldWidget.isMuted != widget.isMuted &&
        _videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        !_videoPlayerController!.isDisposed) {
      try {
        _videoPlayerController!.setVolume(widget.isMuted ? 0.0 : 1.0);
      } catch (e) {
        debugPrint('⚠️ VideoPlayerWidget: Error updating volume: $e');
      }
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
    // Safety check: ensure controller is valid and not already disposed
    if (_videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        !_videoPlayerController!.isDisposed) {
      try {
        _videoPlayerController!.removeListener(_handlePlaybackProgress);
        _videoPlayerController!.pause();
        widget.videoCacheManager.markAsNotVisible(widget.mediaUrl);
      } catch (e) {
        debugPrint('⚠️ VideoPlayerWidget: Error during dispose: $e');
      }
      // Don't dispose controller here - let cache manager handle it
    }
    super.dispose();
  }

  /// Log watch event only once per video when user leaves or video completes
  void _logWatchEventIfNeeded() async {
    // Only log if:
    // 1. Not already logged for this video
    // 2. User watched at least 25% of the video
    // 3. postHelperCallBacks is provided
    // Safety check: ensure controller is valid and not disposed
    if (_hasLoggedWatchEvent == false &&
        widget.postHelperCallBacks != null &&
        _videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        !_videoPlayerController!.isDisposed) {
      try {
        final duration = _videoPlayerController!.duration;
        final watchedSeconds = _maxWatchPosition.inSeconds;
        final totalSeconds = duration.inSeconds;

        // Calculate completion rate as percentage
        final completionRate = totalSeconds > 0
            ? ((watchedSeconds / totalSeconds) * 100).toInt()
            : 0;

        // Only log if user watched at least 25% of the video
        if (completionRate < 25) {
          return;
        }

        final eventMap = <String, dynamic>{
          'view_duration': totalSeconds,
          'view_completion_rate': completionRate,
        };

        // Mark as logged to prevent duplicate logging
        _hasLoggedWatchEvent = true;

        // Call the callback to send analytics
        widget.postHelperCallBacks
            ?.sendAnalyticsEvent(EventType.postViewed.value, eventMap);
      } catch (e) {
        debugPrint('❌ Error logging watch event: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) => VisibilityDetector(
        key: Key('video_player_${widget.mediaUrl}'),
        onVisibilityChanged: _handleVisibilityChanged,
        child: BlocListener<SocialPostBloc, SocialPostState>(
          listenWhen: (previous, current) => current is PlayPauseVideoState,
          listener: (context, state) {
            if (_isDisposed) return; // Safety check: Widget is disposed

            if (state is PlayPauseVideoState) {
              if (state.play) {
                if (_isVisible && mounted && _isManuallyPaused) {
                  play();
                }
              } else {
                pause();
              }
            }
          },
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // Note: Don't check _isDisposed here - build() is only called when widget is active
              if (_isInitialized &&
                  _videoPlayerController != null &&
                  _videoPlayerController!.isInitialized &&
                  !_videoPlayerController!.isDisposed) ...[
                // Video is ready, show the player
                RepaintBoundary(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      child: Builder(
                        builder: (context) {
                          // Safety check: verify controller is still valid before building
                          if (_videoPlayerController == null ||
                              !_videoPlayerController!.isInitialized ||
                              _videoPlayerController!.isDisposed) {
                            // Return thumbnail as fallback if controller becomes invalid
                            return _getImageWidget(
                              imageUrl: widget.thumbnailUrl,
                              width: IsrDimens.getScreenWidth(context),
                              height: IsrDimens.getScreenHeight(context),
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.low,
                              showError: false,
                            );
                          }
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
                                    child: _videoPlayerController!
                                        .buildVideoPlayerWidget(),
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
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.low,
                  showError: false,
                ),
              ]
            ],
          ),
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
    final isLocalUrl =
        imageUrl.isStringEmptyOrNull == false && Utility.isLocalUrl(imageUrl);
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
