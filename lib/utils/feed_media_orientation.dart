import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';

enum PostFeedMediaOrientation {
  portrait,
  landscape,
  square,
}

/// Probes image headers for feed aspect ratio when the API omits dimensions.
abstract final class FeedMediaOrientation {
  static const int _initialProbeBytes = 65536;
  static const int _extendedProbeBytes = 262144;
  static const Duration _requestTimeout = Duration(seconds: 8);
  static const Duration _prefetchBatchTimeout = Duration(seconds: 12);
  static const int _maxConcurrent = 2;

  static final Map<String, ({PostFeedMediaOrientation orientation, int width, int height})> _cache =
      {};
  static final Map<String, ValueNotifier<int>> _revisionByUrl = {};

  /// Rebuild only the post card tied to [url] when its probe finishes (not the whole feed).
  static Listenable listenableForUrl(String url) {
    final key = url.trim();
    return _revisionByUrl.putIfAbsent(key, () => ValueNotifier(0));
  }

  static bool get shouldProbeForCurrentConfig {
    final postConfig = IsrVideoReelConfig.postConfig;
    if (postConfig.feedLayoutType != FeedLayoutType.postFeed) return false;
    return postConfig.postFeedUIConfig?.cardStyle == PostFeedCardStyle.instagram;
  }

  static Future<void> prefetchForPosts(Iterable<TimeLineData> posts) async {
    if (!shouldProbeForCurrentConfig) return;

    final urls =
        _imageUrlsFromPosts(posts).where((url) => !_cache.containsKey(url)).toSet();
    if (urls.isEmpty) return;

    try {
      await _prefetchUrls(urls).timeout(_prefetchBatchTimeout, onTimeout: () {});
    } catch (_) {}
  }

  static double aspectRatioForImageUrl(
    String url, {
    required double portraitAspectRatio,
    required double landscapeAspectRatio,
    double squareAspectRatio = 1,
  }) {
    final probed = _cache[url.trim()];
    if (probed != null) {
      return _aspectRatioForOrientation(
        probed.orientation,
        portraitAspectRatio: portraitAspectRatio,
        landscapeAspectRatio: landscapeAspectRatio,
        squareAspectRatio: squareAspectRatio,
        width: probed.width,
        height: probed.height,
      );
    }

    final urlSize = _parseSizeFromUrl(url);
    if (urlSize != null) {
      return _aspectRatioForOrientation(
        _orientationFromSize(urlSize.$1, urlSize.$2),
        portraitAspectRatio: portraitAspectRatio,
        landscapeAspectRatio: landscapeAspectRatio,
        squareAspectRatio: squareAspectRatio,
        width: urlSize.$1,
        height: urlSize.$2,
      );
    }

    return portraitAspectRatio;
  }

  /// Only the first image per post — carousel frame uses that orientation for all pages.
  static Iterable<String> _imageUrlsFromPosts(Iterable<TimeLineData> posts) sync* {
    for (final post in posts) {
      final mediaList = post.media;
      if (mediaList == null || mediaList.isEmpty) continue;
      final first = mediaList.first;
      if ((first.mediaType ?? '').toLowerCase() != 'image') continue;
      final url = first.url?.trim();
      if (url != null && url.isNotEmpty) yield url;
    }
  }

  static Future<void> _prefetchUrls(Set<String> urls) async {
    final pending = urls.where((u) => !_cache.containsKey(u)).toList();
    if (pending.isEmpty) return;

    final pool = _maxConcurrent.clamp(1, pending.length);
    for (var i = 0; i < pending.length; i += pool) {
      final end = (i + pool) > pending.length ? pending.length : i + pool;
      await Future.wait(
        pending.sublist(i, end).map(_probeUrl),
        eagerError: false,
      );
    }
  }

  static Future<void> _probeUrl(String url) async {
    final key = url.trim();
    if (key.isEmpty || _cache.containsKey(key)) return;

    try {
      final size = await _fetchImageDimensions(key);
      if (size == null) return;

      _cache[key] = (
        orientation: _orientationFromSize(size.$1, size.$2),
        width: size.$1,
        height: size.$2,
      );
      final revision = _revisionByUrl[key];
      if (revision != null) {
        revision.value++;
      }
    } catch (_) {}
  }

  static PostFeedMediaOrientation _orientationFromSize(int width, int height) {
    if (width > height) return PostFeedMediaOrientation.landscape;
    if (width < height) return PostFeedMediaOrientation.portrait;
    return PostFeedMediaOrientation.square;
  }

  static double _aspectRatioForOrientation(
    PostFeedMediaOrientation orientation, {
    required double portraitAspectRatio,
    required double landscapeAspectRatio,
    required double squareAspectRatio,
    int? width,
    int? height,
  }) {
    switch (orientation) {
      case PostFeedMediaOrientation.portrait:
        return portraitAspectRatio;
      case PostFeedMediaOrientation.square:
        return squareAspectRatio;
      case PostFeedMediaOrientation.landscape:
        if (width != null && height != null && width > height) {
          final intrinsic = width / height;
          if (intrinsic > landscapeAspectRatio) return landscapeAspectRatio;
          return intrinsic < 1.0 ? 1.0 : intrinsic;
        }
        return landscapeAspectRatio;
    }
  }

  static Future<(int, int)?> _fetchImageDimensions(String url) async {
    var bytes = await _downloadBytes(url, _initialProbeBytes);
    var size = _readDimensions(bytes);
    if (size != null) return size;

    bytes = await _downloadBytes(url, _extendedProbeBytes);
    return _readDimensions(bytes);
  }

  static Future<Uint8List> _downloadBytes(String url, int maxBytes) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {'Range': 'bytes=0-${maxBytes - 1}'},
    ).timeout(_requestTimeout);

    if (response.statusCode != 200 && response.statusCode != 206) {
      throw StateError('HTTP ${response.statusCode}');
    }

    final body = response.bodyBytes;
    return body.length <= maxBytes ? body : Uint8List.sublistView(body, 0, maxBytes);
  }

  static (int, int)? _readDimensions(Uint8List bytes) {
    if (bytes.length < 24) return null;
    return _pngDimensions(bytes) ?? _jpegDimensions(bytes) ?? _webpDimensions(bytes);
  }

  static (int, int)? _pngDimensions(Uint8List bytes) {
    if (bytes.length < 24 ||
        bytes[0] != 0x89 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x4E ||
        bytes[3] != 0x47) {
      return null;
    }
    final w = _uint32Be(bytes, 16);
    final h = _uint32Be(bytes, 20);
    return w > 0 && h > 0 ? (w, h) : null;
  }

  static (int, int)? _jpegDimensions(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return null;

    var offset = 2;
    while (offset + 3 < bytes.length) {
      if (bytes[offset] != 0xFF) {
        offset++;
        continue;
      }

      var markerIndex = offset;
      var marker = bytes[markerIndex + 1];
      while (marker == 0xFF && markerIndex + 1 < bytes.length) {
        markerIndex++;
        marker = bytes[markerIndex + 1];
      }
      offset = markerIndex;

      if (offset + 3 >= bytes.length) break;

      final markerType = bytes[offset + 1];
      if (markerType == 0xD9 || markerType == 0xDA) break;

      final segmentLength = (bytes[offset + 2] << 8) | bytes[offset + 3];
      if (segmentLength < 2) break;

      final isSof = markerType >= 0xC0 &&
          markerType <= 0xCF &&
          markerType != 0xC4 &&
          markerType != 0xC8 &&
          markerType != 0xCC;
      if (isSof && offset + 8 < bytes.length) {
        final h = (bytes[offset + 5] << 8) | bytes[offset + 6];
        final w = (bytes[offset + 7] << 8) | bytes[offset + 8];
        return w > 0 && h > 0 ? (w, h) : null;
      }

      offset += 2 + segmentLength;
    }
    return null;
  }

  static (int, int)? _webpDimensions(Uint8List bytes) {
    if (bytes.length < 30 ||
        bytes[0] != 0x52 ||
        bytes[1] != 0x49 ||
        bytes[2] != 0x46 ||
        bytes[3] != 0x46 ||
        bytes[8] != 0x57 ||
        bytes[9] != 0x45 ||
        bytes[10] != 0x42 ||
        bytes[11] != 0x50) {
      return null;
    }

    final format = String.fromCharCodes(bytes.sublist(12, 16));
    if (format == 'VP8 ' && bytes.length >= 30) {
      final w = (bytes[26] | (bytes[27] << 8)) & 0x3FFF;
      final h = (bytes[28] | (bytes[29] << 8)) & 0x3FFF;
      return w > 0 && h > 0 ? (w, h) : null;
    }
    if (format == 'VP8L' && bytes.length >= 25) {
      final bits =
          bytes[21] | (bytes[22] << 8) | (bytes[23] << 16) | (bytes[24] << 24);
      final w = (bits & 0x3FFF) + 1;
      final h = ((bits >> 14) & 0x3FFF) + 1;
      return w > 0 && h > 0 ? (w, h) : null;
    }
    if (format == 'VP8X' && bytes.length >= 30) {
      final w = 1 + (bytes[24] | (bytes[25] << 8) | (bytes[26] << 16));
      final h = 1 + (bytes[27] | (bytes[28] << 8) | (bytes[29] << 16));
      return w > 0 && h > 0 ? (w, h) : null;
    }
    return null;
  }

  static int _uint32Be(Uint8List bytes, int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];

  static (int, int)? _parseSizeFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    final uri = Uri.tryParse(url);
    if (uri != null) {
      final w = int.tryParse(uri.queryParameters['width'] ?? uri.queryParameters['w'] ?? '');
      final h = int.tryParse(uri.queryParameters['height'] ?? uri.queryParameters['h'] ?? '');
      if (w != null && h != null && w > 0 && h > 0) return (w, h);
    }

    final match = RegExp(r'(\d{3,5})[xX](\d{3,5})').firstMatch(url);
    if (match != null) {
      final w = int.tryParse(match.group(1)!);
      final h = int.tryParse(match.group(2)!);
      if (w != null && h != null && w > 0 && h > 0) return (w, h);
    }
    return null;
  }
}
