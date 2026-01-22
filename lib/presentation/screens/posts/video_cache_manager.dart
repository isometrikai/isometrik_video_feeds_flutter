import 'dart:async';
import 'dart:io';

import 'package:ism_video_reel_player/presentation/presentation.dart';

class VideoCacheManager implements IMediaCacheManager {
  VideoCacheManager._internal() {
    // Initialize with cached video player by default
    _cacheManager = VideoPlayerFactory.create(_currentType);
  }

  factory VideoCacheManager() => _instance;

  /// Global switch to enable/disable video controller caching.
  ///
  /// When disabled:
  /// - [precacheMedia] becomes a no-op
  /// - [getCachedMedia] always returns `null`
  /// - visibility tracking is ignored
  ///
  /// Playback is still possible, but callers must create and manage their own
  /// controllers (see `VideoPlayerWidget` fallback path).
  static bool _isCachingEnabled = true;

  /// Whether video caching is currently enabled.
  static bool get isCachingEnabled => _isCachingEnabled;

  /// Enables/disables video caching at runtime.
  ///
  /// Disabling will clear existing cached controllers to free resources.
  static void setCachingEnabled(bool enabled) {
    if (_isCachingEnabled == enabled) return;
    _isCachingEnabled = enabled;

    // If caching is turned off, aggressively release resources.
    if (!enabled) {
      try {
        _instance.clearCache();
      } catch (_) {
        // Best-effort cleanup.
      }
    }
  }

  VideoPlayerType _currentType =
      Platform.isAndroid ? VideoPlayerType.standard : VideoPlayerType.mediaKit;

  static final VideoCacheManager _instance = VideoCacheManager._internal();

  late IVideoCacheManager _cacheManager;

  /// Dispose all video players - call this before hot restart to prevent crashes
  /// Only needed for MediaKit player on iOS
  static Future<void> disposeAll() async {
    if (!Platform.isAndroid) {
      await MediaKitCacheManager.disposeAll();
    }
  }

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
      {bool highPriority = false}) {
    if (!_isCachingEnabled) return Future.value();
    return _cacheManager.precacheVideos(mediaUrls, highPriority: highPriority);
  }

  @override
  dynamic getCachedMedia(String url) =>
      _isCachingEnabled ? _cacheManager.getCachedController(url) : null;

  @override
  void markAsVisible(String url) {
    if (!_isCachingEnabled) return;
    _cacheManager.markAsVisible(url);
  }

  @override
  void markAsNotVisible(String url) {
    if (!_isCachingEnabled) return;
    _cacheManager.markAsNotVisible(url);
  }

  @override
  bool isMediaCached(String url) =>
      _isCachingEnabled ? _cacheManager.isVideoCached(url) : false;

  @override
  bool isMediaInitializing(String url) =>
      _isCachingEnabled ? _cacheManager.isVideoInitializing(url) : false;

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
