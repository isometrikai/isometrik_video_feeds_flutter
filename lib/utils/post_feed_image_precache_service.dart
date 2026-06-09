import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/feed_media_orientation.dart';

/// Disk cache for post-feed still frames (images + video thumbnails only).
class IsrPostFeedImageCacheManager {
  IsrPostFeedImageCacheManager._();

  static CacheManager? _instance;

  static CacheManager get instance => _instance ??= CacheManager(
        Config(
          'isr_post_feed_images',
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 300,
        ),
      );
}

/// Scroll-ahead image precache for Instagram-style post feeds.
///
/// Never downloads video streams — only [PostFeedMediaDescriptor.precacheUrl]
/// (images and thumbnails for locked/video posts).
class PostFeedImagePrecacheService {
  PostFeedImagePrecacheService({
    this.maxConcurrent = 4,
    this.lookAhead = 16,
  });

  final int maxConcurrent;
  final int lookAhead;

  final Set<String> _completed = <String>{};
  final Set<String> _inFlight = <String>{};
  int _generation = 0;

  void cancel() {
    _generation++;
    _inFlight.clear();
  }

  Future<void> precacheReels(
    List<ReelsData> reels, {
    BuildContext? context,
    int startIndex = 0,
  }) async {
    if (reels.isEmpty) return;
    final end = (startIndex + lookAhead).clamp(0, reels.length);
    final slice = reels.sublist(startIndex.clamp(0, reels.length), end);
    final descriptors = slice
        .map(FeedMediaOrientation.resolveDescriptor)
        .where((d) => d.precacheUrl != null)
        .toList(growable: false);
    await precacheDescriptors(descriptors, context: context);
    unawaited(FeedMediaOrientation.prefetchForReels(slice));
  }

  Future<void> precacheDescriptors(
    Iterable<PostFeedMediaDescriptor> descriptors, {
    BuildContext? context,
  }) async {
    final urls = descriptors
        .map((d) => d.precacheUrl)
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    await precacheUrls(urls, context: context);
  }

  Future<void> precacheUrls(
    List<String> urls, {
    BuildContext? context,
  }) async {
    if (urls.isEmpty) return;

    final generation = _generation;
    final pending = urls
        .where((url) => !_completed.contains(url) && !_inFlight.contains(url))
        .toList(growable: false);

    if (pending.isEmpty) return;

    for (var i = 0; i < pending.length; i += maxConcurrent) {
      if (generation != _generation) return;
      final batch = pending.skip(i).take(maxConcurrent);
      await Future.wait(
        batch.map(_downloadAndStore),
        eagerError: false,
      );
    }

    if (context == null || !context.mounted || generation != _generation) {
      return;
    }

    for (final url in pending) {
      if (!_completed.contains(url)) continue;
      unawaited(
        precacheImage(
          CachedNetworkImageProvider(
            url,
            cacheKey: url,
            cacheManager: IsrPostFeedImageCacheManager.instance,
          ),
          context,
        ),
      );
    }
  }

  Future<void> _downloadAndStore(String url) async {
    if (_inFlight.contains(url) || _completed.contains(url)) return;
    _inFlight.add(url);

    try {
      final cached =
          await IsrPostFeedImageCacheManager.instance.getFileFromCache(url);
      if (cached != null) {
        _completed.add(url);
        return;
      }

      final bytes = await _downloadBytesInIsolate(url);
      if (bytes != null && bytes.isNotEmpty) {
        await IsrPostFeedImageCacheManager.instance.putFile(
          url,
          bytes,
          key: url,
        );
        _completed.add(url);
        return;
      }

      await IsrPostFeedImageCacheManager.instance
          .downloadFile(url)
          .timeout(const Duration(seconds: 12), onTimeout: () => throw TimeoutException(''));
      _completed.add(url);
    } catch (_) {
      // Individual misses fall back to widget placeholders — never block scroll.
    } finally {
      _inFlight.remove(url);
    }
  }
}

Future<Uint8List?> _downloadBytesInIsolate(String url) =>
    Isolate.run(() => _downloadBytes(url));

Future<Uint8List?> _downloadBytes(String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) return null;
    return consolidateHttpClientResponseBytes(response);
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
