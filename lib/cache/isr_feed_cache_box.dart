import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ism_video_reel_player/cache/isr_feed_cache_entry.dart';
import 'package:ism_video_reel_player/cache/isr_feed_cache_metadata.dart';
import 'package:ism_video_reel_player/cache/isr_feed_cache_post_key.dart';

/// Low-level Hive access for one feed box (`posts` + `meta` JSON keys).
class IsrFeedCacheBox {
  IsrFeedCacheBox._(this._box, this.boxName);

  final Box<String> _box;
  final String boxName;

  static const postsKey = 'posts';
  static const metaKey = 'meta';

  static Future<IsrFeedCacheBox> open(String boxName) async {
    final box = await Hive.openBox<String>(boxName);
    return IsrFeedCacheBox._(box, boxName);
  }

  Future<void> close() async {
    if (_box.isOpen) {
      await _box.close();
    }
  }

  List<IsrFeedCacheEntry> readPosts() {
    final raw = _box.get(postsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (e) => IsrFeedCacheEntry.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .where((e) => e.postId.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[IsrFeedCacheBox] readPosts error ($boxName): $e');
      return [];
    }
  }

  Future<void> writePosts(List<IsrFeedCacheEntry> entries) async {
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _box.put(postsKey, encoded);
  }

  IsrFeedCacheMetadata? readMeta() {
    final raw = _box.get(metaKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return IsrFeedCacheMetadata.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> writeMeta(IsrFeedCacheMetadata meta) async {
    await _box.put(metaKey, jsonEncode(meta.toJson()));
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  Set<String> buildKeySet(List<IsrFeedCacheEntry> entries) =>
      {for (final e in entries) isrFeedPostKey(e.payload)};
}
