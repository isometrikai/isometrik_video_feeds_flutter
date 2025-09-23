import 'dart:async';

import 'package:ism_video_reel_player/presentation/presentation.dart';

class VideoCacheManager {
  VideoCacheManager._internal() {
    // Initialize with cached video player by default
    _cacheManager = VideoPlayerFactory.create(_currentType);
  }

  factory VideoCacheManager() => _instance;
  VideoPlayerType _currentType = VideoPlayerType.standard;

  static final VideoCacheManager _instance = VideoCacheManager._internal();

  late IVideoCacheManager _cacheManager;

  /// Switch video player type
  void setVideoPlayerType(VideoPlayerType type) {
    if (_currentType != type) {
      _cacheManager.clearControllers();
      _cacheManager = VideoPlayerFactory.create(type);
      _currentType = type;
    }
  }

  /// Get current video player type
  VideoPlayerType get currentPlayerType => _currentType;

  /// Precache video controllers for given URLs
  Future<void> precacheVideos(List<String> videoUrls, {bool highPriority = false}) =>
      _cacheManager.precacheVideos(videoUrls, highPriority: highPriority);

  /// Get cached video controller
  IVideoPlayerController? getCachedController(String url) => _cacheManager.getCachedController(url);

  /// Mark video as visible (prevents disposal)
  void markAsVisible(String url) => _cacheManager.markAsVisible(url);

  /// Mark video as not visible (allows disposal)
  void markAsNotVisible(String url) => _cacheManager.markAsNotVisible(url);

  /// Check if video is cached and ready
  bool isVideoCached(String url) => _cacheManager.isVideoCached(url);

  /// Check if video is initializing
  bool isVideoInitializing(String url) => _cacheManager.isVideoInitializing(url);

  /// Clear specific video from cache
  void clearVideo(String url) => _cacheManager.clearVideo(url);

  /// Clear all video controllers
  void clearControllers() => _cacheManager.clearControllers();

  /// Clear controllers for videos that are outside the given range of URLs
  void clearControllersOutsideRange(List<String> activeUrls) =>
      _cacheManager.clearControllersOutsideRange(activeUrls);

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() => _cacheManager.getCacheStats();
}
