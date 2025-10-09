import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/media_cache_interface.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_player_interface.dart';
import 'package:ism_video_reel_player/utils/isr_utils.dart';
import 'package:video_player/video_player.dart';

/// Wrapper for VideoPlayerController implementing IVideoPlayerController
class StandardVideoPlayerController implements IVideoPlayerController {
  StandardVideoPlayerController(this._controller) {
    _setupListeners();
  }

  final VideoPlayerController _controller;
  final ValueNotifier<bool> _playingStateNotifier = ValueNotifier<bool>(false);

  void _setupListeners() {
    _controller.addListener(() {
      _playingStateNotifier.value = _controller.value.isPlaying;
    });
  }

  @override
  Future<void> initialize() => _controller.initialize();

  @override
  Future<void> setLooping(bool looping) => _controller.setLooping(looping);

  @override
  Future<void> setVolume(double volume) => _controller.setVolume(volume);

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> seekTo(Duration position) => _controller.seekTo(position);

  @override
  Duration get position => _controller.value.position;

  @override
  Duration get duration => _controller.value.duration;

  @override
  bool get isPlaying => _controller.value.isPlaying;

  @override
  bool get isInitialized => _controller.value.isInitialized;

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
    await _controller.dispose();
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

/// Cache manager implementation for standard VideoPlayer
class StandardVideoCacheManager implements IVideoCacheManager {
  factory StandardVideoCacheManager() => _instance;

  StandardVideoCacheManager._internal();

  static final StandardVideoCacheManager _instance = StandardVideoCacheManager._internal();

  final Map<String, StandardVideoPlayerController> _videoControllerCache = {};
  final Map<String, Future<StandardVideoPlayerController?>> _initializationCache = {};
  final Queue<String> _lruQueue = Queue<String>();
  final Set<String> _visibleVideos = <String>{};
  static const int _maxCacheSize = 10;

  VideoPlayerController _createVideoPlayerController(String mediaUrl) {
    if (IsrVideoReelUtility.isLocalUrl(mediaUrl)) {
      return VideoPlayerController.file(
        File(mediaUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: true,
        ),
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
      'Connection': 'keep-alive',
      'Cache-Control': 'no-cache',
      if (isHls) 'X-Playback-Session-Id': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    return VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: true,
      ),
      httpHeaders: headers,
      formatHint: isHls ? VideoFormat.hls : null,
    );
  }

  Future<StandardVideoPlayerController?> _initializeVideoController(String url) async {
    // Validate that this is actually a video URL
    final mediaType = MediaTypeUtil.getMediaType(url);
    if (mediaType != MediaType.video) {
      debugPrint(
          '⚠️ Attempted to initialize video controller for non-video URL: $url (type: $mediaType)');
      return null;
    }

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

  Future<StandardVideoPlayerController?> _createAndInitializeController(String url) async {
    debugPrint('StandardVideoCacheManager: _createAndInitializeController: $url');
    try {
      final controller = _createVideoPlayerController(url);

      // Initialize with timeout to prevent hanging
      await controller.initialize().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint('⚠️ Video initialization timeout for: $url');
          throw TimeoutException('Video initialization timeout', const Duration(seconds: 20));
        },
      ).then((value) {
        debugPrint(
            'StandardVideoCacheManager: _createAndInitializeController controller created: $url');
      });

      // Set properties in parallel for faster setup
      await Future.wait([
        controller.setLooping(true),
        controller.setVolume(1.0),
      ]);

      return StandardVideoPlayerController(controller);
    } catch (e) {
      debugPrint('Error creating video controller: $e');
      return null;
    }
  }

  void _addToCache(String url, StandardVideoPlayerController controller) {
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
    final validUrls = <String>[];

    // Filter valid video URLs first
    for (final url in videoUrls) {
      if (url.isEmpty) continue;
      if (_videoControllerCache.containsKey(url)) continue;

      // Only process actual video URLs, skip image URLs
      final mediaType = MediaTypeUtil.getMediaType(url);
      if (mediaType != MediaType.video) {
        debugPrint('⚠️ Skipping non-video URL in precacheVideos: $url (type: $mediaType)');
        continue;
      }

      validUrls.add(url);
    }

    // Process videos in batches for better performance
    const batchSize = 3;
    for (var i = 0; i < validUrls.length; i += batchSize) {
      final batch = validUrls.skip(i).take(batchSize);
      final batchFutures = batch.map(_initializeVideoController).toList();

      if (highPriority) {
        futures.addAll(batchFutures);
      } else {
        // Process non-priority videos in background
        unawaited(Future.wait(batchFutures));
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
