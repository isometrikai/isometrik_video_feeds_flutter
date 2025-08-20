// To parse this JSON data, do
//
//     final timelineResponse = timelineResponseFromMap(jsonString);

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

TimelineResponse timelineResponseFromJson(String str) =>
    TimelineResponse.fromMap(json.decode(str) as Map<String, dynamic>);

String timelineResponseToMap(TimelineResponse data) => json.encode(data.toMap());

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

  factory TimelineResponse.fromMap(Map<String, dynamic> json) => TimelineResponse(
        status: json['status'] as String? ?? '',
        message: json['message'] as String? ?? '',
        statusCode: json['statusCode'] as num? ?? 0,
        code: json['code'] as String? ?? '',
        data: json['data'] == null
            ? []
            : List<TimeLineData>.from(
                (json['data'] as List).map((x) => TimeLineData.fromMap(x as Map<String, dynamic>))),
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
        'data': data == null ? [] : List<dynamic>.from(data!.map((x) => x.toMap())),
        'total': total,
        'page': page,
        'page_size': pageSize,
        'total_pages': totalPages,
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
    this.tags,
    this.settings,
    this.engagementMetrics,
    this.type,
    this.previews,
    this.isLiked,
    this.isSaved,
  });

  factory TimeLineData.fromMap(Map<String, dynamic> json) => TimeLineData(
        textFormatting: json['text_formatting'] as String? ?? '',
        publishedAt: json['published_at'] as String? ?? '',
        media: json['media'] == null
            ? []
            : List<MediaData>.from(
                (json['media'] as List).map((x) => MediaData.fromMap(x as Map<String, dynamic>))),
        soundId: json['sound_id'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        user: json['user'] == null ? null : User.fromMap(json['user'] as Map<String, dynamic>),
        visibility: json['visibility'] as String? ?? '',
        id: json['id'] as String? ?? '',
        soundSnapshot: json['sound_snapshot'] as String? ?? '',
        tags: json['tags'] == null
            ? null
            : json['tags'] is String && (json['tags'] as String).isEmptyOrNull
                ? null
                : Tags.fromMap(json['tags'] as Map<String, dynamic>),
        settings: json['settings'] == null
            ? null
            : Settings.fromMap(json['settings'] as Map<String, dynamic>),
        engagementMetrics: json['engagement_metrics'] == null
            ? null
            : EngagementMetrics.fromMap(json['engagement_metrics'] as Map<String, dynamic>),
        type: json['type'] as String? ?? '',
        previews: json['previews'] == null
            ? []
            : List<PreviewMedia>.from((json['previews'] as List)
                .map((x) => PreviewMedia.fromMap(x as Map<String, dynamic>))),
        isLiked: json['is_liked'] as bool? ?? false,
        isSaved: json['is_saved'] as bool? ?? false,
      );
  String? textFormatting;
  String? publishedAt;
  List<MediaData>? media;
  String? soundId;
  String? caption;
  String? userId;
  User? user;
  String? visibility;
  String? id;
  String? soundSnapshot;
  Tags? tags;
  Settings? settings;
  EngagementMetrics? engagementMetrics;
  String? type;
  List<PreviewMedia>? previews;
  bool? isLiked;
  bool? isSaved;

  Map<String, dynamic> toMap() => {
        'text_formatting': textFormatting,
        'published_at': publishedAt,
        'media': media == null ? [] : List<dynamic>.from(media!.map((x) => x.toMap())),
        'sound_id': soundId,
        'caption': caption,
        'user_id': userId,
        'user': user?.toMap(),
        'visibility': visibility,
        'id': id,
        'sound_snapshot': soundSnapshot,
        'tags': tags?.toMap(),
        'settings': settings?.toMap(),
        'engagement_metrics': engagementMetrics?.toMap(),
        'type': type,
        'previews': previews == null ? [] : List<dynamic>.from(previews!.map((x) => x.toMap())),
        'is_liked': isLiked,
        'is_saved': isSaved,
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

  factory EngagementMetrics.fromMap(Map<String, dynamic> json) => EngagementMetrics(
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
  MediaData({
    this.mediaType,
    this.assetId,
    this.position,
    this.url,
    this.previewUrl,
    this.description,
    this.width,
    this.height,
    this.duration,
    this.fileName,
    this.postType,
    this.size,
  });

  factory MediaData.fromMap(Map<String, dynamic> json) => MediaData(
        mediaType: json['media_type'] as String? ?? '',
        assetId: json['asset_id'] as String? ?? '',
        position: json['position'] as num? ?? 0,
        url: json['url'] as String? ?? '',
        previewUrl: json['preview_url'] as String? ?? '',
        width: json['width'] as num? ?? 0,
        height: json['height'] as num? ?? 0,
        duration: json['duration'] as num? ?? 0,
        fileName: json['fileName'] as String? ?? '',
        postType: json['postType'] as PostType? ?? PostType.photo,
        size: json['size'] as num? ?? 0,
      );
  String? mediaType;
  String? assetId;
  num? position;
  String? url;
  String? previewUrl;
  dynamic description;
  num? width;
  num? height;
  num? duration;
  String? fileName;
  String? fileExtension;
  String? coverFileName;
  String? coverFileExtension;
  PostType? postType;
  num? size;
  Uint8List? videoThumbnailFileBytes;

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
    this.ageRestriction,
    this.autoAdvance,
    this.advanceInterval,
    this.audioSettings,
  });

  factory Settings.fromMap(Map<String, dynamic> json) => Settings(
        commentsEnabled: json['comments_enabled'] as bool? ?? false,
        duetEnabled: json['duet_enabled'] as bool? ?? false,
        stitchEnabled: json['stitch_enabled'] as bool? ?? false,
        saveEnabled: json['save_enabled'] as bool? ?? false,
        ageRestriction: json['age_restriction'] as bool? ?? false,
        autoAdvance: json['auto_advance'] as bool? ?? false,
        advanceInterval: json['advance_interval'] as num? ?? 0,
        audioSettings: json['audio_settings'],
      );
  bool? commentsEnabled;
  bool? duetEnabled;
  bool? stitchEnabled;
  bool? saveEnabled;
  bool? ageRestriction;
  bool? autoAdvance;
  num? advanceInterval;
  dynamic audioSettings;

  Map<String, dynamic> toMap() => {
        'comments_enabled': commentsEnabled,
        'duet_enabled': duetEnabled,
        'stitch_enabled': stitchEnabled,
        'save_enabled': saveEnabled,
        'age_restriction': ageRestriction,
        'auto_advance': autoAdvance,
        'advance_interval': advanceInterval,
        'audio_settings': audioSettings,
      };
}

class Tags {
  Tags({
    this.mentions,
    this.hashtags,
    this.places,
    this.products,
  });

  factory Tags.fromMap(Map<String, dynamic> json) => Tags(
        mentions: json['mentions'] == null || (json['mentions'] as List).isEmptyOrNull
            ? []
            : List<MentionData>.from((json['mentions'] as List).map((x) =>
                x is Map<String, dynamic> ? MentionData.fromJson(x) : MentionData.fromJson({}))),
        hashtags: json['hashtags'] == null || (json['hashtags'] as List).isEmptyOrNull
            ? []
            : List<MentionData>.from((json['hashtags'] as List).map((x) =>
                x is Map<String, dynamic> ? MentionData.fromJson(x) : MentionData.fromJson({}))),
        places:
            json['places'] == null ? [] : List<String>.from((json['places'] as List).map((x) => x)),
        products: json['products'] == null
            ? []
            : List<SocialProductData>.from((json['products'] as List)
                .map((x) => SocialProductData.fromJson(x as Map<String, dynamic>))),
      );
  List<MentionData>? mentions;
  List<MentionData>? hashtags;
  List<String>? places;
  List<SocialProductData>? products;

  Map<String, dynamic> toMap() => {
        'mentions': mentions == null ? [] : List<dynamic>.from(mentions!.map((x) => x.toJson())),
        'hashtags': hashtags == null ? [] : List<dynamic>.from(hashtags!.map((x) => x.toJson())),
        'places': places == null ? [] : List<dynamic>.from(places!.map((x) => x)),
        'products': products == null ? [] : List<dynamic>.from(products!.map((x) => x.toJson())),
      };
}

class User {
  User({
    this.id,
    this.username,
    this.fullName,
    this.displayName,
    this.avatarUrl,
    this.userMetadata,
  });

  factory User.fromMap(Map<String, dynamic> json) => User(
        id: json['id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String? ?? '',
        userMetadata: json['user_metadata'] == null
            ? null
            : UserMetadata.fromMap(json['user_metadata'] as Map<String, dynamic>),
      );
  String? id;
  String? username;
  String? fullName;
  String? displayName;
  String? avatarUrl;
  UserMetadata? userMetadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'full_name': fullName,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'user_metadata': userMetadata?.toMap(),
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
    required this.userId,
    required this.username,
    required this.position,
  });

  factory MentionData.fromJson(Map<String, dynamic> json) => MentionData(
        userId: json['user_id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        position: json['position'] == null
            ? null
            : Position.fromJson(json['position'] as Map<String, dynamic>),
      );
  String? userId;
  String? username;
  Position? position;

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'username': username,
        'position': position?.toJson(),
      };
}

class Position {
  Position({
    required this.start,
    required this.end,
  });

  factory Position.fromJson(Map<String, dynamic> json) => Position(
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
    required this.id,
    required this.name,
    required this.brandName,
    required this.price,
    required this.discountPrice,
    required this.currency,
    required this.url,
    required this.imageUrl,
    required this.position,
  });

  factory SocialProductData.fromJson(Map<String, dynamic> json) => SocialProductData(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        brandName: json['brand_name'] as String? ?? '',
        price: json['price'] as num? ?? 0,
        discountPrice: json['discount_price'] as num? ?? 0,
        currency: json['currency'] == null
            ? null
            : Currency.fromJson(json['currency'] as Map<String, dynamic>),
        url: json['url'] as String? ?? '',
        imageUrl: json['image_url'] as String? ?? '',
        position: json['position'] == null
            ? null
            : ProductPosition.fromJson(json['position'] as Map<String, dynamic>),
      );
  String? id;
  String? name;
  String? brandName;
  num? price;
  num? discountPrice;
  Currency? currency;
  String? url;
  String? imageUrl;
  ProductPosition? position;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand_name': brandName,
        'price': price,
        'discount_price': discountPrice,
        'currency': currency?.toJson(),
        'url': url,
        'image_url': imageUrl,
        'position': position?.toJson(),
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

  factory ProductPosition.fromJson(Map<String, dynamic> json) => ProductPosition(
        mediaPosition: json['media_position'] as num? ?? 0,
        x: json['x'] as num? ?? 0,
        y: json['y'] as num? ?? 0,
      );
  num? mediaPosition;
  num? x;
  num? y;

  Map<String, dynamic> toJson() => {
        'media_position': mediaPosition,
        'x': x,
        'y': y,
      };
}
