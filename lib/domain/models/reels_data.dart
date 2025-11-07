import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class ReelsData {
  ReelsData({
    this.postId,
    this.profilePhoto,
    this.userId,
    this.userName,
    this.firstName,
    this.lastName,
    this.hasTags,
    this.isVerifiedUser,
    this.isSelfProfile = false,
    this.isFollow = false,
    this.isLiked,
    this.likesCount,
    this.onPressSave,
    this.onPressLike,
    this.onDoubleTap,
    this.onPressFollow,
    this.onRefresh,
    this.onTapCartIcon,
    this.placeHolderWidget,
    this.onTapComment,
    this.onTapShare,
    this.onTapUserProfile,
    this.footerWidget,
    this.overlayPadding,
    this.actionWidget,
    this.description,
    this.onTapReport,
    this.showBlur,
    this.productCount,
    this.onPressMoreButton,
    this.commentCount,
    this.postStatus,
    this.isCreatePostButtonVisible,
    this.isScheduledPost,
    this.isSavedPost,
    this.postSetting,
    this.onCreatePost,
    required this.mediaMetaDataList,
    this.mentions = const [],
    this.tagDataList,
    this.onTapMentionTag,
    this.onTapPlace,
    this.placeDataList,
    this.tags,
  });

  final String? postId;
  final String? userName;
  final String? userId;
  final String? firstName;
  final String? lastName;
  final String? profilePhoto;
  final bool? isVerifiedUser;
  final bool? isSelfProfile;
  final String? description;
  final List<MediaMetaData> mediaMetaDataList;
  bool? isFollow;
  bool? isLiked;
  int? likesCount;
  final List<String>? hasTags;
  final ReelsWidgetBuilder? footerWidget;
  final ReelsWidgetBuilder? actionWidget;
  final EdgeInsetsGeometry? overlayPadding;

  final Future<bool> Function(bool isSavedPost)? onPressSave;
  final Future<bool> Function(bool)? onPressLike;
  final Future<bool> Function(bool)? onDoubleTap;
  final Future<bool> Function(String, bool)? onPressFollow;
  final Future<bool> Function()? onRefresh;
  final Future<ReelsData?> Function()? onCreatePost;

  // final Future<num>? Function(String, String)? onTapCartIcon;
  final VoidCallback? onTapCartIcon;
  final Future<dynamic> Function()? onPressMoreButton;
  final Widget? placeHolderWidget;
  final Future<int>? Function(int)? onTapComment;
  final VoidCallback? onTapShare;
  final Function(bool)? onTapUserProfile;
  final Function()? onTapReport;
  final bool? showBlur;
  final int? productCount;
  int? commentCount;
  final int? postStatus;
  final bool? isCreatePostButtonVisible;
  final bool? isScheduledPost;
  bool? isSavedPost;
  final PostSetting? postSetting;
  List<MentionMetaData> mentions;
  final List<MentionMetaData>? tagDataList;
  final List<PlaceMetaData>? placeDataList;
  final Future<List<MentionMetaData>?> Function(List<MentionMetaData>)? onTapMentionTag;
  final Function(List<PlaceMetaData>)? onTapPlace;
  final Tags? tags;
}

class MediaMetaData {
  MediaMetaData({
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.mediaType,
  });

  final String mediaUrl;
  final String thumbnailUrl;
  final int mediaType; // 0 for image, 1 for video
}

class MentionMetaData {
  MentionMetaData({
    this.userId,
    this.username,
    this.tag,
    this.textPosition,
    this.name,
    this.avatarUrl,
    this.mediaPosition,
  });

  factory MentionMetaData.fromJson(Map<String, dynamic> json) => MentionMetaData(
        userId: json['user_id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        tag: json['tag'] as String? ?? '',
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String? ?? '',
        textPosition: json['text_position'] == null
            ? null
            : MentionPosition.fromJson(json['text_position'] as Map<String, dynamic>),
        mediaPosition: json['media_position'] == null
            ? null
            : MediaPosition.fromJson(json['media_position'] as Map<String, dynamic>),
      );
  String? userId;
  String? username;
  String? tag;
  String? name;
  String? avatarUrl;
  MentionPosition? textPosition;
  MediaPosition? mediaPosition;

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'username': username,
        'tag': tag,
        'text_position': textPosition?.toJson(),
        'media_position': mediaPosition?.toJson(),
      }.removeEmptyValues();
}

class MentionPosition {
  MentionPosition({
    required this.start,
    required this.end,
  });

  factory MentionPosition.fromJson(Map<String, dynamic> json) => MentionPosition(
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

class PostSetting {
  PostSetting({
    this.isProfilePicVisible = false,
    this.isCreatePostButtonVisible = false,
    this.isFollowButtonVisible = false,
    this.isUnFollowButtonVisible = false,
    this.isShareButtonVisible = false,
    this.isCommentButtonVisible = false,
    this.isLikeButtonVisible = false,
    this.isSaveButtonVisible = false,
    this.isMoreButtonVisible = false,
  });

  final bool isProfilePicVisible;
  final bool isCreatePostButtonVisible;
  final bool isFollowButtonVisible;
  final bool isUnFollowButtonVisible;
  final bool isShareButtonVisible;
  final bool isCommentButtonVisible;
  final bool isLikeButtonVisible;
  final bool isSaveButtonVisible;
  final bool isMoreButtonVisible;
}

class PlaceMetaData {
  PlaceMetaData({
    this.address,
    this.city,
    this.coordinates,
    this.country,
    this.description,
    this.placeId,
    this.placeName,
    this.placeType,
    this.postalCode,
    this.state,
  });

  factory PlaceMetaData.fromJson(Map<String, dynamic> json) => PlaceMetaData(
        address: json['address'] as String? ?? '',
        city: json['city'] as String? ?? '',
        coordinates: json['coordinates'] == null
            ? []
            : List<double>.from((json['coordinates'] as List).map((x) => x?.toDouble())),
        country: json['country'] as String? ?? '',
        description: json['description'] as String? ?? '',
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
  final String? description;
  final String? placeId;
  final String? placeName;
  final String? placeType;
  final String? postalCode;
  final String? state;

  Map<String, dynamic> toJson() => {
        'address': address,
        'city': city,
        'coordinates': coordinates == null ? [] : List<dynamic>.from(coordinates!.map((x) => x)),
        'country': country,
        'description': description,
        'place_id': placeId,
        'place_name': placeName,
        'place_type': placeType,
        'postal_code': postalCode,
        'state': state,
      };
}

enum PostSectionType {
  forYou,
  following,
  trending,
}
