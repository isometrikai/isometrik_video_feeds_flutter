import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';

// class TabDataModel {
//   TabDataModel({
//     required this.title,
//     this.postList = const [],
//     this.timeLinePosts = const [],
//     this.onCreatePost,
//     this.onTapMore,
//     this.showBlur,
//     this.productList,
//     this.onPressSave,
//     this.onPressLike,
//     this.onPressFollow,
//     this.onLoadMore,
//     this.onRefresh,
//     this.onTapCartIcon,
//     this.placeHolderWidget,
//     this.postSectionType = PostSectionType.following,
//     this.onTapComment,
//     this.onTapShare,
//     this.isCreatePostButtonVisible,
//     this.startingPostIndex = 0,
//     this.onTapUserProfile,
//   });
//
//   final String title;
//   final List<PostDataModel>? postList;
//   final List<TimeLineData>? timeLinePosts;
//   final Future<String?> Function()? onCreatePost;
//   final Future<List<TimeLineData>> Function(PostSectionType?)? onLoadMore;
//   final Future<dynamic> Function(TimeLineData, String userId)? onTapMore;
//   final bool? showBlur;
//   final List<FeaturedProductDataItem>? productList;
//   final Future<bool> Function(String postId, bool isSavedPost)? onPressSave;
//   final Future<bool> Function(String, String, bool)? onPressLike;
//   final Future<bool> Function(String)? onPressFollow;
//   final Future<bool> Function()? onRefresh;
//   final Future<List<SocialProductData>>? Function(String, String)? onTapCartIcon;
//   final Widget? placeHolderWidget;
//   final PostSectionType? postSectionType;
//   final Future<num>? Function(String, int)? onTapComment;
//   final Function(String)? onTapShare;
//   final Function(String)? onTapUserProfile;
//   final bool? isCreatePostButtonVisible;
//   final int? startingPostIndex;
// }

class TabDataModel {
  TabDataModel({
    required this.title,
    required this.reelsDataList,
    this.startingPostIndex = 0,
    required this.postSectionType,
    this.onTapCartIcon,
    this.placeHolderWidget,
    this.onTapUserProfile,
    this.onPressSave,
    this.overlayPadding,
    this.onDeletePostSuccess,
    this.userId,
    this.postId,
    this.tagValue,
    this.tagType,
    this.onShareClick,
  });

  final String title;
  List<TimeLineData> reelsDataList;
  final Function(List<String> productIds, String postId, String userId)?
      onTapCartIcon;
  final int? startingPostIndex;
  final PostSectionType postSectionType;
  final Function(String postId, bool isPostEmpty)? onDeletePostSuccess;
  Widget? placeHolderWidget;
  String? userId;
  String? postId;
  String? tagValue;
  TagType? tagType;
  void Function(String? userId)? onTapUserProfile;
  final Future<bool> Function(bool isSavedPost, TimeLineData postData)?
      onPressSave;
  final Future<void> Function(TimeLineData postData)? onShareClick;
  final EdgeInsetsGeometry? overlayPadding;

  //to maintain state
  // int? currentIndex; //to maintain post position
  // String? currentPostId; //to maintain post position

  // -------------------------------------------------------
  //                      COPY WITH
  // -------------------------------------------------------
  TabDataModel copyWith({
    String? title,
    List<TimeLineData>? reelsDataList,
    Function(List<String> productIds, String postId, String userId)?
        onTapCartIcon,
    int? startingPostIndex,
    PostSectionType? postSectionType,
    Function(String postId, bool isPostEmpty)? onDeletePostSuccess,
    Widget? placeHolderWidget,
    String? userId,
    String? postId,
    String? tagValue,
    TagType? tagType,
    void Function(String? userId)? onTapUserProfile,
    Future<bool> Function(bool isSavedPost, TimeLineData postData)? onPressSave,
    EdgeInsetsGeometry? overlayPadding,
    Future<void> Function(TimeLineData postData)? onShareClick,
  }) =>
      TabDataModel(
        title: title ?? this.title,
        reelsDataList: reelsDataList ?? this.reelsDataList,
        startingPostIndex: startingPostIndex ?? this.startingPostIndex,
        postSectionType: postSectionType ?? this.postSectionType,
        onTapCartIcon: onTapCartIcon ?? this.onTapCartIcon,
        placeHolderWidget: placeHolderWidget ?? this.placeHolderWidget,
        onTapUserProfile: onTapUserProfile ?? this.onTapUserProfile,
        onPressSave: onPressSave ?? this.onPressSave,
        overlayPadding: overlayPadding ?? this.overlayPadding,
        onDeletePostSuccess: onDeletePostSuccess ?? this.onDeletePostSuccess,
        userId: userId ?? this.userId,
        postId: postId ?? this.postId,
        tagValue: tagValue ?? this.tagValue,
        tagType: tagType ?? this.tagType,
        onShareClick: onShareClick ?? this.onShareClick,
      );
}
