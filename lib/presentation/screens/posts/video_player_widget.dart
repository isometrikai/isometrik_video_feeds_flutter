import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/utils/isr_active_video_player_registry.dart';
import 'package:ism_video_reel_player/utils/isr_image_sound_registry.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Configure VisibilityDetector for faster updates (smoother playback)
void _configureVisibilityDetector() {
  VisibilityDetectorController.instance.updateInterval =
      const Duration(milliseconds: 100);
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
    this.videoFitOverride,
    this.onVideoCompleted,
    this.postHelperCallBacks,
    this.videoProgressCallBack,
    this.isPreloaded = false,
    this.logIndex,
    this.isParentVisible,
    this.visibilityManagedByParent = false,
    this.postSectionType,
    this.onPlaybackStateChanged,
  });

  final String mediaUrl;
  final String thumbnailUrl;
  final VideoCacheManager videoCacheManager;
  final bool isMuted;
  final Function(bool isVisible) onVisibilityChanged;
  final double? aspectRatio;
  final BoxFit? videoFitOverride;
  final VoidCallback? onVideoCompleted;
  final PostHelperCallBacks? postHelperCallBacks;
  final bool isPreloaded;
  final Function(Duration totalDuration, Duration curentDuration)?
      videoProgressCallBack;
  final bool Function()? isParentVisible;

  /// When true, defers to [isParentVisible] only (no nested [VisibilityDetector]).
  final bool visibilityManagedByParent;
  final PostSectionType? postSectionType;
  final String? logIndex;

  /// Notifies when play/pause state changes (e.g. feed play icon overlay).
  final VoidCallback? onPlaybackStateChanged;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();

  // Static method to access state from GlobalKey
  static _VideoPlayerWidgetState? of(GlobalKey key) =>
      key.currentState as _VideoPlayerWidgetState?;
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  static bool _isVisibilityConfigured = false;
  IVideoPlayerController? _videoPlayerController;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isVisible = false;
  bool _isDisposed = false;
  bool _listenersAttached = false;
  bool _isManuallyPaused =
      false; // Track if video was manually paused (e.g., long press)
  bool _pendingBlocResume = false;
  late final VoidCallback _backgroundPauseHandler;
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

  // to see if the player has played at least once
  bool _hasPlayed = false;

  bool _isVideoCompleted = false;

  bool get _parentWantsVisible => widget.isParentVisible?.call() ?? true;

  bool get _effectiveVisible =>
      widget.visibilityManagedByParent ? _parentWantsVisible : _isVisible;

  /// Same fit for thumbnail and video so reels do not jump from letterbox to full-bleed.
  BoxFit _resolveDisplayFit({Size? videoSize}) {
    if (widget.videoFitOverride != null) return widget.videoFitOverride!;

    final w = videoSize?.width ?? 0;
    final h = videoSize?.height ?? 0;
    if (w > 0 && h > 0) {
      return h > w ? BoxFit.cover : BoxFit.contain;
    }

    final ar = widget.aspectRatio;
    if (ar != null && ar > 0) {
      return ar < 1.0 ? BoxFit.cover : BoxFit.contain;
    }

    // Full-screen reels: portrait-style cover matches playback once dimensions load.
    if (!widget.visibilityManagedByParent) {
      return BoxFit.cover;
    }

    return BoxFit.contain;
  }

  @override
  void initState() {
    super.initState();
    _backgroundPauseHandler = () {
      if (!_isDisposed) pauseForLifecycle();
    };
    IsrActiveVideoPlayerRegistry.registerPauseHandler(_backgroundPauseHandler);
    _isVisible = widget.visibilityManagedByParent
        ? _parentWantsVisible
        : !widget.isPreloaded;
    if (kDebugMode) {
      debugPrint(
        '⚠️ state VideoPlayerWidget: (${widget.logIndex}) initState - isPreloaded: ${widget.isPreloaded}',
      );
    }
    if (!widget.visibilityManagedByParent && !_isVisibilityConfigured) {
      _configureVisibilityDetector();
      _isVisibilityConfigured = true;
    }
    _hasPlayed = false;
    _initializeVideoPlayer();
    // Start checking if controller becomes ready asynchronously
    _startControllerReadyCheck();
  }

  /// Sync play/pause with widget state; detach controller when UI is disposed.
  void _syncPlaybackState() {
    final controller = _videoPlayerController;

    if (_isDisposed || !mounted) {
      if (controller == null) return;
      _detachControllerListeners();
      try {
        if (controller.isInitialized && !controller.isDisposed) {
          unawaited(controller.pause());
        }
        widget.videoCacheManager
            .detachedFromWidget(widget.mediaUrl, controller);
      } catch (e) {
        debugPrint('⚠️ VideoPlayerWidget: Error detaching on dispose: $e');
      }
      _videoPlayerController = null;
      return;
    }

    if (controller == null ||
        !controller.isInitialized ||
        controller.isDisposed) {
      return;
    }

    final shouldPlay = _effectiveVisible && !_isManuallyPaused;

    try {
      if (shouldPlay) {
        if (!controller.isPlaying) {
          unawaited(controller.setVolume(widget.isMuted ? 0.0 : 1.0));
          unawaited(controller.play());
          widget.videoCacheManager.markAsVisible(widget.mediaUrl);
          _startStuckVideoDetection();
        }
      } else {
        if (controller.isPlaying) {
          unawaited(controller.pause());
        }
        widget.videoCacheManager.markAsNotVisible(widget.mediaUrl);
        _stopStuckVideoDetection();
      }
    } catch (e) {
      debugPrint('⚠️ VideoPlayerWidget: Error syncing playback state: $e');
    }
    _notifyPlaybackStateChanged();
  }

  void _notifyPlaybackStateChanged() {
    widget.onPlaybackStateChanged?.call();
  }

  /// Called when the video playing state changes
  void _onPlayingStateChanged() {
    if (_isDisposed || !mounted) return;

    // If video started playing, ensure UI shows the video player
    if (_videoPlayerController != null && _videoPlayerController!.isPlaying) {
      if (!_isInitialized) {
        debugPrint(
            '🎬 VideoPlayerWidget: Video started playing, updating UI...');
        setState(() {
          _isInitialized = true;
        });
      } else if (!_hasValidVideoSize) {
        setState(() {});
      }
    }
    _notifyPlaybackStateChanged();
  }

  void _syncVisibilityFromParent() {
    if (!widget.visibilityManagedByParent || _isDisposed) return;

    final visible = _parentWantsVisible;
    if (_isVisible == visible) {
      _syncPlaybackState();
      return;
    }

    _isVisible = visible;
    widget.onVisibilityChanged(_isVisible);
    _syncPlaybackState();

    if (_isVisible && !_isInitializing && !_isInitialized) {
      _initializeVideoPlayer();
    }
  }

  /// Periodically check if the controller has become ready (initialized async in cache)
  void _startControllerReadyCheck() {
    _controllerReadyCheckTimer?.cancel();
    final interval = widget.visibilityManagedByParent
        ? const Duration(milliseconds: 400)
        : const Duration(milliseconds: 200);
    _controllerReadyCheckTimer = Timer.periodic(interval, (_) {
      if (_isDisposed) {
        _controllerReadyCheckTimer?.cancel();
        return;
      }

      if (!_effectiveVisible) {
        return;
      }

      // If already initialized, stop checking
      if (_isInitialized && _videoPlayerController != null) {
        _controllerReadyCheckTimer?.cancel();
        return;
      }

      // Check if controller is now available in cache
      final cachedController = widget.videoCacheManager
          .getCachedMedia(widget.mediaUrl) as IVideoPlayerController?;

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
      _videoPlayerController = widget.videoCacheManager
          .getCachedMedia(widget.mediaUrl) as IVideoPlayerController?;

      // OPTIMIZATION: If no cached controller, trigger precaching ONCE
      // Use video cache manager directly to avoid media type detection issues
      if (_videoPlayerController == null) {
        debugPrint(
            '🔄 VideoPlayerWidget: Precaching video for: ${widget.mediaUrl}');
        // Use video cache manager directly (bypasses MediaTypeUtil)

        final controller = await widget.videoCacheManager
            .precacheMediaAndReturnController(widget.mediaUrl);
        if (controller != null && controller is IVideoPlayerController) {
          _videoPlayerController = controller;
        }
        if (_isDisposed &&
            _videoPlayerController != null &&
            _videoPlayerController?.isInitialized == true) {
          // if widget is disposed, detach controller
          widget.videoCacheManager
              .detachedFromWidget(widget.mediaUrl, _videoPlayerController);
          _videoPlayerController = null;
        }
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
        debugPrint(
            '⚠️ VideoPlayerWidget: Failed to initialize video: ${widget.mediaUrl}');
        // If visible, schedule a retry
        if (_isVisible && mounted) {
          debugPrint(
              '🔄 VideoPlayerWidget: Scheduling retry for visible video...');
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
      _maxWatchPosition = Duration.zero;
      _hasLoggedVideoStarted = false;
      _loggedProgressMilestones.clear();

      // Add listener for video completion and playback progress
      _detachControllerListeners();
      _videoPlayerController!.addListener(_handlePlaybackProgress);

      // Listen to playing state changes to update UI
      _videoPlayerController!.playingStateNotifier
          .addListener(_onPlayingStateChanged);
      _listenersAttached = true;

      // OPTIMIZATION: Run setup operations in parallel for faster playback start
      await Future.wait([
        _videoPlayerController!.setLooping(true),
        _videoPlayerController!.setVolume(widget.isMuted ? 0.0 : 1.0),
      ]);

      // If widget is visible when initialized, start playing immediately
      if (_isVisible) {
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
      _videoPlayerController!.playingStateNotifier
          .removeListener(_onPlayingStateChanged);
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

    if (!_hasPlayed) {
      final hasPlayed =
          position.inMilliseconds > 0 && duration.inMilliseconds > 0;
      if (hasPlayed) {
        debugPrint('🎬 VideoPlayerWidget: Video started playing');
        setState(() {
          _hasPlayed = _videoPlayerController?.isPlaying == true;
        });
      }
    }
    // Track maximum watch position for analytics
    if (position.inMilliseconds > _maxWatchPosition.inMilliseconds) {
      _maxWatchPosition = position;
    }

    // OPTIMIZATION: Throttle progress callbacks to every 200ms for smoother UI
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastProgressCallbackTime >= 200 &&
        _videoPlayerController?.isPlaying == true &&
        _videoPlayerController?.isBuffering != true) {
      _lastProgressCallbackTime = now;
      widget.videoProgressCallBack?.call(duration, position);
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

    // 👇 Check if near end (within 500ms)
    final isAtEnd = position >= duration - const Duration(milliseconds: 500);

    if (isAtEnd && !_isVideoCompleted) {
      _isVideoCompleted = true;

      widget.onVideoCompleted?.call(); // 🔥 your callback
    }

    // 👇 Reset when user rewinds or new video loads
    if (position < duration - const Duration(seconds: 1)) {
      _isVideoCompleted = false;
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
    if (_isDisposed || widget.visibilityManagedByParent) return;

    if (!_feedAllowsPlayback) {
      if (_videoPlayerController != null &&
          _videoPlayerController!.isInitialized &&
          !_videoPlayerController!.isDisposed &&
          _videoPlayerController!.isPlaying) {
        unawaited(_videoPlayerController!.pause());
      }
      return;
    }

    final wasVisible = _isVisible;
    _isVisible = info.visibleFraction > 0.55;
    if (kDebugMode) {
      debugPrint(
        '✅ VideoPlayerWidget: (${widget.logIndex}) visibility=${info.visibleFraction}',
      );
    }

    // Only notify if visibility state actually changed
    if (wasVisible != _isVisible) {
      widget.onVisibilityChanged(_isVisible);
    }

    if (_pendingBlocResume &&
        !_isManuallyPaused &&
        _mayStartPlayback(activeReel: true)) {
      _pendingBlocResume = false;
      play();
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
          // Ensure volume is set correctly before playing
          unawaited(
              _videoPlayerController!.setVolume(widget.isMuted ? 0.0 : 1.0));
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
        debugPrint(
            '⚠️ VideoPlayerWidget: Error in visibility change handler: $e');
      }
    } else if (_isVisible) {
      // OPTIMIZATION: If visible but not initialized/initializing, start initialization immediately
      if (!_isInitializing && !_isInitialized) {
        debugPrint(
            '🔄 VideoPlayerWidget: Visible but not initialized, starting initialization...');
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
    if (_isDisposed ||
        !_mayStartPlayback(activeReel: true) ||
        _isManuallyPaused) {
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
        unawaited(
            _videoPlayerController!.setVolume(widget.isMuted ? 0.0 : 1.0));
        unawaited(_videoPlayerController!.forceResume());

        // If too many recovery attempts, try re-initializing the video
        if (_recoveryAttempts >= _maxRecoveryAttempts) {
          debugPrint(
              '⚠️ Max recovery attempts reached, re-initializing video...');
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

  bool get isPlayerReady =>
      !_isDisposed &&
      _isInitialized &&
      _videoPlayerController != null &&
      _videoPlayerController!.isInitialized &&
      !_videoPlayerController!.isDisposed;

  /// True when the clip is loaded but not playing (manual or lifecycle pause).
  bool get showPausedIndicator => isPlayerReady && !isPlaying;

  bool get isPlaying {
    if (_isDisposed ||
        _videoPlayerController == null ||
        !_videoPlayerController!.isInitialized ||
        _videoPlayerController!.isDisposed) {
      return false;
    }
    return _videoPlayerController!.isPlaying;
  }

  // Public methods to control playback
  void pause() {
    if (_isDisposed) return;
    _isManuallyPaused = true;
    _pauseControllerIfPlaying();
    _notifyPlaybackStateChanged();
  }

  /// Background / tab-handoff pause — does not require a user tap to resume.
  void pauseForLifecycle() {
    if (_isDisposed) return;
    _pendingBlocResume = false;
    _pauseControllerIfPlaying();
    _notifyPlaybackStateChanged();
  }

  void _pauseControllerIfPlaying() {
    if (_videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        !_videoPlayerController!.isDisposed &&
        _videoPlayerController!.isPlaying) {
      _videoPlayerController!.pause();
      _logVideoStartedEvent();
    }
  }

  /// Re-evaluates [isParentVisible] after carousel page or feed visibility changes.
  void syncParentVisibility() {
    if (!widget.visibilityManagedByParent || _isDisposed) return;
    _syncVisibilityFromParent();
    _tryConsumePendingBlocResume();
  }

  void _tryConsumePendingBlocResume() {
    if (!_pendingBlocResume || _isManuallyPaused || !_feedAllowsPlayback) {
      return;
    }
    if (_tryStartPlaybackNow()) {
      _pendingBlocResume = false;
    }
  }

  bool get _feedAllowsPlayback =>
      (widget.isParentVisible?.call() ?? true) &&
      IsrVideoReelConfig.allowsPlayback;

  /// Whether this player may start/resume right now.
  ///
  /// Parent-managed players (feed carousel) always follow [_effectiveVisible].
  /// Full-screen reels may use [activeReel] to tolerate VisibilityDetector lag
  /// on the current clip, but still require [_feedAllowsPlayback] (tab + host).
  bool _mayStartPlayback({bool activeReel = false}) {
    if (!_feedAllowsPlayback) return false;
    if (widget.visibilityManagedByParent) {
      return _effectiveVisible;
    }
    // A preloaded (non-current) reel must never force-play; otherwise a scoped
    // play event would resume both the current reel and the preloaded next one.
    if (widget.isPreloaded) return _isVisible;
    return _isVisible || activeReel;
  }

  void play() {
    if (_isDisposed) return; // Safety check: Don't operate on disposed widget

    _isManuallyPaused = false;
    _pendingBlocResume = false;
    // Safety check: ensure controller is valid and not disposed
    if (_videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        !_videoPlayerController!.isDisposed &&
        !_videoPlayerController!.isPlaying) {
      final shouldPlay = widget.visibilityManagedByParent
          ? _effectiveVisible
          : _mayStartPlayback();
      if (shouldPlay) {
        unawaited(
          _videoPlayerController!.setVolume(widget.isMuted ? 0.0 : 1.0),
        );
        unawaited(_videoPlayerController!.play());
      }
      _logVideoStartedEvent();
    }
    _notifyPlaybackStateChanged();
  }

  void _startPlaybackNow() {
    if (!_feedAllowsPlayback) return;

    unawaited(IsrImageSoundRegistry.stopAll());
    _pendingBlocResume = false;
    final controller = _videoPlayerController;
    if (controller == null ||
        !controller.isInitialized ||
        controller.isDisposed) {
      return;
    }
    unawaited(controller.setVolume(widget.isMuted ? 0.0 : 1.0));
    if (!controller.isPlaying) {
      unawaited(controller.play());
    }
    _logVideoStartedEvent();
    _notifyPlaybackStateChanged();
  }

  void forceResume({bool activeReel = false}) {
    if (_isDisposed) return;
    _isManuallyPaused = false;

    if (!_feedAllowsPlayback) {
      _pendingBlocResume = true;
      return;
    }

    if (_tryStartPlaybackNow(activeReel: activeReel)) {
      _notifyPlaybackStateChanged();
      return;
    }
    _pendingBlocResume = true;
    _notifyPlaybackStateChanged();
    VisibilityDetectorController.instance.notifyNow();
  }

  bool _tryStartPlaybackNow({bool activeReel = false}) {
    if (_isInitialized &&
        _videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        !_videoPlayerController!.isDisposed &&
        _mayStartPlayback(activeReel: activeReel)) {
      _startPlaybackNow();
      return true;
    }
    return false;
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

  void _checkInitialVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.visibilityManagedByParent) {
        _syncVisibilityFromParent();
        return;
      }
      VisibilityDetectorController.instance.notifyNow();
    });
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.visibilityManagedByParent) {
      _syncVisibilityFromParent();
    }

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
      _hasPlayed = false;
      _isInitialized = false;
      _initializeVideoPlayer();
    }

    if (oldWidget.isPreloaded &&
        !widget.isPreloaded &&
        !widget.visibilityManagedByParent) {
      _isVisible = true;
      if (_isInitialized) {
        forceResume(activeReel: true);
      } else {
        _initializeVideoPlayer();
      }
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('⚠️ state VideoPlayerWidget: (${widget.logIndex}) dispose');
    }
    _isDisposed = true;
    IsrActiveVideoPlayerRegistry.unregisterPauseHandler(_backgroundPauseHandler);
    // Cancel timers
    _stopStuckVideoDetection();
    _controllerReadyCheckTimer?.cancel();
    // Safety check: ensure controller is valid and not already disposed
    if (_videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        !_videoPlayerController!.isDisposed) {
      try {
        _detachControllerListeners();
        _videoPlayerController!.pause();
        widget.videoCacheManager
            .detachedFromWidget(widget.mediaUrl, _videoPlayerController);
      } catch (e) {
        debugPrint('⚠️ VideoPlayerWidget: Error during dispose: $e');
      }
      // Don't dispose controller here - let cache manager handle it
    }
    super.dispose();
  }

  Widget _buildPlayerBody(BuildContext context) =>
      BlocListener<SocialPostBloc, SocialPostState>(
        listenWhen: (previous, current) => current is PlayPauseVideoState,
        listener: (context, state) {
          if (_isDisposed) return; // Safety check: Widget is disposed

          if (state is PlayPauseVideoState) {
            final section = widget.postSectionType;
            if (section != null &&
                !IsrVideoReelConfig.playPauseAppliesToSection(
                  section,
                  state,
                )) {
              return;
            }
            if (!state.pausePlayback) return;
            if (state.play) {
              _isManuallyPaused = false;
              if (widget.visibilityManagedByParent) {
                syncParentVisibility();
                if (_effectiveVisible && mounted) {
                  forceResume();
                } else {
                  _pendingBlocResume = true;
                }
              } else {
                forceResume(activeReel: true);
              }
            } else {
              _pendingBlocResume = false;
              pauseForLifecycle();
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
                  !_videoPlayerController!.isDisposed &&
                  _hasPlayed) ...[
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
                        child: _buildThumbnailWidget(context),
                      );
                    }

                    final size = _videoPlayerController!.videoSize;
                    final hasValidSize = size.width > 0 && size.height > 0;

                    // If video size is valid, use FittedBox for proper scaling
                    // Portrait (h > w) -> fill screen; square/landscape (h <= w) -> fit screen
                    if (hasValidSize) {
                      final aspect = _videoPlayerController!.aspectRatio;
                      final videoFit = _resolveDisplayFit(videoSize: size);
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
                          child:
                              _videoPlayerController!.buildVideoPlayerWidget(),
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
                      _buildThumbnailWidget(context),
                      // Show loading indicator when initializing
                      if (_isInitializing ||
                          (_effectiveVisible && !_isInitialized))
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
      );

  @override
  Widget build(BuildContext context) {
    final body = _buildPlayerBody(context);
    if (widget.visibilityManagedByParent) {
      return body;
    }
    return VisibilityDetector(
      key: Key('video_player_${widget.mediaUrl}'),
      onVisibilityChanged: _handleVisibilityChanged,
      child: body,
    );
  }

  Widget _buildThumbnailWidget(BuildContext context) {
    final fit = _resolveDisplayFit(
      videoSize: _videoPlayerController?.isInitialized == true
          ? _videoPlayerController!.videoSize
          : null,
    );
    if (fit == BoxFit.cover) {
      return SizedBox.expand(
        child: _getImageWidget(
          imageUrl: widget.thumbnailUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
          showError: false,
        ),
      );
    }

    return Center(
      child: _getImageWidget(
        imageUrl: widget.thumbnailUrl,
        width: IsrDimens.getScreenWidth(context),
        height: IsrDimens.getScreenHeight(context),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        showError: false,
      ),
    );
  }

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
