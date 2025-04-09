import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

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
  });

  final String title;
  final List<PostDataModel>? postList;
  final Future<String?> Function()? onCreatePost;
  final Future<List<PostDataModel>> Function()? onLoadMore;
  final Future<bool> Function(String)? onTapMore;
  final bool? showBlur;
  final List<FeaturedProductDataItem>? productList;
  final Future<bool> Function(String postId)? onPressSave;
  final Future<bool> Function(String, String, bool)? onPressLike;
  final Future<bool> Function(String)? onPressFollow;
  final Future<bool> Function()? onRefresh;
  final Function(String?)? onTapCartIcon;
  final Widget? placeHolderWidget;
}
