import 'dart:convert';

String _firstName(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.split(RegExp(r'\s+')).first;
}

StoryData? _pickRepresentativeStory(List<StoryData> stories) {
  for (final story in stories) {
    final hasName =
        story.fullName.trim().isNotEmpty || story.username.trim().isNotEmpty;
    final hasAvatar = story.avatarUrl.trim().isNotEmpty;
    if (hasName || hasAvatar) return story;
  }
  return stories.isNotEmpty ? stories.first : null;
}

class StoryFeedResponse {
  StoryFeedResponse({
    this.unViewed = const [],
    this.viewed = const [],
    this.nextCursor,
  });

  factory StoryFeedResponse.fromMap(Map<String, dynamic> map) {
    final legacyUn = (map['unviewed'] ?? map['un_viewed']) as List<dynamic>?;
    final legacyViewed = map['viewed'] as List<dynamic>?;
    if (legacyUn != null || legacyViewed != null) {
      return StoryFeedResponse(
        unViewed: (legacyUn ?? [])
            .map((e) => StoryGroup.fromMap(e as Map<String, dynamic>))
            .toList(),
        viewed: (legacyViewed ?? [])
            .map((e) => StoryGroup.fromMap(e as Map<String, dynamic>))
            .toList(),
        nextCursor: map['next_cursor']?.toString(),
      );
    }

    // TrulyFree-style feed: data.stories (flat or grouped rings)
    final storiesKey = map['stories'] as List<dynamic>? ??
        map['items'] as List<dynamic>? ??
        [];
    if (storiesKey.isEmpty) {
      return StoryFeedResponse(
        nextCursor: map['next_cursor']?.toString(),
      );
    }
    final first = storiesKey.first;
    if (first is! Map<String, dynamic>) {
      return StoryFeedResponse(
        nextCursor: map['next_cursor']?.toString(),
      );
    }
    if (first['stories'] is List) {
      return StoryFeedResponse(
        unViewed: storiesKey
            .map((e) => StoryGroup.fromMap(e as Map<String, dynamic>))
            .toList(),
        nextCursor: map['next_cursor']?.toString(),
      );
    }
    final flat = storiesKey
        .map((e) => StoryData.fromMap(e as Map<String, dynamic>))
        .toList();
    final byUser = <String, List<StoryData>>{};
    for (final s in flat) {
      final key = s.userId.isEmpty ? '_me' : s.userId;
      byUser.putIfAbsent(key, () => []).add(s);
    }
    final groups = byUser.entries.map(
      (e) {
        final firstStory = _pickRepresentativeStory(e.value);
        final derivedName = _firstName(
          firstStory?.fullName ?? firstStory?.username ?? '',
        );
        return StoryGroup(
          userId: e.key == '_me' ? '' : e.key,
          username: derivedName,
          avatarUrl: firstStory?.avatarUrl ?? '',
          stories: e.value,
        );
      },
    ).toList();
    return StoryFeedResponse(
      unViewed: groups,
      nextCursor: map['next_cursor']?.toString(),
    );
  }

  final List<StoryGroup> unViewed;
  final List<StoryGroup> viewed;
  final String? nextCursor;
}

class StoryGroup {
  StoryGroup({
    this.userId = '',
    this.username = '',
    this.avatarUrl = '',
    this.stories = const [],
    this.isViewed = false,
  });

  factory StoryGroup.fromMap(Map<String, dynamic> map) {
    final stories = (map['stories'] as List<dynamic>? ?? [])
        .map((e) => StoryData.fromMap(e as Map<String, dynamic>))
        .toList();
    final firstStory = _pickRepresentativeStory(stories);
    final username = map['username']?.toString() ??
        _firstName(firstStory?.fullName ?? firstStory?.username ?? '');
    final avatarUrl = map['avatar_url']?.toString() ??
        map['url']?.toString() ??
        firstStory?.avatarUrl ??
        '';
    return StoryGroup(
      userId: map['user_id']?.toString() ?? '',
      username: username,
      avatarUrl: avatarUrl,
      stories: stories,
      isViewed: map['is_viewed'] as bool? ?? false,
    );
  }

  final String userId;
  final String username;
  final String avatarUrl;
  final List<StoryData> stories;
  final bool isViewed;

  bool get allStoriesViewed =>
      stories.isEmpty ? isViewed : stories.every((s) => s.isViewed);
}

int _storyViewCountFromMap(
  Map<String, dynamic>? engagementMap,
  Map<String, dynamic> map,
) {
  final fromEngagement = engagementMap?['view_count'];
  if (fromEngagement is num) return fromEngagement.toInt();
  if (fromEngagement is String) return int.tryParse(fromEngagement) ?? 0;
  final topLevel = map['view_count'];
  if (topLevel is num) return topLevel.toInt();
  if (topLevel is String) return int.tryParse(topLevel) ?? 0;
  return 0;
}

class StoryData {
  StoryData({
    this.id = '',
    this.userId = '',
    this.mediaUrl = '',
    this.mediaType = '',
    this.caption = '',
    this.username = '',
    this.fullName = '',
    this.avatarUrl = '',
    this.createdAt = '',
    this.expiresAt = '',
    this.isViewed = false,
    this.isReacted = false,
    this.viewCount = 0,
  });

  factory StoryData.fromMap(Map<String, dynamic> map) {
    final media = map['media'];
    final mediaMap = media is Map<String, dynamic> ? media : null;
    final user = map['user'];
    final userMap = user is Map<String, dynamic> ? user : null;
    final engagement = map['engagement_metrics'];
    final engagementMap =
        engagement is Map<String, dynamic> ? engagement : null;
    return StoryData(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      mediaUrl: map['media_url']?.toString() ??
          map['url']?.toString() ??
          mediaMap?['url']?.toString() ??
          mediaMap?['media_url']?.toString() ??
          '',
      mediaType: map['media_type']?.toString() ??
          mediaMap?['media_type']?.toString() ??
          '',
      caption: map['caption']?.toString() ?? '',
      username: userMap?['username']?.toString() ?? '',
      fullName: userMap?['full_name']?.toString() ??
          userMap?['display_name']?.toString() ??
          '',
      avatarUrl: userMap?['avatar_url']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
      expiresAt: map['expires_at']?.toString() ?? '',
      isViewed: map['is_viewed'] as bool? ?? false,
      isReacted: map['is_reacted'] as bool? ?? false,
      viewCount: _storyViewCountFromMap(engagementMap, map),
    );
  }

  StoryData copyWith({
    String? id,
    String? userId,
    String? mediaUrl,
    String? mediaType,
    String? caption,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? createdAt,
    String? expiresAt,
    bool? isViewed,
    bool? isReacted,
    int? viewCount,
  }) =>
      StoryData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        mediaType: mediaType ?? this.mediaType,
        caption: caption ?? this.caption,
        username: username ?? this.username,
        fullName: fullName ?? this.fullName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
        isViewed: isViewed ?? this.isViewed,
        isReacted: isReacted ?? this.isReacted,
        viewCount: viewCount ?? this.viewCount,
      );

  final String id;
  final String userId;
  final String mediaUrl;
  final String mediaType;
  final String caption;
  final String username;
  final String fullName;
  final String avatarUrl;
  final String createdAt;
  final String expiresAt;
  final bool isViewed;
  final bool isReacted;
  final int viewCount;
}

class StoryHighlightData {
  StoryHighlightData({
    this.id = '',
    this.userId = '',
    this.title = '',
    this.coverUrl = '',
    this.sortOrder = 0,
    this.items = const [],
    this.embeddedStories = const [],
  });

  factory StoryHighlightData.fromMap(Map<String, dynamic> map) =>
      StoryHighlightData(
        id: map['id']?.toString() ?? '',
        userId: map['user_id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        coverUrl: map['cover_url']?.toString() ?? '',
        sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
        items: _highlightItemsFromMap(map),
        embeddedStories: _embeddedStoriesFromHighlightMap(map),
      );

  /// Full story rows from `GET .../highlights/:id` (`data.stories`). Used to open
  /// the highlight viewer without calling `/stories` or per-story detail (which
  /// may be empty or fail for archived / highlight-only stories).
  static List<StoryData> _embeddedStoriesFromHighlightMap(
    Map<String, dynamic> map,
  ) {
    final dynamic raw = map['stories'];
    if (raw is! List<dynamic> || raw.isEmpty) return const [];
    return raw
        .map((e) => e is Map ? Map<String, dynamic>.from(e) : null)
        .whereType<Map<String, dynamic>>()
        .map(StoryData.fromMap)
        .where(
          (s) =>
              s.id.trim().isNotEmpty && s.mediaUrl.trim().isNotEmpty,
        )
        .toList();
  }

  static List<StoryHighlightItem> _highlightItemsFromMap(
    Map<String, dynamic> map,
  ) {
    // Prefer `stories` when the API sends it (detail + full payloads). A
    // non-empty but partial `items` list must not hide additional stories.
    final dynamic rawStories = map['stories'];
    if (rawStories is List<dynamic> && rawStories.isNotEmpty) {
      return rawStories
          .map((e) => e is Map ? Map<String, dynamic>.from(e) : null)
          .whereType<Map<String, dynamic>>()
          .map(
            (storyMap) => StoryHighlightItem(
              itemId: storyMap['item_id']?.toString() ?? '',
              storyId: storyMap['story_id']?.toString() ??
                  storyMap['id']?.toString() ??
                  '',
            ),
          )
          .where((item) => item.storyId.trim().isNotEmpty)
          .toList();
    }

    final dynamic rawItems = map['items'];
    if (rawItems is List<dynamic> && rawItems.isNotEmpty) {
      return rawItems
          .map((e) => e is Map ? Map<String, dynamic>.from(e) : null)
          .whereType<Map<String, dynamic>>()
          .map(StoryHighlightItem.fromMap)
          .where((item) => item.storyId.trim().isNotEmpty)
          .toList();
    }

    return const <StoryHighlightItem>[];
  }

  final String id;
  final String userId;
  final String title;
  final String coverUrl;
  final int sortOrder;
  final List<StoryHighlightItem> items;
  final List<StoryData> embeddedStories;
}

class StoryHighlightItem {
  StoryHighlightItem({
    this.itemId = '',
    this.storyId = '',
  });

  factory StoryHighlightItem.fromMap(Map<String, dynamic> map) =>
      StoryHighlightItem(
        itemId: map['item_id']?.toString() ?? '',
        storyId: map['story_id']?.toString() ?? map['id']?.toString() ?? '',
      );

  final String itemId;
  final String storyId;
}

List<StoryHighlightData> storyHighlightsFromResponseData(String rawData) {
  final map = jsonDecode(rawData) as Map<String, dynamic>;
  final list = map['data'] as List<dynamic>? ?? [];
  return list
      .map((e) => StoryHighlightData.fromMap(e as Map<String, dynamic>))
      .toList();
}
