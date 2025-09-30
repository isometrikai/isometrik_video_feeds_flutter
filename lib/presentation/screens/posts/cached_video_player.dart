import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_player_interface.dart';
import 'package:ism_video_reel_player/utils/isr_utils.dart';
import 'package:video_player/video_player.dart';

/// Wrapper for CachedVideoPlayerPlus implementing IVideoPlayerController
class CachedVideoPlayerWrapper implements IVideoPlayerController {
  CachedVideoPlayerWrapper(this._player) {
    _setupListeners();
  }

  final CachedVideoPlayerPlus _player;
  final ValueNotifier<bool> _playingStateNotifier = ValueNotifier<bool>(false);

  VideoPlayerController get _controller => _player.controller;

  void _setupListeners() {
    _controller.addListener(() {
      _playingStateNotifier.value = _controller.value.isPlaying;
    });
  }

  @override
  Future<void> initialize() => _player.initialize();

  @override
  Future<void> setLooping(bool looping) async {
    await _player.initialize();
    await _controller.setLooping(looping);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player.initialize();
    await _controller.setVolume(volume);
  }

  @override
  Future<void> play() async {
    await _player.initialize();
    await _controller.play();
  }

  @override
  Future<void> pause() async {
    await _player.initialize();
    await _controller.pause();
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _player.initialize();
    await _controller.seekTo(position);
  }

  @override
  Duration get position => _controller.value.position;

  @override
  Duration get duration => _controller.value.duration;

  @override
  bool get isPlaying => _controller.value.isPlaying;

  @override
  bool get isInitialized => _player.isInitialized;

  @override
  ValueNotifier<bool> get playingStateNotifier => _playingStateNotifier;

  @override
  Size get videoSize => _controller.value.size;

  @override
  double get aspectRatio => _controller.value.aspectRatio;

  @override
  Widget buildVideoPlayerWidget() => VideoPlayer(_controller);

  @override
  Future<void> dispose() async {
    _playingStateNotifier.dispose();
    await _player.dispose();
  }

  @override
  void addListener(VoidCallback listener) {
    _controller.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _controller.removeListener(listener);
  }
}

/// Cache manager implementation for CachedVideoPlayerPlus
class CachedVideoCacheManager implements IVideoCacheManager {
  factory CachedVideoCacheManager() => _instance;
  CachedVideoCacheManager._internal();
  static final CachedVideoCacheManager _instance = CachedVideoCacheManager._internal();

  final Map<String, CachedVideoPlayerWrapper> _videoControllerCache = {};
  final Map<String, Future<CachedVideoPlayerWrapper?>> _initializationCache = {};
  final Queue<String> _lruQueue = Queue<String>();
  final Set<String> _visibleVideos = <String>{};
  static const int _maxCacheSize = 10;

  CachedVideoPlayerPlus _createVideoPlayerController(String mediaUrl) {
    if (IsrVideoReelUtility.isLocalUrl(mediaUrl)) {
      return CachedVideoPlayerPlus.file(
        File(mediaUrl),
      );
    }

    var url = mediaUrl;
    if (url.startsWith('http:')) {
      url = url.replaceFirst('http:', 'https:');
    }

    // For HLS streams, add specific headers and format hint
    final isHls = url.toLowerCase().endsWith('.m3u8');
    final headers = {
      'User-Agent': 'AppleCoreMedia/1.0.0.19G82 (iPhone; U; CPU OS 15_6_1 like Mac OS X; en_us)',
      'Accept': '*/*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
      if (isHls) 'X-Playback-Session-Id': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    return CachedVideoPlayerPlus.networkUrl(
      Uri.parse(url),
      httpHeaders: headers,
      formatHint: isHls ? VideoFormat.hls : null,
    );
  }

  Future<CachedVideoPlayerWrapper?> _initializeVideoController(String url) async {
    if (_initializationCache.containsKey(url)) {
      return _initializationCache[url];
    }

    final initFuture = _createAndInitializeController(url);
    _initializationCache[url] = initFuture;

    try {
      final controller = await initFuture;
      if (controller != null) {
        _addToCache(url, controller);
      }
      return controller;
    } catch (e) {
      debugPrint('Error initializing video controller: $e');
      return null;
    } finally {
      await _initializationCache.remove(url);
    }
  }

  Future<CachedVideoPlayerWrapper?> _createAndInitializeController(String url) async {
    try {
      final controller = _createVideoPlayerController(url);
      await controller.initialize();
      final wrapper = CachedVideoPlayerWrapper(controller);
      await wrapper.setLooping(true);
      await wrapper.setVolume(1.0);
      return wrapper;
    } catch (e, stackTrace) {
      debugPrint('Error creating video controller for URL: $url');
      debugPrint('Error details: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  void _addToCache(String url, CachedVideoPlayerWrapper controller) {
    _lruQueue.remove(url);
    _lruQueue.addFirst(url);
    _videoControllerCache[url] = controller;
    _evictIfNeeded();
  }

  void _evictIfNeeded() {
    while (_lruQueue.length > _maxCacheSize) {
      final url = _lruQueue.removeLast();
      if (_visibleVideos.contains(url)) continue;

      final controller = _videoControllerCache.remove(url);
      controller?.dispose();
    }
  }

  @override
  Future<void> precacheVideos(List<String> videoUrls, {bool highPriority = false}) async {
    final futures = <Future<void>>[];

    for (final url in videoUrls) {
      if (url.isEmpty) continue;
      if (_videoControllerCache.containsKey(url)) continue;

      final future = _initializeVideoController(url);
      if (highPriority) {
        futures.add(future);
      } else {
        unawaited(future);
      }
    }

    if (highPriority && futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  @override
  IVideoPlayerController? getCachedController(String url) {
    final controller = _videoControllerCache[url];
    if (controller != null) {
      _lruQueue.remove(url);
      _lruQueue.addFirst(url);
    }
    return controller;
  }

  @override
  void markAsVisible(String url) => _visibleVideos.add(url);

  @override
  void markAsNotVisible(String url) => _visibleVideos.remove(url);

  @override
  bool isVideoCached(String url) {
    final controller = _videoControllerCache[url];
    return controller != null && controller.isInitialized;
  }

  @override
  bool isVideoInitializing(String url) => _initializationCache.containsKey(url);

  @override
  void clearVideo(String url) {
    _visibleVideos.remove(url);
    _lruQueue.remove(url);
    final controller = _videoControllerCache.remove(url);
    controller?.dispose();
    _initializationCache.remove(url);
  }

  @override
  void clearControllers() {
    for (final controller in _videoControllerCache.values) {
      controller.dispose();
    }
    _videoControllerCache.clear();
    _initializationCache.clear();
    _lruQueue.clear();
    _visibleVideos.clear();
  }

  @override
  void clearControllersOutsideRange(List<String> activeUrls) {
    final urlsToKeep = Set<String>.from(activeUrls);
    final urlsToRemove =
        _videoControllerCache.keys.where((url) => !urlsToKeep.contains(url)).toList();

    for (final url in urlsToRemove) {
      clearVideo(url);
    }
  }

  @override
  Map<String, dynamic> getCacheStats() => {
        'cached_videos': _videoControllerCache.length,
        'initializing_videos': _initializationCache.length,
        'visible_videos': _visibleVideos.length,
        'lru_queue_size': _lruQueue.length,
      };
}
