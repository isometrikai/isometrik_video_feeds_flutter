import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';

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
    this.onPressFollow,
    this.onRefresh,
    this.onTapCartIcon,
    this.placeHolderWidget,
    this.onTapComment,
    this.onTapShare,
    this.onTapUserProfile,
    this.footerWidget,
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
    this.mentions,
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

  final Future<bool> Function(bool isSavedPost)? onPressSave;
  final Future<bool> Function(bool)? onPressLike;
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
  final List<MentionMetaData>? mentions;
}

class MediaMetaData {
  MediaMetaData({
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.mediaType,
  });

  final String mediaUrl;
  final String thumbnailUrl;
  final int mediaType;
}

class MentionMetaData {
  MentionMetaData({
    required this.userId,
    required this.username,
    required this.position,
    this.name,
    this.avatarUrl,
  });

  factory MentionMetaData.fromJson(Map<String, dynamic> json) => MentionMetaData(
        userId: json['user_id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String? ?? '',
        position: json['position'] == null
            ? null
            : MentionPosition.fromJson(json['position'] as Map<String, dynamic>),
      );
  String? userId;
  String? username;
  String? name;
  String? avatarUrl;
  MentionPosition? position;

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'username': username,
        'position': position?.toJson(),
      };
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
