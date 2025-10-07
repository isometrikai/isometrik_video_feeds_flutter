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
  static const int _maxCacheSize = 20; // More images can be cached compared to videos

  @override
  Future<void> precacheMedia(List<String> mediaUrls, {bool highPriority = false}) async {
    final futures = <Future<void>>[];

    for (final url in mediaUrls) {
      if (url.isEmpty) continue;
      if (isMediaCached(url)) continue;

      // Only process actual image URLs, skip video URLs
      final mediaType = MediaTypeUtil.getMediaType(url);
      if (mediaType != MediaType.image) {
        debugPrint('⚠️ Skipping non-image URL in precacheMedia: $url (type: $mediaType)');
        continue;
      }

      futures.add(_cacheImage(url, highPriority: highPriority));
    }

    await Future.wait(futures);
  }

  Future<void> _cacheImage(String url, {bool highPriority = false}) async {
    final cleanUrl = url.split('?').first.split('#').first;

    // Validate that this is actually an image URL
    final mediaType = MediaTypeUtil.getMediaType(cleanUrl);
    if (mediaType != MediaType.image) {
      debugPrint('⚠️ Attempted to cache non-image URL: $cleanUrl (type: $mediaType)');
      return;
    }

    if (_initializationCache.containsKey(cleanUrl)) {
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
      // Cache in memory
      final provider = NetworkImage(url);
      _addToCache(url, provider);

      // Cache on disk in parallel if high priority
      if (highPriority) {
        unawaited(_diskCache.downloadFile(url));
      }
    } catch (e) {
      debugPrint('Error initializing image cache for URL: $url');
      debugPrint('Error details: $e');
      rethrow;
    }
  }

  void _addToCache(String url, ImageProvider provider) {
    _lruQueue.remove(url);
    _lruQueue.addFirst(url);
    _imageCache[url] = provider;
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
    final urlsToRemove = _imageCache.keys.where((url) => !activeUrls.contains(url)).toList();
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
}
