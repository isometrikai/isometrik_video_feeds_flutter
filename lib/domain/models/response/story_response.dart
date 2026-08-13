import 'dart:convert';

import 'package:ism_video_reel_player/domain/models/response/timeline_response.dart';

String _storyPreferredName(StoryData? story) {
  if (story == null) return '';
  final candidates = <String>[
    story.displayName,
    story.fullName,
    story.username,
  ];
  for (final value in candidates) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return '';
}

StoryData? _pickRepresentativeStory(List<StoryData> stories) {
  for (final story in stories) {
    final hasName = _storyPreferredName(story).isNotEmpty;
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
        final derivedName = _storyPreferredName(firstStory);
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

StoriesResponse storiesResponseFromJson(String str) =>
    StoriesResponse.fromMap(json.decode(str) as Map<String, dynamic>);

String storiesResponseToJson(StoriesResponse data) =>
    json.encode(data.toMap());

class StoriesResponse {
  StoriesResponse({
    this.status,
    this.message,
    this.statusCode,
    this.code,
    this.data,
  });

  factory StoriesResponse.fromMap(Map<String, dynamic> map) => StoriesResponse(
        status: map['status']?.toString() ?? '',
        message: map['message']?.toString() ?? '',
        statusCode: (map['status_code'] ?? map['statusCode']) as num? ?? 0,
        code: map['code']?.toString() ?? '',
        data: map['data'] == null
            ? []
            : List<StoryData>.from(
                (map['data'] as List).map(
                  (e) => StoryData.fromMap(e as Map<String, dynamic>),
                ),
              ),
      );

  final String? status;
  final String? message;
  final num? statusCode;
  final String? code;
  final List<StoryData>? data;

  Map<String, dynamic> toMap() => {
        'status': status,
        'message': message,
        'status_code': statusCode,
        'code': code,
        'data': data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toMap())),
      };
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
    final user = map['user'];
    final userMap = user is Map<String, dynamic> ? user : null;
    final username = map['display_name']?.toString() ??
        map['full_name']?.toString() ??
        map['username']?.toString() ??
        userMap?['display_name']?.toString() ??
        userMap?['full_name']?.toString() ??
        userMap?['username']?.toString() ??
        _storyPreferredName(firstStory);
    final avatarUrl = map['avatar_url']?.toString() ??
        map['url']?.toString() ??
        userMap?['avatar_url']?.toString() ??
        firstStory?.avatarUrl ??
        '';
    return StoryGroup(
      userId: map['user_id']?.toString() ?? userMap?['id']?.toString() ?? '',
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

StoryEngagementMetrics? _storyEngagementFromMap(
  Map<String, dynamic>? engagementMap,
  Map<String, dynamic> map,
) {
  if (engagementMap != null) {
    return StoryEngagementMetrics.fromMap(engagementMap);
  }
  final topLevelViewCount = map['view_count'];
  if (topLevelViewCount == null) return null;
  return StoryEngagementMetrics(
    viewCount: _storyViewCountFromMap(null, map),
  );
}

class StoryEngagementMetrics {
  StoryEngagementMetrics({
    this.viewCount = 0,
    this.reactionTypes,
  });

  factory StoryEngagementMetrics.fromMap(Map<String, dynamic> map) {
    final reactions = map['reaction_types'] ?? map['reactionTypes'];
    return StoryEngagementMetrics(
      viewCount: _storyViewCountFromMap(map, const {}),
      reactionTypes: reactions is Map<String, dynamic>
          ? LikeTypes.fromMap(reactions)
          : null,
    );
  }

  final int viewCount;
  final LikeTypes? reactionTypes;

  Map<String, dynamic> toMap() => {
        'view_count': viewCount,
        'reaction_types': reactionTypes?.toMap(),
      };
}

class StoryData {
  StoryData({
    this.id = '',
    this.userId = '',
    this.mediaUrl = '',
    this.previewUrl = '',
    this.mediaType = '',
    this.caption = '',
    this.username = '',
    this.fullName = '',
    this.displayName = '',
    this.avatarUrl = '',
    this.createdAt = '',
    this.expiresAt = '',
    this.isViewed = false,
    this.isReacted = false,
    this.viewCount = 0,
    this.soundId = '',
    this.textFormatting,
    this.extraData,
    this.soundSnapshot,
    this.media,
    this.user,
    this.tags,
    this.engagementMetrics,
    this.gender,
    this.profileType = '',
    this.verificationStatus = '',
    this.isPrivate = false,
  });

  factory StoryData.fromMap(Map<String, dynamic> map) {
    final media = map['media'];
    final mediaMap = media is Map<String, dynamic> ? media : null;
    final user = map['user'];
    final userMap = user is Map<String, dynamic> ? user : null;
    final engagement = map['engagement_metrics'];
    final engagementMap =
        engagement is Map<String, dynamic> ? engagement : null;
    final parsedUser =
        userMap == null ? null : SocialUserData.fromMap(userMap);
    final parsedMedia =
        mediaMap == null ? null : MediaData.fromMap(mediaMap);
    final parsedEngagement =
        _storyEngagementFromMap(engagementMap, map);
    final extraDataRaw = map['extra_data'];
    return StoryData(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? parsedUser?.id ?? '',
      mediaUrl: map['media_url']?.toString() ??
          map['url']?.toString() ??
          parsedMedia?.url ??
          mediaMap?['url']?.toString() ??
          mediaMap?['media_url']?.toString() ??
          '',
      previewUrl: map['preview_url']?.toString() ??
          parsedMedia?.previewUrl ??
          mediaMap?['preview_url']?.toString() ??
          '',
      mediaType: map['media_type']?.toString() ??
          parsedMedia?.mediaType ??
          mediaMap?['media_type']?.toString() ??
          '',
      caption: map['caption']?.toString() ?? '',
      username: parsedUser?.username ?? userMap?['username']?.toString() ?? '',
      fullName: parsedUser?.fullName ??
          userMap?['full_name']?.toString() ??
          userMap?['display_name']?.toString() ??
          '',
      displayName: parsedUser?.displayName ??
          userMap?['display_name']?.toString() ??
          '',
      avatarUrl: parsedUser?.avatarUrl ??
          userMap?['avatar_url']?.toString() ??
          '',
      createdAt: map['created_at']?.toString() ?? '',
      expiresAt: map['expires_at']?.toString() ?? '',
      isViewed: map['is_viewed'] as bool? ?? false,
      isReacted: map['is_reacted'] as bool? ?? false,
      viewCount: parsedEngagement?.viewCount ??
          _storyViewCountFromMap(engagementMap, map),
      soundId: map['sound_id']?.toString() ?? '',
      textFormatting: map['text_formatting'],
      extraData: extraDataRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(extraDataRaw)
          : null,
      soundSnapshot: map['sound_snapshot'],
      media: parsedMedia,
      user: parsedUser,
      tags: map['tags'] == null
          ? null
          : Tags.fromMap(map['tags'] as Map<String, dynamic>),
      engagementMetrics: parsedEngagement,
      gender: userMap?['gender']?.toString(),
      profileType: parsedUser?.profileType ??
          userMap?['profile_type']?.toString() ??
          '',
      verificationStatus: parsedUser?.verificationStatus ??
          userMap?['verification_status']?.toString() ??
          '',
      isPrivate: parsedUser?.isPrivate == 1 ||
          userMap?['is_private'] == true,
    );
  }

  StoryData copyWith({
    String? id,
    String? userId,
    String? mediaUrl,
    String? previewUrl,
    String? mediaType,
    String? caption,
    String? username,
    String? fullName,
    String? displayName,
    String? avatarUrl,
    String? createdAt,
    String? expiresAt,
    bool? isViewed,
    bool? isReacted,
    int? viewCount,
    String? soundId,
    dynamic textFormatting,
    Map<String, dynamic>? extraData,
    dynamic soundSnapshot,
    MediaData? media,
    SocialUserData? user,
    Tags? tags,
    StoryEngagementMetrics? engagementMetrics,
    String? gender,
    String? profileType,
    String? verificationStatus,
    bool? isPrivate,
  }) =>
      StoryData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        previewUrl: previewUrl ?? this.previewUrl,
        mediaType: mediaType ?? this.mediaType,
        caption: caption ?? this.caption,
        username: username ?? this.username,
        fullName: fullName ?? this.fullName,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
        isViewed: isViewed ?? this.isViewed,
        isReacted: isReacted ?? this.isReacted,
        viewCount: viewCount ?? this.viewCount,
        soundId: soundId ?? this.soundId,
        textFormatting: textFormatting ?? this.textFormatting,
        extraData: extraData ?? this.extraData,
        soundSnapshot: soundSnapshot ?? this.soundSnapshot,
        media: media ?? this.media,
        user: user ?? this.user,
        tags: tags ?? this.tags,
        engagementMetrics: engagementMetrics ?? this.engagementMetrics,
        gender: gender ?? this.gender,
        profileType: profileType ?? this.profileType,
        verificationStatus: verificationStatus ?? this.verificationStatus,
        isPrivate: isPrivate ?? this.isPrivate,
      );

  final String id;
  final String userId;
  final String mediaUrl;
  final String previewUrl;
  final String mediaType;

  /// Thumbnail for story rings and highlight pickers (video uses [previewUrl]).
  String get thumbDisplayUrl {
    final preview = previewUrl.trim();
    if (mediaType.toLowerCase().contains('video') && preview.isNotEmpty) {
      return preview;
    }
    return mediaUrl.trim();
  }

  final String caption;
  final String username;
  final String fullName;
  final String displayName;
  final String avatarUrl;
  final String createdAt;
  final String expiresAt;
  final bool isViewed;
  final bool isReacted;
  final int viewCount;
  final String soundId;
  final dynamic textFormatting;
  final Map<String, dynamic>? extraData;
  final dynamic soundSnapshot;
  final MediaData? media;
  final SocialUserData? user;
  final Tags? tags;
  final StoryEngagementMetrics? engagementMetrics;
  final String? gender;
  final String profileType;
  final String verificationStatus;
  final bool isPrivate;

  bool get isVerified => verificationStatus.toLowerCase() == 'verified';

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'caption': caption,
        'media': media?.toMap(),
        'sound_id': soundId,
        'created_at': createdAt,
        'expires_at': expiresAt,
        'text_formatting': textFormatting,
        'extra_data': extraData,
        'sound_snapshot': soundSnapshot,
        'user': user?.toMap(),
        'tags': tags?.toMap(),
        'engagement_metrics': engagementMetrics?.toMap(),
        'is_viewed': isViewed,
        'is_reacted': isReacted,
      };
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
          (s) => s.id.trim().isNotEmpty && s.mediaUrl.trim().isNotEmpty,
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

List<StoryData> storiesFromResponseData(String rawData) =>
    StoriesResponse.fromMap(jsonDecode(rawData) as Map<String, dynamic>).data ??
    const [];

List<StoryHighlightData> storyHighlightsFromResponseData(String rawData) {
  final map = jsonDecode(rawData) as Map<String, dynamic>;
  final list = map['data'] as List<dynamic>? ?? [];
  return list
      .map((e) => StoryHighlightData.fromMap(e as Map<String, dynamic>))
      .toList();
}
