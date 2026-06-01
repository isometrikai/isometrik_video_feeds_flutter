import 'dart:async';

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
  final Map<int, int> _refreshCounts = {};
  final ScrollController _scrollController = ScrollController();
  var _isRefreshing = false;
  var _loadMoreInFlight = false;
  Timer? _loadMoreDebounce;

  @override
  void initState() {
    super.initState();
    VisibilityDetectorController.instance.updateInterval =
        const Duration(milliseconds: 250);
  }

  @override
  void dispose() {
    _loadMoreDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing || widget.onRefresh == null) return;
    _isRefreshing = true;
    try {
      final refreshed = await widget.onRefresh!.call();
      if (!mounted || refreshed != true) return;

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
    if (metrics.pixels >= threshold) {
      _scheduleLoadMore();
    }
  }

  void _scheduleLoadMore() {
    if (widget.onLoadMore == null || _loadMoreInFlight) return;
    _loadMoreDebounce?.cancel();
    _loadMoreDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted || _loadMoreInFlight) return;
      _loadMoreInFlight = true;
      try {
        await widget.onLoadMore!();
      } finally {
        if (mounted) _loadMoreInFlight = false;
      }
    });
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
          itemBuilder: (context, index) => _PostFeedListItem(
            key: ValueKey(widget.reelsDataList[index].postId),
            index: index,
            reelsData: widget.reelsDataList[index],
            refreshToken: _refreshCounts[index] ?? 0,
            reelsConfig: widget.reelsConfig,
            postSectionType: widget.postSectionType,
            loggedInUserId: widget.loggedInUserId,
            videoCacheManager: widget.videoCacheManager,
            onBecamePrimaryVisible: widget.onReelsChange,
            onPressFollowButton: widget.onPressFollowButton,
            onPressMoreButton: widget.onPressMoreButton,
            onPressLikeButton: widget.onPressLikeButton,
            onPressSaveButton: widget.onPressSaveButton,
            onTapUserProfile: widget.onTapUserProfile,
            onTapShare: widget.onTapShare,
            onTapComment: widget.onTapComment,
          ),
        ),
      ),
    );
  }
}

/// Owns visibility state so scrolling does not rebuild every card in the list.
class _PostFeedListItem extends StatefulWidget {
  const _PostFeedListItem({
    super.key,
    required this.index,
    required this.reelsData,
    required this.refreshToken,
    required this.reelsConfig,
    this.postSectionType,
    this.loggedInUserId,
    this.videoCacheManager,
    this.onBecamePrimaryVisible,
    this.onPressMoreButton,
    this.onPressFollowButton,
    this.onPressLikeButton,
    this.onPressSaveButton,
    this.onTapComment,
    this.onTapShare,
    this.onTapUserProfile,
  });

  final int index;
  final ReelsData reelsData;
  final int refreshToken;
  final ReelsConfig reelsConfig;
  final PostSectionType? postSectionType;
  final String? loggedInUserId;
  final VideoCacheManager? videoCacheManager;
  final void Function(ReelsData reelsData, int index)? onBecamePrimaryVisible;
  final Future<void> Function(ReelsData reelsData)? onPressMoreButton;
  final Future<bool> Function(ReelsData reelsData, bool currentFollow)?
      onPressFollowButton;
  final Future<bool> Function(ReelsData reelsData, bool currentLiked)?
      onPressLikeButton;
  final Future<bool> Function(ReelsData reelsData, bool currentSaved)?
      onPressSaveButton;
  final Future<int> Function(ReelsData reelsData, int currentCount)?
      onTapComment;
  final Future<void> Function(ReelsData reelsData)? onTapShare;
  final Future<void> Function(ReelsData reelsData)? onTapUserProfile;

  @override
  State<_PostFeedListItem> createState() => _PostFeedListItemState();
}

class _PostFeedListItemState extends State<_PostFeedListItem> {
  late final Key _visibilityKey;
  late final ValueNotifier<bool> _isVisible;
  var _disposed = false;

  @override
  void initState() {
    super.initState();
    _visibilityKey = Key('post_feed_${widget.reelsData.postId}');
    _isVisible = ValueNotifier(false);
  }

  @override
  void dispose() {
    _disposed = true;
    VisibilityDetectorController.instance.forget(_visibilityKey);
    _isVisible.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_disposed || !mounted) return;
    final visible = info.visibleFraction >= 0.55;
    if (_isVisible.value == visible) return;
    _isVisible.value = visible;
    if (visible) {
      widget.onBecamePrimaryVisible?.call(widget.reelsData, widget.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRect(
        child: VisibilityDetector(
          key: _visibilityKey,
          onVisibilityChanged: _onVisibilityChanged,
          child: ValueListenableBuilder<bool>(
            valueListenable: _isVisible,
            builder: (context, isVisible, _) => IsmPostFeedCardView(
              key: ValueKey('${widget.reelsData.postId}_${widget.refreshToken}'),
              reelsData: widget.reelsData,
              reelsConfig: widget.reelsConfig,
              postSectionType: widget.postSectionType ?? PostSectionType.forYou,
              isPostVisible: isVisible,
              videoCacheManager: widget.videoCacheManager,
              loggedInUserId: widget.loggedInUserId,
              logIndex: '${widget.index}',
              onPressFollowButton: widget.onPressFollowButton,
              onPressMoreButton: widget.onPressMoreButton != null
                  ? () => widget.onPressMoreButton!(widget.reelsData)
                  : null,
              onPressLikeButton: widget.onPressLikeButton,
              onPressSaveButton: widget.onPressSaveButton,
              onTapUserProfile: widget.onTapUserProfile != null
                  ? () => widget.onTapUserProfile!(widget.reelsData)
                  : null,
              onTapShare: widget.onTapShare != null
                  ? () => widget.onTapShare!(widget.reelsData)
                  : null,
              onTapComment: widget.onTapComment != null
                  ? () => widget.onTapComment!(
                        widget.reelsData,
                        widget.reelsData.commentCount ?? 0,
                      )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
