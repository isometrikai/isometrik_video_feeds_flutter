import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Vertical scrollable list of [IsmPostFeedCardView] cards.
class PostFeedListWidget extends StatefulWidget {
  const PostFeedListWidget({
    super.key,
    required this.reelsDataList,
    required this.reelsConfig,
    this.postSectionType,
    this.loggedInUserId,
    this.videoCacheManager,
    this.onLoadMore,
    this.onRefresh,
    this.getEmptyScreen,
    this.onTapPlaceHolder,
    this.onReelsChange,
    this.onPressMoreButton,
    this.onCreatePost,
    this.onPressFollowButton,
    this.onPressLikeButton,
    this.onPressSaveButton,
    this.onTapMentionTag,
    this.onTapComment,
    this.onTapShare,
    this.onTapUserProfile,
  });

  final List<ReelsData> reelsDataList;
  final ReelsConfig reelsConfig;
  final PostSectionType? postSectionType;
  final String? loggedInUserId;
  final VideoCacheManager? videoCacheManager;
  final Future<List<ReelsData>> Function()? onLoadMore;
  final Future<bool> Function()? onRefresh;
  final Widget? Function()? getEmptyScreen;
  final VoidCallback? onTapPlaceHolder;
  final void Function(ReelsData reelsData, int index)? onReelsChange;
  final Future<void> Function(ReelsData reelsData)? onPressMoreButton;
  final Future<ReelsData?> Function(ReelsData reelsData)? onCreatePost;
  final Future<bool> Function(ReelsData reelsData, bool currentFollow)?
      onPressFollowButton;
  final Future<bool> Function(ReelsData reelsData, bool currentLiked)?
      onPressLikeButton;
  final Future<bool> Function(ReelsData reelsData, bool currentSaved)?
      onPressSaveButton;
  final Future<List<MentionMetaData>?> Function(
    ReelsData reelsData,
    List<MentionMetaData>,
  )? onTapMentionTag;
  final Future<int> Function(ReelsData reelsData, int currentCount)?
      onTapComment;
  final Future<void> Function(ReelsData reelsData)? onTapShare;
  final Future<void> Function(ReelsData reelsData)? onTapUserProfile;

  @override
  State<PostFeedListWidget> createState() => _PostFeedListWidgetState();
}

class _PostFeedListWidgetState extends State<PostFeedListWidget> {
  final ValueNotifier<int> _visiblePostIndex = ValueNotifier(0);
  final Map<int, int> _refreshCounts = {};
  final ScrollController _scrollController = ScrollController();
  var _isRefreshing = false;

  @override
  void dispose() {
    _visiblePostIndex.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing || widget.onRefresh == null) return;
    _isRefreshing = true;
    try {
      final refreshed = await widget.onRefresh!.call();
      if (!mounted || refreshed != true) return;

      _visiblePostIndex.value = 0;
      setState(() {
        for (var i = 0; i < widget.reelsDataList.length; i++) {
          _refreshCounts[i] = (_refreshCounts[i] ?? 0) + 1;
        }
      });

      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } finally {
      _isRefreshing = false;
    }
  }

  void _onScrollNotification(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) return;
    final metrics = notification.metrics;
    if (!metrics.hasPixels || metrics.maxScrollExtent <= 0) return;

    final threshold = metrics.maxScrollExtent * 0.65;
    if (metrics.pixels >= threshold && widget.onLoadMore != null) {
      widget.onLoadMore!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedUi = widget.reelsConfig.postConfig.postFeedUIConfig;
    final showHeader = feedUi?.showHeader ?? true;
    final usePostDividers = feedUi?.showPostDividers ?? false;
    final itemGap = usePostDividers
        ? 0.0
        : (feedUi?.postSpacing ?? 0).clamp(0.0, double.infinity);
    final topInset = showHeader
        ? MediaQuery.paddingOf(context).top + IsrDimens.fiftySix
        : MediaQuery.paddingOf(context).top;

    final refreshDisplacement = topInset + IsrDimens.forty;

    if (widget.reelsDataList.isListEmptyOrNull == true) {
      return RefreshIndicator(
        displacement: refreshDisplacement,
        onRefresh: widget.onRefresh != null ? _onRefresh : () async {},
        child: widget.getEmptyScreen?.call() ??
            ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              padding: EdgeInsets.only(top: topInset),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.7,
                  child: PostPlaceHolderView(
                    postSectionType: widget.postSectionType,
                    onTap: widget.onTapPlaceHolder,
                  ),
                ),
              ],
            ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _onScrollNotification(notification);
        return false;
      },
      child: RefreshIndicator(
        displacement: refreshDisplacement,
        onRefresh: widget.onRefresh != null ? _onRefresh : () async {},
        child: ListView.separated(
          controller: _scrollController,
          padding: EdgeInsets.only(top: topInset),
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          itemCount: widget.reelsDataList.length,
          separatorBuilder: (context, index) {
            if (usePostDividers) {
              return Divider(
                height: IsrDimens.one,
                thickness: IsrDimens.one,
                color: feedUi?.dividerColor ?? const Color(0xFFEFEFEF),
              );
            }
            return itemGap > 0 ? SizedBox(height: itemGap) : const SizedBox.shrink();
          },
          itemBuilder: (context, index) {
            final reelsData = widget.reelsDataList[index];
            return ClipRect(
              child: VisibilityDetector(
              key: Key('post_feed_${reelsData.postId}_$index'),
              onVisibilityChanged: (info) {
                if (info.visibleFraction >= 0.55) {
                  if (_visiblePostIndex.value != index) {
                    _visiblePostIndex.value = index;
                    widget.onReelsChange?.call(reelsData, index);
                  }
                }
              },
              child: ValueListenableBuilder<int>(
                valueListenable: _visiblePostIndex,
                builder: (context, visibleIndex, _) => IsmPostFeedCardView(
                  key: ValueKey(
                    '${reelsData.postId}_${_refreshCounts[index] ?? 0}',
                  ),
                  reelsData: reelsData,
                  reelsConfig: widget.reelsConfig,
                  postSectionType:
                      widget.postSectionType ?? PostSectionType.forYou,
                  isPostVisible: visibleIndex == index,
                  videoCacheManager: widget.videoCacheManager,
                  loggedInUserId: widget.loggedInUserId,
                  logIndex: '$index',
                  onPressFollowButton: widget.onPressFollowButton,
                  onPressMoreButton: widget.onPressMoreButton != null
                      ? () => widget.onPressMoreButton!(reelsData)
                      : null,
                  onPressLikeButton: widget.onPressLikeButton,
                  onPressSaveButton: widget.onPressSaveButton,
                  onTapUserProfile: widget.onTapUserProfile != null
                      ? () => widget.onTapUserProfile!(reelsData)
                      : null,
                  onTapShare: widget.onTapShare != null
                      ? () => widget.onTapShare!(reelsData)
                      : null,
                  onTapComment: widget.onTapComment != null
                      ? () => widget.onTapComment!(
                            reelsData,
                            reelsData.commentCount ?? 0,
                          )
                      : null,
                ),
              ),
            ),
            );
          },
        ),
      ),
    );
  }
}
