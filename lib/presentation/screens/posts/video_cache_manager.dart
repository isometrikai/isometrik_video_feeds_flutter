import 'dart:async';

import 'package:ism_video_reel_player/presentation/presentation.dart';

class VideoCacheManager implements IMediaCacheManager {
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

  @override
  Future<void> precacheMedia(List<String> mediaUrls,
          {bool highPriority = false}) =>
      _cacheManager.precacheVideos(mediaUrls, highPriority: highPriority);

  @override
  dynamic getCachedMedia(String url) => _cacheManager.getCachedController(url);

  @override
  void markAsVisible(String url) => _cacheManager.markAsVisible(url);

  @override
  void markAsNotVisible(String url) => _cacheManager.markAsNotVisible(url);

  @override
  bool isMediaCached(String url) => _cacheManager.isVideoCached(url);

  @override
  bool isMediaInitializing(String url) =>
      _cacheManager.isVideoInitializing(url);

  @override
  void clearMedia(String url) => _cacheManager.clearVideo(url);

  @override
  void clearCache() => _cacheManager.clearControllers();

  @override
  void clearOutsideRange(List<String> activeUrls) =>
      _cacheManager.clearControllersOutsideRange(activeUrls);

  @override
  Map<String, dynamic> getCacheStats() => _cacheManager.getCacheStats();
}
