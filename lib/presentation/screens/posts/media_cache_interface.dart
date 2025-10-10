import 'package:ism_video_reel_player/ism_video_reel_player.dart';

/// Abstract interface for media (video/image) cache management
abstract class IMediaCacheManager {
  /// Precache media items for given URLs
  Future<void> precacheMedia(List<String> mediaUrls, {bool highPriority = false});

  /// Get cached media item (could be controller for video or image provider for images)
  dynamic getCachedMedia(String url);

  /// Mark media as visible (prevents disposal)
  void markAsVisible(String url);

  /// Mark media as not visible (allows disposal)
  void markAsNotVisible(String url);

  /// Check if media is cached and ready
  bool isMediaCached(String url);

  /// Check if media is initializing
  bool isMediaInitializing(String url);

  /// Clear specific media from cache
  void clearMedia(String url);

  /// Clear all cached media
  void clearCache();

  /// Clear media outside given range
  void clearOutsideRange(List<String> activeUrls);

  /// Get cache statistics
  Map<String, dynamic> getCacheStats();
}

/// Configuration for media caching
class MediaCacheConfig {
  const MediaCacheConfig({
    this.maxCacheSize = 10,
    this.maxAge = const Duration(hours: 1),
    this.enableDiskCache = true,
    this.maxDiskSizeInBytes = 100 * 1024 * 1024, // 100MB by default
  });
  final int maxCacheSize;
  final Duration maxAge;
  final bool enableDiskCache;
  final int maxDiskSizeInBytes;
}

/// Utility class to determine media type
class MediaTypeUtil {
  static MediaType getMediaType(String url) {
    // Remove query parameters and fragments before extracting extension
    final cleanUrl = url.split('?').first.split('#').first;
    final extension = cleanUrl.split('.').last.toLowerCase();

    // Video extensions
    if (['mp4', 'mov', 'avi', 'mkv', 'm3u8', 'webm'].contains(extension)) {
      return MediaType.video;
    }

    // Image extensions
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension)) {
      return MediaType.image;
    }

    return MediaType.unknown;
  }
}
