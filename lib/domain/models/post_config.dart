import 'package:flutter/widgets.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class PostConfig {
  const PostConfig({
    this.postUIConfig,
    this.postCallBackConfig,
    this.autoMoveToNextMedia = true,
  });

  final PostUIConfig? postUIConfig;
  final PostCallBackConfig? postCallBackConfig;
  final bool autoMoveToNextMedia;

  PostConfig copyWith({
    PostUIConfig? postUIConfig,
    PostCallBackConfig? postCallBackConfig,
  }) =>
      PostConfig(
        postUIConfig: postUIConfig ?? this.postUIConfig,
        postCallBackConfig: postCallBackConfig ?? postCallBackConfig,
      );
}

class PostUIConfig {
  const PostUIConfig({
    this.overlayPadding,
  });

  final EdgeInsetsGeometry? overlayPadding;

  PostUIConfig copyWith({
    EdgeInsetsGeometry? overlayPadding,
  }) =>
      PostUIConfig(
        overlayPadding: overlayPadding ?? this.overlayPadding,
      );
}

class PostCallBackConfig {
  const PostCallBackConfig({
    this.onSaveChanged,
    this.onLikeChanged,
    this.onSaveClicked,
    this.onFollowClick,
    this.onShareClicked,
    this.onLikeClick,
    this.onCommentClick,
    this.onProfileClick,
    this.onTagProductClick,
    this.onPostChanged,
  });

  final Function(TimeLineData postData, bool isSaved)? onSaveChanged;
  final Function(TimeLineData postData, bool isLiked)? onLikeChanged;
  // return true if success
  final Future<bool> Function(TimeLineData? postData, bool isSaved)?
      onSaveClicked;
  final Future<bool> Function(TimeLineData? postData, bool isLiked)?
      onLikeClick;
  final Future<bool> Function(TimeLineData? postData, bool isFollow)?
      onFollowClick;

  final Function(TimeLineData postData)? onShareClicked;
  final Function(TimeLineData postData)? onCommentClick;
  final Function(TimeLineData? postData, String userId, bool? isFollowing)?
      onProfileClick;
  final Future<void> Function(TimeLineData postData)? onTagProductClick;
  final Function(TimeLineData postData, int index)? onPostChanged;

  PostCallBackConfig copyWith({
    Function(TimeLineData postData, bool isSaved)? onSaveChanged,
    Function(TimeLineData postData, bool isLiked)? onLikeChanged,
    Future<bool> Function(TimeLineData? postData, bool isLiked)? onLikeClick,
    Future<bool> Function(TimeLineData? postData, bool isLiked)?
        onFollowClicked,
    Future<bool> Function(TimeLineData? postData, bool isSaved)? onSaveClicked,
    Function(TimeLineData postData)? onShareClicked,
    Function(TimeLineData postData)? onCommentClick,
    Function(TimeLineData? postData, String userId, bool? isFollowing)?
        onProfileClick,
    Future<void> Function(TimeLineData postData)? onTagProductClick,
    Function(TimeLineData postData, int index)? onPostChanged,
  }) =>
      PostCallBackConfig(
        onSaveChanged: onSaveChanged ?? this.onSaveChanged,
        onLikeChanged: onLikeChanged ?? this.onLikeChanged,
        onSaveClicked: onSaveClicked ?? this.onSaveClicked,
        onShareClicked: onShareClicked ?? this.onShareClicked,
        onLikeClick: onLikeClick ?? this.onLikeClick,
        onCommentClick: onCommentClick ?? this.onCommentClick,
        onProfileClick: onProfileClick ?? this.onProfileClick,
        onTagProductClick: onTagProductClick ?? this.onTagProductClick,
        onPostChanged: onPostChanged ?? this.onPostChanged,
      );
}
