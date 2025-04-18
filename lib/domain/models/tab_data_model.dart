import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/isr_enums.dart';

class TabDataModel {
  TabDataModel({
    required this.title,
    this.postList = const [],
    this.onCreatePost,
    this.onTapMore,
    this.showBlur,
    this.productList,
    this.onPressSave,
    this.onPressLike,
    this.onPressFollow,
    this.onLoadMore,
    this.onRefresh,
    this.onTapCartIcon,
    this.placeHolderWidget,
    this.postSectionType = PostSectionType.following,
    this.onTapComment,
    this.onTapShare,
    this.isCreatePostButtonVisible,
    this.startingPostIndex = 0,
  });

  final String title;
  final List<PostDataModel>? postList;
  final Future<String?> Function()? onCreatePost;
  final Future<List<PostDataModel>> Function()? onLoadMore;
  final Future<bool> Function(String postId, String userId)? onTapMore;
  final bool? showBlur;
  final List<FeaturedProductDataItem>? productList;
  final Future<bool> Function(String postId)? onPressSave;
  final Future<bool> Function(String, String, bool)? onPressLike;
  final Future<bool> Function(String)? onPressFollow;
  final Future<bool> Function()? onRefresh;
  final Function(String, String)? onTapCartIcon;
  final Widget? placeHolderWidget;
  final PostSectionType? postSectionType;
  final Future<num>? Function(String)? onTapComment;
  final Function(String)? onTapShare;
  final bool? isCreatePostButtonVisible;
  final int? startingPostIndex;
}
