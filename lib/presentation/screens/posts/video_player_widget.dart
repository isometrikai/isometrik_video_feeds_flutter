import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/data/data.dart';
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

  // RACE CONDITION FIX: Track play/pause operations to prevent overlapping calls
  bool _isPlayOperationInProgress = false;
  bool _isPauseOperationInProgress = false;
  Completer<void>? _pendingPlayOperation;
  Completer<void>? _pendingPauseOperation;

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

  @override
  void initState() {
    super.initState();
    // OPTIMIZATION: Configure VisibilityDetector for faster updates
    _configureVisibilityDetector();
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
        debugPrint(
            '🎬 VideoPlayerWidget: Video started playing, updating UI...');
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
    _controllerReadyCheckTimer =
        Timer.periodic(const Duration(milliseconds: 200), (_) {
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

    // FLICKERING FIX: Check retry limit first
    if (_initializationRetryCount >= _maxInitializationRetries) {
      debugPrint(
          '⚠️ VideoPlayerWidget: Max initialization retries reached, stopping retries');
      _updateLoadingIndicator(false);
      return;
    }

    // FLICKERING FIX: Prevent too frequent retry attempts with exponential backoff
    final now = DateTime.now();
    if (_lastInitializationAttempt != null && _initializationRetryCount > 0) {
      final timeSinceLastAttempt = now.difference(_lastInitializationAttempt!);
      // Use current retry count for delay calculation (before increment)
      final requiredDelay =
          _getRetryDelay(retryCount: _initializationRetryCount);
      if (timeSinceLastAttempt < requiredDelay) {
        final remainingSeconds =
            (requiredDelay - timeSinceLastAttempt).inSeconds;
        debugPrint(
            '⏸️ VideoPlayerWidget: Skipping retry - need to wait ${remainingSeconds}s more (attempt $_initializationRetryCount)');
        return;
      }
    }

    _isInitializing = true;

    // FLICKERING FIX: Increment retry count (starts at 0, so first attempt is 1)
    if (_lastInitializationAttempt == null) {
      _initializationRetryCount = 1; // First attempt
    } else {
      _initializationRetryCount++; // Subsequent retry
    }

    _lastInitializationAttempt = now;

    // FLICKERING FIX: Debounce loading indicator update
    _updateLoadingIndicator(true);

    try {
      // OPTIMIZATION: Try to get already cached and initialized controller first
      _videoPlayerController = widget.videoCacheManager
          .getCachedMedia(widget.mediaUrl) as IVideoPlayerController?;

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
        _initializationRetryCount = 0; // Reset on success
        _updateLoadingIndicator(false);
        return; // Early return - no need to initialize again
      }

      // OPTIMIZATION: If no cached controller, trigger precaching ONCE
      // Use video cache manager directly to avoid media type detection issues
      if (_videoPlayerController == null) {
        debugPrint(
            '🔄 VideoPlayerWidget: Precaching video for: ${widget.mediaUrl}');
        // Use video cache manager directly (bypasses MediaTypeUtil)
        await widget.videoCacheManager
            .precacheMedia([widget.mediaUrl], highPriority: true);
        _videoPlayerController = widget.videoCacheManager
            .getCachedMedia(widget.mediaUrl) as IVideoPlayerController?;
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
        _initializationRetryCount = 0; // Reset on success
        _updateLoadingIndicator(false);
      } else {
        debugPrint(
            '⚠️ VideoPlayerWidget: Failed to initialize video: ${widget.mediaUrl} (attempt $_initializationRetryCount/$_maxInitializationRetries)');
        // FLICKERING FIX: Only retry if under limit and visible with exponential backoff
        if (_isVisible &&
            mounted &&
            _initializationRetryCount < _maxInitializationRetries) {
          // Use current retry count (already incremented) for delay calculation
          final retryDelay =
              _getRetryDelay(retryCount: _initializationRetryCount);
          debugPrint(
              '🔄 VideoPlayerWidget: Scheduling retry for visible video in ${retryDelay.inSeconds}s... (attempt $_initializationRetryCount/$_maxInitializationRetries)');
          Future.delayed(retryDelay, () {
            if (!_isDisposed && _isVisible && !_isInitialized) {
              _isInitializing = false;
              _initializeVideoPlayer();
            }
          });
        } else {
          _updateLoadingIndicator(false);
        }
      }
    } catch (e) {
      debugPrint('❌ VideoPlayerWidget: Error initializing video: $e');
      // FLICKERING FIX: Only retry if under limit and visible with exponential backoff
      if (_isVisible &&
          mounted &&
          _initializationRetryCount < _maxInitializationRetries) {
        // Use current retry count (already incremented) for delay calculation
        final retryDelay =
            _getRetryDelay(retryCount: _initializationRetryCount);
        debugPrint(
            '🔄 VideoPlayerWidget: Scheduling retry after error in ${retryDelay.inSeconds}s... (attempt $_initializationRetryCount/$_maxInitializationRetries)');
        Future.delayed(retryDelay, () {
          if (!_isDisposed && _isVisible && !_isInitialized) {
            _isInitializing = false;
            _initializeVideoPlayer();
          }
        });
      } else {
        _updateLoadingIndicator(false);
      }
    } finally {
      _isInitializing = false;
    }
  }

  /// FLICKERING FIX: Debounce loading indicator updates to prevent flickering
  void _updateLoadingIndicator(bool show) {
    _loadingIndicatorDebounceTimer?.cancel();

    if (show) {
      // Show after a small delay to prevent flickering on quick success
      _loadingIndicatorDebounceTimer =
          Timer(const Duration(milliseconds: 500), () {
        if (!_showLoadingIndicator && mounted && !_isInitialized) {
          setState(() {
            _showLoadingIndicator = true;
          });
        }
      });
    } else {
      // Hide after a delay to prevent flickering
      _loadingIndicatorDebounceTimer =
          Timer(const Duration(milliseconds: 500), () {
        if (_showLoadingIndicator && mounted) {
          setState(() {
            _showLoadingIndicator = false;
          });
        }
      });
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
      _hasCompleted = false;
      _isManuallyPaused = false;
      _hasLoggedWatchEvent = false;
      _maxWatchPosition = Duration.zero;
      _hasLoggedVideoStarted = false;
      _loggedProgressMilestones.clear();
      _isAtVideoEnd = false;
      _hasPlaybackError = false;
      _timeoutRecoveryAttempts = 0;
      _isSeekingToStart = false;
      _initializationRetryCount = 0;
      _lastInitializationAttempt = null;
      _updateLoadingIndicator(false);

      // Add listener for video completion and playback progress
      _videoPlayerController!.addListener(_handlePlaybackProgress);

      // Listen to playing state changes to update UI
      _videoPlayerController!.playingStateNotifier
          .addListener(_onPlayingStateChanged);

      // TIMEOUT FIX: Monitor for playback errors and timeouts
      _startPlaybackErrorMonitoring();

      // OPTIMIZATION: Run setup operations in parallel for faster playback start
      await Future.wait([
        _videoPlayerController!.setLooping(true),
        _videoPlayerController!.setVolume(widget.isMuted ? 0.0 : 1.0),
      ]);

      // If widget is visible when initialized, start playing immediately
      if (_isVisible && !widget.isPreloaded) {
        // RACE CONDITION FIX: Use proper play control instead of direct play
        // This ensures other videos are paused first
        unawaited(_performPlayPauseControl());
      } else {
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

    // STUCK VIDEO DETECTION: Detect if video frame is stuck (audio playing but video not updating)
    // Also detect timeout/stall during playback - IMPROVED DETECTION
    if (_videoPlayerController!.isPlaying &&
        _isVisible &&
        duration.inMilliseconds > 0 &&
        !_isAtVideoEnd) {
      // Check if video position is updating
      if (_lastVideoPosition != null) {
        final positionDiff =
            (position.inMilliseconds - _lastVideoPosition!.inMilliseconds)
                .abs();

        // STUCK VIDEO FIX: More aggressive detection - check if position hasn't changed for multiple callbacks
        // Also check if video is at start and not progressing (common stuck scenario)
        final isAtStart = position.inMilliseconds < 500;
        final isStuckAtStart =
            isAtStart && _stuckFrameCount >= 3; // Faster detection at start

        // If position hasn't changed significantly (less than 100ms) for multiple checks, video might be stuck
        if (positionDiff < 100) {
          _stuckFrameCount++;

          // Also check if video size is invalid (0x0) which indicates video isn't rendering
          final videoSize = _videoPlayerController!.videoSize;
          final hasInvalidSize = videoSize.width == 0 || videoSize.height == 0;

          // Check if video is buffering (potential timeout)
          final isBuffering = _videoPlayerController!.isBuffering;

          // STUCK VIDEO FIX: More aggressive detection - trigger recovery sooner
          if (_stuckFrameCount >= _maxStuckFrameCount ||
              hasInvalidSize ||
              isStuckAtStart ||
              (isBuffering && _stuckFrameCount >= 5)) {
            // Faster detection for buffering
            debugPrint(
                '⚠️ VideoPlayerWidget: Detected stuck video - Position stuck: ${_stuckFrameCount >= _maxStuckFrameCount}, Invalid size: $hasInvalidSize, Buffering: $isBuffering, Stuck at start: $isStuckAtStart, Size: $videoSize, Pos: ${position.inMilliseconds}ms');

            // Prioritize recovery based on issue type
            if (hasInvalidSize) {
              // Audio-only playback - recover frame
              _recoverStuckVideoFrame();
            } else if (isStuckAtStart ||
                (isBuffering && _stuckFrameCount >= 5)) {
              // Stuck at start or buffering - recover from timeout immediately
              if (!_hasPlaybackError) {
                _hasPlaybackError = true;
                _recoverFromPlaybackTimeout();
              }
            } else if (_stuckFrameCount >= _maxStuckFrameCount) {
              // General stuck frame - recover
              _recoverStuckVideoFrame();
            }

            _stuckFrameCount = 0; // Reset counter
          }
        } else {
          // Video position is updating - reset counter
          _stuckFrameCount = 0;
          _lastVideoPosition = position;
        }
      } else {
        // First position update - store it
        _lastVideoPosition = position;
      }
    } else {
      // Not playing or not visible or at end - reset tracking
      _stuckFrameCount = 0;
      if (!_isAtVideoEnd) {
        _lastVideoPosition = null;
      }
    }

    // OPTIMIZATION: Throttle progress callbacks to every 200ms for smoother UI
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastProgressCallbackTime >= 200) {
      _lastProgressCallbackTime = now;
      widget.videoProgressCallBack
          ?.call(duration.inMilliseconds, position.inMilliseconds);
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

    // TIMEOUT FIX: Detect if video stops playing mid-stream (timeout/error)
    // This is handled in the stuck video detection above, but we also check here for timeout-specific cases
    if (_videoPlayerController!.isPlaying &&
        _isVisible &&
        duration.inMilliseconds > 0 &&
        !_isAtVideoEnd) {
      // Check if video position is advancing
      if (_lastVideoPosition != null) {
        final positionDiff =
            (position.inMilliseconds - _lastVideoPosition!.inMilliseconds)
                .abs();
        final timeSinceLastUpdate = DateTime.now().millisecondsSinceEpoch -
            (_lastProgressCallbackTime > 0
                ? _lastProgressCallbackTime
                : DateTime.now().millisecondsSinceEpoch);

        // If position hasn't changed for more than 2 seconds and video should be playing, it might be timed out
        if (positionDiff < 100 && timeSinceLastUpdate > 2000) {
          if (!_hasPlaybackError) {
            _hasPlaybackError = true;
            debugPrint(
                '⚠️ VideoPlayerWidget: Detected playback timeout/stall - position not advancing');
            _recoverFromPlaybackTimeout();
          }
        } else if (positionDiff >= 100) {
          // Position is advancing - reset error flags
          if (_hasPlaybackError) {
            _hasPlaybackError = false;
            _timeoutRecoveryAttempts = 0;
            debugPrint(
                '✅ VideoPlayerWidget: Playback recovered, position advancing');
          }
        }
      }
    }

    // 3. Check if video has completed (with small threshold to account for timing)
    if (duration.inMilliseconds > 0 &&
        position.inMilliseconds >= duration.inMilliseconds - 100 &&
        !_hasCompleted) {
      _hasCompleted = true;
      _isAtVideoEnd = true;

      // LOOPING FIX: Call onVideoCompleted callback
      // The callback will handle whether to move to next video or let it loop
      // based on autoMoveNextMedia configuration
      widget.onVideoCompleted?.call();

      // Log watch event when video completes
      // _logWatchEventIfNeeded();
    }

    // LOOPING FIX: Detect when video loops back to start and reset completion flag
    // This allows the video to loop continuously without getting stuck
    if (_hasCompleted &&
        duration.inMilliseconds > 0 &&
        position.inMilliseconds < 500) {
      // Reset when back near start (500ms threshold)
      // Video has looped back to start - reset completion flag so it can complete again
      _hasCompleted = false;
      _isAtVideoEnd = false;
      _maxWatchPosition =
          Duration.zero; // Reset max watch position for next loop
      _hasLoggedVideoStarted = false; // Reset so we can log start event again
      _loggedProgressMilestones.clear(); // Reset milestones for next loop
      debugPrint('🔄 Video looped back to start, resetting completion flag');
    }

    // LOOPING FIX: If video reaches end and looping is enabled but hasn't looped yet,
    // manually seek to start to ensure looping works
    if (duration.inMilliseconds > 0 &&
        position.inMilliseconds >= duration.inMilliseconds - 50 &&
        _hasCompleted &&
        _isAtVideoEnd &&
        !_isSeekingToStart) {
      // Check if we should loop (no completion callback means infinite loop)
      final shouldLoop = widget.onVideoCompleted == null;

      if (shouldLoop) {
        // Video reached end but hasn't looped - manually seek to start
        _isSeekingToStart = true;
        Future.delayed(const Duration(milliseconds: 200), () async {
          if (!_isDisposed &&
              _videoPlayerController != null &&
              _videoPlayerController!.isInitialized &&
              !_videoPlayerController!.isDisposed) {
            final currentPos = _videoPlayerController!.position;
            final currentDuration = _videoPlayerController!.duration;

            // Double check we're still at the end
            if (currentDuration.inMilliseconds > 0 &&
                currentPos.inMilliseconds >=
                    currentDuration.inMilliseconds - 100) {
              // Still at end - seek to start to force loop
              try {
                await _videoPlayerController!.pause();
                await Future.delayed(const Duration(milliseconds: 50));
                await _videoPlayerController!.seekTo(Duration.zero);
                _hasCompleted = false;
                _isAtVideoEnd = false;
                _maxWatchPosition = Duration.zero;
                _hasLoggedVideoStarted = false;
                _loggedProgressMilestones.clear();

                await Future.delayed(const Duration(milliseconds: 50));
                if (!_isDisposed && _isVisible && !_isManuallyPaused) {
                  await _videoPlayerController!.play();
                }
                debugPrint('🔄 Manually seeking video to start for looping');
              } catch (e) {
                debugPrint('❌ Error seeking to start: $e');
              } finally {
                _isSeekingToStart = false;
              }
            } else {
              // Video has already looped or moved
              _isSeekingToStart = false;
            }
          } else {
            _isSeekingToStart = false;
          }
        });
      }
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
    // OPTIMIZATION: Lower threshold (0.5) for earlier video start like Instagram
    _isVisible = info.visibleFraction > 0.5;

    // Only notify if visibility state actually changed
    if (wasVisible != _isVisible) {
      widget.onVisibilityChanged(_isVisible);
    }

    // STUCK VIDEO FIX: Reset recovery state when scrolling back to video
    if (!wasVisible && _isVisible) {
      // Video became visible again - reset all recovery states
      debugPrint(
          '🔄 VideoPlayerWidget: Video became visible again, resetting recovery state');
      _hasPlaybackError = false;
      _timeoutRecoveryAttempts = 0;
      _stuckFrameCount = 0;
      _lastVideoPosition = null;
      _isAtVideoEnd = false;
      _isSeekingToStart = false;
      // Reset retry count when scrolling back (give it a fresh chance)
      _initializationRetryCount = 0;
      _lastInitializationAttempt = null;
    }

    // RACE CONDITION FIX: Use debounced play/pause to prevent overlapping operations
    if (_isVisible != wasVisible) {
      _debouncedPlayPauseControl();
    }
  }

  // RACE CONDITION FIX: Debounced play/pause control to prevent race conditions
  Timer? _playPauseDebounceTimer;
  void _debouncedPlayPauseControl() {
    _playPauseDebounceTimer?.cancel();
    _playPauseDebounceTimer =
        Timer(const Duration(milliseconds: 50), _performPlayPauseControl);
  }

  /// Perform play/pause control with race condition protection
  Future<void> _performPlayPauseControl() async {
    if (_isDisposed) return;

    // Safety check: ensure controller is valid and not disposed
    if (_videoPlayerController == null ||
        !_videoPlayerController!.isInitialized ||
        _videoPlayerController!.isDisposed) {
      // If visible but not initialized, start initialization
      if (_isVisible && !_isInitializing && !_isInitialized) {
        debugPrint(
            '🔄 VideoPlayerWidget: Visible but not initialized, starting initialization...');
        _isDisposed = false;
        _initializeVideoPlayer();
      }
      return;
    }

    try {
      // RACE CONDITION FIX: Check if we need to play
      if (_isVisible &&
          !_videoPlayerController!.isPlaying &&
          !_isManuallyPaused &&
          !widget.isPreloaded) {
        // Cancel any pending pause operation
        if (_isPauseOperationInProgress) {
          _pendingPauseOperation?.complete();
          _isPauseOperationInProgress = false;
        }

        // Wait for any pending play operation to complete
        if (_isPlayOperationInProgress && _pendingPlayOperation != null) {
          await _pendingPlayOperation!.future;
        }

        // Mark play operation in progress
        _isPlayOperationInProgress = true;
        _pendingPlayOperation = Completer<void>();

        try {
          // CRITICAL: Pause all other videos first to prevent sound overlap
          // This ensures only one video plays at a time
          await widget.videoCacheManager.pauseAllExcept(widget.mediaUrl);
          widget.videoCacheManager.markAsVisible(widget.mediaUrl);

          // Ensure volume is set correctly before playing
          await _videoPlayerController!.setVolume(widget.isMuted ? 0.0 : 1.0);

          // Play the video
          await _videoPlayerController!.play();

          // STUCK VIDEO FIX: Reset recovery state before starting monitoring
          _hasPlaybackError = false;
          _timeoutRecoveryAttempts = 0;
          _stuckFrameCount = 0;
          _lastVideoPosition = null;

          // Start stuck video detection for visible video
          _startStuckVideoDetection();
          // Start playback error monitoring
          _startPlaybackErrorMonitoring();
        } finally {
          _isPlayOperationInProgress = false;
          _pendingPlayOperation?.complete();
          _pendingPlayOperation = null;
        }
      }
      // RACE CONDITION FIX: Check if we need to pause
      else if (!_isVisible && _videoPlayerController!.isPlaying) {
        // Cancel any pending play operation
        if (_isPlayOperationInProgress) {
          _pendingPlayOperation?.complete();
          _isPlayOperationInProgress = false;
        }

        // Wait for any pending pause operation to complete
        if (_isPauseOperationInProgress && _pendingPauseOperation != null) {
          await _pendingPauseOperation!.future;
        }

        // Mark pause operation in progress
        _isPauseOperationInProgress = true;
        _pendingPauseOperation = Completer<void>();

        try {
          // Pause the video
          await _videoPlayerController!.pause();

          // Mark as not visible
          widget.videoCacheManager.markAsNotVisible(widget.mediaUrl);

          // Stop stuck video detection when not visible
          _stopStuckVideoDetection();
          _stopPlaybackErrorMonitoring();
        } finally {
          _isPauseOperationInProgress = false;
          _pendingPauseOperation?.complete();
          _pendingPauseOperation = null;
        }
      }
    } catch (e) {
      debugPrint('⚠️ VideoPlayerWidget: Error in play/pause control: $e');
      // Reset flags on error
      _isPlayOperationInProgress = false;
      _isPauseOperationInProgress = false;
      _pendingPlayOperation?.complete();
      _pendingPauseOperation?.complete();
    }
  }

  // Track recovery attempts
  int _recoveryAttempts = 0;
  static const int _maxRecoveryAttempts = 5;

  // Track video frame updates to detect stuck video
  Duration? _lastVideoPosition;
  int _stuckFrameCount = 0;
  static const int _maxStuckFrameCount = 10; // ~5 seconds at 500ms intervals

  // LOOPING FIX: Track if we're currently seeking to start
  bool _isSeekingToStart = false;

  // TIMEOUT FIX: Track playback errors and timeout recovery
  bool _hasPlaybackError = false;
  int _timeoutRecoveryAttempts = 0;
  static const int _maxTimeoutRecoveryAttempts = 3;
  Timer? _playbackErrorTimer;

  // LOOPING FIX: Track if video is at end and should loop
  bool _isAtVideoEnd = false;

  // FLICKERING FIX: Track initialization retry attempts to prevent infinite retries
  int _initializationRetryCount = 0;
  static const int _maxInitializationRetries = 3;
  DateTime? _lastInitializationAttempt;

  // LOADING INDICATOR FIX: Track loading state to prevent flickering
  bool _showLoadingIndicator = false;
  Timer? _loadingIndicatorDebounceTimer;

  // RETRY LOGIC FIX: Calculate exponential backoff delay
  Duration _getRetryDelay({int? retryCount}) {
    // Start at 3 seconds, increase by 2 seconds for each retry
    // Retry 1: 3s, Retry 2: 5s, Retry 3: 7s
    final baseDelay = 3;
    final count = retryCount ?? _initializationRetryCount;
    final additionalDelay = count * 2;
    return Duration(seconds: baseDelay + additionalDelay);
  }

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
      // Check if video is playing but frame is stuck (audio-only playback)
      final videoSize = _videoPlayerController!.videoSize;
      final hasInvalidSize = videoSize.width == 0 || videoSize.height == 0;

      // If video is visible but not playing, try to recover
      if (!_videoPlayerController!.isPlaying) {
        _recoveryAttempts++;
        debugPrint(
            '🔄 Detected stuck video (not playing), recovery attempt $_recoveryAttempts/$_maxRecoveryAttempts...');

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
      }
      // STUCK FRAME DETECTION: Check if video is playing but frame is invalid (audio-only)
      else if (_videoPlayerController!.isPlaying &&
          hasInvalidSize &&
          _isInitialized) {
        _recoveryAttempts++;
        debugPrint(
            '🔄 Detected stuck video frame (audio playing but video not rendering), recovery attempt $_recoveryAttempts/$_maxRecoveryAttempts...');

        // Try to recover stuck frame
        unawaited(_recoverStuckVideoFrame());

        // If too many recovery attempts, try re-initializing the video
        if (_recoveryAttempts >= _maxRecoveryAttempts) {
          debugPrint(
              '⚠️ Max recovery attempts reached for stuck frame, re-initializing video...');
          _stopStuckVideoDetection();
          _reinitializeVideo();
        }
      } else {
        // Video is playing and rendering correctly, stop the detection timer
        if (_recoveryAttempts > 0) {
          debugPrint(
              '✅ Video started playing correctly after $_recoveryAttempts attempts');
        }
        _recoveryAttempts = 0; // Reset recovery attempts
        _stopStuckVideoDetection();
      }
    } else if (!_isInitializing && _isVisible) {
      // Controller is not ready but video is visible - try to initialize
      debugPrint('🔄 Controller not ready, reinitializing...');
      _reinitializeVideo();
    }
  }

  /// Recover from stuck video frame (audio playing but video not updating)
  Future<void> _recoverStuckVideoFrame() async {
    if (_isDisposed || !_isVisible || _videoPlayerController == null) return;

    debugPrint(
        '🔄 VideoPlayerWidget: Attempting to recover stuck video frame...');

    try {
      // Method 1: Try seeking to current position to force video refresh
      final currentPos = _videoPlayerController!.position;
      await _videoPlayerController!.seekTo(currentPos);
      await Future.delayed(const Duration(milliseconds: 100));

      // Check if video is still stuck after seek
      if (_videoPlayerController!.isPlaying &&
          _videoPlayerController!.position == currentPos) {
        // Still stuck - try pause and play
        debugPrint(
            '🔄 VideoPlayerWidget: Seek didn\'t help, trying pause/play...');
        await _videoPlayerController!.pause();
        await Future.delayed(const Duration(milliseconds: 50));
        await _videoPlayerController!.play();

        // If still stuck after pause/play, reinitialize
        await Future.delayed(const Duration(milliseconds: 500));
        if (_videoPlayerController!.isPlaying &&
            _videoPlayerController!.position == currentPos) {
          debugPrint(
              '🔄 VideoPlayerWidget: Pause/play didn\'t help, reinitializing...');
          await _reinitializeVideo();
        }
      }
    } catch (e) {
      debugPrint('❌ VideoPlayerWidget: Error recovering stuck video frame: $e');
      // Fallback to reinitialization
      await _reinitializeVideo();
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
    _hasValidVideoSize = false;
    _stuckFrameCount = 0;
    _lastVideoPosition = null;
    _hasPlaybackError = false;
    _timeoutRecoveryAttempts = 0;
    _isAtVideoEnd = false;
    _isSeekingToStart = false;
    _initializationRetryCount = 0; // Reset retry count when reinitializing
    _lastInitializationAttempt = null;
    _updateLoadingIndicator(false);

    // Small delay before reinitializing
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_isDisposed && _isVisible) {
      await _initializeVideoPlayer();
    }
  }

  // Public methods to control playback with race condition protection
  Future<void> pause() async {
    if (_isDisposed) return; // Safety check: Don't operate on disposed widget

    // RACE CONDITION FIX: Wait for any pending operations
    if (_isPlayOperationInProgress && _pendingPlayOperation != null) {
      await _pendingPlayOperation!.future;
    }

    // Safety check: ensure controller is valid and not disposed
    if (_videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        !_videoPlayerController!.isDisposed &&
        _videoPlayerController!.isPlaying) {
      _isManuallyPaused = true;

      // Mark pause operation in progress
      _isPauseOperationInProgress = true;
      _pendingPauseOperation = Completer<void>();

      try {
        await _videoPlayerController!.pause();
        widget.videoCacheManager.markAsNotVisible(widget.mediaUrl);
        _logVideoStartedEvent();
      } finally {
        _isPauseOperationInProgress = false;
        _pendingPauseOperation?.complete();
        _pendingPauseOperation = null;
      }
    }
  }

  Future<void> play() async {
    if (_isDisposed) return; // Safety check: Don't operate on disposed widget

    // RACE CONDITION FIX: Wait for any pending operations
    if (_isPauseOperationInProgress && _pendingPauseOperation != null) {
      await _pendingPauseOperation!.future;
    }

    // Safety check: ensure controller is valid and not disposed
    if (_videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        !_videoPlayerController!.isDisposed &&
        !_videoPlayerController!.isPlaying) {
      _isManuallyPaused = false;

      // Only play if visible
      if (_isVisible && !widget.isPreloaded) {
        // Mark play operation in progress
        _isPlayOperationInProgress = true;
        _pendingPlayOperation = Completer<void>();

        try {
          // CRITICAL: Pause all other videos first to prevent sound overlap
          await widget.videoCacheManager.pauseAllExcept(widget.mediaUrl);
          widget.videoCacheManager.markAsVisible(widget.mediaUrl);
          await _videoPlayerController!.setVolume(widget.isMuted ? 0.0 : 1.0);
          await _videoPlayerController!.play();

          // STUCK VIDEO FIX: Reset recovery state before starting monitoring
          _hasPlaybackError = false;
          _timeoutRecoveryAttempts = 0;
          _stuckFrameCount = 0;
          _lastVideoPosition = null;

          _startStuckVideoDetection();
          _startPlaybackErrorMonitoring();
          _logVideoStartedEvent();
        } finally {
          _isPlayOperationInProgress = false;
          _pendingPlayOperation?.complete();
          _pendingPlayOperation = null;
        }
      }
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
      _initializationRetryCount = 0; // Reset retry count for new video
      _lastInitializationAttempt = null;
      _initializeVideoPlayer();
    }
  }

  /// Start monitoring for playback errors and timeouts
  void _startPlaybackErrorMonitoring() {
    _playbackErrorTimer?.cancel();
    _playbackErrorTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_isDisposed || !_isVisible) {
        _playbackErrorTimer?.cancel();
        return;
      }

      if (_videoPlayerController != null &&
          _videoPlayerController!.isInitialized &&
          !_videoPlayerController!.isDisposed &&
          _videoPlayerController!.isPlaying &&
          !_isManuallyPaused) {
        // Check if video is buffering for too long (potential timeout)
        if (_videoPlayerController!.isBuffering) {
          _hasPlaybackError = true;
          debugPrint(
              '⚠️ VideoPlayerWidget: Video buffering detected, may be timed out');
        }
      }
    });
  }

  /// Stop playback error monitoring
  void _stopPlaybackErrorMonitoring() {
    _playbackErrorTimer?.cancel();
    _playbackErrorTimer = null;
  }

  /// Recover from playback timeout
  Future<void> _recoverFromPlaybackTimeout() async {
    if (_isDisposed ||
        !_isVisible ||
        _timeoutRecoveryAttempts >= _maxTimeoutRecoveryAttempts) {
      return;
    }

    _timeoutRecoveryAttempts++;
    debugPrint(
        '🔄 VideoPlayerWidget: Recovering from playback timeout (attempt $_timeoutRecoveryAttempts/$_maxTimeoutRecoveryAttempts)');

    try {
      if (_videoPlayerController != null &&
          _videoPlayerController!.isInitialized &&
          !_videoPlayerController!.isDisposed) {
        // Method 1: Try seeking slightly back to restart playback
        final currentPos = _videoPlayerController!.position;
        final seekBackPos = Duration(
          milliseconds: (currentPos.inMilliseconds - 500)
              .clamp(0, currentPos.inMilliseconds),
        );

        await _videoPlayerController!.pause();
        await Future.delayed(const Duration(milliseconds: 100));
        await _videoPlayerController!.seekTo(seekBackPos);
        await Future.delayed(const Duration(milliseconds: 100));
        await _videoPlayerController!.play();

        // Check if recovery worked after delay
        await Future.delayed(const Duration(milliseconds: 1000));
        if (_videoPlayerController!.isPlaying &&
            _videoPlayerController!.position.inMilliseconds >
                seekBackPos.inMilliseconds) {
          debugPrint(
              '✅ VideoPlayerWidget: Playback timeout recovered successfully');
          _hasPlaybackError = false;
          _timeoutRecoveryAttempts = 0;
          return;
        }

        // Method 2: If seek didn't work, try reinitializing
        if (_timeoutRecoveryAttempts >= _maxTimeoutRecoveryAttempts) {
          debugPrint(
              '⚠️ VideoPlayerWidget: Max timeout recovery attempts reached, reinitializing...');
          await _reinitializeVideo();
        }
      }
    } catch (e) {
      debugPrint('❌ VideoPlayerWidget: Error recovering from timeout: $e');
      if (_timeoutRecoveryAttempts >= _maxTimeoutRecoveryAttempts) {
        await _reinitializeVideo();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Cancel timers
    _stopStuckVideoDetection();
    _stopPlaybackErrorMonitoring();
    _controllerReadyCheckTimer?.cancel();
    _playPauseDebounceTimer?.cancel();
    _loadingIndicatorDebounceTimer?.cancel();

    // Complete any pending operations
    _pendingPlayOperation?.complete();
    _pendingPauseOperation?.complete();
    // Log watch event when widget is disposed (user navigates away)
    _logWatchEventIfNeeded();
    // Safety check: ensure controller is valid and not already disposed
    if (_videoPlayerController != null &&
        _videoPlayerController!.isInitialized &&
        !_videoPlayerController!.isDisposed) {
      try {
        _videoPlayerController!.removeListener(_handlePlaybackProgress);
        _videoPlayerController!.playingStateNotifier
            .removeListener(_onPlayingStateChanged);
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
                if (_isVisible &&
                    mounted &&
                    _isManuallyPaused &&
                    !widget.isPreloaded) {
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

                    // STUCK FRAME FIX: If video is playing but size is invalid, show thumbnail
                    // This handles the case where audio plays but video frame is stuck
                    if (_videoPlayerController!.isPlaying &&
                        !hasValidSize &&
                        _isInitialized) {
                      debugPrint(
                          '⚠️ VideoPlayerWidget: Video playing but invalid size detected, showing thumbnail');
                      // Trigger recovery in background
                      unawaited(_recoverStuckVideoFrame());
                      // Show thumbnail while recovering
                      return Container(
                        color: Colors.black,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Center(
                              child: _getImageWidget(
                                imageUrl: widget.thumbnailUrl,
                                width: IsrDimens.getScreenWidth(context),
                                height: IsrDimens.getScreenHeight(context),
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.low,
                                showError: false,
                              ),
                            ),
                            // LOADING INDICATOR FIX: Show small grey progress indicator at bottom while recovering
                            if (_showLoadingIndicator)
                              Positioned(
                                bottom: 20,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.grey,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }

                    // If video size is valid, use FittedBox for proper scaling
                    if (hasValidSize) {
                      final aspect = _videoPlayerController!.aspectRatio;
                      return RepaintBoundary(
                        child: FittedBox(
                          fit: BoxFit.cover,
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
                    // But only if video is not playing (initializing)
                    if (!_videoPlayerController!.isPlaying) {
                      debugPrint(
                          '🎬 VideoPlayerWidget: Using fallback layout (size: $size, not playing)');
                      return SizedBox.expand(
                        child: Container(
                          color: Colors.black,
                          child: RepaintBoundary(
                            child: _videoPlayerController!
                                .buildVideoPlayerWidget(),
                          ),
                        ),
                      );
                    } else {
                      // Video is playing but size is invalid - show thumbnail
                      debugPrint(
                          '⚠️ VideoPlayerWidget: Video playing but size invalid, showing thumbnail');
                      return Container(
                        color: Colors.black,
                        child: Center(
                          child: _getImageWidget(
                            imageUrl: widget.thumbnailUrl,
                            width: IsrDimens.getScreenWidth(context),
                            height: IsrDimens.getScreenHeight(context),
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.low,
                            showError: false,
                          ),
                        ),
                      );
                    }
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
                      // LOADING INDICATOR FIX: Show small grey progress indicator at bottom
                      if (_showLoadingIndicator)
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.grey,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
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
