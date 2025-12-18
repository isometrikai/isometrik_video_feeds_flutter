import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class PostItemWidget extends StatefulWidget {
  const PostItemWidget({
    super.key,
    this.onLoadMore,
    this.onRefresh,
    this.placeHolderWidget,
    this.postSectionType,
    this.onTapPlaceHolder,
    this.startingPostIndex = 0,
    this.loggedInUserId,
    this.allowImplicitScrolling = true,
    required this.reelsDataList,
    this.videoCacheManager,
    required this.reelsConfig,
  });

  final Future<List<ReelsData>> Function()? onLoadMore;
  final Future<bool> Function()? onRefresh;
  final Widget? placeHolderWidget;
  final PostSectionType? postSectionType;
  final VoidCallback? onTapPlaceHolder;
  final int? startingPostIndex;
  final String? loggedInUserId;
  final bool? allowImplicitScrolling;
  final List<ReelsData> reelsDataList;
  final VideoCacheManager? videoCacheManager;
  final ReelsConfig reelsConfig;

  @override
  State<PostItemWidget> createState() => _PostItemWidgetState();
}

class _PostItemWidgetState extends State<PostItemWidget>
    with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  final Set<String> _cachedImages = {};
  late final VideoCacheManager _videoCacheManager;
  List<ReelsData> _reelsDataList = [];
  late final IsmSocialActionCubit _ismSocialActionCubit;

  bool _isInitialized = false;

  // Track refresh count for each index to force rebuild
  final Map<int, int> _refreshCounts = {};

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  /// Initialize the widget
  void _onStartInit() {
    _ismSocialActionCubit = context.getOrCreateBloc();
    _videoCacheManager = widget.videoCacheManager ?? VideoCacheManager();
    _reelsDataList = widget.reelsDataList;
    _pageController =
        PageController(initialPage: widget.startingPostIndex ?? 0);
    _initializeContent();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
    }
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

    // OPTIMIZATION: Animate to target page without blocking
    final targetPage = _pageController.initialPage >= _reelsDataList.length
        ? _reelsDataList.length - 1
        : _pageController.initialPage;
    if (targetPage > 0) {
      unawaited(_pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 1),
        curve: Curves.easeIn,
      ));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Don't clear all cache on dispose, only clear controllers
    // _videoCacheManager.clearControllers();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return context.attachBlocIfNeeded<IsmSocialActionCubit>(
      bloc: _ismSocialActionCubit,
      child: BlocListener<IsmSocialActionCubit, IsmSocialActionState>(
        listenWhen: (previous, current) =>
            (current is IsmFollowActionListenerState &&
                widget.postSectionType == PostSectionType.following) ||
            (current is IsmSaveActionListenerState &&
                widget.postSectionType == PostSectionType.savedPost) ||
            (current is IsmDeletedPostActionListenerState) ||
            (current is IsmEditPostActionListenerState),
        listener: (context, state) {
          if (state is IsmFollowActionListenerState &&
              widget.postSectionType == PostSectionType.following) {
            _updateWithFollowAction(state);
          } else if (state is IsmSaveActionListenerState &&
              widget.postSectionType == PostSectionType.savedPost) {
            _updateWithSaveAction(state);
          } else if (state is IsmDeletedPostActionListenerState) {
            _updateWithDeleteAction(state);
          } else if (state is IsmEditPostActionListenerState) {
            _updateWithEditAction(state);
          }
        },
        child: _reelsDataList.isListEmptyOrNull == true
            ? _buildPlaceHolder(context)
            : _buildContent(context),
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
        _reelsDataList[index] = postData; // replace
        await updateStateByKey();
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

  Future<void> _updateWithSaveAction(IsmSaveActionListenerState state) async {
    if (!state.isSaved && widget.postSectionType == PostSectionType.savedPost) {
      _reelsDataList.removeWhere((element) => element.postId == state.postId);
      await updateStateByKey();
    }
  }

  Future<void> updateStateByKey() async {
    // Get current index before refresh
    final currentIndex = _pageController.page?.toInt() ?? 0;
    debugPrint('🔄 MainWidget: Starting update at index $currentIndex');

    // Increment refresh count to force rebuild
    _refreshCounts[currentIndex] = (_refreshCounts[currentIndex] ?? 0) + 1;
    _updateState();
    // Re-initialize caching for current index after successful refresh
    await _doMediaCaching(currentIndex);
  }

  Future<void> _updateWithFollowAction(
      IsmFollowActionListenerState state) async {
    var updateState = false;
    if (state.isFollowing &&
        !_reelsDataList.any((element) => element.userId == state.userId)) {
      final followedUserReels = _ismSocialActionCubit.getPostList(
          filter: (post) => post.userId == state.userId);
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
        _reelsDataList.any((element) => element.userId == state.userId)) {
      _reelsDataList.removeWhere((element) => element.userId == state.userId);
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
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Center(
                    child: widget.placeHolderWidget ??
                        PostPlaceHolderView(
                          postSectionType: widget.postSectionType,
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

  Widget _buildContent(BuildContext context) => Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _refreshPost();
              },
              child: PageView.builder(
                // key: _pageStorageKey,
                allowImplicitScrolling: widget.allowImplicitScrolling ?? true,
                controller: _pageController,
                physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics()),
                onPageChanged: (index) {
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
                    if (widget.onLoadMore != null) {
                      widget.onLoadMore!().then(
                        (value) {
                          if (value.isListEmptyOrNull) return;
                          final newReels = value.where((newReel) =>
                              !_reelsDataList.any((existingReel) =>
                                  existingReel.postId == newReel.postId));
                          _reelsDataList.addAll(newReels);
                          if (_reelsDataList.isNotEmpty) {
                            _doMediaCaching(0);
                          }
                          _updateState();
                        },
                      );
                    }
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
                      reelsData: reelsData,
                      postSectionType:
                          widget.postSectionType ?? PostSectionType.following,
                      loggedInUserId: widget.loggedInUserId,
                      videoCacheManager: _videoCacheManager,
                      // Add refresh count to force rebuild
                      key: ValueKey(
                          '${reelsData.postId}_${_refreshCounts[index] ?? 0}'),
                      // onVideoCompleted: () => _handleVideoCompletion(index),
                      reelsConfig: widget.reelsConfig,
                      onPressMoreButton: () async {
                        if (widget.reelsConfig.onPressMoreButton == null) {
                          return;
                        }
                        await widget.reelsConfig.onPressMoreButton!
                            .call(reelsData);
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
                          final result = await widget.reelsConfig
                              .onTapMentionTag!(reelsData, mentionedList);
                          if (result.isListEmptyOrNull == false) {
                            final index = _reelsDataList.indexWhere((element) =>
                                element.postId == reelsData.postId);
                            if (index != -1) {
                              _reelsDataList[index].mentions = result ?? [];
                              _refreshCounts[index] =
                                  (_refreshCounts[index] ?? 0) + 1;
                              _updateState();
                            }
                          }
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

    // OPTIMIZATION: Platform-specific preloading to avoid Android memory issues
    // Android: ONLY 1 ahead (very conservative to prevent NO_MEMORY decoder errors)
    // iOS: 3 ahead (more aggressive for smoother experience)
    final preloadCount = Platform.isAndroid ? 1 : 3;
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

  Future<void> _evictDeletedPostImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;

    // Evict from Flutter's memory cache
    await NetworkImage(imageUrl).evict();

    // Clear from appropriate cache manager based on media type
    final mediaType = MediaTypeUtil.getMediaType(imageUrl);
    final cacheManager = MediaCacheFactory.getCacheManager(mediaType);
    cacheManager.clearMedia(imageUrl);

    // Also evict from disk cache if using CachedNetworkImage
    try {
      await DefaultCacheManager().removeFile(imageUrl);
      debugPrint(
          '🗑️ MainWidget: Evicted deleted post image from cache - $imageUrl');
    } catch (_) {}
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

    // Check if there's a next post available
    if (currentIndex < _reelsDataList.length - 1) {
      final nextIndex = currentIndex + 1;
      debugPrint(
          '🎬 PostItemWidget: Video completed, moving to next post at index $nextIndex');

      // Animate to next page
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      debugPrint(
          '🎬 PostItemWidget: Video completed, but no more posts available');
      // Optionally trigger load more if we're at the end
      if (widget.onLoadMore != null) {
        debugPrint('🎬 PostItemWidget: Triggering load more...');
        widget.onLoadMore!().then((value) {
          if (value.isListEmptyOrNull) return;
          final newReels = value.where((newReel) => !_reelsDataList
              .any((existingReel) => existingReel.postId == newReel.postId));
          _reelsDataList.addAll(newReels);
          if (_reelsDataList.isNotEmpty) {
            _doMediaCaching(0);
          }
          _updateState();
        });
      }
    }
  }

  Future<void> _refreshPost() async {
    if (widget.loggedInUserId.isStringEmptyOrNull == true) return;
    try {
      if (widget.onRefresh != null) {
        final result = await widget.onRefresh?.call();
        if (result == true) {
          // Get current index before refresh
          final currentIndex = _pageController.page?.toInt() ?? 0;
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
