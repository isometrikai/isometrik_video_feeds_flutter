import 'package:flutter/widgets.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';

/// UI + interaction handlers only
class ReelsConfig {
  ReelsConfig({
    this.footerWidget,
    this.actionWidget,
    this.overlayPadding,
    this.placeHolderWidget,
    this.onPressSave,
    this.onPressLike,
    this.onPressFollow,
    this.onRefresh,
    this.onTaggedProduct,
    this.onTapComment,
    this.onTapShare,
    this.onTapUserProfile,
    this.onTapReport,
    this.onPressMoreButton,
    this.onCreatePost,
    this.onReelsChange,
    this.onTapMentionTag,
    this.onTapPlace,
  });

  // UI Elements
  final ReelsWidgetBuilder Function(ReelsData reelsData)? footerWidget;
  final ReelsWidgetBuilder Function(ReelsData reelsData)? actionWidget;
  final EdgeInsetsGeometry? overlayPadding;
  final Widget? placeHolderWidget;

  // All callbacks return Future<void>
  final Future<bool> Function(ReelsData reelsData, bool currentSaved)?
      onPressSave;

  final Future<bool> Function(ReelsData reelsData, bool currentLiked)?
      onPressLike;

  final Future<bool> Function(ReelsData reelsData, bool currentFollow)?
      onPressFollow;

  final Future<bool> Function(ReelsData reelsData)? onRefresh;
  final Future<void> Function(ReelsData reelsData)? onTaggedProduct;
  final Future<int> Function(ReelsData reelsData, int currentCount)?
      onTapComment;
  final Future<void> Function(ReelsData reelsData)? onTapShare;
  final Future<void> Function(ReelsData reelsData)? onTapUserProfile;
  final Future<void> Function(ReelsData reelsData)? onTapReport;
  final Future<dynamic> Function(ReelsData reelsData)? onPressMoreButton;
  final Future<ReelsData?> Function(ReelsData reelsData)? onCreatePost;

  final void Function(ReelsData reelsData, int index)? onReelsChange;

  final Future<List<MentionMetaData>?> Function(
      ReelsData reelsData, List<MentionMetaData>)? onTapMentionTag;

  final Future<void> Function(ReelsData reelsData, List<PlaceMetaData>)?
      onTapPlace;
}
