import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';

/// Cache manager implementation for images
class ImageCacheManager implements IMediaCacheManager {
  factory ImageCacheManager() => _instance;

  ImageCacheManager._internal();

  static final ImageCacheManager _instance = ImageCacheManager._internal();

  final Map<String, ImageProvider> _imageCache = {};
  final Map<String, Future<void>> _initializationCache = {};
  final Queue<String> _lruQueue = Queue<String>();
  final Set<String> _visibleImages = <String>{};
  final DefaultCacheManager _diskCache = DefaultCacheManager();
  static const int _maxCacheSize =
      20; // More images can be cached compared to videos

  @override
  Future<void> precacheMedia(List<String> mediaUrls,
      {bool highPriority = false}) async {
    final futures = <Future<void>>[];
    final validUrls = <String>[];

    // Filter valid URLs first
    for (final url in mediaUrls) {
      if (url.isEmpty) continue;
      if (isMediaCached(url)) continue;

      // Only process actual image URLs, skip video URLs
      final mediaType = MediaTypeUtil.getMediaType(url);
      if (mediaType != MediaType.image) {
        debugPrint(
            '⚠️ Skipping non-image URL in precacheMedia: $url (type: $mediaType)');
        continue;
      }

      validUrls.add(url);
    }

    if (validUrls.isEmpty) return;

    // Process images in batches for better performance and memory management
    const batchSize = 5; // Process 5 images at a time
    for (var i = 0; i < validUrls.length; i += batchSize) {
      final batch = validUrls.skip(i).take(batchSize);
      final batchFutures = batch
          .map((url) => _cacheImage(url, highPriority: highPriority))
          .toList();

      if (highPriority) {
        // For high priority, wait for each batch to complete
        await Future.wait(batchFutures);
      } else {
        // For normal priority, start caching in background without blocking
        unawaited(Future.wait(batchFutures));
      }
    }

    // If high priority, ensure all futures are tracked
    if (highPriority) {
      for (final url in validUrls) {
        futures.add(_cacheImage(url, highPriority: highPriority));
      }
      await Future.wait(futures);
    }
  }

  Future<void> _cacheImage(String url, {bool highPriority = false}) async {
    final cleanUrl = url.split('?').first.split('#').first;

    // Validate that this is actually an image URL
    final mediaType = MediaTypeUtil.getMediaType(cleanUrl);
    if (mediaType != MediaType.image) {
      debugPrint(
          '⚠️ Attempted to cache non-image URL: $cleanUrl (type: $mediaType)');
      return;
    }

    // Check if already cached in memory
    if (isMediaCached(cleanUrl)) {
      debugPrint(
          '✅ ImageCacheManager: Image already cached in memory: $cleanUrl');
      return;
    }

    // Check if already cached in CachedNetworkImage's disk cache
    if (await _isImageCachedOnDisk(cleanUrl)) {
      debugPrint(
          '✅ ImageCacheManager: Image already cached on disk: $cleanUrl');
      return;
    }

    // Check if already initializing
    if (_initializationCache.containsKey(cleanUrl)) {
      debugPrint(
          '🔄 ImageCacheManager: Image already being cached, waiting...');
      await _initializationCache[cleanUrl];
      return;
    }

    final initFuture = _initializeImage(cleanUrl, highPriority: highPriority);
    _initializationCache[cleanUrl] = initFuture;

    try {
      await initFuture;
    } catch (e) {
      debugPrint('Error caching image: $e');
    } finally {
      await _initializationCache.remove(cleanUrl);
    }
  }

  Future<void> _initializeImage(String url, {bool highPriority = false}) async {
    try {
      // Since we're using CachedNetworkImage, focus on disk caching
      // CachedNetworkImage will handle its own memory cache
      if (highPriority) {
        // For high priority, preload into CachedNetworkImage's disk cache
        await _diskCache.downloadFile(url);
        debugPrint(
            '✅ ImageCacheManager: Successfully cached image on disk: $url');

        // Also preload into Flutter's memory cache for instant display
        unawaited(_preloadIntoFlutterCache(url));
      } else {
        // For low priority, just trigger disk caching in background
        unawaited(_diskCache.downloadFile(url).then((_) {
          debugPrint(
              '✅ ImageCacheManager: Successfully cached image on disk: $url');
        }));
      }
    } catch (e) {
      debugPrint(
          '❌ ImageCacheManager: Error initializing image cache for URL: $url');
      debugPrint('Error details: $e');
      rethrow;
    }
  }

  /// Preload image into Flutter's image cache for instant display
  Future<void> _preloadIntoFlutterCache(String url) async {
    try {
      final provider = NetworkImage(url);
      // Use the global image cache directly
      provider.resolve(ImageConfiguration.empty);
      debugPrint(
          '✅ ImageCacheManager: Successfully preloaded image into Flutter cache: $url');
    } catch (e) {
      debugPrint(
          '❌ ImageCacheManager: Error preloading image into Flutter cache: $e');
    }
  }

  void _addToCache(String url, ImageProvider provider) {
    // Since we're using CachedNetworkImage, we don't need to maintain our own memory cache
    // Just track URLs for statistics
    _lruQueue.remove(url);
    _lruQueue.addFirst(url);
    _imageCache[url] =
        provider; // Keep for compatibility but CachedNetworkImage handles the real caching
    _evictIfNeeded();
  }

  void _evictIfNeeded() {
    while (_lruQueue.length > _maxCacheSize) {
      final url = _lruQueue.removeLast();
      if (_visibleImages.contains(url)) continue;

      _imageCache.remove(url);
      // No need to dispose ImageProvider
    }
  }

  @override
  dynamic getCachedMedia(String url) => _imageCache[url];

  @override
  void markAsVisible(String url) {
    _visibleImages.add(url);
  }

  @override
  void markAsNotVisible(String url) {
    _visibleImages.remove(url);
  }

  @override
  bool isMediaCached(String url) => _imageCache.containsKey(url);

  @override
  bool isMediaInitializing(String url) => _initializationCache.containsKey(url);

  @override
  void clearMedia(String url) {
    _imageCache.remove(url);
    _lruQueue.remove(url);
    _visibleImages.remove(url);
    _diskCache.removeFile(url); // Clean disk cache too
  }

  @override
  void clearCache() {
    _imageCache.clear();
    _lruQueue.clear();
    _visibleImages.clear();
    _diskCache.emptyCache(); // Clean disk cache
  }

  @override
  void clearOutsideRange(List<String> activeUrls) {
    final urlsToRemove =
        _imageCache.keys.where((url) => !activeUrls.contains(url)).toList();
    for (final url in urlsToRemove) {
      if (!_visibleImages.contains(url)) {
        clearMedia(url);
      }
    }
  }

  @override
  Map<String, dynamic> getCacheStats() => {
        'totalCached': _imageCache.length,
        'visibleCount': _visibleImages.length,
        'initializingCount': _initializationCache.length,
        'lruQueueSize': _lruQueue.length,
      };

  /// Check if image is already cached on disk by CachedNetworkImage
  Future<bool> _isImageCachedOnDisk(String url) async {
    try {
      final file = await _diskCache.getFileFromCache(url);
      return file != null;
    } catch (e) {
      debugPrint('⚠️ Error checking disk cache for $url: $e');
      return false;
    }
  }
}
