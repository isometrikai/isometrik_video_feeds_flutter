import 'package:ism_video_reel_player/cache/isr_feed_cache_box.dart';
import 'package:ism_video_reel_player/cache/isr_feed_cache_entry.dart';
import 'package:ism_video_reel_player/cache/isr_feed_cache_metadata.dart';
import 'package:ism_video_reel_player/cache/isr_feed_cache_post_key.dart';
import 'package:ism_video_reel_player/cache/isr_feed_cache_section.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_feed_cache_config.dart';

/// Hive-backed cache for follow-sensitive SDK tabs (Following + Feeds).
class IsrFeedCacheRepository {
  IsrFeedCacheRepository._();

  static final IsrFeedCacheRepository instance = IsrFeedCacheRepository._();

  IsrFeedCacheConfig _config = const IsrFeedCacheConfig();
  String _ownerKey = 'guest';
  bool _initialized = false;
  Future<void>? _initFuture;

  final Map<IsrFeedCacheSection, IsrFeedCacheBox?> _boxes = {
    IsrFeedCacheSection.following: null,
    IsrFeedCacheSection.feeds: null,
  };

  bool get isEnabled => _initialized && _config.enabledSections.isNotEmpty;

  IsrFeedCacheConfig get config => _config;

  String _boxSuffix() => 'v${_config.cacheVersion}';

  String _boxName(IsrFeedCacheSection section, String owner) =>
      'isr_feed_cache_${section.name}_${owner}_${_boxSuffix()}';

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initFuture ??= _initInternal();
    await _initFuture;
  }

  Future<void> init({
    required IsrFeedCacheConfig config,
    required String ownerKey,
  }) async {
    _config = config;
    _ownerKey = ownerKey.isEmpty ? 'guest' : ownerKey;
    _initFuture = _initInternal();
    await _initFuture;
  }

  Future<void> reopenForOwner(String ownerKey) async {
    final next = ownerKey.isEmpty ? 'guest' : ownerKey;
    if (next == _ownerKey && _initialized) return;
    _ownerKey = next;
    await _closeBoxes();
    if (_config.enabledSections.isEmpty) {
      _initialized = false;
      return;
    }
    await _openBoxes();
    _initialized = true;
  }

  Future<void> _initInternal() async {
    if (_config.enabledSections.isEmpty) {
      _initialized = false;
      return;
    }
    if (_boxes.values.every((b) => b != null)) {
      _initialized = true;
      return;
    }
    var owner = _ownerKey;
    if (owner == 'guest' || owner.isEmpty) {
      try {
        owner =
            await IsmInjectionUtils.getUseCase<IsmLocalDataUseCase>().getUserId();
      } catch (_) {}
      if (owner.isEmpty) owner = 'guest';
      _ownerKey = owner;
    }
    await _openBoxes();
    _initialized = true;
  }

  Future<void> _openBoxes() async {
    for (final section in IsrFeedCacheSection.values) {
      if (!_enabled(section)) {
        _boxes[section] = null;
        continue;
      }
      _boxes[section] = await IsrFeedCacheBox.open(
        _boxName(section, _ownerKey),
      );
    }
  }

  Future<void> _closeBoxes() async {
    for (final section in IsrFeedCacheSection.values) {
      await _boxes[section]?.close();
      _boxes[section] = null;
    }
  }

  bool _enabled(IsrFeedCacheSection section) =>
      _config.enabledSections.contains(section);

  IsrFeedCacheBox? _box(IsrFeedCacheSection section) {
    if (!_initialized || !_enabled(section)) return null;
    return _boxes[section];
  }

  List<Map<String, dynamic>> getPosts(IsrFeedCacheSection section) {
    final box = _box(section);
    if (box == null) return [];
    try {
      return box
          .readPosts()
          .map((e) => Map<String, dynamic>.from(e.payload))
          .toList();
    } catch (_) {
      return [];
    }
  }

  IsrFeedCacheMetadata? getMeta(IsrFeedCacheSection section) {
    final box = _box(section);
    if (box == null) return null;
    try {
      return box.readMeta();
    } catch (_) {
      return null;
    }
  }

  bool isSectionExpired(IsrFeedCacheSection section) {
    final meta = getMeta(section);
    if (meta == null) return true;
    final ttl = _config.ttlFor(section);
    return DateTime.now().difference(meta.lastFetchedAt) > ttl;
  }

  /// Full replace after refresh / first API page — removes unfollowed authors' posts.
  Future<void> replaceSection(
    IsrFeedCacheSection section,
    List<Map<String, dynamic>> orderedMaps, {
    bool? hasMore,
    int? currentPage,
  }) async {
    final box = _box(section);
    if (box == null) return;

    final cap = _config.maxItemsPerSection;
    final entries = <IsrFeedCacheEntry>[];
    final seen = <String>{};
    for (final m in orderedMaps) {
      final id = isrFeedPostKey(m);
      if (!seen.add(id)) continue;
      entries.add(
        IsrFeedCacheEntry(
          postId: id,
          payload: Map<String, dynamic>.from(m),
          insertedAt: DateTime.now(),
        ),
      );
    }
    final list = entries.length > cap ? entries.sublist(0, cap) : entries;

    await box.writePosts(list);
    final prev = box.readMeta();
    await box.writeMeta(
      IsrFeedCacheMetadata(
        hasMore: hasMore ?? prev?.hasMore ?? true,
        lastFetchedAt: DateTime.now(),
        ownerKey: _ownerKey,
        version: _config.cacheVersion,
        currentPage: currentPage ?? prev?.currentPage,
      ),
    );
  }

  /// Append-only for pagination (deduped).
  Future<void> appendSection(
    IsrFeedCacheSection section,
    List<Map<String, dynamic>> newMaps, {
    bool? hasMore,
    int? currentPage,
  }) async {
    final box = _box(section);
    if (box == null || newMaps.isEmpty) return;

    final cap = _config.maxItemsPerSection;
    final existing = box.readPosts();
    final keys = box.buildKeySet(existing);
    final merged = [...existing];

    for (final m in newMaps) {
      final id = isrFeedPostKey(m);
      if (keys.contains(id)) continue;
      keys.add(id);
      merged.add(
        IsrFeedCacheEntry(
          postId: id,
          payload: Map<String, dynamic>.from(m),
          insertedAt: DateTime.now(),
        ),
      );
    }

    final trimmed =
        merged.length > cap ? merged.sublist(merged.length - cap) : merged;
    await box.writePosts(trimmed);
    final prev = box.readMeta();
    await box.writeMeta(
      IsrFeedCacheMetadata(
        hasMore: hasMore ?? prev?.hasMore ?? true,
        lastFetchedAt: prev?.lastFetchedAt ?? DateTime.now(),
        ownerKey: _ownerKey,
        version: _config.cacheVersion,
        currentPage: currentPage ?? prev?.currentPage,
      ),
    );
  }

  Future<void> removePostEverywhere(String postId) async {
    if (postId.isEmpty || !_initialized) return;
    for (final section in _config.enabledSections) {
      await _removeWhere(
        section,
        (e) => e.postId == postId || _payloadMatchesPostId(e, postId),
      );
    }
  }

  Future<void> removePostsByAuthor(String authorUserId) async {
    if (authorUserId.isEmpty || !_initialized) return;
    for (final section in _config.enabledSections) {
      await _removeWhere(
        section,
        (e) => isrFeedAuthorUserId(e.payload) == authorUserId,
      );
    }
  }

  Future<void> _removeWhere(
    IsrFeedCacheSection section,
    bool Function(IsrFeedCacheEntry e) test,
  ) async {
    final box = _box(section);
    if (box == null) return;
    final entries = box.readPosts();
    final next = entries.where((e) => !test(e)).toList();
    if (next.length == entries.length) return;
    await box.writePosts(next);
  }

  bool _payloadMatchesPostId(IsrFeedCacheEntry e, String postId) {
    final id = e.payload['id']?.toString() ??
        e.payload['postId']?.toString() ??
        e.payload['_id']?.toString();
    return id == postId;
  }

  Future<void> clear({IsrFeedCacheSection? only}) async {
    if (!_initialized) return;
    final targets = only != null ? [only] : _config.enabledSections.toList();
    for (final section in targets) {
      await _box(section)?.clearAll();
    }
  }
}
