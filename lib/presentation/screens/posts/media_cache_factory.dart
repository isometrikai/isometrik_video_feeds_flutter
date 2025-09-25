import 'package:flutter/foundation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/image_cache_manager.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/media_cache_interface.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_cache_manager.dart';

/// Factory class to create and manage media cache instances
class MediaCacheFactory {
  static final Map<MediaType, IMediaCacheManager> _cacheManagers = {
    MediaType.image: ImageCacheManager(),
    MediaType.video: VideoCacheManager(),
  };

  /// Get cache manager for specific media type
  static IMediaCacheManager getCacheManager(MediaType type) =>
      _cacheManagers[type] ?? _cacheManagers[MediaType.unknown]!;

  /// Precache multiple media items, automatically determining their type
  static Future<void> precacheMedia(List<String> mediaUrls,
      {bool highPriority = false}) async {
    final mediaByType = <MediaType, List<String>>{};

    // Group URLs by media type
    for (final url in mediaUrls) {
      final type = MediaTypeUtil.getMediaType(url);
      mediaByType.putIfAbsent(type, () => []).add(url);
    }

    // Precache each type in parallel
    final futures = mediaByType.entries.map((entry) {
      final type = entry.key;
      final urls = entry.value;
      debugPrint('Precaching ${urls.length} ${type.toString()} items');
      return getCacheManager(type)
          .precacheMedia(urls, highPriority: highPriority);
    });

    await Future.wait(futures);
  }

  /// Clear all media caches
  static void clearAllCaches() {
    for (final manager in _cacheManagers.values) {
      manager.clearCache();
    }
  }

  /// Get combined cache statistics
  static Map<String, dynamic> getCombinedStats() {
    final stats = <String, dynamic>{};
    for (final entry in _cacheManagers.entries) {
      stats[entry.key.toString()] = entry.value.getCacheStats();
    }
    return stats;
  }

  /// Clear media outside range for all types
  static void clearOutsideRange(List<String> activeUrls) {
    for (final manager in _cacheManagers.values) {
      manager.clearOutsideRange(activeUrls);
    }
  }
}
