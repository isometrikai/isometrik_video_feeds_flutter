import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:preload_page_view/preload_page_view.dart';

class PostItemWidget extends StatefulWidget {
  const PostItemWidget({
    super.key,
    this.onLoadMore,
    this.onPostFeedLoadMore,
    this.onRefresh,
    this.postSectionType,
    this.feedLayoutType = FeedLayoutType.reels,
    this.postFeedListTopInset,
    this.postFeedListBottomInset,
    this.onTapPlaceHolder,
    this.startingPostIndex = 0,
    this.loggedInUserId,
    this.allowImplicitScrolling = true,
    this.allowDuplicatePostInList = false,
    required this.reelsDataList,
    this.videoCacheManager,
    this.getEmptyScreen,
    required this.reelsConfig,
  });

  final Future<List<ReelsData>> Function()? onLoadMore;
  final Future<PostFeedLoadMoreResult> Function()? onPostFeedLoadMore;
  final Widget? Function()? getEmptyScreen;
  final Future<bool> Function()? onRefresh;
  final PostSectionType? postSectionType;
  final FeedLayoutType feedLayoutType;

  /// When the reels tab bar overlays a post-card tab, inset scroll content below it.
  final double? postFeedListTopInset;

  /// When a host bottom nav overlays the feed, inset scroll content above it.
  final double? postFeedListBottomInset;

  final VoidCallback? onTapPlaceHolder;
  final int? startingPostIndex;
  final String? loggedInUserId;
  final bool? allowImplicitScrolling;

  /// When true, load-more appends posts even if the same post id already exists.
  final bool allowDuplicatePostInList;

  final List<ReelsData> reelsDataList;
  final VideoCacheManager? videoCacheManager;
  final ReelsConfig reelsConfig;

  @override
  State<PostItemWidget> createState() => _PostItemWidgetState();
}

class _PostItemWidgetState extends State<PostItemWidget>
    with AutomaticKeepAliveClientMixin {
  late PreloadPageController _pageController;
  final Set<String> _cachedImages = {};
  late final VideoCacheManager _videoCacheManager;
  List<ReelsData> _reelsDataList = [];
  late final IsmSocialActionCubit _ismSocialActionCubit;
  late final ValueNotifier<int> _currentIndex;
  final ValueNotifier<int> _lifecycleResumeTick = ValueNotifier<int>(0);
  bool _isPlaybackBlocked = false;
  late final VoidCallback _sectionForegroundResumeHandler;

  bool _isInitialized = false;
  /// Guards reels [onLoadMore] so rapid page changes past the threshold do not
  /// stack concurrent pagination requests.
  var _reelsLoadMoreInFlight = false;

  // Track refresh count for each index to force rebuild
  final Map<int, int> _refreshCounts = {};

  /// [PreloadPageController.page] asserts when no [PreloadPageView] is attached.
  int get _resolvedCurrentPageIndex => _pageController.hasClients
      ? _pageController.page!.round()
      : _currentIndex.value;

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  /// Initialize the widget
  void _onStartInit() {
    _ismSocialActionCubit = context.getOrCreateBloc();
    _videoCacheManager = widget.videoCacheManager ?? VideoCacheManager();
    _reelsDataList = List<ReelsData>.from(widget.reelsDataList);
    _pageController =
        PreloadPageController(initialPage: widget.startingPostIndex ?? 0);
    _currentIndex = ValueNotifier<int>(widget.startingPostIndex ?? 0);
    _sectionForegroundResumeHandler = _onSectionForegroundResume;
    final section = widget.postSectionType;
    if (section != null) {
      IsrVideoReelConfig.registerSectionForegroundResume(
        section,
        _sectionForegroundResumeHandler,
      );
    }
    _initializeContent();
  }

  void _onSectionForegroundResume() {
    if (!mounted || !IsrVideoReelConfig.allowsPlayback) return;
    if (!widget.reelsConfig.isTabVisible()) return;
    _isPlaybackBlocked = false;
    _lifecycleResumeTick.value++;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
    }
  }

  @override
  void didUpdateWidget(PostItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameReelsList(oldWidget.reelsDataList, widget.reelsDataList)) return;

    if (_isPostFeedLayout &&
        widget.reelsDataList.length > _reelsDataList.length &&
        _hasSameReelsPrefix(_reelsDataList, widget.reelsDataList)) {
      final allowDuplicates = widget.allowDuplicatePostInList;
      final appended = allowDuplicates
          ? widget.reelsDataList.sublist(_reelsDataList.length)
          : widget.reelsDataList
              .where((reel) =>
                  !_reelsDataList.any((e) => e.postId == reel.postId))
              .toList();
      if (appended.isNotEmpty) {
        _reelsDataList.addAll(appended);
        _updateState();
        return;
      }
    }

    _reelsDataList = List<ReelsData>.from(widget.reelsDataList);
    _updateState();
  }

  bool _sameReelsList(List<ReelsData> previous, List<ReelsData> next) {
    if (identical(previous, next)) return true;
    if (previous.length != next.length) return false;
    for (var i = 0; i < previous.length; i++) {
      if (previous[i].postId != next[i].postId) return false;
      if (previous[i].isLocked != next[i].isLocked) return false;
      if (previous[i].lockReason != next[i].lockReason) return false;
      if (previous[i].mediaMetaDataList.length !=
          next[i].mediaMetaDataList.length) {
        return false;
      }
    }
    return true;
  }

  bool _hasSameReelsPrefix(List<ReelsData> prefix, List<ReelsData> full) {
    if (prefix.length > full.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (prefix[i].postId != full[i].postId) return false;
    }
    return true;
  }

  /// Engagement / caption refresh from host-cache detail sync — same media,
  /// no need to remount [IsmReelsVideoPlayerView] (that clears comments/video).
  bool _isSoftReelUpdate(ReelsData existing, ReelsData updated) {
    if (existing.postId != updated.postId) return false;
    if (existing.mediaMetaDataList.length != updated.mediaMetaDataList.length) {
      return false;
    }
    for (var i = 0; i < existing.mediaMetaDataList.length; i++) {
      final prev = existing.mediaMetaDataList[i];
      final next = updated.mediaMetaDataList[i];
      if (prev.mediaUrl != next.mediaUrl ||
          prev.mediaType != next.mediaType ||
          prev.thumbnailUrl != next.thumbnailUrl) {
        return false;
      }
    }
    return true;
  }

  void _initializeContent() async {
    if (_reelsDataList.isListEmptyOrNull == false) {
      // OPTIMIZATION: Separate critical (thumbnails) from non-critical (videos) loading
      final firstPost = _reelsDataList[0];
      final criticalUrls =
          <String>[]; // Thumbnails and images - must load first
      final nonCriticalUrls = <String>[]; // Videos - can load in background

      // Process ALL media items in the first post
      for (var mediaItem in firstPost.mediaMetaDataList) {
        if (mediaItem.mediaUrl.isEmpty) continue;

        if (mediaItem.mediaType == MediaType.video.value) {
          // Video - load thumbnail first (critical), video later (non-critical)
          if (mediaItem.thumbnailUrl.isNotEmpty) {
            criticalUrls.add(mediaItem.thumbnailUrl);
            debugPrint(
                '🚀 MainWidget: Prioritizing thumbnail: ${mediaItem.thumbnailUrl}');
          }
          nonCriticalUrls.add(mediaItem.mediaUrl);
        } else {
          // Image - critical to show immediately
          criticalUrls.add(mediaItem.mediaUrl);
          debugPrint(
              '🚀 MainWidget: Prioritizing image: ${mediaItem.mediaUrl}');
        }
      }

      // OPTIMIZATION: Only wait for critical thumbnails/images, not full videos
      if (criticalUrls.isNotEmpty) {
        // Load thumbnails and images first with high priority
        unawaited(
            MediaCacheFactory.precacheMedia(criticalUrls, highPriority: true)
                .then((_) {
          debugPrint(
              '✅ MainWidget: Critical media loaded (${criticalUrls.length} items)');

          // Preload profile images and other critical images in background
          unawaited(_preloadCriticalImages(firstPost));
        }));
      }

      // OPTIMIZATION: Start video loading immediately but don't wait for it
      if (nonCriticalUrls.isNotEmpty) {
        unawaited(
            MediaCacheFactory.precacheMedia(nonCriticalUrls, highPriority: true)
                .then((_) {
          debugPrint(
              '✅ MainWidget: Videos loaded (${nonCriticalUrls.length} items)');
        }));
      }

      // Start caching other media in parallel (non-blocking)
      unawaited(_doMediaCaching(0));

      // Start background preloading of remaining posts (low priority)
      unawaited(_backgroundPreloadPosts());
    }

    if (!mounted) return;

    // OPTIMIZATION: Animate to target page after PageView is built
    // Must use post-frame callback because PageController is not attached yet in initState
    final targetPage = _pageController.initialPage >= _reelsDataList.length
        ? _reelsDataList.length - 1
        : _pageController.initialPage;
    if (targetPage > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(targetPage);
        }
      });
    }
  }

  @override
  void dispose() {
    final section = widget.postSectionType;
    if (section != null) {
      IsrVideoReelConfig.unregisterSectionForegroundResume(section);
    }
    _pageController.dispose();
    _currentIndex.dispose();
    _lifecycleResumeTick.dispose();
    // Don't clear all cache on dispose, only clear controllers
    // _videoCacheManager.clearControllers();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  bool get _isPostFeedLayout =>
      widget.feedLayoutType == FeedLayoutType.postFeed;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return context.attachBlocIfNeeded<IsmSocialActionCubit>(
      bloc: _ismSocialActionCubit,
      child: BlocListener<IsmSocialActionCubit, IsmSocialActionState>(
        listenWhen: (previous, current) =>
            (current is IsmFollowActionListenerState &&
                (widget.postSectionType == PostSectionType.following ||
                    widget.postSectionType == PostSectionType.feeds)) ||
            (current is IsmSaveActionListenerState &&
                widget.postSectionType == PostSectionType.savedPost) ||
            (current is IsmDeletedPostActionListenerState) ||
            (current is IsmEditPostActionListenerState) ||
            (current is IsmMentionRemovedActionListenerState),
        listener: (context, state) {
          if (state is IsmFollowActionListenerState &&
              (widget.postSectionType == PostSectionType.following ||
                  widget.postSectionType == PostSectionType.feeds)) {
            _updateWithFollowAction(state);
          } else if (state is IsmSaveActionListenerState &&
              widget.postSectionType == PostSectionType.savedPost) {
            _updateWithSaveAction(state);
          } else if (state is IsmDeletedPostActionListenerState) {
            _updateWithDeleteAction(state);
          } else if (state is IsmMentionRemovedActionListenerState) {
            _updateWithMentionRemovedAction(state);
          } else if (state is IsmEditPostActionListenerState) {
            _updateWithEditAction(state);
          }
        },
        child: BlocListener<SocialPostBloc, SocialPostState>(
          listenWhen: (previous, current) => current is PlayPauseVideoState,
          listener: (context, state) {
            if (state is PlayPauseVideoState) {
              final section = widget.postSectionType;
              if (section != null &&
                  !IsrVideoReelConfig.playPauseAppliesToSection(
                    section,
                    state,
                  )) {
                return;
              }
              _isPlaybackBlocked = !state.play;
            }
          },
          child: _reelsDataList.isListEmptyOrNull == true
              ? _buildPlaceHolder(context)
              : _isPostFeedLayout
                  ? _buildPostFeedContent(context)
                  : _buildContent(context),
        ),
      ),
    );
  }

  Future<void> _updateWithEditAction(
      IsmEditPostActionListenerState state) async {
    debugPrint('IsmEditPostActionListenerState: ${state.postData?.toMap()}');
    if (state.postData != null &&
        _reelsDataList.any((e) => e.postId == state.postId)) {
      final index = _reelsDataList.indexWhere(
        (element) => element.postId == state.postData!.id,
      );

      debugPrint('IsmEditPostActionListenerState: index $index');
      if (index != -1) {
        final postData =
            getReelData(state.postData!, loggedInUserId: widget.loggedInUserId);
        final existing = _reelsDataList[index];
        _reelsDataList[index] = postData;
        if (_isSoftReelUpdate(existing, postData)) {
          _updateState();
          return;
        }
        await updateStateByKey(editedIndex: index);
      }
    }
  }

  Future<void> _updateWithDeleteAction(
      IsmDeletedPostActionListenerState state) async {
    if (_reelsDataList.any((e) => e.postId == state.postId)) {
      final deletedPost =
          _reelsDataList.firstWhere((e) => e.postId == state.postId);
      await evictDeletedPostMedia(deletedPost);
      _reelsDataList.removeWhere((element) => element.postId == state.postId);
      await updateStateByKey();
    }
  }

  Future<void> _updateWithMentionRemovedAction(
      IsmMentionRemovedActionListenerState state) async {
    if (!_reelsDataList.any((e) => e.postId == state.postId)) {
      return;
    }

    if (widget.postSectionType == PostSectionType.myTaggedPost) {
      await _updateWithDeleteAction(
        IsmDeletedPostActionListenerState(postId: state.postId),
      );
      return;
    }

    final index =
        _reelsDataList.indexWhere((element) => element.postId == state.postId);
    if (index == -1) {
      return;
    }

    final reel = _reelsDataList[index];
    reel.mentions = reel.mentions
        .where((mention) => mention.userId != state.userId)
        .toList();

    if (reel.postData is TimeLineData) {
      final post = reel.postData as TimeLineData;
      post.tags?.mentions
          ?.removeWhere((mention) => mention.userId == state.userId);
    }

    _refreshCounts[index] = (_refreshCounts[index] ?? 0) + 1;
    await updateStateByKey();
  }

  Future<void> _updateWithSaveAction(IsmSaveActionListenerState state) async {
    if (!state.isSaved && widget.postSectionType == PostSectionType.savedPost) {
      _reelsDataList.removeWhere((element) => element.postId == state.postId);
      await updateStateByKey();
    }
  }

  Future<void> updateStateByKey({int? editedIndex}) async {
    final refreshIndex = editedIndex ?? _resolvedCurrentPageIndex;
    debugPrint('🔄 MainWidget: Starting update at index $refreshIndex');

    // Increment refresh count to force rebuild
    _refreshCounts[refreshIndex] = (_refreshCounts[refreshIndex] ?? 0) + 1;
    _updateState();
    // Re-initialize caching for current index after successful refresh
    await _doMediaCaching(refreshIndex);
  }

  String? _reelAuthorUserId(ReelsData reel) {
    final direct = reel.userId;
    if (direct != null && direct.isNotEmpty) return direct;
    final post = reel.postData;
    if (post is TimeLineData) {
      final fromUser = post.user?.id;
      if (fromUser != null && fromUser.isNotEmpty) return fromUser;
      final userId = post.userId;
      if (userId != null && userId.isNotEmpty) return userId;
    }
    return null;
  }

  Future<void> _updateWithFollowAction(
      IsmFollowActionListenerState state) async {
    var updateState = false;
    if (state.isFollowing &&
        !state.followRequestPending &&
        !_reelsDataList.any((element) => element.userId == state.userId)) {
      final followedUserReels = await _ismSocialActionCubit.getUserPostList(
          state.userId,
          forceMap: (post) => post.also((p) => p.isFollowing = true));
      if (followedUserReels.isEmpty) {
        followedUserReels.addAll(_ismSocialActionCubit.getPostList(
            filter: (post) => post.userId == state.userId));
      }
      if (followedUserReels.isNotEmpty) {
        _reelsDataList.addAll(followedUserReels
            .map((e) => getReelData(e, loggedInUserId: widget.loggedInUserId)));
        _reelsDataList.sort((a, b) {
          final dateA = DateTime.tryParse(a.createOn ?? '');
          final dateB = DateTime.tryParse(b.createOn ?? '');

          // Default fallback date when parsing fails
          final safeA =
              dateA ?? DateTime.fromMillisecondsSinceEpoch(0); // oldest
          final safeB = dateB ?? DateTime.fromMillisecondsSinceEpoch(0);

          return safeB.compareTo(safeA); // latest → oldest
        });

        updateState = true;
      }
    } else if (!state.isFollowing &&
        !state.followRequestPending &&
        _reelsDataList.any((element) => _reelAuthorUserId(element) == state.userId)) {
      _reelsDataList.removeWhere(
        (element) => _reelAuthorUserId(element) == state.userId,
      );
      updateState = true;
    }
    if (updateState) {
      await updateStateByKey();
    }
  }

  Widget _buildPlaceHolder(BuildContext context) => Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _refreshPost();
              },
              child: widget.getEmptyScreen?.call() ??
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: Center(
                        child: PostPlaceHolderView(
                              postSectionType: widget.postSectionType,
                              feedLayoutType: widget.feedLayoutType,
                              onTap: () {
                                if (widget.onTapPlaceHolder != null) {
                                  widget.onTapPlaceHolder!();
                                }
                              },
                            ),
                      ),
                    ),
                  ),
            ),
          ),
        ],
      );

  Widget _buildPostFeedContent(BuildContext context) => PostFeedListWidget(
        reelsDataList: _reelsDataList,
        refreshCounts: _refreshCounts,
        reelsConfig: widget.reelsConfig,
        lifecycleResumeTick: _lifecycleResumeTick,
        postSectionType: widget.postSectionType,
        listTopInset: widget.postFeedListTopInset,
        listBottomInset: widget.postFeedListBottomInset,
        loggedInUserId: widget.loggedInUserId,
        videoCacheManager: _videoCacheManager,
        getEmptyScreen: widget.getEmptyScreen,
        onTapPlaceHolder: widget.onTapPlaceHolder,
        onReelsChange: widget.reelsConfig.onReelsChange,
        onLoadMore: () async {
          final allowDuplicates = widget.allowDuplicatePostInList;
          if (widget.onPostFeedLoadMore != null) {
            final result = await widget.onPostFeedLoadMore!();
            if (result.items.isNotEmpty) {
              final appended = allowDuplicates
                  ? result.items
                  : result.items
                      .where((reel) => !_reelsDataList
                          .any((existing) => existing.postId == reel.postId))
                      .toList();
              if (appended.isNotEmpty) {
                _reelsDataList.addAll(appended);
                _updateState();
              }
            }
            return result;
          }
          if (widget.onLoadMore == null) {
            return const PostFeedLoadMoreResult(items: [], hasMore: false);
          }
          final value = await widget.onLoadMore!();
          if (value.isListEmptyOrNull) {
            return const PostFeedLoadMoreResult(items: [], hasMore: false);
          }
          final newReels = allowDuplicates
              ? value
              : value
                  .where((newReel) => !_reelsDataList
                      .any((existing) => existing.postId == newReel.postId))
                  .toList();
          if (newReels.isNotEmpty) {
            _reelsDataList.addAll(newReels);
            _updateState();
          }
          return PostFeedLoadMoreResult(
            items: newReels.toList(),
            hasMore: value.length >= 20,
          );
        },
        onRefresh: _refreshPostFeed,
        onPressMoreButton: widget.reelsConfig.onPressMoreButton,
        onCreatePost: widget.reelsConfig.onCreatePost,
        onPressFollowButton: widget.reelsConfig.onPressFollow,
        onPressLikeButton: widget.reelsConfig.onPressLike,
        onPressSaveButton: widget.reelsConfig.onPressSave,
        onTapMentionTag: widget.reelsConfig.onTapMentionTag,
        onTapComment: widget.reelsConfig.onTapComment,
        onTapShare: widget.reelsConfig.onTapShare,
        onTapUserProfile: widget.reelsConfig.onTapUserProfile,
      );

  Widget _buildContent(BuildContext context) => Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _refreshPost();
              },
              child: PreloadPageView.builder(
                preloadPagesCount: _videoCacheManager.currentPlayerType == VideoPlayerType.standardNonPreload ? 2 : 1,
                // key: _pageStorageKey,
                // allowImplicitScrolling: widget.allowImplicitScrolling ?? true,
                controller: _pageController,
                // physics: const AlwaysScrollableScrollPhysics(
                //     parent: ClampingScrollPhysics()),
                onPageChanged: (index) {
                  _currentIndex.value = index;
                  _doMediaCaching(index);
                  final post = _reelsDataList[index];

                  // EventQueueProvider.instance.addEvent({
                  //   'type': EventType.view.value,
                  //   'postId': post.postId,
                  //   'userId': widget.loggedInUserId,
                  //   'timestamp': DateTime.now().toUtc().toIso8601String(),
                  // });
                  // Check if we're at 65% of the list
                  final threshold = (_reelsDataList.length * 0.65).floor();
                  if (index >= threshold ||
                      index == _reelsDataList.length - 1) {
                    _requestReelsLoadMore();
                  }
                  if (widget.reelsConfig.onReelsChange != null) {
                    widget.reelsConfig.onReelsChange?.call(post, index);
                  }
                },
                itemCount: _reelsDataList.length,
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  final reelsData = _reelsDataList[index];
                  return RepaintBoundary(
                    child: IsmReelsVideoPlayerView(
                      index: index,
                      currentIndex: _currentIndex,
                      lifecycleResumeTick: _lifecycleResumeTick,
                      reelsData: reelsData,
                      postSectionType:
                          widget.postSectionType ?? PostSectionType.following,
                      loggedInUserId: widget.loggedInUserId,
                      videoCacheManager: _videoCacheManager,
                      // Add refresh count to force rebuild
                      key: ValueKey(
                          '${reelsData.postId}_${_refreshCounts[index] ?? 0}'),
                      onVideoCompleted: (widget.reelsConfig.postConfig.autoMoveToNextPost)
                          ? () => _handleVideoCompletion(index)
                          : null,
                      reelsConfig: widget.reelsConfig,
                      onPressMoreButton: () async {
                        if (widget.reelsConfig.onPressMoreButton == null) {
                          return;
                        }
                        final savedIndex = _resolvedCurrentPageIndex;
                        await widget.reelsConfig.onPressMoreButton!
                            .call(reelsData);
                        if (!mounted || !_pageController.hasClients) return;
                        final target = savedIndex.clamp(
                          0,
                          _reelsDataList.length - 1,
                        );
                        if (target != _resolvedCurrentPageIndex) {
                          _pageController.jumpToPage(target);
                          _currentIndex.value = target;
                        }
                      },
                      onCreatePost: () async {
                        if (widget.reelsConfig.onCreatePost != null) {
                          final result =
                              await widget.reelsConfig.onCreatePost!(reelsData);
                          if (result != null) {
                            _reelsDataList.insert(index, result);
                            _updateState();
                          }
                        }
                      },
                      onPressFollowButton: widget.reelsConfig.onPressFollow,
                      onPressLikeButton: widget.reelsConfig.onPressLike,
                      onPressSaveButton: widget.reelsConfig.onPressSave,
                      onTapMentionTag: (mentionedList) async {
                        if (widget.reelsConfig.onTapMentionTag != null) {
                          await widget.reelsConfig.onTapMentionTag!(reelsData, mentionedList);
                          // for untagging, do so from IsmSocialActionCubit
                        }
                      },
                      onTapCartIcon: (productId) {
                        widget.reelsConfig.onTaggedProduct?.call(reelsData);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );

  /// Background preloading of posts that are not immediately visible
  Future<void> _backgroundPreloadPosts() async {
    if (_reelsDataList.length <= 5) return; // Skip if not enough posts

    final backgroundUrls = <String>[];

    // OPTIMIZATION: Platform-specific background preloading
    // Android: Only preload 5-7 positions away (conservative)
    // iOS: Preload 5-10 positions away (more aggressive)
    final startIndex = 5;
    final endIndex =
        math.min(_reelsDataList.length - 1, Platform.isAndroid ? 7 : 10);

    for (var i = startIndex; i <= endIndex; i++) {
      final post = _reelsDataList[i];
      for (var mediaItem in post.mediaMetaDataList) {
        if (mediaItem.mediaUrl.isEmpty) continue;

        if (mediaItem.mediaType == MediaType.video.value) {
          backgroundUrls.add(mediaItem.mediaUrl);
          if (mediaItem.thumbnailUrl.isNotEmpty) {
            backgroundUrls.add(mediaItem.thumbnailUrl);
          }
        } else {
          backgroundUrls.add(mediaItem.mediaUrl);
        }
      }
    }

    if (backgroundUrls.isNotEmpty) {
      debugPrint(
          '🔄 Background preloading ${backgroundUrls.length} media items');
      unawaited(
          MediaCacheFactory.precacheMedia(backgroundUrls, highPriority: false));
    }
  }

  // Handle media caching for both images and videos - OPTIMIZED FOR PERFORMANCE
  Future<void> _doMediaCaching(int index) async {
    if (_reelsDataList.isEmpty || index >= _reelsDataList.length) return;

    final reelsData = _reelsDataList[index];

    // Only log every 5th scroll to reduce performance impact
    if (index % 5 == 0) {
      debugPrint(
          '🎯 MainWidget: Page changed to index $index (@${reelsData.userName})');
    }

    // OPTIMIZATION: Platform-specific preloading for smooth scrolling
    // Android: 2 ahead (balanced for smooth experience with increased cache)
    // iOS: 3 ahead (more aggressive for smoother experience)
    final preloadCount = Platform.isAndroid ? 2 : 3;
    final startIndex = math.max(0, index - 1); // 1 behind
    final endIndex = math.min(_reelsDataList.length - 1, index + preloadCount);

    // Collect media URLs for current post only (high priority)
    final currentPostMedia = <String>[];
    final currentPostThumbnails = <String>[];

    // Process current post with high priority
    for (var mediaItem in reelsData.mediaMetaDataList) {
      if (mediaItem.mediaUrl.isEmpty) continue;

      if (mediaItem.mediaType == MediaType.video.value) {
        // Video - cache thumbnail first (highest priority), then video
        if (mediaItem.thumbnailUrl.isNotEmpty) {
          currentPostThumbnails.add(mediaItem.thumbnailUrl);
        }
        currentPostMedia.add(mediaItem.mediaUrl);
      } else {
        // Image - high priority
        currentPostMedia.add(mediaItem.mediaUrl);
      }
    }

    // OPTIMIZATION: Load thumbnails FIRST (instant display), then videos
    if (currentPostThumbnails.isNotEmpty) {
      unawaited(MediaCacheFactory.precacheMedia(currentPostThumbnails,
          highPriority: true));
    }

    // Cache current post videos/images with high priority (NON-BLOCKING)
    if (currentPostMedia.isNotEmpty) {
      unawaited(MediaCacheFactory.precacheMedia(currentPostMedia,
          highPriority: true));
    }

    // Background cache nearby posts (non-blocking) - now includes 3 posts ahead
    unawaited(_cacheNearbyPosts(startIndex, endIndex, index));
  }

  /// Cache nearby posts in background without blocking UI
  Future<void> _cacheNearbyPosts(
      int startIndex, int endIndex, int currentIndex) async {
    final nearbyMedia = <String>[];

    for (var i = startIndex; i <= endIndex; i++) {
      if (i == currentIndex) continue; // Skip current post

      final post = _reelsDataList[i];
      for (var mediaItem in post.mediaMetaDataList) {
        if (mediaItem.mediaUrl.isEmpty) continue;

        if (mediaItem.mediaType == MediaType.video.value) {
          nearbyMedia.add(mediaItem.mediaUrl);
          if (mediaItem.thumbnailUrl.isNotEmpty) {
            nearbyMedia.add(mediaItem.thumbnailUrl);
          }
        } else {
          nearbyMedia.add(mediaItem.mediaUrl);
        }
      }
    }

    if (nearbyMedia.isNotEmpty) {
      await MediaCacheFactory.precacheMedia(nearbyMedia, highPriority: false);
    }
  }

// Updated _evictDeletedPostImage method to handle all media items
  Future<void> evictDeletedPostMedia(ReelsData deletedPost) async {
    // Loop through all media items in the deleted post
    for (var mediaIndex = 0;
        mediaIndex < deletedPost.mediaMetaDataList.length;
        mediaIndex++) {
      final mediaItem = deletedPost.mediaMetaDataList[mediaIndex];

      // Evict image or thumbnail
      final imageUrl = mediaItem.mediaType == MediaType.photo.value
          ? mediaItem.mediaUrl
          : mediaItem.thumbnailUrl;

      if (imageUrl.isNotEmpty) {
        // Evict from Flutter's memory cache
        await NetworkImage(imageUrl).evict();
        _cachedImages.remove(imageUrl);

        // Also evict from disk cache if using CachedNetworkImage
        try {
          await DefaultCacheManager().removeFile(imageUrl);
          debugPrint(
              '🗑️ MainWidget: Evicted deleted post image from cache - Media $mediaIndex: $imageUrl');
        } catch (_) {}
      }

      // For videos, also evict from video cache
      if (mediaItem.mediaType == MediaType.video.value &&
          mediaItem.mediaUrl.isNotEmpty) {
        // Clear from appropriate cache manager based on media type
        final imageCacheManager =
            MediaCacheFactory.getCacheManager(MediaType.photo);
        final videoCacheManager =
            MediaCacheFactory.getCacheManager(MediaType.video);

        imageCacheManager.clearMedia(mediaItem.mediaUrl);
        videoCacheManager.clearMedia(mediaItem.mediaUrl);

        debugPrint(
            '🗑️ MainWidget: Evicted deleted post video from cache - Media $mediaIndex: ${mediaItem.mediaUrl}');
      }
    }
  }

  Future<void> clearAllCache() async {
    PaintingBinding.instance.imageCache.clear(); // removes decoded images
    PaintingBinding.instance.imageCache
        .clearLiveImages(); // removes "live" references

    // Clear all media caches using MediaCacheFactory
    MediaCacheFactory.clearAllCaches();

    // Clear disk cache from CachedNetworkImage
    await DefaultCacheManager().emptyCache();
  }

  /// Handles video completion - navigates to next post if available
  void _handleVideoCompletion(int currentIndex) {
    debugPrint(
        '🎬 PostItemWidget: _handleVideoCompletion called with index $currentIndex');
    debugPrint(
        '🎬 PostItemWidget: mounted: $mounted, reelsDataList length: ${_reelsDataList.length}');

    if (!mounted || _reelsDataList.isEmpty) {
      debugPrint('🎬 PostItemWidget: Early return - not mounted or empty list');
      return;
    }
    if (_isPlaybackBlocked) {
      debugPrint(
          '🎬 PostItemWidget: Ignoring auto-scroll because playback is blocked');
      return;
    }

    // Check if there's a next post available
    if (currentIndex < _reelsDataList.length - 1) {
      final nextIndex = currentIndex + 1;
      debugPrint(
          '🎬 PostItemWidget: Video completed, moving to next post at index $nextIndex');

      // Animate to next page
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      debugPrint(
          '🎬 PostItemWidget: Video completed, but no more posts available');
      // Optionally trigger load more if we're at the end
      _requestReelsLoadMore();
    }
  }

  /// Loads the next page once; ignores further triggers while a request is open.
  void _requestReelsLoadMore() {
    if (widget.onLoadMore == null || _reelsLoadMoreInFlight) return;
    _reelsLoadMoreInFlight = true;
    widget.onLoadMore!().then((value) {
      if (!mounted) return;
      if (value.isListEmptyOrNull) return;
      final allowDuplicates = widget.allowDuplicatePostInList;
      final newReels = allowDuplicates
          ? value
          : value.where((newReel) => !_reelsDataList
              .any((existingReel) => existingReel.postId == newReel.postId));
      _reelsDataList.addAll(newReels);
      if (_reelsDataList.isNotEmpty) {
        _doMediaCaching(0);
      }
      _updateState();
    }).whenComplete(() {
      _reelsLoadMoreInFlight = false;
    });
  }

  Future<bool> _refreshPostFeed() async {
    try {
      if (widget.onRefresh == null) return false;
      final result = await widget.onRefresh!.call();
      if (result == true && mounted) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return result;
        _reelsDataList = List<ReelsData>.from(widget.reelsDataList);
        _updateState();
        if (_reelsDataList.isNotEmpty) {
          await _doMediaCaching(0);
        }
      }
      return result;
    } catch (e) {
      debugPrint('❌ PostItemWidget: Error during post-feed refresh - $e');
      return false;
    }
  }

  Future<void> _refreshPost() async {
    try {
      if (widget.onRefresh != null) {
        final result = await widget.onRefresh?.call();
        if (result == true) {
          // Get current index before refresh
          final currentIndex = _resolvedCurrentPageIndex;
          debugPrint('🔄 MainWidget: Starting refresh at index $currentIndex');

          // Increment refresh count to force rebuild
          _refreshCounts[currentIndex] =
              (_refreshCounts[currentIndex] ?? 0) + 1;
          _updateState();
          // Re-initialize caching for current index after successful refresh
          await _doMediaCaching(currentIndex);
          debugPrint(
              '✅ MainWidget: Posts refreshed successfully with count: ${_refreshCounts[currentIndex]}');
        } else {
          debugPrint('⚠️ MainWidget: Refresh returned false');
        }
      }
    } catch (e) {
      debugPrint('❌ MainWidget: Error during refresh - $e');
    }
    return;
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Preload critical images that need to be displayed immediately
  Future<void> _preloadCriticalImages(ReelsData post) async {
    final criticalUrls = <String>[];

    // Add profile image
    if (post.profilePhoto?.isNotEmpty == true) {
      criticalUrls.add(post.profilePhoto!);
    }

    // Add thumbnails for videos (these are already loaded via MediaCacheFactory)
    // Only add if not already in the main loading queue
    for (final mediaItem in post.mediaMetaDataList) {
      if (mediaItem.mediaType == MediaType.video.value &&
          mediaItem.thumbnailUrl.isNotEmpty) {
        criticalUrls.add(mediaItem.thumbnailUrl);
      }
    }

    // OPTIMIZATION: Preload in background without blocking
    if (criticalUrls.isEmpty) return;

    // Use the same cache manager that CachedNetworkImage uses
    final cacheManager = DefaultCacheManager();

    // Process images in parallel for better performance
    final futures = criticalUrls.map((url) async {
      try {
        // Check if already cached before downloading
        final cachedFile = await cacheManager.getFileFromCache(url);
        if (cachedFile != null) {
          debugPrint('✅ PostItemWidget: Image already cached: $url');
          return;
        }

        // Preload into CachedNetworkImage's disk cache
        await cacheManager.downloadFile(url);
        debugPrint(
            '✅ PostItemWidget: Successfully preloaded critical image: $url');
      } catch (e) {
        debugPrint(
            '❌ PostItemWidget: Error preloading critical image $url: $e');
      }
    });

    // OPTIMIZATION: Don't wait for all to complete, start in background
    unawaited(Future.wait(futures));
  }
}
