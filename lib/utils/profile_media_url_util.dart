import 'package:flutter/foundation.dart';
import 'package:ism_video_reel_player/domain/models/response/timeline_response.dart';

/// Extracts a still image URL from timeline post [media] / [previews] lists.
abstract final class ProfileMediaUrlUtil {
  ProfileMediaUrlUtil._();

  static String? extractMediaUrl(dynamic post) {
    if (post == null) return null;
    return _urlFromList(_getList(post, 'previews')) ??
        _urlFromList(_getList(post, 'media'));
  }

  static List<dynamic>? _getList(dynamic source, String key) {
    if (source == null) return null;
    try {
      if (source is Map && source.containsKey(key)) {
        final value = source[key];
        return value is List ? value : null;
      }
      final dynamic value = key == 'previews'
          ? (source as dynamic).previews
          : (source as dynamic).media;
      return value is List ? value : null;
    } catch (e) {
      debugPrint('ProfileMediaUrlUtil._getList error: $e');
      return null;
    }
  }

  static String? _urlFromList(List<dynamic>? list) {
    if (list == null || list.isEmpty) return null;
    final sorted = List<dynamic>.from(list);
    try {
      sorted.sort((a, b) {
        final pa = _positionOf(a);
        final pb = _positionOf(b);
        return pa.compareTo(pb);
      });
    } catch (_) {}
    for (final item in sorted) {
      final url = _resolveMediaItemUrl(item);
      if (url != null && url.isNotEmpty) return _cleanUrl(url);
    }
    return null;
  }

  static num _positionOf(dynamic item) {
    if (item is Map) return (item['position'] as num?) ?? 0;
    return (item as dynamic).position as num? ?? 0;
  }

  static String? _resolveMediaItemUrl(dynamic item) {
    try {
      if (item is Map) {
        final type = item['media_type']?.toString();
        final url = item['url']?.toString() ?? '';
        final preview = item['preview_url']?.toString() ?? '';
        if (type == 'video') {
          return _usableStillUrl(preview);
        }
        return _usableStillUrl(url);
      }
      if (item is PreviewMedia) {
        return _usableStillUrl(item.url);
      }
      if (item is MediaData) {
        final type = item.mediaType?.toString();
        if (type == 'video') {
          return _usableStillUrl(item.previewUrl);
        }
        return _usableStillUrl(item.url);
      }
      return null;
    } catch (e) {
      debugPrint('ProfileMediaUrlUtil._resolveMediaItemUrl error: $e');
      return null;
    }
  }

  static String? _usableStillUrl(String? candidate) {
    final stripped = (candidate ?? '').trim();
    if (stripped.isEmpty || _looksLikeStreamingOrVideoUrl(stripped)) {
      return null;
    }
    return _cleanUrl(stripped);
  }

  static bool _looksLikeStreamingOrVideoUrl(String url) {
    final u = url.trim().toLowerCase();
    if (u.isEmpty) return false;
    return u.endsWith('.mp4') ||
        u.endsWith('.mov') ||
        u.endsWith('.m3u8') ||
        u.endsWith('.webm') ||
        u.endsWith('.m4v') ||
        u.contains('.m3u8');
  }

  static String _cleanUrl(String url) {
    final stripped = url.replaceAll("''", '').trim();
    if (stripped.startsWith('http://') || stripped.startsWith('https://')) {
      return stripped;
    }
    return stripped;
  }
}
