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
  });

  final String title;
  final List<PostDataModel>? postList;
  final Future<PostDataModel?> Function()? onCreatePost;
  final Future<bool> Function(String)? onTapMore;
  final bool? showBlur;
  final List<FeaturedProductDataItem>? productList;
  final Future<bool> Function(String postId)? onPressSave;
  final Future<bool> Function(String, String, bool)? onPressLike;
  final Future<bool> Function(String)? onPressFollow;
}
