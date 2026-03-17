import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// Caches ONLY the first .ts segment of an HLS stream
class VideoMediaUtil {
  static final CacheManager _cache = DefaultCacheManager();

  /// Prevent duplicate parallel downloads
  static final Set<String> _inFlightSegments = {};

  static Future<void> precacheFirstSegment(String m3u8Url) async {
    if (!m3u8Url.endsWith('.m3u8')) return;

    try {
      // 1️⃣ Fetch playlist
      final response = await http.get(Uri.parse(m3u8Url));
      if (response.statusCode != 200) return;

      final lines = const LineSplitter().convert(response.body);

      // 2️⃣ Find first .ts segment
      final firstSegment = lines.firstWhere(
            (line) => line.isNotEmpty && !line.startsWith('#'),
        orElse: () => '',
      );

      if (firstSegment.isEmpty) return;

      // 3️⃣ Resolve absolute URL
      final segmentUrl =
      Uri.parse(m3u8Url).resolve(firstSegment).toString();

      // 🔒 Prevent duplicate parallel downloads
      if (_inFlightSegments.contains(segmentUrl)) return;
      _inFlightSegments.add(segmentUrl);

      // 4️⃣ Check disk cache FIRST
      final cached = await _cache.getFileFromCache(segmentUrl);
      if (cached != null) {
        debugPrint('♻️ First HLS segment already cached: $segmentUrl');
        _inFlightSegments.remove(segmentUrl);
        return;
      }

      // 5️⃣ Download & cache
      await _cache.downloadFile(segmentUrl, key: segmentUrl);
      debugPrint('✅ Cached first HLS segment: $segmentUrl');
    } catch (e) {
      debugPrint('⚠️ Failed to cache first HLS segment: $e');
    } finally {
      _inFlightSegments.clear();
    }
  }
}