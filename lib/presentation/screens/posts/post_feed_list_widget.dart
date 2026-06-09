import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/post_feed_scroll_scope.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Result of a post-feed pagination request.
class PostFeedLoadMoreResult {
  const PostFeedLoadMoreResult({
    required this.items,
    required this.hasMore,
  });

  final List<ReelsData> items;
  final bool hasMore;
}

/// Vertical scrollable list of [IsmPostFeedCardView] cards.
class PostFeedListWidget extends StatefulWidget {
  const PostFeedListWidget({
    super.key,
    required this.reelsDataList,
    this.refreshCounts,
    required this.reelsConfig,
    this.postSectionType,
    this.listTopInset,
    this.listBottomInset,
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

  /// Optional per-index refresh tokens from [PostItemWidget] (e.g. after unlock).
  final Map<int, int>? refreshCounts;

  final ReelsConfig reelsConfig;
  final PostSectionType? postSectionType;

  /// Extra top padding when a tab bar overlays this list (multi-tab post-card feed).
  final double? listTopInset;

  /// Extra bottom padding so the last post clears a host bottom nav bar.
  final double? listBottomInset;

  final String? loggedInUserId;
  final VideoCacheManager? videoCacheManager;
  final Future<PostFeedLoadMoreResult> Function()? onLoadMore;
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
  /// Minimum visible fraction before a post can take playback (Instagram-like handoff).
  static const double _minPlayFraction = 0.32;

  /// Keep the current post playing until it drops below this while another competes.
  static const double _stickyPlayFraction = 0.22;

  /// Do not switch unless the challenger leads by at least this much (reduces flicker).
  static const double _switchLeadFraction = 0.06;

  static const double _loadMoreExtent = 360;

  final Map<int, int> _refreshCounts = {};
  final Map<int, double> _visibilityFractions = {};
  final ScrollController _scrollController = ScrollController();
  var _isRefreshing = false;
  var _loadMoreInFlight = false;
  var _showPaginationLoader = false;
  var _hasMorePages = true;
  final ValueNotifier<bool> _isUserScrollingNotifier = ValueNotifier(false);
  final ValueNotifier<int?> _activePlayIndexNotifier = ValueNotifier(null);
  Timer? _scrollIdleDebounce;
  Timer? _precacheDebounce;
  final PostFeedImagePrecacheService _imagePrecache =
      PostFeedImagePrecacheService();

  @override
  void initState() {
    super.initState();
    VisibilityDetectorController.instance.updateInterval =
        const Duration(milliseconds: 100);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleScrollAheadPrecache();
    });
  }

  void _onItemVisibilityFractionChanged(int index, double fraction) {
    if (!mounted) return;
    _visibilityFractions[index] = fraction;
    _recomputeActivePlayIndex();
  }

  void _recomputeActivePlayIndex() {
    int? candidate;
    var maxFraction = 0.0;
    for (final entry in _visibilityFractions.entries) {
      if (entry.value > maxFraction) {
        maxFraction = entry.value;
        candidate = entry.key;
      }
    }

    final current = _activePlayIndexNotifier.value;
    final currentFraction =
        current == null ? 0.0 : (_visibilityFractions[current] ?? 0.0);

    int? newActive = current;

    // If the challenger is clearly leading, switch to it.
    if (candidate != null && maxFraction >= _minPlayFraction) {
      newActive = candidate;

      if (current != null && current != candidate) {
        if (currentFraction >= _stickyPlayFraction &&
            maxFraction - currentFraction < _switchLeadFraction) {
          newActive = current;
        }
      }
    } else {
      // Otherwise keep playing the current post if it still has enough
      // visible area. This avoids the "pause-on-scroll" feeling.
      if (current == null || currentFraction < _stickyPlayFraction) {
        if (candidate != null && maxFraction >= _stickyPlayFraction) {
          newActive = candidate;
        } else {
          newActive = null;
        }
      }
    }

    if (newActive == _activePlayIndexNotifier.value) return;

    final previous = _activePlayIndexNotifier.value;
    _activePlayIndexNotifier.value = newActive;

    if (newActive != null &&
        newActive != previous &&
        newActive < widget.reelsDataList.length) {
      widget.onReelsChange?.call(widget.reelsDataList[newActive], newActive);
    }
  }

  @override
  void dispose() {
    _scrollIdleDebounce?.cancel();
    _precacheDebounce?.cancel();
    _imagePrecache.cancel();
    _isUserScrollingNotifier.dispose();
    _activePlayIndexNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int _estimateFirstVisibleIndex() {
    final active = _activePlayIndexNotifier.value;
    if (active != null) {
      return active.clamp(0, widget.reelsDataList.length - 1);
    }
    if (!_scrollController.hasClients || widget.reelsDataList.isEmpty) {
      return 0;
    }
    const estimatedPostHeight = 520.0;
    return (_scrollController.offset / estimatedPostHeight)
        .floor()
        .clamp(0, widget.reelsDataList.length - 1);
  }

  void _scheduleScrollAheadPrecache() {
    if (!FeedMediaOrientation.shouldProbeForCurrentConfig) return;
    _precacheDebounce?.cancel();
    _precacheDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted || widget.reelsDataList.isEmpty) return;
      final start = _estimateFirstVisibleIndex();
      unawaited(
        _imagePrecache.precacheReels(
          widget.reelsDataList,
          context: context,
          startIndex: start,
        ),
      );
    });
  }

  void _setUserScrolling(bool scrolling) {
    if (_isUserScrollingNotifier.value == scrolling) return;
    _isUserScrollingNotifier.value = scrolling;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // Ignore horizontal child scrollables (media carousels). Treating them as
    // feed scrolling disables PageView swipe physics mid-gesture.
    if (notification.metrics.axis == Axis.horizontal) {
      return false;
    }

    if (notification is ScrollStartNotification ||
        (notification is ScrollUpdateNotification &&
            notification.dragDetails != null)) {
      PostFeedOverlayMenuCoordinator.dismissIfOpen();
      _scrollIdleDebounce?.cancel();
      _setUserScrolling(true);
    } else if (notification is ScrollEndNotification) {
      _scrollIdleDebounce?.cancel();
      _scrollIdleDebounce = Timer(const Duration(milliseconds: 120), () {
        if (mounted) _setUserScrolling(false);
      });
    }

    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification) {
      final metrics = notification.metrics;
      if (metrics.hasPixels) {
        final threshold =
            metrics.maxScrollExtent > 0 ? metrics.maxScrollExtent * 0.65 : 0;
        final nearEnd = metrics.extentAfter <= _loadMoreExtent;
        if (nearEnd || metrics.pixels >= threshold) {
          _scheduleLoadMore();
        }
        _scheduleScrollAheadPrecache();
      }
    }
    if (notification is ScrollEndNotification) {
      _scheduleScrollAheadPrecache();
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
        _hasMorePages = true;
        final visibleCap =
            widget.reelsDataList.length < 6 ? widget.reelsDataList.length : 6;
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

  void _loadMoreIfNearEnd() {
    if (!mounted ||
        widget.onLoadMore == null ||
        _loadMoreInFlight ||
        !_hasMorePages ||
        !_scrollController.hasClients) {
      return;
    }
    final metrics = _scrollController.position;
    if (metrics.extentAfter <= _loadMoreExtent) {
      _scheduleLoadMore();
    }
  }

  void _scheduleLoadMore() {
    if (widget.onLoadMore == null || !_hasMorePages) return;

    // Show the Instagram-style footer spinner immediately — do not wait for
    // the API. A debounce that resets on every scroll frame was delaying both
    // the spinner and the request.
    if (!_showPaginationLoader) {
      setState(() => _showPaginationLoader = true);
    }
    if (_loadMoreInFlight) return;

    unawaited(_executeLoadMore());
  }

  Future<void> _executeLoadMore() async {
    if (!mounted ||
        _loadMoreInFlight ||
        !_hasMorePages ||
        widget.onLoadMore == null) {
      return;
    }

    setState(() => _loadMoreInFlight = true);
    try {
      final result = await widget.onLoadMore!();
      if (!mounted) return;
      setState(() {
        _loadMoreInFlight = false;
        _showPaginationLoader = false;
        _hasMorePages = result.hasMore;
      });
      if (result.hasMore) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadMoreIfNearEnd();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadMoreInFlight = false;
          _showPaginationLoader = false;
        });
      }
    }
  }

  Widget _buildPaginationLoader(PostFeedUIConfig feedUi) {
    final loaderColor = feedUi.secondaryTextColor.withValues(alpha: 0.55);
    final useCupertino = Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS;

    return ColoredBox(
      color: feedUi.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: useCupertino
              ? CupertinoActivityIndicator(radius: 10, color: loaderColor)
              : SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: loaderColor,
                  ),
                ),
        ),
      ),
    );
  }

  ScrollPhysics _listPhysics(BuildContext context) {
    final platform = Theme.of(context).platform;
    final parent =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
            ? const BouncingScrollPhysics()
            : const ClampingScrollPhysics();
    return AlwaysScrollableScrollPhysics(parent: parent);
  }

  @override
  Widget build(BuildContext context) {
    final feedUi = widget.reelsConfig.postConfig.resolvedPostFeedUIConfig;
    final showHeader = feedUi.showHeader;
    final usePostDividers = feedUi.showPostDividers;
    final itemGap =
        usePostDividers ? 0.0 : feedUi.postSpacing.clamp(0.0, double.infinity);
    final topInset = widget.listTopInset ??
        (showHeader
            ? MediaQuery.paddingOf(context).top + IsrDimens.fiftySix
            : MediaQuery.paddingOf(context).top);
    final bottomInset = widget.listBottomInset ?? 0.0;
    final listPadding = EdgeInsets.only(top: topInset, bottom: bottomInset);

    final refreshDisplacement = topInset + IsrDimens.forty;
    // Increase how far ahead the list pre-builds items so the next video is
    // ready to play when it reaches the center of the screen.
    final cacheExtent = MediaQuery.sizeOf(context).height * 1.9;

    Widget buildList(Widget list) => ValueListenableBuilder<bool>(
          valueListenable: _isUserScrollingNotifier,
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: RefreshIndicator(
              displacement: refreshDisplacement,
              onRefresh: widget.onRefresh != null ? _onRefresh : () async {},
              child: list,
            ),
          ),
          builder: (context, isScrolling, scrollableList) =>
              PostFeedScrollScope(
            isScrolling: isScrolling,
            child: scrollableList!,
          ),
        );

    if (widget.reelsDataList.isListEmptyOrNull == true) {
      return buildList(
        ListView(
          controller: _scrollController,
          physics: _listPhysics(context),
          padding: listPadding,
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
        padding: listPadding,
        physics: _listPhysics(context),
        cacheExtent: cacheExtent,
        addRepaintBoundaries: true,
        itemCount:
            widget.reelsDataList.length + (_showPaginationLoader ? 1 : 0),
        separatorBuilder: (context, index) {
          if (index >= widget.reelsDataList.length - 1) {
            return const SizedBox.shrink();
          }
          if (usePostDividers) {
            return Divider(
              height: IsrDimens.one,
              thickness: IsrDimens.one,
              color: feedUi.dividerColor,
            );
          }
          return itemGap > 0
              ? SizedBox(height: itemGap)
              : const SizedBox.shrink();
        },
        itemBuilder: (context, index) {
          if (index >= widget.reelsDataList.length) {
            return _buildPaginationLoader(feedUi);
          }
          return ValueListenableBuilder<int?>(
            valueListenable: _activePlayIndexNotifier,
            builder: (context, activePlayIndex, _) {
              // On first frame, visibility callbacks may not have fired yet.
              // Default to playing the first item so the feed "starts instantly".
              final isFirstItemByDefault =
                  activePlayIndex == null && index == 0;
              return _PostFeedListItem(
                key: ValueKey(widget.reelsDataList[index].postId),
                index: index,
                reelsData: widget.reelsDataList[index],
                refreshToken: widget.refreshCounts?[index] ??
                    _refreshCounts[index] ??
                    0,
                reelsConfig: widget.reelsConfig,
                postSectionType: widget.postSectionType,
                loggedInUserId: widget.loggedInUserId,
                videoCacheManager: widget.videoCacheManager,
                isPostVisible: widget.reelsConfig.isTabVisible() &&
                    (isFirstItemByDefault || activePlayIndex == index),
                onVisibilityFractionChanged: _onItemVisibilityFractionChanged,
                onPressFollowButton: widget.onPressFollowButton,
                onPressMoreButton: widget.onPressMoreButton,
                onPressLikeButton: widget.onPressLikeButton,
                onPressSaveButton: widget.onPressSaveButton,
                onTapUserProfile: widget.onTapUserProfile,
                onTapShare: widget.onTapShare,
                onTapComment: widget.onTapComment,
              );
            },
          );
        },
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
    required this.isPostVisible,
    required this.onVisibilityFractionChanged,
    this.postSectionType,
    this.loggedInUserId,
    this.videoCacheManager,
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
  final bool isPostVisible;
  final void Function(int index, double visibleFraction)
      onVisibilityFractionChanged;
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
  var _disposed = false;

  @override
  void initState() {
    super.initState();
    _visibilityKey = Key('post_feed_${widget.reelsData.postId}');
  }

  @override
  void didUpdateWidget(covariant _PostFeedListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reelsData.postId != widget.reelsData.postId) {
      VisibilityDetectorController.instance.forget(_visibilityKey);
      _visibilityKey = Key('post_feed_${widget.reelsData.postId}');
      widget.onVisibilityFractionChanged(widget.index, 0);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    VisibilityDetectorController.instance.forget(_visibilityKey);
    widget.onVisibilityFractionChanged(widget.index, 0);
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_disposed || !mounted) return;
    widget.onVisibilityFractionChanged(widget.index, info.visibleFraction);
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: ClipRect(
          child: VisibilityDetector(
            key: _visibilityKey,
            onVisibilityChanged: _onVisibilityChanged,
            child: IsmPostFeedCardView(
              key: ValueKey(
                '${widget.reelsData.postId}_${widget.refreshToken}',
              ),
              reelsData: widget.reelsData,
              reelsConfig: widget.reelsConfig,
              postSectionType: widget.postSectionType ?? PostSectionType.forYou,
              isPostVisible: widget.isPostVisible,
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
      );
}
