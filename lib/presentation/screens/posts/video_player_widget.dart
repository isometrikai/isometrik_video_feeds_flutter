import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Configure VisibilityDetector for faster updates (smoother playback)
void _configureVisibilityDetector() {
  VisibilityDetectorController.instance.updateInterval = const Duration(milliseconds: 100);
}

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
    this.isPreloaded = false,
  });

  final String mediaUrl;
  final String thumbnailUrl;
  final VideoCacheManager videoCacheManager;
  final bool isMuted;
  final Function(bool isVisible) onVisibilityChanged;
  final double? aspectRatio;
  final VoidCallback? onVideoCompleted;
  final PostHelperCallBacks? postHelperCallBacks;
  final bool isPreloaded;
  final Function(int, int)? videoProgressCallBack;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();

  // Static method to access state from GlobalKey
  static _VideoPlayerWidgetState? of(GlobalKey key) => key.currentState as _VideoPlayerWidgetState?;
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  static bool _isVisibilityConfigured = false;
  IVideoPlayerController? _videoPlayerController;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isVisible = false;
  bool _isDisposed = false;
  bool _listenersAttached = false;
  bool _isManuallyPaused = false; // Track if video was manually paused (e.g., long press)
  bool _hasLoggedWatchEvent = false; // Track if watch event has been logged
  Duration _maxWatchPosition = Duration.zero; // Track maximum watch position

  // Track video start and progress milestones
  bool _hasLoggedVideoStarted = false;
  final Set<int> _loggedProgressMilestones =
      {}; // Track which milestones (25, 50, 75, 100) have been logged

  // OPTIMIZATION: Throttle progress callbacks for smoother performance
  int _lastProgressCallbackTime = 0;

  // Timer to detect and recover stuck videos
  Timer? _stuckVideoTimer;

  // Timer to check if controller is ready (for async initialization)
  Timer? _controllerReadyCheckTimer;

  // Track if we've received valid video dimensions
  bool _hasValidVideoSize = false;

  num _remainingDuration = 0;

  @override
  void initState() {
    super.initState();
    // OPTIMIZATION: Configure VisibilityDetector for faster updates
    if (!_isVisibilityConfigured) {
      _configureVisibilityDetector();
      _isVisibilityConfigured = true;
    }
    _initializeVideoPlayer();
    // Start checking if controller becomes ready asynchronously
    _startControllerReadyCheck();
  }

  /// Called when the video playing state changes
  void _onPlayingStateChanged() {
    if (_isDisposed || !mounted) return;

    // If video started playing, ensure UI shows the video player
    if (_videoPlayerController != null && _videoPlayerController!.isPlaying) {
      if (!_isInitialized) {
        debugPrint('🎬 VideoPlayerWidget: Video started playing, updating UI...');
        setState(() {
          _isInitialized = true;
        });
      } else {
        // Video is playing, trigger rebuild to update layout if size changed
        setState(() {});
      }
    }
  }

  /// Periodically check if the controller has become ready (initialized async in cache)
  void _startControllerReadyCheck() {
    _controllerReadyCheckTimer?.cancel();
    _controllerReadyCheckTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_isDisposed) {
        _controllerReadyCheckTimer?.cancel();
        return;
      }

      // If already initialized, stop checking
      if (_isInitialized && _videoPlayerController != null) {
        _controllerReadyCheckTimer?.cancel();
        return;
      }

      // Check if controller is now available in cache
      final cachedController =
          widget.videoCacheManager.getCachedMedia(widget.mediaUrl) as IVideoPlayerController?;

      if (cachedController != null &&
          cachedController.isInitialized &&
          !cachedController.isDisposed) {
        debugPrint(
            '✅ VideoPlayerWidget: Controller became ready (async check) for: ${widget.mediaUrl}');
        _controllerReadyCheckTimer?.cancel();
        _videoPlayerController = cachedController;
        _setupVideoController().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
          }
        });
      }
    });
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

    // Trigger UI update to show loading indicator
    if (mounted) {
      setState(() {});
    }

    try {
      // OPTIMIZATION: Try to get already cached and initialized controller first
      _videoPlayerController =
          widget.videoCacheManager.getCachedMedia(widget.mediaUrl) as IVideoPlayerController?;

      // If controller exists and is already initialized, use it directly
      if (_videoPlayerController != null &&
          _videoPlayerController!.isInitialized &&
          !_videoPlayerController!.isDisposed) {
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
      // Use video cache manager directly to avoid media type detection issues
      if (_videoPlayerController == null) {
        debugPrint('🔄 VideoPlayerWidget: Precaching video for: ${widget.mediaUrl}');
        // Use video cache manager directly (bypasses MediaTypeUtil)
        await widget.videoCacheManager.precacheMedia([widget.mediaUrl], highPriority: true);
        _videoPlayerController =
            widget.videoCacheManager.getCachedMedia(widget.mediaUrl) as IVideoPlayerController?;
      }

      // Setup only if controller is now initialized
      if (_videoPlayerController != null &&
          _videoPlayerController!.isInitialized &&
          !_videoPlayerController!.isDisposed) {
        await _setupVideoController();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _checkInitialVisibility();
        }
      } else {
        debugPrint('⚠️ VideoPlayerWidget: Failed to initialize video: ${widget.mediaUrl}');
        // If visible, schedule a retry
        if (_isVisible && mounted) {
          debugPrint('🔄 VideoPlayerWidget: Scheduling retry for visible video...');
          Future.delayed(const Duration(seconds: 1), () {
            if (!_isDisposed && _isVisible && !_isInitialized) {
              _isInitializing = false;
              _initializeVideoPlayer();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('❌ VideoPlayerWidget: Error initializing video: $e');
      // If visible, schedule a retry on error
      if (_isVisible && mounted) {
        debugPrint('🔄 VideoPlayerWidget: Scheduling retry after error...');
        Future.delayed(const Duration(seconds: 2), () {
          if (!_isDisposed && _isVisible && !_isInitialized) {
            _isInitializing = false;
            _initializeVideoPlayer();
          }
        });
      }
    } finally {
      _isInitializing = false;
      if (mounted) {
        setState(() {});
      }
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
      // Reset completion flag, manual pause state, and analytics tracking
      _isManuallyPaused = false;
      _hasLoggedWatchEvent = false;
      _maxWatchPosition = Duration.zero;
      _hasLoggedVideoStarted = false;
      _loggedProgressMilestones.clear();

      // Add listener for video completion and playback progress
      _detachControllerListeners();
      _videoPlayerController!.addListener(_handlePlaybackProgress);

      // Listen to playing state changes to update UI
      _videoPlayerController!.playingStateNotifier.addListener(_onPlayingStateChanged);
      _listenersAttached = true;

      // OPTIMIZATION: Run setup operations in parallel for faster playback start
      await Future.wait([
        _videoPlayerController!.setLooping(true),
        _videoPlayerController!.setVolume(widget.isMuted ? 0.0 : 1.0),
      ]);

      // If widget is visible when initialized, start playing immediately
      if (_isVisible && !widget.isPreloaded) {
        // Don't await play - let it start immediately
        unawaited(_videoPlayerController!.play());
        widget.videoCacheManager.markAsVisible(widget.mediaUrl);
        // Start stuck video detection to handle videos that don't start
        _startStuckVideoDetection();
      } else {
        widget.videoCacheManager.markAsNotVisible(widget.mediaUrl);
      }
    } catch (e) {
      debugPrint('❌ VideoPlayerWidget: Error setting up controller: $e');
    }
  }

  void _detachControllerListeners() {
    if (_videoPlayerController == null || !_listenersAttached) {
      return;
    }
    try {
      _videoPlayerController!.removeListener(_handlePlaybackProgress);
      _videoPlayerController!.playingStateNotifier.removeListener(_onPlayingStateChanged);
    } catch (_) {}
    _listenersAttached = false;
  }

  void _handlePlaybackProgress() {
    // Safety check: ensure widget and controller are valid and not disposed
    if (_isDisposed ||
        _videoPlayerController == null ||
        !_videoPlayerController!.isInitialized ||
        _videoPlayerController!.isDisposed) {
      return;
    }

    // Check if video size became valid - trigger rebuild to update layout
    if (!_hasValidVideoSize && _videoPlayerController != null) {
      final size = _videoPlayerController!.videoSize;
      if (size.width > 0 && size.height > 0) {
        _hasValidVideoSize = true;
        debugPrint('📐 VideoPlayerWidget: Video size now valid: $size');
        if (mounted) {
          setState(() {});
        }
      }
    }

    final position = _videoPlayerController!.position;
    final duration = _videoPlayerController!.duration;

    // Track maximum watch position for analytics
    if (position.inMilliseconds > _maxWatchPosition.inMilliseconds) {
      _maxWatchPosition = position;
    }

    // OPTIMIZATION: Throttle progress callbacks to every 200ms for smoother UI
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastProgressCallbackTime >= 200) {
      _lastProgressCallbackTime = now;
      widget.videoProgressCallBack?.call(duration.inMilliseconds, position.inMilliseconds);
    }

    // 1. Log "Video Started" event when video actually starts playing (position > 0)
    if (!_hasLoggedVideoStarted &&
        position.inMilliseconds > 0 &&
        widget.postHelperCallBacks != null) {
      _hasLoggedVideoStarted = true;
      _logVideoStartedEvent();
    }

    // 2. Log "Video Progress" events at 25%, 50%, 75%, 100% milestones
    if (duration.inMilliseconds > 0 && widget.postHelperCallBacks != null) {
      final progressPercentage = (position.inMilliseconds / duration.inMilliseconds * 100).toInt();

      // Check and log each milestone once
      final milestones = [25, 50, 75, 100];
      for (final milestone in milestones) {
        if (progressPercentage >= milestone && !_loggedProgressMilestones.contains(milestone)) {
          _loggedProgressMilestones.add(milestone);
          // _logVideoProgressEvent(milestone, position, duration);
        }
      }
    }

    // 3. Check if video has completed (with small threshold to account for timing)
    if (kDebugMode) {
      debugPrint('⏳ VideoPlayerWidget: Video position: $position, duration: $duration');
    }
    final remainingDuration = duration.inMilliseconds - position.inMilliseconds;
    if (kDebugMode) {
      debugPrint(
          '⏳ VideoPlayerWidget: Remaining duration: $remainingDuration > $_remainingDuration = ${remainingDuration > _remainingDuration}');
    }
    if (_remainingDuration > 0 && remainingDuration > _remainingDuration) {
      // remainingDuration is greater then _remainingDuration then video has restarted after completing
      // Video completed - notify callback
      widget.onVideoCompleted?.call();
      // Log watch event when video completes
      // _logWatchEventIfNeeded();
    }
    _remainingDuration = remainingDuration;
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
        'status': _videoPlayerController?.isPlaying == true ? 'playing' : 'paused',
        'view_duration': watchedSeconds,
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
    // OPTIMIZATION: Lower threshold (0.5) for earlier video start like Instagram
    _isVisible = info.visibleFraction > 0.5;

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
            !_isManuallyPaused &&
            !widget.isPreloaded) {
          // Ensure volume is set correctly before playing
          unawaited(_videoPlayerController!.setVolume(widget.isMuted ? 0.0 : 1.0));
          // OPTIMIZATION: Don't await - fire and forget for instant response
          unawaited(_videoPlayerController!.play());
          widget.videoCacheManager.markAsVisible(widget.mediaUrl);
          // Start stuck video detection for visible video
          _startStuckVideoDetection();
        } else if (!_isVisible && _videoPlayerController!.isPlaying) {
          // Video is not visible - pause it
          unawaited(_videoPlayerController!.pause());
          widget.videoCacheManager.markAsNotVisible(widget.mediaUrl);
          // Stop stuck video detection when not visible
          _stopStuckVideoDetection();
        }
      } catch (e) {
        debugPrint('⚠️ VideoPlayerWidget: Error in visibility change handler: $e');
      }
    } else if (_isVisible) {
      // OPTIMIZATION: If visible but not initialized/initializing, start initialization immediately
      if (!_isInitializing && !_isInitialized) {
        debugPrint('🔄 VideoPlayerWidget: Visible but not initialized, starting initialization...');
        _isDisposed = false;
        _initializeVideoPlayer();
      }
    }
  }

  // Track recovery attempts
  int _recoveryAttempts = 0;
  static const int _maxRecoveryAttempts = 5;

  /// Start periodic check for stuck videos (only for visible video)
  void _startStuckVideoDetection() {
    _stopStuckVideoDetection(); // Cancel any existing timer
    _recoveryAttempts = 0; // Reset recovery attempts

    // First check after 300ms (catch early stuck videos faster)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_isDisposed && _isVisible) {
        _checkAndRecoverStuckVideo();
      }
    });

    // Then check every 500ms (more aggressive for faster recovery)
    _stuckVideoTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _checkAndRecoverStuckVideo();
    });
  }

  /// Stop stuck video detection
  void _stopStuckVideoDetection() {
    _stuckVideoTimer?.cancel();
    _stuckVideoTimer = null;
  }

  /// Check if video is stuck and try to recover
  void _checkAndRecoverStuckVideo() {
    if (_isDisposed || !_isVisible || _isManuallyPaused) {
      _stopStuckVideoDetection();
      return;
    }

    if (_videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        !_videoPlayerController!.isDisposed) {
      // If video is visible but not playing, try to recover
      if (!_videoPlayerController!.isPlaying) {
        _recoveryAttempts++;
        debugPrint(
            '🔄 Detected stuck video, recovery attempt $_recoveryAttempts/$_maxRecoveryAttempts...');

        // Set volume and force resume
        unawaited(_videoPlayerController!.setVolume(widget.isMuted ? 0.0 : 1.0));
        unawaited(_videoPlayerController!.forceResume());

        // If too many recovery attempts, try re-initializing the video
        if (_recoveryAttempts >= _maxRecoveryAttempts) {
          debugPrint('⚠️ Max recovery attempts reached, re-initializing video...');
          _stopStuckVideoDetection();
          _reinitializeVideo();
        }
      } else {
        // Video is playing, stop the detection timer
        debugPrint('✅ Video started playing after $_recoveryAttempts attempts');
        _stopStuckVideoDetection();
      }
    } else if (!_isInitializing && _isVisible) {
      // Controller is not ready but video is visible - try to initialize
      debugPrint('🔄 Controller not ready, reinitializing...');
      _reinitializeVideo();
    }
  }

  /// Re-initialize video when stuck
  Future<void> _reinitializeVideo() async {
    if (_isDisposed || !_isVisible) return;

    debugPrint('🔄 Re-initializing video: ${widget.mediaUrl}');

    // Clear the cached controller
    widget.videoCacheManager.clearMedia(widget.mediaUrl);

    // Reset state
    _isInitialized = false;
    _videoPlayerController = null;

    // Small delay before reinitializing
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_isDisposed && _isVisible) {
      await _initializeVideoPlayer();
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
      if (_isVisible && !widget.isPreloaded) {
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
      _initializeVideoPlayer();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Cancel timers
    _stopStuckVideoDetection();
    _controllerReadyCheckTimer?.cancel();
    // Log watch event when widget is disposed (user navigates away)
    _logWatchEventIfNeeded();
    // Safety check: ensure controller is valid and not already disposed
    if (_videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        !_videoPlayerController!.isDisposed) {
      try {
        _detachControllerListeners();
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
        final completionRate =
            totalSeconds > 0 ? ((watchedSeconds / totalSeconds) * 100).toInt() : 0;

        // Only log if user watched at least 25% of the video
        if (completionRate < 25) {
          return;
        }

        final eventMap = <String, dynamic>{
          'view_duration': watchedSeconds,
          'view_completion_rate': completionRate,
        };

        // Mark as logged to prevent duplicate logging
        _hasLoggedWatchEvent = true;

        // Call the callback to send analytics
        widget.postHelperCallBacks?.sendAnalyticsEvent(EventType.postViewed.value, eventMap);
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
                if (_isVisible && mounted && _isManuallyPaused && !widget.isPreloaded) {
                  play();
                }
              } else {
                pause();
              }
            }
          },
          child: Container(
            color: Colors.black,
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
                  // Use SizedBox.expand to fill available space when video size is 0
                  Builder(
                    builder: (context) {
                      // Safety check: verify controller is still valid before building
                      if (_videoPlayerController == null ||
                          !_videoPlayerController!.isInitialized ||
                          _videoPlayerController!.isDisposed) {
                        // Return thumbnail as fallback if controller becomes invalid
                        return Container(
                          color: Colors.black,
                          child: Center(
                            child: _getImageWidget(
                              imageUrl: widget.thumbnailUrl,
                              width: IsrDimens.getScreenWidth(context),
                              height: IsrDimens.getScreenHeight(context),
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.low,
                              showError: false,
                            ),
                          ),
                        );
                      }

                      final size = _videoPlayerController!.videoSize;
                      final hasValidSize = size.width > 0 && size.height > 0;

                      // If video size is valid, use FittedBox for proper scaling
                      // Portrait (h > w) -> fill screen; square/landscape (h <= w) -> fit screen
                      if (hasValidSize) {
                        final aspect = _videoPlayerController!.aspectRatio;
                        final isPortrait = size.height > size.width;
                        final videoFit =
                            isPortrait ? BoxFit.cover : BoxFit.contain;
                        return RepaintBoundary(
                          child: FittedBox(
                            fit: videoFit,
                            child: SizedBox(
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
                            ),
                          ),
                        );
                      }

                      // Fallback: Video size not available yet, fill the available space
                      // This ensures video is visible even if dimensions aren't reported
                      if (kDebugMode) {
                        debugPrint(
                            '🎬 VideoPlayerWidget: Using fallback layout (size: $size)');
                      }
                      return SizedBox.expand(
                        child: Container(
                          color: Colors.black,
                          child: RepaintBoundary(
                            child: _videoPlayerController!
                                .buildVideoPlayerWidget(),
                          ),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  // Video is not ready, show thumbnail with loading indicator
                  Container(
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: _getImageWidget(
                            imageUrl: widget.thumbnailUrl,
                            width: IsrDimens.getScreenWidth(context),
                            height: IsrDimens.getScreenHeight(context),
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.low,
                            showError: false,
                          ),
                        ),
                        // Show loading indicator when initializing
                        if (_isInitializing || (_isVisible && !_isInitialized))
                          const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
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
