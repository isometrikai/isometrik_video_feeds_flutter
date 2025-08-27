import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/utils/isr_utils.dart';
import 'package:video_player/video_player.dart';

class VideoCacheManager {
  factory VideoCacheManager() => _instance;
  VideoCacheManager._internal();
  static final VideoCacheManager _instance = VideoCacheManager._internal();

  // Cache to store initialized video controllers
  final Map<String, VideoPlayerController> _videoControllerCache = {};

  // Cache to store initialization futures to avoid duplicate initialization
  final Map<String, Future<VideoPlayerController?>> _initializationCache = {};

  // Queue to manage cache size (LRU - Least Recently Used)
  final Queue<String> _lruQueue = Queue<String>();

  // Maximum number of videos to keep in cache
  static const int _maxCacheSize = 8;

  // Set to track currently visible videos (should not be disposed)
  final Set<String> _visibleVideos = <String>{};

  /// Precache video controllers for given URLs
  Future<void> precacheVideos(List<String> videoUrls) async {
    debugPrint('🎬 VideoCacheManager: Starting precache for ${videoUrls.length} videos');

    var alreadyCached = 0;
    var initializing = 0;
    var newCaching = 0;

    for (final url in videoUrls) {
      if (url.isEmpty) {
        debugPrint('⚠️ VideoCacheManager: Skipping empty URL');
        continue;
      }

      // Don't cache if already cached
      if (_videoControllerCache.containsKey(url)) {
        alreadyCached++;
        debugPrint('✅ VideoCacheManager: Already cached - ${_extractVideoId(url)}');
        continue;
      }

      // Don't cache if currently being initialized
      if (_initializationCache.containsKey(url)) {
        initializing++;
        debugPrint('⏳ VideoCacheManager: Already initializing - ${_extractVideoId(url)}');
        continue;
      }

      newCaching++;
      debugPrint('🚀 VideoCacheManager: Starting precache for - ${_extractVideoId(url)}');

      // Start initialization without waiting
      unawaited(_initializeVideoController(url));
    }

    debugPrint(
        '📊 VideoCacheManager: Precache summary - Already cached: $alreadyCached, Initializing: $initializing, New caching: $newCaching');
  }

  /// Initialize a single video controller
  Future<VideoPlayerController?> _initializeVideoController(String url) async {
    final videoId = _extractVideoId(url);
    debugPrint('🎯 VideoCacheManager: Initializing video controller for $videoId');

    if (_initializationCache.containsKey(url)) {
      debugPrint('⚠️ VideoCacheManager: Video $videoId already in initialization cache');
      return _initializationCache[url];
    }

    final initFuture = _createAndInitializeController(url);
    _initializationCache[url] = initFuture;
    debugPrint('📝 VideoCacheManager: Added $videoId to initialization cache');

    try {
      final startTime = DateTime.now();
      final controller = await initFuture;
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      if (controller != null) {
        _addToCache(url, controller);
        debugPrint('✅ VideoCacheManager: Successfully initialized $videoId in ${duration}ms');
      } else {
        debugPrint('❌ VideoCacheManager: Failed to initialize $videoId after ${duration}ms');
      }
      return controller;
    } catch (e) {
      debugPrint('💥 VideoCacheManager: Exception initializing $videoId - $e');
      return null;
    } finally {
      await _initializationCache.remove(url);
      debugPrint('🗑️ VideoCacheManager: Removed $videoId from initialization cache');
    }
  }

  /// Create and initialize video controller
  Future<VideoPlayerController?> _createAndInitializeController(String url) async {
    final videoId = _extractVideoId(url);
    debugPrint('🔧 VideoCacheManager: Creating controller for $videoId');

    try {
      // Convert http to https if needed
      var mediaUrl = url;
      if (mediaUrl.startsWith('http:')) {
        mediaUrl = mediaUrl.replaceFirst('http:', 'https:');
        debugPrint('🔒 VideoCacheManager: Converted to HTTPS for $videoId');
      }

      debugPrint('🌐 VideoCacheManager: Creating NetworkUrl controller for $videoId');
      final controller = IsrVideoReelUtility.isLocalUrl(mediaUrl)
          ? VideoPlayerController.file(File(mediaUrl))
          : VideoPlayerController.networkUrl(Uri.parse(mediaUrl));

      debugPrint('⏳ VideoCacheManager: Initializing controller for $videoId');
      await controller.initialize();

      debugPrint('🔄 VideoCacheManager: Setting up looping for $videoId');
      await controller.setLooping(true);

      debugPrint('🔊 VideoCacheManager: Setting volume for $videoId');
      await controller.setVolume(1.0);

      debugPrint(
          '🎉 VideoCacheManager: Controller ready for $videoId (${controller.value.size.width}x${controller.value.size.height})');
      return controller;
    } catch (e) {
      debugPrint('💥 VideoCacheManager: Error creating controller for $videoId - $e');
      return null;
    }
  }

  /// Add controller to cache with LRU management
  void _addToCache(String url, VideoPlayerController controller) {
    final videoId = _extractVideoId(url);
    debugPrint('💾 VideoCacheManager: Adding $videoId to cache');

    // Remove from queue if already exists (for LRU update)
    final wasInQueue = _lruQueue.contains(url);
    _lruQueue.remove(url);

    // Add to front of queue (most recently used)
    _lruQueue.addFirst(url);

    // Add to cache
    _videoControllerCache[url] = controller;

    debugPrint(
        '📦 VideoCacheManager: Cache status - Size: ${_videoControllerCache.length}/$_maxCacheSize, ${wasInQueue ? 'Updated' : 'Added'} $videoId');

    // Manage cache size
    _evictIfNeeded();
  }

  /// Evict least recently used items if cache exceeds max size
  void _evictIfNeeded() {
    if (_lruQueue.length <= _maxCacheSize) {
      debugPrint('✅ VideoCacheManager: Cache within limits (${_lruQueue.length}/$_maxCacheSize)');
      return;
    }

    debugPrint('🚨 VideoCacheManager: Cache exceeded limit, starting eviction process');
    var evicted = 0;
    var protected = 0;

    while (_lruQueue.length > _maxCacheSize) {
      final oldestUrl = _lruQueue.removeLast();
      final videoId = _extractVideoId(oldestUrl);

      // Don't evict if video is currently visible
      if (_visibleVideos.contains(oldestUrl)) {
        protected++;
        debugPrint('🛡️ VideoCacheManager: Protected visible video $videoId from eviction');
        continue;
      }

      final controller = _videoControllerCache.remove(oldestUrl);
      if (controller != null) {
        controller.dispose();
        evicted++;
        debugPrint('🗑️ VideoCacheManager: Evicted $videoId from cache');
      }
    }

    debugPrint(
        '📊 VideoCacheManager: Eviction complete - Evicted: $evicted, Protected: $protected, Final size: ${_videoControllerCache.length}');
  }

  /// Get cached video controller
  VideoPlayerController? getCachedController(String url) {
    final videoId = _extractVideoId(url);
    final controller = _videoControllerCache[url];

    if (controller != null) {
      // Update LRU order
      _lruQueue.remove(url);
      _lruQueue.addFirst(url);
      debugPrint(
          '🎯 VideoCacheManager: Retrieved cached controller for $videoId (moved to front of LRU)');
    } else {
      debugPrint('❌ VideoCacheManager: No cached controller found for $videoId');
    }

    return controller;
  }

  /// Mark video as visible (prevents disposal)
  void markAsVisible(String url) {
    final videoId = _extractVideoId(url);
    final wasVisible = _visibleVideos.contains(url);
    _visibleVideos.add(url);

    if (!wasVisible) {
      debugPrint(
          '👁️ VideoCacheManager: Marked $videoId as VISIBLE (${_visibleVideos.length} total visible)');
    }
  }

  /// Mark video as not visible (allows disposal)
  void markAsNotVisible(String url) {
    final videoId = _extractVideoId(url);
    final wasVisible = _visibleVideos.remove(url);

    if (wasVisible) {
      debugPrint(
          '👁️‍🗨️ VideoCacheManager: Marked $videoId as NOT VISIBLE (${_visibleVideos.length} total visible)');
    }
  }

  /// Check if video is cached and ready
  bool isVideoCached(String url) {
    final controller = _videoControllerCache[url];
    final isCached = controller != null && controller.value.isInitialized;
    final videoId = _extractVideoId(url);

    if (isCached) {
      debugPrint('✅ VideoCacheManager: $videoId is cached and ready');
    }

    return isCached;
  }

  /// Get initialization status
  bool isVideoInitializing(String url) {
    final isInitializing = _initializationCache.containsKey(url);
    final videoId = _extractVideoId(url);

    if (isInitializing) {
      debugPrint('⏳ VideoCacheManager: $videoId is currently initializing');
    }

    return isInitializing;
  }

  /// Clear specific video from cache
  void clearVideo(String url) {
    final videoId = _extractVideoId(url);
    debugPrint('🧹 VideoCacheManager: Clearing $videoId from cache');

    _visibleVideos.remove(url);
    _lruQueue.remove(url);
    final controller = _videoControllerCache.remove(url);
    controller?.dispose();
    _initializationCache.remove(url);

    debugPrint('✅ VideoCacheManager: Cleared $videoId successfully');
  }

  /// Clear all cache
  void clearAll() {
    debugPrint(
        '🧹 VideoCacheManager: Clearing ALL cached videos (${_videoControllerCache.length} videos)');

    for (final entry in _videoControllerCache.entries) {
      final videoId = _extractVideoId(entry.key);
      debugPrint('🗑️ VideoCacheManager: Disposing controller for $videoId');
      // entry.value.dispose();
    }

    _videoControllerCache.clear();
    _initializationCache.clear();
    _lruQueue.clear();
    _visibleVideos.clear();

    debugPrint('✅ VideoCacheManager: All cache cleared successfully');
  }

  /// Extract video ID from URL for logging
  String _extractVideoId(String url) {
    if (url.isEmpty) return 'empty-url';

    // Extract filename or last part of URL for cleaner logs
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final lastSegment = segments.last;
        // If it has an extension, remove it for cleaner display
        final dotIndex = lastSegment.lastIndexOf('.');
        if (dotIndex > 0) {
          return lastSegment.substring(0, dotIndex);
        }
        return lastSegment;
      }
    }

    // Fallback: take last 20 characters
    return url.length > 20 ? '...${url.substring(url.length - 20)}' : url;
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() => {
        'cached_videos': _videoControllerCache.length,
        'initializing_videos': _initializationCache.length,
        'visible_videos': _visibleVideos.length,
        'lru_queue_size': _lruQueue.length,
      };
}
