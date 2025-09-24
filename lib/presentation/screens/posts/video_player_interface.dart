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

  /// Check if video is initialized
  bool get isInitialized;

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
}

/// Abstract interface for video player cache management
abstract class IVideoCacheManager {
  /// Precache videos for given URLs
  Future<void> precacheVideos(List<String> videoUrls,
      {bool highPriority = false});

  /// Get cached video controller
  IVideoPlayerController? getCachedController(String url);

  /// Mark video as visible (prevents disposal)
  void markAsVisible(String url);

  /// Mark video as not visible (allows disposal)
  void markAsNotVisible(String url);

  /// Check if video is cached and ready
  bool isVideoCached(String url);

  /// Check if video is initializing
  bool isVideoInitializing(String url);

  /// Clear specific video from cache
  void clearVideo(String url);

  /// Clear all video controllers
  void clearControllers();

  /// Clear controllers outside given range
  void clearControllersOutsideRange(List<String> activeUrls);

  /// Get cache statistics
  Map<String, dynamic> getCacheStats();
}
