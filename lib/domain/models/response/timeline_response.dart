// To parse this JSON data, do
//
//     final timelineResponse = timelineResponseFromMap(jsonString);

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/res/constants/constants.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

TimelineResponse timelineResponseFromJson(String str) =>
    TimelineResponse.fromMap(json.decode(str) as Map<String, dynamic>);

String timelineResponseToMap(TimelineResponse data) =>
    json.encode(data.toMap());

class TimelineResponse {
  TimelineResponse({
    this.status,
    this.message,
    this.statusCode,
    this.code,
    this.data,
    this.total,
    this.page,
    this.pageSize,
    this.totalPages,
  });

  factory TimelineResponse.fromMap(Map<String, dynamic> json) =>
      TimelineResponse(
        status: json['status'] as String? ?? '',
        message: json['message'] as String? ?? '',
        statusCode: (json['status_code'] ?? json['statusCode']) as num? ?? 0,
        code: json['code'] as String? ?? '',
        data: json['data'] == null
            ? []
            : List<TimeLineData>.from((json['data'] as List)
                .map((x) => TimeLineData.fromMap(x as Map<String, dynamic>))),
        total: json['total'] as num? ?? 0,
        page: json['page'] as num? ?? 0,
        pageSize: json['page_size'] as num? ?? 0,
        totalPages: json['total_pages'] as num? ?? 0,
      );
  String? status;
  String? message;
  num? statusCode;
  String? code;
  List<TimeLineData>? data;
  num? total;
  num? page;
  num? pageSize;
  num? totalPages;

  Map<String, dynamic> toMap() => {
        'status': status,
        'message': message,
        'statusCode': statusCode,
        'code': code,
        'data':
            data == null ? [] : List<dynamic>.from(data!.map((x) => x.toMap())),
        'total': total,
        'page': page,
        'page_size': pageSize,
        'total_pages': totalPages,
      };
}

TimelineDataResponse timelineDataResponseFromJson(String str) =>
    TimelineDataResponse.fromMap(json.decode(str) as Map<String, dynamic>);

String timelineDataResponseToMap(TimelineDataResponse data) =>
    json.encode(data.toMap());

class TimelineDataResponse {
  TimelineDataResponse({
    this.status,
    this.message,
    this.statusCode,
    this.code,
    this.data,
    this.total,
    this.page,
    this.pageSize,
    this.totalPages,
  });

  factory TimelineDataResponse.fromMap(Map<String, dynamic> json) =>
      TimelineDataResponse(
        status: json['status'] as String? ?? '',
        message: json['message'] as String? ?? '',
        statusCode: (json['status_code'] ?? json['statusCode']) as num? ?? 0,
        code: json['code'] as String? ?? '',
        data: json['data'] == null
            ? null
            : json.objectOrNull('data', TimeLineBodyData.fromMap),
        total: json['total'] as num? ?? 0,
        page: json['page'] as num? ?? 0,
        pageSize: json['page_size'] as num? ?? 0,
        totalPages: json['total_pages'] as num? ?? 0,
      );
  String? status;
  String? message;
  num? statusCode;
  String? code;
  TimeLineBodyData? data;
  num? total;
  num? page;
  num? pageSize;
  num? totalPages;

  Map<String, dynamic> toMap() => {
        'status': status,
        'message': message,
        'statusCode': statusCode,
        'code': code,
        'data': data?.toMap(),
        'total': total,
        'page': page,
        'page_size': pageSize,
        'total_pages': totalPages,
      };
}

class TimeLineBodyData {
  TimeLineBodyData({
    this.posts,
    this.nextCursor,
  });

  factory TimeLineBodyData.fromMap(Map<String, dynamic> json) =>
      TimeLineBodyData(
        posts: json['posts'] == null
            ? []
            : List<TimeLineData>.from((json['posts'] as List?)?.map((x) =>
                    TimeLineData.fromMap(x as Map<String, dynamic>? ?? {})) ??
                []),
        nextCursor: json['next_cursor'] as String? ?? '',
      );

  List<TimeLineData>? posts;
  String? nextCursor;

  Map<String, dynamic> toMap() => {
        'posts': posts == null
            ? []
            : List<dynamic>.from(posts!.map((x) => x.toMap())),
        'next_cursor': nextCursor,
      };
}

class TimeLineData {
  TimeLineData({
    this.textFormatting,
    this.publishedAt,
    this.media,
    this.soundId,
    this.caption,
    this.userId,
    this.user,
    this.visibility,
    this.id,
    this.soundSnapshot,
    this.sound,
    this.tags,
    this.settings,
    this.engagementMetrics,
    this.type,
    this.previews,
    this.isLiked,
    this.isSaved,
    this.isFollowing,
    this.interests,
    this.status,
    this.scheduledAt,
    this.isLocked,
    this.lockReason,
    this.allowDownload,
  });

  factory TimeLineData.fromMap(Map<String, dynamic> json) => TimeLineData(
        textFormatting: json['text_formatting'],
        publishedAt: json['published_at'] as String? ?? '',
        media: json['media'] == null
            ? []
            : List<MediaData>.from((json['media'] as List)
                .map((x) => MediaData.fromMap(x as Map<String, dynamic>))),
        soundId: json['sound_id'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        user: json['user'] == null
            ? null
            : SocialUserData.fromMap(json['user'] as Map<String, dynamic>),
        visibility: json['visibility'] as String? ?? '',
        id: json['id'] as String? ?? '',
        soundSnapshot: json['sound_snapshot'],
        sound: _parseSoundInfo(json),
        tags: json['tags'] == null
            ? null
            : json['tags'] is String &&
                    (json['tags'] as String).isStringEmptyOrNull
                ? null
                : Tags.fromMap(json['tags'] as Map<String, dynamic>),
        settings: json['settings'] == null
            ? null
            : Settings.fromMap(json['settings'] as Map<String, dynamic>),
        engagementMetrics: json['engagement_metrics'] == null
            ? null
            : EngagementMetrics.fromMap(
                json['engagement_metrics'] as Map<String, dynamic>),
        type: json['type'] as String? ?? '',
        previews: json['previews'] == null
            ? []
            : List<PreviewMedia>.from((json['previews'] as List)
                .map((x) => PreviewMedia.fromMap(x as Map<String, dynamic>))),
        isLiked: json['is_liked'] as bool? ?? false,
        isSaved: json['is_saved'] as bool? ?? false,
        isFollowing: json['is_following'] as bool? ?? false,
        scheduledAt: json['scheduled_at'] as String? ?? '',
        status: json['status'] as String? ?? '',
        interests: json['interests'] == null || json['interests'] is String
            ? []
            : List<String>.from(json['interests'] as List)
                .map((item) => item)
                .toList(),
        isLocked: json['is_locked'] as bool?,
        lockReason: json['lock_reason'] as String?,
        allowDownload: Settings._readBool(json['allow_download'],
                key: 'allow_download') ??
            Settings._readBool(json['allowDownload'], key: 'allowDownload') ??
            true,
      );
  dynamic textFormatting;
  String? publishedAt;
  List<MediaData>? media;
  String? soundId;
  String? caption;
  String? userId;
  SocialUserData? user;
  String? visibility;
  String? id;
  dynamic soundSnapshot;
  PostSoundInfo? sound;
  Tags? tags;
  Settings? settings;
  EngagementMetrics? engagementMetrics;
  String? scheduledAt;
  String? type;
  List<PreviewMedia>? previews;
  bool? isLiked;
  bool? isSaved;
  bool? isFromLocal;
  bool? isFollowing;
  String? status;
  List<String>? interests;
  bool? isLocked;
  String? lockReason;
  bool? allowDownload;

  Map<String, dynamic> toMap() => {
        'text_formatting': textFormatting,
        'published_at': publishedAt,
        'media': media == null
            ? []
            : List<dynamic>.from(media!.map((x) => x.toMap())),
        'sound_id': soundId,
        'caption': caption,
        'user_id': userId,
        'user': user?.toMap(),
        'visibility': visibility,
        'id': id,
        'sound_snapshot': soundSnapshot,
        'sound': sound?.toMap(),
        'tags': tags?.toMap(),
        'settings': settings?.toMap(),
        'engagement_metrics': engagementMetrics?.toMap(),
        'type': type,
        'previews': previews == null
            ? []
            : List<dynamic>.from(previews!.map((x) => x.toMap())),
        'is_liked': isLiked,
        'is_saved': isSaved,
        'isFromLocal': isFromLocal,
        'is_following': isFollowing,
        'status': status,
        'interests': interests == null
            ? []
            : List<dynamic>.from(interests!.map((x) => x)),
        'scheduled_at': scheduledAt,
        'is_locked': isLocked,
        'lock_reason': lockReason,
        if (allowDownload != null) 'allow_download': allowDownload,
      };
}

class PreviewMedia {
  factory PreviewMedia.fromMap(Map<String, dynamic> json) => PreviewMedia(
        mediaType: json['media_type'] as String? ?? '',
        position: json['position'] as num? ?? 0,
        url: json['url'] as String? ?? '',
      );

  PreviewMedia({
    this.mediaType,
    this.position,
    this.url,
    this.file,
    this.fileName,
    this.localFilePath,
  });

  Map<String, dynamic> toMap() => {
        'media_type': mediaType,
        'position': position,
        'url': url,
        'file': file,
        'file_name': fileName,
      };
  String? mediaType;
  num? position;
  String? url;
  File? file;
  String? fileName;
  String? localFilePath;
}

class EngagementMetrics {
  EngagementMetrics({
    this.views,
    this.uniqueViews,
    this.likeTypes,
    this.comments,
    this.shares,
    this.saves,
    this.watchTime,
    this.completionRate,
    this.engagementRate,
  });

  factory EngagementMetrics.fromMap(Map<String, dynamic> json) =>
      EngagementMetrics(
        views: json['views'] as num? ?? 0,
        uniqueViews: json['unique_views'] as num? ?? 0,
        likeTypes: json['like_types'] == null
            ? null
            : LikeTypes.fromMap(json['like_types'] as Map<String, dynamic>),
        comments: json['comments'] as num? ?? 0,
        shares: json['shares'] as num? ?? 0,
        saves: json['saves'] as num? ?? 0,
        watchTime: json['watch_time'] as num? ?? 0,
        completionRate: json['completion_rate'] as num? ?? 0,
        engagementRate: json['engagement_rate'] as num? ?? 0,
      );
  num? views;
  num? uniqueViews;
  LikeTypes? likeTypes;
  num? comments;
  num? shares;
  num? saves;
  num? watchTime;
  num? completionRate;
  num? engagementRate;

  Map<String, dynamic> toMap() => {
        'views': views,
        'unique_views': uniqueViews,
        'like_types': likeTypes?.toMap(),
        'comments': comments,
        'shares': shares,
        'saves': saves,
        'watch_time': watchTime,
        'completion_rate': completionRate,
        'engagement_rate': engagementRate,
      };
}

class LikeTypes {
  LikeTypes({
    this.like,
    this.love,
    this.haha,
    this.wow,
    this.sad,
    this.angry,
  });

  factory LikeTypes.fromMap(Map<String, dynamic> json) => LikeTypes(
        like: json['like'] as num? ?? 0,
        love: json['love'] as num? ?? 0,
        haha: json['haha'] as num? ?? 0,
        wow: json['wow'] as num? ?? 0,
        sad: json['sad'] as num? ?? 0,
        angry: json['angry'] as num? ?? 0,
      );
  num? like;
  num? love;
  num? haha;
  num? wow;
  num? sad;
  num? angry;

  Map<String, dynamic> toMap() => {
        'like': like,
        'love': love,
        'haha': haha,
        'wow': wow,
        'sad': sad,
        'angry': angry,
      };
}

class MediaData {
  MediaData(
      {this.mediaType,
      this.assetId,
      this.position,
      this.url,
      this.previewUrl,
      this.coverFileLocalPath,
      this.description,
      this.width,
      this.height,
      this.duration,
      this.file,
      this.fileName,
      this.postType,
      this.size,
      this.localPath,
      this.fileExtension});

  factory MediaData.fromMap(Map<String, dynamic> json) => MediaData(
        mediaType: json['media_type'] as String? ?? '',
        assetId: json['asset_id'] as String? ?? '',
        position: json['position'] as num? ?? 0,
        url: json['url'] as String? ?? '',
        previewUrl: json['preview_url'] as String? ?? '',
        width: json['width'] as num? ?? 0,
        height: json['height'] as num? ?? 0,
        duration: json['duration'] as num? ?? 0,
        file: json['file'] as File?,
        fileName: json['fileName'] as String? ?? '',
        postType: json['postType'] as PostType? ?? PostType.photo,
        size: json['size'] as num? ?? 0,
      );
  String? mediaType;
  String? assetId;
  num? position;
  String? url;
  String? localPath;
  String? previewUrl;
  dynamic description;
  num? width;
  num? height;
  num? duration;
  String? fileName;
  File? file;
  File? previewFile;
  String? fileExtension;
  String? coverFileName;
  String? coverFileExtension;
  String? coverFileLocalPath;
  PostType? postType;
  num? size;
  Uint8List? videoThumbnailFileBytes;
  bool isCompressed = false;

  Map<String, dynamic> toMap() => {
        'media_type': mediaType,
        'asset_id': assetId,
        'position': position,
        'url': url,
        'preview_url': previewUrl,
        'description': description,
        'height': height,
        'width': width,
        'duration': duration,
      }.removeEmptyValues();
}

class Settings {
  Settings({
    this.commentsEnabled,
    this.duetEnabled,
    this.stitchEnabled,
    this.saveEnabled,
    this.downloadEnabled,
    this.isPaid,
    this.priceAmount,
    this.priceCurrency,
    this.ageRestriction,
    this.autoAdvance,
    this.advanceInterval,
    this.audioSettings,
  });

  factory Settings.fromMap(Map<String, dynamic> json) {
    final isPaid = _readBool(json['is_paid'], key: 'is_paid');
    final priceAmount =
        _readPriceAmount(json['price_amount'], key: 'price_amount');
    final normalizedIsPaid =
        (isPaid == true && priceAmount == null) ? false : isPaid;

    return Settings(
      commentsEnabled:
          _readBool(json['comments_enabled'], key: 'comments_enabled') ?? false,
      duetEnabled:
          _readBool(json['duet_enabled'], key: 'duet_enabled') ?? false,
      stitchEnabled:
          _readBool(json['stitch_enabled'], key: 'stitch_enabled') ?? false,
      saveEnabled:
          _readBool(json['save_enabled'], key: 'save_enabled') ?? false,
      downloadEnabled: _readBool(json['download_enabled'],
              key: 'download_enabled') ??
          _readBool(json['allow_download'], key: 'allow_download') ??
          true,
      isPaid: normalizedIsPaid,
      priceAmount: priceAmount,
      priceCurrency: json['price_currency'] as String?,
      ageRestriction:
          _readBool(json['age_restriction'], key: 'age_restriction') ?? false,
      autoAdvance:
          _readBool(json['auto_advance'], key: 'auto_advance') ?? false,
      advanceInterval:
          _readNum(json['advance_interval'], key: 'advance_interval') ?? 0,
      audioSettings: json['audio_settings'],
    );
  }
  bool? commentsEnabled;
  bool? duetEnabled;
  bool? stitchEnabled;
  bool? saveEnabled;
  bool? downloadEnabled;
  bool? isPaid;
  Object? priceAmount;
  String? priceCurrency;
  bool? ageRestriction;
  bool? autoAdvance;
  num? advanceInterval;
  dynamic audioSettings;

  static bool? _readBool(dynamic value, {required String key}) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }

  static num? _readNum(dynamic value, {required String key}) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static Object? _readPriceAmount(dynamic value, {required String key}) {
    if (value == null) return null;
    if (value is num || value is String) return value;
    return null;
  }

  Map<String, dynamic> toMap() => {
        'comments_enabled': commentsEnabled,
        'duet_enabled': duetEnabled,
        'stitch_enabled': stitchEnabled,
        'save_enabled': saveEnabled,
        if (downloadEnabled != null) 'download_enabled': downloadEnabled,
        if (isPaid != null) 'is_paid': isPaid,
        if (priceAmount != null) 'price_amount': priceAmount,
        if (priceCurrency != null) 'price_currency': priceCurrency,
        'age_restriction': ageRestriction,
        'auto_advance': autoAdvance,
        'advance_interval': advanceInterval,
        'audio_settings': audioSettings,
      };
}

/// Tagged link on a post (`tags.links[]`).
class PostLinkData {
  const PostLinkData({
    required this.url,
    this.title,
    this.textPosition,
    this.mediaPosition,
    this.previewImage,
    this.linkData,
  });

  factory PostLinkData.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as String? ??
            json['button_text'] as String? ??
            '')
        .trim();
    return PostLinkData(
      url: (json['url'] as String? ?? '').trim(),
      title: title.isEmpty ? null : title,
      textPosition: json['text_position'] == null
          ? null
          : TaggedPosition.fromJson(
              json['text_position'] as Map<String, dynamic>),
      mediaPosition: json['media_position'] == null
          ? null
          : MediaPosition.fromJson(
              json['media_position'] as Map<String, dynamic>),
      previewImage: json['preview_image'] as String?,
      linkData: json['link_data'] == null
          ? null
          : Map<String, dynamic>.from(
              json['link_data'] as Map<String, dynamic>),
    );
  }

  final String url;
  final String? title;
  final TaggedPosition? textPosition;
  final MediaPosition? mediaPosition;
  final String? previewImage;
  final Map<String, dynamic>? linkData;

  String get displayTitle =>
      (title?.trim().isNotEmpty == true) ? title!.trim() : 'Link';

  bool get isValid {
    if (url.isEmpty || title?.trim().isNotEmpty != true) return false;
    final withScheme = url.contains('://') ? url : 'https://$url';
    final uri = Uri.tryParse(withScheme);
    return uri != null && uri.scheme == 'https';
  }

  /// Default sticker anchor when the user adds a link without placing it on media.
  /// API requires each link to include `text_position` and/or `media_position`.
  static MediaPosition defaultMediaStickerPosition({num mediaIndex = 1}) =>
      MediaPosition(position: mediaIndex, x: 0, y: 0);

  /// Link payload for create/edit when only URL + title are collected in the SDK UI.
  factory PostLinkData.forCreate({
    required String url,
    required String title,
    num mediaIndex = 1,
  }) =>
      PostLinkData(
        url: url,
        title: title,
        mediaPosition: defaultMediaStickerPosition(mediaIndex: mediaIndex),
      );

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'url': _normalizedUrl(),
      if (title != null && title!.isNotEmpty) 'title': title,
      if (textPosition != null) 'text_position': textPosition!.toJson(),
      if (previewImage != null && previewImage!.isNotEmpty)
        'preview_image': previewImage,
    };
    final media = mediaPosition ??
        (textPosition == null ? defaultMediaStickerPosition() : null);
    if (media != null) {
      payload['media_position'] = media.toJson();
    }
    if (linkData != null && linkData!.isNotEmpty) {
      payload['link_data'] = linkData;
    }
    return payload;
  }

  String _normalizedUrl() {
    final trimmed = url.trim();
    if (trimmed.contains('://')) return trimmed;
    return 'https://$trimmed';
  }

  PostLinkData copyWith({
    String? url,
    String? title,
    TaggedPosition? textPosition,
    MediaPosition? mediaPosition,
    String? previewImage,
    Map<String, dynamic>? linkData,
  }) =>
      PostLinkData(
        url: url ?? this.url,
        title: title ?? this.title,
        textPosition: textPosition ?? this.textPosition,
        mediaPosition: mediaPosition ?? this.mediaPosition,
        previewImage: previewImage ?? this.previewImage,
        linkData: linkData ?? this.linkData,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostLinkData &&
          other.url == url &&
          other.title == title &&
          other.previewImage == previewImage;

  @override
  int get hashCode => Object.hash(url, title, previewImage);
}

class Tags {
  Tags({
    this.mentions,
    this.hashtags,
    this.places,
    this.products,
    this.links,
  });

  factory Tags.fromMap(Map<String, dynamic> json) => Tags(
        mentions: json['mentions'] == null ||
                (json['mentions'] as List).isListEmptyOrNull
            ? []
            : List<MentionData>.from((json['mentions'] as List).map((x) =>
                x is Map<String, dynamic>
                    ? MentionData.fromJson(x)
                    : MentionData.fromJson({}))),
        hashtags: json['hashtags'] == null ||
                (json['hashtags'] as List).isListEmptyOrNull
            ? []
            : List<MentionData>.from((json['hashtags'] as List).map((x) =>
                x is Map<String, dynamic>
                    ? MentionData.fromJson(x)
                    : MentionData.fromJson({}))),
        places: json['places'] == null
            ? []
            : List<TaggedPlace>.from((json['places'] as List).map((x) =>
                x is Map<String, dynamic>
                    ? TaggedPlace.fromJson(x)
                    : TaggedPlace.fromJson({}))),
        products: json['products'] == null
            ? []
            : List<SocialProductData>.from((json['products'] as List).map(
                (x) => SocialProductData.fromJson(x as Map<String, dynamic>))),
        links: _parsePostLinks(json['links']),
      );
  List<MentionData>? mentions;
  List<MentionData>? hashtags;
  List<TaggedPlace>? places;
  List<SocialProductData>? products;
  List<PostLinkData>? links;

  static List<PostLinkData>? _parsePostLinks(dynamic raw) {
    if (raw == null) return [];
    if (raw is! List || raw.isEmpty) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(PostLinkData.fromJson)
        .where((link) => link.isValid)
        .toList();
  }

  /// Primary CTA link for reels overlay (first valid entry).
  PostLinkData? get primaryLink {
    final list = links;
    if (list == null || list.isEmpty) return null;
    return list.firstWhere((l) => l.isValid, orElse: () => list.first);
  }

  Map<String, dynamic> toMap() => {
        'mentions': mentions == null
            ? []
            : List<dynamic>.from(mentions!.map((x) => x.toJson())),
        'hashtags': hashtags == null
            ? []
            : List<dynamic>.from(hashtags!.map((x) => x.toJson())),
        'places':
            places == null ? [] : List<dynamic>.from(places!.map((x) => x)),
        'products': products == null
            ? []
            : List<dynamic>.from(products!.map((x) => x.toJson())),
        'links': links == null
            ? []
            : List<dynamic>.from(links!.map((x) => x.toJson())),
      };
}

class SocialUserData {
  SocialUserData({
    this.id,
    this.username,
    this.fullName,
    this.displayName,
    this.avatarUrl,
    this.userMetadata,
    this.profileType,
    this.isFollowing,
    this.isPrivate,
    this.followStatus,
    this.targetId,
    this.isRequested,
  });

  factory SocialUserData.fromMap(Map<String, dynamic> json) => SocialUserData(
        id: json['id'] == null
            ? (json['user_id'] as String? ?? '')
            : (json['id'] as String? ?? ''),
        username: json['username'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String? ?? '',
        profileType: json['profile_type'] as String? ?? '',
        userMetadata: json['user_metadata'] == null
            ? null
            : UserMetadata.fromMap(
                json['user_metadata'] as Map<String, dynamic>),
        isFollowing: json['is_following'] as bool? ?? false,
        isPrivate: _readPrivateFlag(json),
        followStatus: FollowRelationshipStatus.parseFromApiFields(
          followStatus: json['follow_status'] ?? json['followStatus'],
          followRelationship:
              json['follow_relationship'] ?? json['followRelationship'],
        ),
        targetId: json['target_id'] as String? ?? '',
        isRequested: SocialUserData._readRequested(json),
      );

  /// Pending follow request sent (`is_requested` when backend adds it).
  static bool? _readRequested(Map<String, dynamic> json) {
    final v = json['is_requested'] ?? json['isRequested'];
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    return null;
  }

  static num? _readPrivateFlag(Map<String, dynamic> json) {
    if (json['is_private'] != null) {
      final v = json['is_private'];
      if (v is bool) return v ? 1 : 0;
      if (v is num) return v;
    }
    if (json['isPrivate'] != null) {
      final v = json['isPrivate'];
      if (v is bool) return v ? 1 : 0;
      if (v is num) return v;
    }
    return null;
  }

  String? id;
  String? username;
  String? fullName;
  String? displayName;
  String? avatarUrl;
  String? profileType;
  UserMetadata? userMetadata;
  bool? isFollowing;
  num? isPrivate;
  num? followStatus;
  String? targetId;
  bool? isRequested;

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'full_name': fullName,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'profile_type': profileType,
        'user_metadata': userMetadata?.toMap(),
        'is_following': isFollowing,
        'is_private': isPrivate,
        'follow_status': followStatus,
        'target_id': targetId,
        'is_requested': isRequested,
      };
}

class UserMetadata {
  UserMetadata({
    this.preferences,
  });

  factory UserMetadata.fromMap(Map<String, dynamic> json) => UserMetadata(
        preferences: json['preferences'] == null
            ? null
            : Preferences.fromMap(json['preferences'] as Map<String, dynamic>),
      );
  Preferences? preferences;

  Map<String, dynamic> toMap() => {
        'preferences': preferences?.toMap(),
      };
}

class Preferences {
  Preferences({
    this.theme,
    this.language,
  });

  factory Preferences.fromMap(Map<String, dynamic> json) => Preferences(
        theme: json['theme'] as String? ?? '',
        language: json['language'] as String? ?? '',
      );
  String? theme;
  String? language;

  Map<String, dynamic> toMap() => {
        'theme': theme,
        'language': language,
      };
}

class MentionData {
  MentionData({
    this.userId,
    this.username,
    this.tag,
    this.textPosition,
    this.name,
    this.avatarUrl,
    this.mediaPosition,
  });

  factory MentionData.fromJson(Map<String, dynamic> json) => MentionData(
        userId: json['user_id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        tag: json['tag'] as String? ?? '',
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String? ?? '',
        textPosition: json['text_position'] == null
            ? null
            : TaggedPosition.fromJson(
                json['text_position'] as Map<String, dynamic>),
        mediaPosition: json['media_position'] == null
            ? null
            : MediaPosition.fromJson(
                json['media_position'] as Map<String, dynamic>),
      );
  String? userId;
  String? username;
  String? tag;
  String? name;
  String? avatarUrl;
  TaggedPosition? textPosition;
  MediaPosition? mediaPosition;

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'username': username,
        'tag': tag,
        'text_position': textPosition?.toJson(),
        'media_position': mediaPosition?.toJson(),
      }.removeEmptyValues();
}

class TaggedPosition {
  TaggedPosition({
    required this.start,
    required this.end,
  });

  factory TaggedPosition.fromJson(Map<String, dynamic> json) => TaggedPosition(
        start: json['start'] as num? ?? 0,
        end: json['end'] as num? ?? 0,
      );
  num? start;
  num? end;

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
      };
}

class SocialProductData {
  SocialProductData({
    required this.productId,
    required this.productName,
    required this.brand,
    required this.category,
    required this.price,
    required this.discountPrice,
    required this.currency,
    required this.productUrl,
    required this.productImage,
    required this.mediaPosition,
    required this.productSlug,
  });

  factory SocialProductData.fromJson(Map<String, dynamic> json) =>
      SocialProductData(
        productId: json['product_id'] as String? ?? '',
        productName: json['product_name'] as String? ?? '',
        brand: json['brand'] as String? ?? '',
        category: json['category'] as String? ?? '',
        price: json['price'] as num? ?? 0,
        discountPrice: json['discount_price'] as num? ?? 0,
        currency: json['currency'] == null
            ? null
            : Currency.fromJson(json['currency'] as Map<String, dynamic>),
        productUrl: json['product_url'] as String? ?? '',
        productImage: json['product_image'] as String? ?? '',
        mediaPosition: json['media_position'] == null
            ? null
            : ProductPosition.fromJson(
                json['media_position'] as Map<String, dynamic>),
        productSlug: json['product_slug'] as String? ?? '',
      );
  String? productId;
  String? productName;
  String? brand;
  String? category;
  num? price;
  num? discountPrice;
  Currency? currency;
  String? productUrl;
  String? productImage;
  String? productSlug;
  ProductPosition? mediaPosition;

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'brand': brand,
        'price': price,
        'discount_price': discountPrice,
        'currency': currency?.toJson(),
        'product_url': productUrl,
        'product_image': productImage,
        'media_position': mediaPosition?.toJson(),
        'product_slug': productSlug,
      };
}

class Currency {
  Currency({
    required this.code,
    required this.symbol,
  });

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
        code: json['code'] as String? ?? '',
        symbol: json['symbol'] as String? ?? '',
      );
  String? code;
  String? symbol;

  Map<String, dynamic> toJson() => {
        'code': code,
        'symbol': symbol,
      };
}

class ProductPosition {
  ProductPosition({
    required this.mediaPosition,
    required this.x,
    required this.y,
  });

  factory ProductPosition.fromJson(Map<String, dynamic> json) =>
      ProductPosition(
        mediaPosition: json['position'] as num? ?? 0,
        x: json['x'] as num? ?? 0,
        y: json['y'] as num? ?? 0,
      );
  num? mediaPosition;
  num? x;
  num? y;

  Map<String, dynamic> toJson() => {
        'position': mediaPosition,
        'x': x,
        'y': y,
      };
}

class MediaPosition {
  MediaPosition({
    this.position,
    required this.x,
    required this.y,
  });

  factory MediaPosition.fromJson(Map<String, dynamic> json) => MediaPosition(
        position: json['position'] as num? ?? 0,
        x: json['x'] as num? ?? 0,
        y: json['y'] as num? ?? 0,
      );
  num? position;
  num? x;
  num? y;

  Map<String, dynamic> toJson() => {
        'position': position,
        'x': x,
        'y': y,
      };
}

class TaggedPlace {
  TaggedPlace({
    this.address,
    this.city,
    this.coordinates,
    this.country,
    this.placeData,
    this.placeId,
    this.placeName,
    this.placeType,
    this.postalCode,
    this.state,
  });

  factory TaggedPlace.fromJson(Map<String, dynamic> json) => TaggedPlace(
        address: json['address'] as String? ?? '',
        city: json['city'] as String? ?? '',
        coordinates: json['coordinates'] == null
            ? []
            : List<double>.from(
                (json['coordinates'] as List).map((x) => x?.toDouble())),
        country: json['country'] as String? ?? '',
        placeData: json['place_data'] == null
            ? null
            : PlaceData.fromJson(json['place_data'] as Map<String, dynamic>),
        placeId: json['place_id'] as String? ?? '',
        placeName: json['place_name'] as String? ?? '',
        placeType: json['place_type'] as String? ?? '',
        postalCode: json['postal_code'] as String? ?? '',
        state: json['state'] as String? ?? '',
      );
  final String? address;
  final String? city;
  final List<double>? coordinates;
  final String? country;
  final PlaceData? placeData;
  final String? placeId;
  final String? placeName;
  final String? placeType;
  final String? postalCode;
  final String? state;

  Map<String, dynamic> toJson() => {
        'address': address,
        'city': city,
        'coordinates': coordinates == null
            ? []
            : List<dynamic>.from(coordinates!.map((x) => x)),
        'country': country,
        'place_data': placeData?.toJson(),
        'place_id': placeId,
        'place_name': placeName,
        'place_type': placeType,
        'postal_code': postalCode,
        'state': state,
      };
}

class PlaceData {
  PlaceData({
    this.description,
  });

  factory PlaceData.fromJson(Map<String, dynamic> json) => PlaceData(
        description: json['description'] as String? ?? '',
      );
  final String? description;

  Map<String, dynamic> toJson() => {
        'description': description,
      };
}

PostSoundInfo? _parseSoundInfo(Map<String, dynamic> json) {
  final snapshotRaw = json['sound_snapshot'];
  final snapshot = snapshotRaw is Map<String, dynamic>
      ? Map<String, dynamic>.from(snapshotRaw)
      : null;
  final soundObj = json['sound'];
  if (soundObj is Map<String, dynamic> && (soundObj['id'] ?? '') != '') {
    return PostSoundInfo.fromMap(soundObj, snapshot: snapshot);
  }
  final soundId = (json['sound_id'] as String?)?.trim() ?? '';
  if (soundId.isEmpty) return null;
  return PostSoundInfo(id: soundId, snapshot: snapshot);
}

List<MediaMetaData> reelMediaMetaDataFromTimeline(TimeLineData postData) {
  if (postData.media.isListEmptyOrNull == false) {
    return postData.media!.map(_getMediaMetaData).toList();
  }
  final previews = postData.previews;
  if (previews.isListEmptyOrNull == false) {
    final sorted = List<PreviewMedia>.from(previews!)
      ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
    return sorted.map((p) {
      final isImage = (p.mediaType ?? '').toLowerCase() == 'image';
      final url = p.url ?? '';
      return MediaMetaData(
        mediaUrl: url,
        thumbnailUrl: url,
        mediaType: isImage ? 0 : 1,
        durationSeconds: AppConstants.defaultImagePostDurationSeconds,
      );
    }).toList();
  }
  return [];
}

ReelsData getReelData(TimeLineData postData, {String? loggedInUserId}) =>
    ReelsData(
      postData: postData,
      createOn: postData.publishedAt,
      isLocked: postData.isLocked,
      lockReason: postData.lockReason,
      isPaid: postData.settings?.isPaid,
      priceAmount: postData.settings?.priceAmount,
      priceCurrency: postData.settings?.priceCurrency,
      postSetting: PostSetting(
        isProfilePicVisible: true,
        isCreatePostButtonVisible: false,
        isCommentButtonVisible: postData.settings?.commentsEnabled == true,
        isSaveButtonVisible: postData.settings?.saveEnabled == true,
        isLikeButtonVisible: true,
        isShareButtonVisible: true,
        isMoreButtonVisible: true,
        isFollowButtonVisible: postData.user?.id != loggedInUserId,
        isUnFollowButtonVisible: postData.user?.id != loggedInUserId,
      ),
      mentions: postData.tags != null &&
              postData.tags?.mentions.isListEmptyOrNull == false
          ? (postData.tags?.mentions?.map(_getMentionMetaData).toList() ?? [])
          : [],
      tagDataList: postData.tags != null &&
              postData.tags?.hashtags.isListEmptyOrNull == false
          ? postData.tags?.hashtags?.map(_getMentionMetaData).toList()
          : null,
      placeDataList: postData.tags != null &&
              postData.tags?.places.isListEmptyOrNull == false
          ? postData.tags?.places?.map(_getPlaceMetaData).toList()
          : null,
      postId: postData.id,
      tags: postData.tags,
      mediaMetaDataList: reelMediaMetaDataFromTimeline(postData),
      userId: postData.user?.id ?? '',
      userName: postData.user?.username ?? '',
      profilePhoto: postData.user?.avatarUrl ?? '',
      firstName: postData.user?.displayName?.split(' ').firstOrNull ?? '',
      lastName: postData.user?.displayName
              ?.split(' ')
              .takeIf((_) => _.length > 1)
              ?.lastOrNull ??
          '',
      likesCount: postData.engagementMetrics?.likeTypes?.like?.toInt() ?? 0,
      viewCount: postData.engagementMetrics?.views?.toInt() ?? 0,
      commentCount: postData.engagementMetrics?.comments?.toInt() ?? 0,
      isFollow: postData.isFollowing == true,
      isLiked: postData.isLiked,
      isSavedPost: postData.isSaved,
      isVerifiedUser: false,
      productCount: postData.tags?.products?.length ?? 0,
      postLink: postData.tags?.primaryLink,
      description: postData.caption ?? '',
      interests: postData.interests,
      sound: postData.sound,
    );

MediaMetaData _getMediaMetaData(MediaData mediaData) {
  if (AppConstants.convertHlsPostMediaToImageMedia &&
      mediaData.mediaType == 'video' &&
      mediaData.url?.endsWith('.m3u8') == true) {
    return MediaMetaData(
      mediaType: 0,
      mediaUrl: mediaData.previewUrl ?? '',
      thumbnailUrl: mediaData.previewUrl ?? '',
      durationSeconds: AppConstants.defaultImagePostDurationSeconds,
    );
  }

  return MediaMetaData(
    mediaType: mediaData.mediaType == 'image' ? 0 : 1,
    mediaUrl: mediaData.url ?? '',
    thumbnailUrl: mediaData.previewUrl ?? '',
    durationSeconds: (mediaData.mediaType == 'image'
            ? AppConstants.defaultImagePostDurationSeconds
            : mediaData.duration?.toInt()) ??
        AppConstants.defaultImagePostDurationSeconds,
  );
}

MentionMetaData _getMentionMetaData(MentionData mentionData) => MentionMetaData(
      userId: mentionData.userId,
      username: mentionData.username,
      name: mentionData.name,
      avatarUrl: mentionData.avatarUrl,
      tag: mentionData.tag,
      textPosition: mentionData.textPosition != null
          ? MentionPosition(
              start: mentionData.textPosition?.start,
              end: mentionData.textPosition?.end,
            )
          : null,
      mediaPosition: mentionData.mediaPosition != null
          ? MediaPosition(
              position: mentionData.mediaPosition?.position,
              x: mentionData.mediaPosition?.x,
              y: mentionData.mediaPosition?.y,
            )
          : null,
    );

PlaceMetaData _getPlaceMetaData(TaggedPlace placeData) => PlaceMetaData(
      address: placeData.address,
      city: placeData.city,
      coordinates: placeData.coordinates,
      country: placeData.country,
      description: placeData.placeData?.description,
      placeId: placeData.placeId,
      placeName: placeData.placeName ?? '',
      placeType: placeData.placeType,
      postalCode: placeData.postalCode,
      state: placeData.state,
    );
