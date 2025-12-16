// To parse this JSON data, do
//
//     final timelineResponse = timelineResponseFromMap(jsonString);

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
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
        statusCode: json['statusCode'] as num? ?? 0,
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
    this.isFollowing,
    this.interests,
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
        interests: json['interests'] == null || json['interests'] is String
            ? []
            : List<String>.from(json['interests'] as List)
                .map((item) => item)
                .toList(),
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
  Tags? tags;
  Settings? settings;
  EngagementMetrics? engagementMetrics;
  String? type;
  List<PreviewMedia>? previews;
  bool? isLiked;
  bool? isSaved;
  bool? isFromLocal;
  bool? isFollowing;
  List<String>? interests;

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
        'interests': interests == null
            ? []
            : List<dynamic>.from(interests!.map((x) => x)),
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
      );
  List<MentionData>? mentions;
  List<MentionData>? hashtags;
  List<TaggedPlace>? places;
  List<SocialProductData>? products;

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
      );
  String? id;
  String? username;
  String? fullName;
  String? displayName;
  String? avatarUrl;
  String? profileType;
  UserMetadata? userMetadata;
  bool? isFollowing;

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'full_name': fullName,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'profile_type': profileType,
        'user_metadata': userMetadata?.toMap(),
        'is_following': isFollowing,
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

ReelsData getReelData(TimeLineData postData, {String? loggedInUserId}) =>
    ReelsData(
      postData: postData,
      createOn: postData.publishedAt,
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
      mediaMetaDataList: postData.media?.map(_getMediaMetaData).toList() ?? [],
      userId: postData.user?.id ?? '',
      userName: postData.user?.username ?? '',
      profilePhoto: postData.user?.avatarUrl ?? '',
      firstName: postData.user?.displayName?.split(' ').firstOrNull ?? '',
      lastName: postData.user?.displayName
              ?.split(' ')
              .takeIf((_) => _.length > 1)
              ?.lastOrNull ??
          '',
      likesCount: postData.engagementMetrics?.likeTypes?.love?.toInt() ?? 0,
      commentCount: postData.engagementMetrics?.comments?.toInt() ?? 0,
      isFollow: postData.isFollowing == true,
      isLiked: postData.isLiked,
      isSavedPost: postData.isSaved,
      isVerifiedUser: false,
      productCount: postData.tags?.products?.length ?? 0,
      description: postData.caption ?? '',
      interests: postData.interests,
    );

MediaMetaData _getMediaMetaData(MediaData mediaData) => MediaMetaData(
      mediaType: mediaData.mediaType == 'image' ? 0 : 1,
      mediaUrl: mediaData.url ?? '',
      thumbnailUrl: mediaData.previewUrl ?? '',
    );

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
      placeName: placeData.placeName,
      placeType: placeData.placeType,
      postalCode: placeData.postalCode,
      state: placeData.state,
    );
