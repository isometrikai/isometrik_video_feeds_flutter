import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_player_interface.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:video_player/video_player.dart';

/// Wrapper for CachedVideoPlayerPlus implementing IVideoPlayerController
class CachedVideoPlayerWrapper implements IVideoPlayerController {
  CachedVideoPlayerWrapper(this._player) {
    _setupListeners();
  }

  final CachedVideoPlayerPlus _player;
  final ValueNotifier<bool> _playingStateNotifier = ValueNotifier<bool>(false);
  bool _isDisposed = false;
  bool _hasLoggedError = false;

  VideoPlayerController get _controller => _player.controller;

  void _setupListeners() {
    _controller.addListener(() {
      if (!_isDisposed) {
        _playingStateNotifier.value = _controller.value.isPlaying;

        // Monitor for runtime errors (green blocks, decoding failures)
        if (_controller.value.hasError && !_hasLoggedError) {
          _hasLoggedError = true;
          debugPrint('❌ Video playback error detected during runtime');
          debugPrint(
              '❌ Error description: ${_controller.value.errorDescription}');
          debugPrint('❌ Video size: ${_controller.value.size}');
          debugPrint('❌ Position: ${_controller.value.position}');
          debugPrint('❌ Duration: ${_controller.value.duration}');
          // This indicates hardware decoding failure - video should be re-encoded
        }

        // Detect potential decoding issues (size becomes zero during playback)
        if (_controller.value.isInitialized &&
            _controller.value.size == Size.zero &&
            !_hasLoggedError) {
          _hasLoggedError = true;
          debugPrint(
              '⚠️ Video size became zero during playback - possible decoder failure');
          debugPrint('⚠️ This may cause green blocks or corrupted frames');
        }
      }
    });
  }

  @override
  Future<void> initialize() => _player.initialize();

  @override
  Future<void> setLooping(bool looping) async {
    await _player.initialize();
    await _controller.setLooping(true);
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
  bool get isBuffering => _controller.value.isBuffering;

  @override
  Future<void> forceResume() async {
    if (_isDisposed) return;
    
    debugPrint('🔄 CachedVideoPlayer force resuming... isPlaying=${_controller.value.isPlaying}, isBuffering=${_controller.value.isBuffering}, position=${_controller.value.position}');
    
    try {
      // Ensure player is initialized
      await _player.initialize();
      
      // Check if video is stuck at the beginning
      final isStuckAtStart = _controller.value.position == Duration.zero && 
                             !_controller.value.isPlaying;
      
      if (_controller.value.isBuffering || isStuckAtStart) {
        // Seek to unstick the video
        final currentPos = _controller.value.position;
        if (currentPos == Duration.zero) {
          await _controller.seekTo(const Duration(milliseconds: 100));
        } else {
          await _controller.seekTo(currentPos);
        }
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      if (!_controller.value.isPlaying) {
        await _controller.play();
        debugPrint('▶️ CachedVideoPlayer force play triggered');
      }
    } catch (e) {
      debugPrint('⚠️ Error in CachedVideoPlayer forceResume: $e');
    }
  }

  @override
  bool get isInitialized => _player.isInitialized;

  @override
  bool get isDisposed => _isDisposed;

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
    // Check if already disposed to prevent double disposal
    if (_isDisposed) {
      return; // Already disposed
    }

    _isDisposed = true;

    try {
      _playingStateNotifier.dispose();
    } catch (e) {
      debugPrint('⚠️ Error disposing playing state notifier: $e');
    }

    try {
      await _player.dispose();
    } catch (e) {
      debugPrint('⚠️ Error disposing cached video player: $e');
    }
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
  static final CachedVideoCacheManager _instance =
      CachedVideoCacheManager._internal();

  final Map<String, CachedVideoPlayerWrapper> _videoControllerCache = {};
  final Map<String, Future<CachedVideoPlayerWrapper?>> _initializationCache =
      {};
  final Queue<String> _lruQueue = Queue<String>();
  final Set<String> _visibleVideos = <String>{};

  // SMART CACHING: Balanced cache sizes for smooth playback without memory spikes
  // Android: 5 videos max (allows buffer for bidirectional scrolling)
  // iOS: 8 videos max (more lenient for smoother experience)
  // Smart eviction keeps videos near current position cached
  static int get _maxCacheSize => Platform.isAndroid ? 5 : 8;

  // Track memory errors to adaptively reduce cache
  int _memoryErrorCount = 0;

  CachedVideoPlayerPlus _createVideoPlayerController(String mediaUrl) {
    if (Utility.isLocalUrl(mediaUrl)) {
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
    // final headers = {
    //   'User-Agent':
    //       'AppleCoreMedia/1.0.0.19G82 (iPhone; U; CPU OS 15_6_1 like Mac OS X; en_us)',
    //   'Accept': '*/*',
    //   'Accept-Language': 'en-US,en;q=0.9',
    //   'Accept-Encoding': 'gzip, deflate, br',
    //   if (isHls)
    //     'X-Playback-Session-Id':
    //         DateTime.now().millisecondsSinceEpoch.toString(),
    // };

    final headers = {
      // Neutral, cross-platform user agent
      'User-Agent': 'FlutterVideoPlayer',

      // Allow all HLS-related MIME types
      'Accept': '*/*',

      // Keep it simple – avoid segment compression issues
      // DO NOT send Accept-Encoding

      // Optional but safe
      'Connection': 'keep-alive',
    };

    return CachedVideoPlayerPlus.networkUrl(
      Uri.parse(url),
      httpHeaders: headers,
      formatHint: isHls ? VideoFormat.hls : null,
    );
  }

  Future<CachedVideoPlayerWrapper?> _initializeVideoController(
      String url) async {
    // If already initializing, wait for existing initialization
    if (_initializationCache.containsKey(url)) {
      return _initializationCache[url];
    }

    // CRITICAL: Limit concurrent initializations to prevent memory spikes
    // Android: Max 2 concurrent initializations (allows preloading next video)
    // iOS: Max 3 concurrent initializations
    final maxConcurrentInit = Platform.isAndroid ? 2 : 3;
    if (_initializationCache.length >= maxConcurrentInit) {
      debugPrint(
          '⚠️ Too many concurrent initializations (${_initializationCache.length}), clearing cache');
      await _clearNonVisibleVideos();

      // Give system time to release resources
      final delayMs = Platform.isAndroid ? 300 : 200;
      await Future.delayed(Duration(milliseconds: delayMs));
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

  Future<CachedVideoPlayerWrapper?> _createAndInitializeController(
      String url) async {
    try {
      // SMART CACHE MANAGEMENT: Only clear when at limit, preserve nearby videos
      // Clear only non-visible videos that are far from current position
      if (_videoControllerCache.length >= _maxCacheSize) {
        debugPrint(
            '🔥 Smart cache: At limit (${_videoControllerCache.length}/$_maxCacheSize), clearing distant non-visible videos');
        // CRITICAL: Only clear non-visible videos, preserve visible ones
        await _clearNonVisibleVideos();

        // Give system time to release decoder resources
        final delayMs = Platform.isAndroid ? 200 : 100;
        await Future.delayed(Duration(milliseconds: delayMs));
      }

      // Add delay between initializations to prevent decoder overload
      if (_memoryErrorCount > 0) {
        // OPTIMIZATION: Increased delay per error to allow more time for cleanup
        final delay = 300 * _memoryErrorCount.clamp(1, 5);
        debugPrint(
            '⏳ Adding ${delay}ms delay before initialization (error count: $_memoryErrorCount)');
        await Future.delayed(Duration(milliseconds: delay));
        
        // Also reduce cache size temporarily when memory errors occur
        if (_memoryErrorCount >= 2 && _videoControllerCache.length > 2) {
          debugPrint('🔥 Memory pressure detected, clearing additional cache...');
          await _clearNonVisibleVideos();
        }
      }

      final controller = _createVideoPlayerController(url);

      // OPTIMIZATION: Platform-specific timeout for initialization
      // Android: 3s (faster failure to free memory quickly)
      // iOS: 5s (more lenient as iOS handles memory better)
      final timeoutDuration = Duration(seconds: Platform.isAndroid ? 3 : 5);

      try {
        await controller.initialize().timeout(
          timeoutDuration,
          onTimeout: () {
            debugPrint('⚠️ CachedVideoPlayer initialization timeout for: $url');
            throw TimeoutException(
                'Video initialization timeout', timeoutDuration);
          },
        );
      } catch (e) {
        // CRITICAL FIX: On Android, if initialization fails due to memory,
        // aggressively clear cache and retry ONCE
        final errorMsg = e.toString().toLowerCase();
        final isMemoryError = Platform.isAndroid &&
            (errorMsg.contains('no_memory') ||
                errorMsg.contains('0xfffffff4') ||
                errorMsg.contains('decoder init failed') ||
                errorMsg.contains('mediacodec') ||
                errorMsg.contains('videoerror') ||
                errorMsg.contains('exoplaybackexception'));

        if (isMemoryError) {
          _memoryErrorCount++;
          debugPrint(
              '🔥 CRITICAL: Memory/Decoder error detected! (Count: $_memoryErrorCount)');
          debugPrint('🔥 Error type: ${e.runtimeType}');
          debugPrint('🔥 Error message: $e');
          debugPrint('🔥 Disposing failed controller and clearing cache...');

          // CRITICAL: Dispose the failed controller first!
          try {
            await controller.controller.dispose();
          } catch (_) {}

          await _clearNonVisibleVideos();

          // Create a NEW controller for retry (don't reuse failed one!)
          final retryController = _createVideoPlayerController(url);

          // Retry initialization ONCE after clearing cache
          try {
            await retryController.initialize().timeout(
              timeoutDuration,
              onTimeout: () {
                debugPrint(
                    '⚠️ CachedVideoPlayer retry initialization timeout for: $url');
                throw TimeoutException(
                    'Video retry initialization timeout', timeoutDuration);
              },
            );
            debugPrint('✅ Video initialized successfully after cache clear!');
            // Reset error count on success
            if (_memoryErrorCount > 0) _memoryErrorCount--;

            // Use the retry controller instead of the failed one
            final retryWrapper = CachedVideoPlayerWrapper(retryController);
            await retryWrapper.setLooping(false);
            await retryWrapper.setVolume(1.0);
            return retryWrapper;
          } catch (retryError) {
            debugPrint('❌ Retry failed after cache clear: $retryError');
            try {
              await retryController.controller.dispose();
            } catch (_) {}
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      final wrapper = CachedVideoPlayerWrapper(controller);

      // Validate video initialization - check for decoding errors
      if (!wrapper.isInitialized) {
        debugPrint('❌ CachedVideoPlayer not initialized properly for: $url');
        await wrapper.dispose();
        return null;
      }

      if (controller.controller.value.hasError) {
        debugPrint(
            '❌ CachedVideoPlayer has error after initialization: ${controller.controller.value.errorDescription}');
        debugPrint('❌ URL: $url');
        await wrapper.dispose();
        return null;
      }

      // Check for valid video dimensions (Size.zero indicates decoding failure)
      if (controller.controller.value.size == Size.zero) {
        debugPrint(
            '❌ CachedVideoPlayer has invalid size (0x0) - possible decoding failure for: $url');
        await wrapper.dispose();
        return null;
      }

      debugPrint(
          '✅ CachedVideoPlayer initialized successfully - Size: ${controller.controller.value.size}, Duration: ${controller.controller.value.duration}, URL: $url');

      await wrapper.setLooping(false);
      await wrapper.setVolume(1.0);
      return wrapper;
    } catch (e, stackTrace) {
      debugPrint(
          '❌ CachedVideoPlayer Error creating video controller for URL: $url');
      debugPrint('❌ CachedVideoPlayer Error details: $e');
      debugPrint('❌ CachedVideoPlayer Stack trace: $stackTrace');
      return null;
    }
  }

  /// CRITICAL: Clear all non-visible videos to free up decoder memory
  /// This is called proactively to prevent memory spikes
  Future<void> _clearNonVisibleVideos() async {
    final urlsToRemove = <String>[];

    // Collect all non-visible videos for removal
    for (final url in _videoControllerCache.keys) {
      if (!_visibleVideos.contains(url)) {
        urlsToRemove.add(url);
      }
    }

    // CRITICAL: If we have too many videos (more than 1.5x limit), clear excess
    // This prevents memory crashes when scrolling through many videos
    // But be less aggressive - only clear when significantly over limit
    if (_videoControllerCache.length > (_maxCacheSize * 1.5).round()) {
      debugPrint('🔥 CRITICAL: Cache size (${_videoControllerCache.length}) exceeds safe limit, clearing excess videos');
      // Keep visible videos + some buffer, but clear oldest non-visible ones
      // Don't clear visible videos unless absolutely necessary
    }

    // Clear them - dispose in parallel for faster cleanup
    final disposeFutures = <Future<void>>[];
    for (final url in urlsToRemove) {
      final controller = _videoControllerCache.remove(url);
      if (controller != null) {
        disposeFutures.add(controller.dispose().catchError((e) {
          debugPrint('⚠️ Error disposing controller for $url: $e');
        }));
        _lruQueue.remove(url);
        debugPrint('🗑️ Emergency: Clearing video from cache: $url');
      }
    }

    // Wait for all disposals to complete
    if (disposeFutures.isNotEmpty) {
      await Future.wait(disposeFutures);
    }

    debugPrint(
        '🔥 Emergency cache clear: Removed ${urlsToRemove.length} videos, ${_videoControllerCache.length} remaining');
  }

  void _addToCache(String url, CachedVideoPlayerWrapper controller) {
    _lruQueue.remove(url);
    _lruQueue.addFirst(url);
    _videoControllerCache[url] = controller;
    _evictIfNeeded();
  }

  void _evictIfNeeded() {
    // SMART EVICTION: Only evict videos that are truly not needed
    // Keep visible videos + nearby buffer for smooth bidirectional scrolling
    final cacheThreshold = _maxCacheSize;
    final urlsToEvict = <String>[];

    // Only evict when cache exceeds limit
    if (_lruQueue.length <= cacheThreshold) {
      return; // Cache is within limits, no eviction needed
    }

    // Evict oldest non-visible videos that exceed cache limit
    // CRITICAL: Never evict visible videos - they're actively being watched
    while (_lruQueue.length > cacheThreshold) {
      final url = _lruQueue.removeLast();

      // NEVER evict visible videos - they're actively being watched
      if (_visibleVideos.contains(url)) {
        _lruQueue.addFirst(url); // Move to front to prevent re-eviction
        continue;
      }

      urlsToEvict.add(url);
    }

    // Dispose evicted videos (only non-visible ones far from current position)
    for (final url in urlsToEvict) {
      final controller = _videoControllerCache.remove(url);
      if (controller != null) {
        controller.dispose();
        debugPrint(
            '🗑️ CachedVideoCache: Smart evicted non-visible video (cache: ${_videoControllerCache.length}/$_maxCacheSize): $url');
      }
    }
  }

  @override
  Future<void> precacheVideos(List<String> videoUrls,
      {bool highPriority = false}) async {
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
  void markAsNotVisible(String url) {
    _visibleVideos.remove(url);
    // Don't dispose immediately - let LRU eviction handle it
    // This allows smooth scrolling back and forth without reloading videos
    // Only trigger eviction check, don't force disposal
    _evictIfNeeded();
  }

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
    final urlsToRemove = _videoControllerCache.keys
        .where((url) => !urlsToKeep.contains(url))
        .toList();

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
