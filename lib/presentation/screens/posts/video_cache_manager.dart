import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class VideoCacheManager implements IMediaCacheManager {
  VideoCacheManager._internal() {
    // Initialize with cached video player by default
    _cacheManager = VideoPlayerFactory.create(_currentType);
  }

  factory VideoCacheManager() => _instance;
  VideoPlayerType _currentType =
      Platform.isAndroid ? VideoPlayerType.standardNonPreload : VideoPlayerType.standardNonPreload;

  static final VideoCacheManager _instance = VideoCacheManager._internal();

  late IVideoCacheManager _cacheManager;
  final Set<String> _preferOriginal = {};

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

  String _originalUrl(String url) => Utility.resolveOriginalMediaUrl(url);

  String _displayUrl(String url) {
    final original = _originalUrl(url);
    if (_preferOriginal.contains(url) || _preferOriginal.contains(original)) {
      return original;
    }
    return Utility.buildGumletVideoUrl(original);
  }

  bool _isControllerUnusable(dynamic controller) {
    if (controller == null) return true;
    if (controller is! IVideoPlayerController) return true;
    return !controller.isInitialized || controller.isDisposed;
  }

  @override
  Future<void> precacheMedia(List<String> mediaUrls, {bool highPriority = false}) =>
      _cacheManager.precacheVideos(
        mediaUrls.map(_displayUrl).toList(),
        highPriority: highPriority,
      );

  @override
  dynamic getCachedMedia(String url) => _cacheManager.getCachedController(_displayUrl(url));

  Future<dynamic> precacheMediaAndReturnController(String url) async {
    final original = _originalUrl(url);
    final display = _displayUrl(url);
    var controller = await _cacheManager.precacheMediaAndReturnController(display, useFallBackControllerOnFail: display == original);
    if (_isControllerUnusable(controller) && display != original) {
      debugPrint('VideoCacheManager: Gumlet video failed, retrying original: $original');
      _preferOriginal
        ..add(url)
        ..add(original);
      _cacheManager.clearVideo(display);
      controller = await _cacheManager.precacheMediaAndReturnController(original);
    }
    return controller;
  }

  @override
  void markAsVisible(String url) => _cacheManager.markAsVisible(_displayUrl(url));

  @override
  void markAsNotVisible(String url) => _cacheManager.markAsNotVisible(_displayUrl(url));

  void detachedFromWidget(String url, IVideoPlayerController? controller) =>
      _cacheManager.detachedFromWidget(_displayUrl(url), controller);

  @override
  bool isMediaCached(String url) => _cacheManager.isVideoCached(_displayUrl(url));

  @override
  bool isMediaInitializing(String url) => _cacheManager.isVideoInitializing(_displayUrl(url));

  @override
  void clearMedia(String url) => _cacheManager.clearVideo(_displayUrl(url));

  @override
  void clearCache() {
    _preferOriginal.clear();
    _cacheManager.clearControllers();
  }

  @override
  Map<String, dynamic> getCacheStats() => _cacheManager.getCacheStats();
}
