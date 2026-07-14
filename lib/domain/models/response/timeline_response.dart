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
        status: json.getString('status'),
        message: json.getString('message'),
        statusCode:
            json.numOrNull('status_code') ?? json.numOrNull('statusCode') ?? 0,
        code: json.getString('code'),
        data: _parseObjectList(json, 'data', TimeLineData.fromMap),
        total: json.getNum('total'),
        page: json.getNum('page'),
        pageSize: json.getNum('page_size'),
        totalPages: json.getNum('total_pages'),
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
        status: json.getString('status'),
        message: json.getString('message'),
        statusCode:
            json.numOrNull('status_code') ?? json.numOrNull('statusCode') ?? 0,
        code: json.getString('code'),
        data: json.objectOrNull('data', TimeLineBodyData.fromMap),
        total: json.getNum('total'),
        page: json.getNum('page'),
        pageSize: json.getNum('page_size'),
        totalPages: json.getNum('total_pages'),
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
        posts: _parseObjectList(json, 'posts', TimeLineData.fromMap),
        nextCursor: json.getString('next_cursor'),
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
    this.createdAt,
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
    this.rejectionReason,
    this.rejectedAt,
  });

  factory TimeLineData.fromMap(Map<String, dynamic> json) => TimeLineData(
        textFormatting: json['text_formatting'],
        publishedAt: json.getString('published_at'),
        createdAt: json.stringOrNull('created_at') ??
            json.stringOrNull('createdAt') ??
            '',
        media: _parseObjectList(json, 'media', MediaData.fromMap),
        soundId: json.getString('sound_id'),
        caption: json.getString('caption'),
        userId: json.getString('user_id'),
        user: json.objectOrNull('user', SocialUserData.fromMap),
        visibility: json.getString('visibility'),
        id: json.getString('id'),
        soundSnapshot: json['sound_snapshot'],
        sound: _parseSoundInfo(json),
        tags: json.objectOrNull('tags', Tags.fromMap),
        settings: json.objectOrNull('settings', Settings.fromMap),
        engagementMetrics:
            json.objectOrNull('engagement_metrics', EngagementMetrics.fromMap),
        type: json.getString('type'),
        previews: _parseObjectList(json, 'previews', PreviewMedia.fromMap),
        isLiked: json.getBool('is_liked'),
        isSaved: json.getBool('is_saved'),
        isFollowing: json.getBool('is_following'),
        scheduledAt: json.getString('scheduled_at'),
        status: json.getString('status'),
        interests: (json.listOrNull('interests') ?? [])
            .map((item) => item.toString())
            .toList(),
        isLocked: json.boolOrNull('is_locked'),
        lockReason: json.stringOrNull('lock_reason'),
        allowDownload: json.boolOrNull('allow_download') ??
            json.boolOrNull('allowDownload'),
        rejectionReason: json.stringOrNull('rejection_reason') ??
            json.stringOrNull('rejectionReason'),
        rejectedAt:
            json.stringOrNull('rejected_at') ?? json.stringOrNull('rejectedAt'),
      );
  dynamic textFormatting;
  String? publishedAt;
  String? createdAt;
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
  String? rejectionReason;
  String? rejectedAt;

  Map<String, dynamic> toMap() => {
        'text_formatting': textFormatting,
        'published_at': publishedAt,
        'created_at': createdAt,
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
        'rejection_reason': rejectionReason,
        'rejected_at': rejectedAt,
      };

  TimeLineData copyWith({
    dynamic textFormatting,
    String? publishedAt,
    String? createdAt,
    List<MediaData>? media,
    String? soundId,
    String? caption,
    String? userId,
    SocialUserData? user,
    String? visibility,
    String? id,
    dynamic soundSnapshot,
    PostSoundInfo? sound,
    Tags? tags,
    Settings? settings,
    EngagementMetrics? engagementMetrics,
    String? type,
    List<PreviewMedia>? previews,
    bool? isLiked,
    bool? isSaved,
    bool? isFromLocal,
    bool? isFollowing,
    String? status,
    List<String>? interests,
    String? scheduledAt,
    bool? isLocked,
    String? lockReason,
    String? rejectionReason,
    String? rejectedAt,
  }) =>
      TimeLineData(
        textFormatting: textFormatting ?? this.textFormatting,
        publishedAt: publishedAt ?? this.publishedAt,
        createdAt: createdAt ?? this.createdAt,
        media: media ?? this.media,
        soundId: soundId ?? this.soundId,
        caption: caption ?? this.caption,
        userId: userId ?? this.userId,
        user: user ?? this.user,
        visibility: visibility ?? this.visibility,
        id: id ?? this.id,
        soundSnapshot: soundSnapshot ?? this.soundSnapshot,
        sound: sound ?? this.sound,
        tags: tags ?? this.tags,
        settings: settings ?? this.settings,
        engagementMetrics: engagementMetrics ?? this.engagementMetrics,
        type: type ?? this.type,
        previews: previews ?? this.previews,
        isLiked: isLiked ?? this.isLiked,
        isSaved: isSaved ?? this.isSaved,
        isFollowing: isFollowing ?? this.isFollowing,
        interests: interests ?? this.interests,
        status: status ?? this.status,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        isLocked: isLocked ?? this.isLocked,
        lockReason: lockReason ?? this.lockReason,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        rejectedAt: rejectedAt ?? this.rejectedAt,
      )..isFromLocal = isFromLocal ?? this.isFromLocal;
}

class PreviewMedia {
  factory PreviewMedia.fromMap(Map<String, dynamic> json) => PreviewMedia(
        mediaType: json.getString('media_type'),
        position: json.getNum('position'),
        url: json.getString('url'),
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
        views: json.getNum('views'),
        uniqueViews: json.getNum('unique_views'),
        likeTypes: json.objectOrNull('like_types', LikeTypes.fromMap),
        comments: json.getNum('comments'),
        shares: json.getNum('shares'),
        saves: json.getNum('saves'),
        watchTime: json.getNum('watch_time'),
        completionRate: json.getNum('completion_rate'),
        engagementRate: json.getNum('engagement_rate'),
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
        like: json.getNum('like'),
        love: json.getNum('love'),
        haha: json.getNum('haha'),
        wow: json.getNum('wow'),
        sad: json.getNum('sad'),
        angry: json.getNum('angry'),
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

class MediaModerationResult {
  MediaModerationResult({
    this.result,
    this.details,
    this.confidence,
    this.provider,
    this.moderatedAt,
  });

  factory MediaModerationResult.fromMap(Map<String, dynamic> json) =>
      MediaModerationResult(
        result: json.stringOrNull('result'),
        details: json.stringOrNull('details'),
        confidence: json.numOrNull('confidence'),
        provider: json.stringOrNull('provider'),
        moderatedAt: json.stringOrNull('moderated_at') ??
            json.stringOrNull('moderatedAt'),
      );

  final String? result;
  final String? details;
  final num? confidence;
  final String? provider;
  final String? moderatedAt;

  Map<String, dynamic> toMap() => {
        'result': result,
        'details': details,
        'confidence': confidence,
        'provider': provider,
        'moderated_at': moderatedAt,
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
      this.fileExtension,
      this.moderationStatus,
      this.rejectionReason,
      this.moderationResult});

  factory MediaData.fromMap(Map<String, dynamic> json) => MediaData(
        mediaType: json.getString('media_type'),
        assetId: json.getString('asset_id'),
        position: json.getNum('position'),
        url: json.getString('url'),
        previewUrl: json.getString('preview_url'),
        width: json.getNum('width'),
        height: json.getNum('height'),
        duration: json.getNum('duration'),
        file: json['file'] is File ? json['file'] as File : null,
        fileName: json.getString('fileName'),
        postType: json['postType'] is PostType
            ? json['postType'] as PostType
            : PostType.photo,
        size: json.getNum('size'),
        moderationStatus: json.stringOrNull('moderation_status') ??
            json.stringOrNull('moderationStatus') ??
            '',
        rejectionReason: json.stringOrNull('rejection_reason') ??
            json.stringOrNull('rejectionReason') ??
            json.stringOrNull('moderation_reason') ??
            json.stringOrNull('moderationReason') ??
            '',
        moderationResult: json.objectOrNull(
          'moderation_result',
          MediaModerationResult.fromMap,
        ),
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
  String? moderationStatus;
  String? rejectionReason;
  MediaModerationResult? moderationResult;
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
        'moderation_status': moderationStatus,
        'rejection_reason': rejectionReason,
        'moderation_result': moderationResult?.toMap(),
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
    final isPaid = json.boolOrNull('is_paid');
    final priceAmount = _readPriceAmount(json['price_amount']);
    final normalizedIsPaid =
        (isPaid == true && priceAmount == null) ? false : isPaid;

    return Settings(
      commentsEnabled: json.getBool('comments_enabled'),
      duetEnabled: json.getBool('duet_enabled'),
      stitchEnabled: json.getBool('stitch_enabled'),
      saveEnabled: json.getBool('save_enabled'),
      downloadEnabled: json.boolOrNull('download_enabled') ?? true,
      isPaid: normalizedIsPaid,
      priceAmount: priceAmount,
      priceCurrency: json.stringOrNull('price_currency'),
      ageRestriction: json.getBool('age_restriction'),
      autoAdvance: json.getBool('auto_advance'),
      advanceInterval: json.getNum('advance_interval'),
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

  static Object? _readPriceAmount(dynamic value) {
    if (value == null) return null;
    if (value is num || value is String) return value;
    return null;
  }

  Map<String, dynamic> toMap() => {
        'comments_enabled': commentsEnabled,
        'duet_enabled': duetEnabled,
        'stitch_enabled': stitchEnabled,
        'save_enabled': saveEnabled,
        'download_enabled': downloadEnabled ?? true,
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
    final title =
        (json.stringOrNull('title') ?? json.stringOrNull('button_text') ?? '')
            .trim();
    return PostLinkData(
      url: json.getString('url').trim(),
      title: title.isEmpty ? null : title,
      textPosition: json.objectOrNull('text_position', TaggedPosition.fromJson),
      mediaPosition:
          json.objectOrNull('media_position', MediaPosition.fromJson),
      previewImage: json.stringOrNull('preview_image'),
      linkData: json.mapOrNull('link_data'),
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
        mentions: _parseObjectList(json, 'mentions', MentionData.fromJson),
        hashtags: _parseObjectList(json, 'hashtags', MentionData.fromJson),
        places: _parseObjectList(json, 'places', TaggedPlace.fromJson),
        products: _parseObjectList(json, 'products', SocialProductData.fromJson),
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
    this.verificationStatus,
  });

  factory SocialUserData.fromMap(Map<String, dynamic> json) => SocialUserData(
        id: json.stringOrNull('id') ?? json.getString('user_id'),
        username: json.getString('username'),
        fullName: json.getString('full_name'),
        displayName: json.getString('display_name'),
        avatarUrl: json.getString('avatar_url'),
        profileType: json.getString('profile_type'),
        userMetadata: json.objectOrNull('user_metadata', UserMetadata.fromMap),
        isFollowing: json.getBool('is_following'),
        isPrivate: _readPrivateFlag(json),
        followStatus: FollowRelationshipStatus.parseFromApiFields(
          followStatus: json['follow_status'] ?? json['followStatus'],
          followRelationship:
              json['follow_relationship'] ?? json['followRelationship'],
        ),
        targetId: json.getString('target_id'),
        isRequested: SocialUserData._readRequested(json),
        verificationStatus: json.stringOrNull('verification_status') ??
            json.stringOrNull('verificationStatus'),
      );

  /// Pending follow request sent (`is_requested` when backend adds it).
  static bool? _readRequested(Map<String, dynamic> json) =>
      json.boolOrNull('is_requested') ?? json.boolOrNull('isRequested');

  static num? _readPrivateFlag(Map<String, dynamic> json) {
    final raw = json['is_private'] ?? json['isPrivate'];
    if (raw == null) return null;
    if (raw is num) return raw;
    final asBool =
        json.boolOrNull('is_private') ?? json.boolOrNull('isPrivate');
    if (asBool != null) return asBool ? 1 : 0;
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
  String? verificationStatus;

  bool get isVerified =>
      verificationStatus?.toLowerCase() == 'verified';

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
        'verification_status': verificationStatus,
      };
}

class UserMetadata {
  UserMetadata({
    this.preferences,
  });

  factory UserMetadata.fromMap(Map<String, dynamic> json) => UserMetadata(
        preferences: json.objectOrNull('preferences', Preferences.fromMap),
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
        theme: json.getString('theme'),
        language: json.getString('language'),
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
        userId: json.getString('user_id'),
        username: json.getString('username'),
        tag: json.getString('tag'),
        name: json.getString('name'),
        avatarUrl: json.getString('avatarUrl'),
        textPosition: json.objectOrNull('text_position', TaggedPosition.fromJson),
        mediaPosition:
            json.objectOrNull('media_position', MediaPosition.fromJson),
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
        start: json.getNum('start'),
        end: json.getNum('end'),
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
        productId: json.getString('product_id'),
        productName: json.getString('product_name'),
        brand: json.getString('brand'),
        category: json.getString('category'),
        price: json.getNum('price'),
        discountPrice: json.getNum('discount_price'),
        currency: json.objectOrNull('currency', Currency.fromJson),
        productUrl: json.getString('product_url'),
        productImage: json.getString('product_image'),
        mediaPosition:
            json.objectOrNull('media_position', ProductPosition.fromJson),
        productSlug: json.getString('product_slug'),
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
        code: json.getString('code'),
        symbol: json.getString('symbol'),
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
        mediaPosition: json.getNum('position'),
        x: json.getNum('x'),
        y: json.getNum('y'),
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
        position: json.getNum('position'),
        x: json.getNum('x'),
        y: json.getNum('y'),
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
        address: json.getString('address'),
        city: json.getString('city'),
        coordinates: (json.listOrNull('coordinates') ?? [])
            .map((x) => (x is num
                    ? x.toDouble()
                    : (x is String ? double.tryParse(x) : null)) ??
                0.0)
            .toList(),
        country: json.getString('country'),
        placeData: json.objectOrNull('place_data', PlaceData.fromJson),
        placeId: json.getString('place_id'),
        placeName: json.getString('place_name'),
        placeType: json.getString('place_type'),
        postalCode: json.getString('postal_code'),
        state: json.getString('state'),
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
        description: json.getString('description'),
      );
  final String? description;

  Map<String, dynamic> toJson() => {
        'description': description,
      };
}

PostSoundInfo? _parseSoundInfo(Map<String, dynamic> json) {
  final snapshot = json.mapOrNull('sound_snapshot');
  final soundObj = json.mapOrNull('sound');
  if (soundObj != null && (soundObj['id'] ?? '') != '') {
    return PostSoundInfo.fromMap(soundObj, snapshot: snapshot);
  }
  final soundId = json.getString('sound_id').trim();
  if (soundId.isEmpty) return null;
  return PostSoundInfo(id: soundId, snapshot: snapshot);
}

List<T> _parseObjectList<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) factory,
) {
  final raw = json.listOrNull(key);
  if (raw == null || raw.isEmpty) return [];
  return raw
      .map((item) {
        if (item is Map) {
          return factory(Map<String, dynamic>.from(item));
        }
        return null;
      })
      .whereType<T>()
      .toList();
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
        durationSeconds: IsrAppConstants.defaultImagePostDurationSeconds,
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
  if (IsrAppConstants.convertHlsPostMediaToImageMedia &&
      mediaData.mediaType == 'video' &&
      mediaData.url?.endsWith('.m3u8') == true) {
    return MediaMetaData(
      mediaType: 0,
      mediaUrl: mediaData.previewUrl ?? '',
      thumbnailUrl: mediaData.previewUrl ?? '',
      durationSeconds: IsrAppConstants.defaultImagePostDurationSeconds,
    );
  }

  return MediaMetaData(
    mediaType: mediaData.mediaType == 'image' ? 0 : 1,
    mediaUrl: mediaData.url ?? '',
    thumbnailUrl: mediaData.previewUrl ?? '',
    durationSeconds: (mediaData.mediaType == 'image'
            ? IsrAppConstants.defaultImagePostDurationSeconds
            : mediaData.duration?.toInt()) ??
        IsrAppConstants.defaultImagePostDurationSeconds,
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
