import 'package:ism_video_reel_player/utils/utils.dart';

/// Abstract interface for media (video/image) cache management
abstract class IMediaCacheManager {
  /// Precache media items for given URLs
  Future<void> precacheMedia(List<String> mediaUrls,
      {bool highPriority = false});

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

    // Video extensions - include HLS, DASH, and other streaming formats
    if (['mp4', 'mov', 'avi', 'mkv', 'm3u8', 'webm', 'ts', 'mpd', '3gp', 'flv', 'wmv'].contains(extension)) {
      return MediaType.video;
    }

    // Image extensions
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif', 'avif'].contains(extension)) {
      return MediaType.photo;
    }

    // Check URL path for video indicators (CDN URLs may not have file extensions)
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('/video/') || 
        lowerUrl.contains('/videos/') ||
        lowerUrl.contains('video_') ||
        lowerUrl.contains('/stream/') ||
        lowerUrl.contains('/hls/') ||
        lowerUrl.contains('/media/') && !lowerUrl.contains('/image/')) {
      return MediaType.video;
    }

    // Check URL path for image indicators
    if (lowerUrl.contains('/image/') || 
        lowerUrl.contains('/images/') ||
        lowerUrl.contains('/thumb/') ||
        lowerUrl.contains('/thumbnail/')) {
      return MediaType.photo;
    }

    return MediaType.unknown;
  }
}
