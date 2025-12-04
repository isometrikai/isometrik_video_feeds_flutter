import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Core reel data model (NO callbacks)
class ReelsData {
  ReelsData({
    this.postData,
    this.postId,
    this.userName,
    this.userId,
    this.firstName,
    this.lastName,
    this.profilePhoto,
    this.isVerifiedUser,
    this.isSelfProfile = false,
    this.description,
    required this.mediaMetaDataList,
    this.isFollow,
    this.isLiked,
    this.likesCount,
    this.hasTags,
    this.showBlur,
    this.productCount,
    this.commentCount,
    this.postStatus,
    this.isCreatePostButtonVisible,
    this.isScheduledPost,
    this.isSavedPost,
    this.postSetting,
    this.mentions = const [],
    this.tagDataList,
    this.placeDataList,
    this.tags,
    this.createOn,
  });

  final dynamic postData;
  final String? postId;
  final String? userName;
  final String? userId;
  final String? firstName;
  final String? lastName;
  final String? profilePhoto;
  final bool? isVerifiedUser;
  final bool? isSelfProfile;
  final String? description;
  final String? createOn;

  final List<MediaMetaData> mediaMetaDataList;

  bool? isFollow;
  bool? isLiked;
  bool? isSavedPost;
  int? likesCount;
  int? commentCount;
  final List<String>? hasTags;

  final bool? showBlur;
  final int? productCount;
  final int? postStatus;
  final bool? isCreatePostButtonVisible;
  final bool? isScheduledPost;
  final PostSetting? postSetting;

  List<MentionMetaData> mentions;
  final List<MentionMetaData>? tagDataList;
  final List<PlaceMetaData>? placeDataList;
  final Tags? tags;

  ReelsData copyWith({
    bool? isFollow,
    bool? isLiked,
    bool? isSavedPost,
    int? likesCount,
    int? commentCount,
  }) => ReelsData(
      postData: postData,
      postId: postId,
      userName: userName,
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      profilePhoto: profilePhoto,
      isVerifiedUser: isVerifiedUser,
      isSelfProfile: isSelfProfile,
      description: description,
      mediaMetaDataList: mediaMetaDataList,
      hasTags: hasTags,
      showBlur: showBlur,
      productCount: productCount,
      postStatus: postStatus,
      isCreatePostButtonVisible: isCreatePostButtonVisible,
      isScheduledPost: isScheduledPost,
      postSetting: postSetting,
      mentions: mentions,
      tagDataList: tagDataList,
      placeDataList: placeDataList,
      tags: tags,
      createOn: createOn,
      isFollow: isFollow ?? this.isFollow,
      isLiked: isLiked ?? this.isLiked,
      isSavedPost: isSavedPost ?? this.isSavedPost,
      likesCount: likesCount ?? this.likesCount,
      commentCount: commentCount ?? this.commentCount,
    );
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

  factory MentionMetaData.fromJson(Map<String, dynamic> json) =>
      MentionMetaData(
        userId: json['user_id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        tag: json['tag'] as String? ?? '',
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String? ?? '',
        textPosition: json['text_position'] == null
            ? null
            : MentionPosition.fromJson(
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

  factory MentionPosition.fromJson(Map<String, dynamic> json) =>
      MentionPosition(
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
            : List<double>.from(
                (json['coordinates'] as List).map((x) => x?.toDouble())),
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
        'coordinates': coordinates == null
            ? []
            : List<dynamic>.from(coordinates!.map((x) => x)),
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
  myPost,
  otherUserPost,
  savedPost,
  myTaggedPost,
  tagPost,
  singlePost,
}
