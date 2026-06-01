import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/post_feed_scroll_scope.dart';
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
    this.listTopInset,
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

  /// Extra top padding when a tab bar overlays this list (multi-tab post-card feed).
  final double? listTopInset;

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
  static const double _visibleEnterThreshold = 0.72;
  static const double _visibleExitThreshold = 0.28;

  final Map<int, int> _refreshCounts = {};
  final ScrollController _scrollController = ScrollController();
  var _isRefreshing = false;
  var _loadMoreInFlight = false;
  var _isUserScrolling = false;
  Timer? _loadMoreDebounce;
  Timer? _scrollIdleDebounce;

  @override
  void initState() {
    super.initState();
    VisibilityDetectorController.instance.updateInterval =
        const Duration(milliseconds: 400);
  }

  @override
  void dispose() {
    _loadMoreDebounce?.cancel();
    _scrollIdleDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _setUserScrolling(bool scrolling) {
    if (_isUserScrolling == scrolling) return;
    setState(() => _isUserScrolling = scrolling);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification ||
        (notification is ScrollUpdateNotification &&
            notification.dragDetails != null)) {
      _scrollIdleDebounce?.cancel();
      _setUserScrolling(true);
    } else if (notification is ScrollEndNotification) {
      _scrollIdleDebounce?.cancel();
      _scrollIdleDebounce = Timer(const Duration(milliseconds: 120), () {
        if (mounted) _setUserScrolling(false);
      });
    }

    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      if (metrics.hasPixels && metrics.maxScrollExtent > 0) {
        final threshold = metrics.maxScrollExtent * 0.65;
        if (metrics.pixels >= threshold) {
          _scheduleLoadMore();
        }
      }
    }
    return false;
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing || widget.onRefresh == null) return;
    _isRefreshing = true;
    try {
      final refreshed = await widget.onRefresh!.call();
      if (!mounted || refreshed != true) return;

      setState(() {
        final visibleCap = widget.reelsDataList.length < 6
            ? widget.reelsDataList.length
            : 6;
        for (var i = 0; i < visibleCap; i++) {
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

  ScrollPhysics _listPhysics(BuildContext context) {
    final platform = Theme.of(context).platform;
    final parent = platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    return AlwaysScrollableScrollPhysics(parent: parent);
  }

  @override
  Widget build(BuildContext context) {
    final feedUi = widget.reelsConfig.postConfig.resolvedPostFeedUIConfig;
    final showHeader = feedUi.showHeader;
    final usePostDividers = feedUi.showPostDividers;
    final itemGap = usePostDividers
        ? 0.0
        : feedUi.postSpacing.clamp(0.0, double.infinity);
    final topInset = widget.listTopInset ??
        (showHeader
            ? MediaQuery.paddingOf(context).top + IsrDimens.fiftySix
            : MediaQuery.paddingOf(context).top);

    final refreshDisplacement = topInset + IsrDimens.forty;
    final cacheExtent = MediaQuery.sizeOf(context).height * 1.25;

    Widget buildList(Widget list) => PostFeedScrollScope(
          isScrolling: _isUserScrolling,
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: RefreshIndicator(
              displacement: refreshDisplacement,
              onRefresh: widget.onRefresh != null ? _onRefresh : () async {},
              child: list,
            ),
          ),
        );

    if (widget.reelsDataList.isListEmptyOrNull == true) {
      return buildList(
        ListView(
          controller: _scrollController,
          physics: _listPhysics(context),
          padding: EdgeInsets.only(top: topInset),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.7,
              child: PostPlaceHolderView(
                postSectionType: widget.postSectionType,
                feedLayoutType: FeedLayoutType.postFeed,
                onTap: widget.onTapPlaceHolder,
              ),
            ),
          ],
        ),
      );
    }

    return buildList(
      ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.only(top: topInset),
        physics: _listPhysics(context),
        cacheExtent: cacheExtent,
        addRepaintBoundaries: true,
        itemCount: widget.reelsDataList.length,
        separatorBuilder: (context, index) {
          if (usePostDividers) {
            return Divider(
              height: IsrDimens.one,
              thickness: IsrDimens.one,
              color: feedUi.dividerColor,
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
  late Key _visibilityKey;
  late final ValueNotifier<bool> _isVisible;
  var _disposed = false;
  var _wasPrimaryVisible = false;

  @override
  void initState() {
    super.initState();
    _visibilityKey = Key('post_feed_${widget.reelsData.postId}');
    _isVisible = ValueNotifier(false);
  }

  @override
  void didUpdateWidget(covariant _PostFeedListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reelsData.postId != widget.reelsData.postId) {
      VisibilityDetectorController.instance.forget(_visibilityKey);
      _visibilityKey = Key('post_feed_${widget.reelsData.postId}');
      _wasPrimaryVisible = false;
      _isVisible.value = false;
    }
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

    final fraction = info.visibleFraction;
    final currentlyVisible = _isVisible.value;

    final bool visible;
    if (currentlyVisible) {
      visible = fraction >= _PostFeedListWidgetState._visibleExitThreshold;
    } else {
      visible = fraction >= _PostFeedListWidgetState._visibleEnterThreshold;
    }

    if (currentlyVisible == visible) return;
    _isVisible.value = visible;

    if (visible && !_wasPrimaryVisible) {
      _wasPrimaryVisible = true;
      widget.onBecamePrimaryVisible?.call(widget.reelsData, widget.index);
    } else if (!visible) {
      _wasPrimaryVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scrollScope = PostFeedScrollScope.maybeOf(context);
    final allowHeavyMedia = scrollScope?.allowHeavyMedia ?? true;

    return RepaintBoundary(
      child: ClipRect(
        child: VisibilityDetector(
          key: _visibilityKey,
          onVisibilityChanged: _onVisibilityChanged,
          child: ValueListenableBuilder<bool>(
            valueListenable: _isVisible,
            builder: (context, isVisible, _) {
              final allowVideo = isVisible && allowHeavyMedia;
              return IsmPostFeedCardView(
                key: ValueKey(
                  '${widget.reelsData.postId}_${widget.refreshToken}',
                ),
                reelsData: widget.reelsData,
                reelsConfig: widget.reelsConfig,
                postSectionType:
                    widget.postSectionType ?? PostSectionType.forYou,
                isPostVisible: allowVideo,
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
              );
            },
          ),
        ),
      ),
    );
  }
}
