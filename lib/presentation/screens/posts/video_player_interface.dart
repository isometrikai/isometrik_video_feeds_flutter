import 'dart:async';

import 'package:flutter/material.dart';

/// Abstract interface for video player controllers
abstract class IVideoPlayerController {
  /// Initialize the video controller
  Future<void> initialize();

  /// Set looping state
  Future<void> setLooping(bool looping);

  /// Set volume level
  Future<void> setVolume(double volume);

  /// Set playback speed (e.g. 1.0, 1.5, 2.0)
  Future<void> setPlaybackSpeed(double speed);

  /// Play the video
  Future<void> play();

  /// Pause the video
  Future<void> pause();

  /// Seek to a specific position
  Future<void> seekTo(Duration position);

  /// Get current position
  Duration get position;

  /// Get video duration
  Duration get duration;

  /// Check if video is playing
  bool get isPlaying;

  /// Check if video is buffering
  bool get isBuffering;

  /// Force resume playback if stuck (only for visible videos)
  Future<void> forceResume();

  /// Check if video is initialized
  bool get isInitialized;

  /// Check if the controller has been disposed
  bool get isDisposed;

  /// Get video value notifier
  ValueNotifier<bool> get playingStateNotifier;

  /// Get video size
  Size get videoSize;

  /// Get video aspect ratio
  double get aspectRatio;

  /// Build the video player widget
  Widget buildVideoPlayerWidget();

  /// Dispose the controller
  Future<void> dispose();

  /// Add listener
  void addListener(VoidCallback listener);

  /// Remove listener
  void removeListener(VoidCallback listener);
}

/// Abstract interface for video player cache management
abstract class IVideoCacheManager {
  /// Precache videos for given URLs
  Future<void> precacheVideos(List<String> videoUrls,
      {bool highPriority = false});

  /// Get cached video controller
  IVideoPlayerController? getCachedController(String url);

  Future<IVideoPlayerController?> precacheMediaAndReturnController(String url);

  /// Mark video as visible (prevents disposal)
  void markAsVisible(String url);

  /// Mark video as not visible (allows disposal)
  void markAsNotVisible(String url);

  /// Widget started owning [controller] (increments attach count).
  ///
  /// Eviction must not dispose while attach count > 0.
  void attachedToWidget(String url, IVideoPlayerController? controller);

  /// Widget released [controller] (decrements attach count).
  ///
  /// When attach count reaches 0, backends may schedule native dispose
  /// only after the platform video view Element has unmounted.
  void detachedFromWidget(String url, IVideoPlayerController? controller);

  /// Check if video is cached and ready
  bool isVideoCached(String url);

  /// Check if video is initializing
  bool isVideoInitializing(String url);

  /// Clear specific video from cache
  void clearVideo(String url);

  /// Clear all video controllers
  void clearControllers();

  /// Get cache statistics
  Map<String, dynamic> getCacheStats();
}
