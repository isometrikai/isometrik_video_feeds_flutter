import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
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
    this.onPageChanged,
    required this.reelsDataList,
    this.videoCacheManager,
  });

  final Future<List<ReelsData>> Function()? onLoadMore;
  final Future<bool> Function()? onRefresh;
  final Widget? placeHolderWidget;
  final PostSectionType? postSectionType;
  final VoidCallback? onTapPlaceHolder;
  final int? startingPostIndex;
  final String? loggedInUserId;
  final bool? allowImplicitScrolling;
  final Function(int, String)? onPageChanged;
  final List<ReelsData> reelsDataList;
  final VideoCacheManager? videoCacheManager;

  @override
  State<PostItemWidget> createState() => _PostItemWidgetState();
}

class _PostItemWidgetState extends State<PostItemWidget>
    with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  final Set<String> _cachedImages = {};
  late final VideoCacheManager _videoCacheManager;
  List<ReelsData> _reelsDataList = [];

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
    return _reelsDataList.isListEmptyOrNull == true
        ? _buildPlaceHolder(context)
        : _buildContent(context);
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
                    child: widget.postSectionType == PostSectionType.trending
                        ? const Text('No Data')
                        : widget.placeHolderWidget ??
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
                  if (widget.onPageChanged != null) {
                    widget.onPageChanged!(index, post.postId ?? '');
                  }
                },
                itemCount: _reelsDataList.length,
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  final reelsData = _reelsDataList[index];
                  return RepaintBoundary(
                    child: IsmReelsVideoPlayerView(
                      reelsData: reelsData,
                      loggedInUserId: widget.loggedInUserId,
                      videoCacheManager: _videoCacheManager,
                      // Add refresh count to force rebuild
                      key: ValueKey(
                          '${reelsData.postId}_${_refreshCounts[index] ?? 0}'),
                      onVideoCompleted: () => _handleVideoCompletion(index),
                      onPressMoreButton: () async {
                        if (reelsData.onPressMoreButton == null) return;
                        final result =
                            await reelsData.onPressMoreButton!.call();
                        if (result == null) return;
                        if (result is bool) {
                          final isSuccess = result;
                          if (isSuccess) {
                            final postIndex = _reelsDataList.indexWhere(
                                (element) =>
                                    element.postId == reelsData.postId);
                            if (postIndex != -1) {
                              _reelsDataList.removeAt(postIndex);
                              final imageUrl = _reelsDataList[postIndex]
                                  .mediaMetaDataList[0]
                                  .mediaUrl;
                              final thumbnailUrl = _reelsDataList[postIndex]
                                  .mediaMetaDataList[0]
                                  .thumbnailUrl;
                              if (_reelsDataList[postIndex]
                                      .mediaMetaDataList[0]
                                      .mediaType ==
                                  MediaType.image.value) {
                                // For image post
                                await _evictDeletedPostImage(imageUrl);
                              } else {
                                // For video post
                                await _evictDeletedPostImage(thumbnailUrl);
                                // Clear video controller
                                _videoCacheManager.clearMedia(imageUrl);
                              }
                            }
                            _updateState();
                          }
                        }
                        if (result is ReelsData) {
                          final index = _reelsDataList.indexWhere(
                              (element) => element.postId == result.postId);
                          if (index != -1) {
                            _refreshCounts[index] =
                                (_refreshCounts[index] ?? 0) + 1;
                            _reelsDataList[index] = result;
                            _updateState();
                          }
                        }
                      },
                      onCreatePost: () async {
                        if (reelsData.onCreatePost != null) {
                          final result = await reelsData.onCreatePost!();
                          if (result != null) {
                            _reelsDataList.insert(index, result);
                            _updateState();
                          }
                        }
                      },
                      onPressFollowButton: () async {
                        if (reelsData.onPressFollow != null) {
                          final result = await reelsData.onPressFollow!(
                              reelsData.userId ?? '',
                              reelsData.isFollow ?? false);
                          if (result == true && mounted) {
                            final index = _reelsDataList.indexWhere((element) =>
                                element.postId == reelsData.postId);
                            if (index != -1) {
                              _reelsDataList[index].isFollow =
                                  reelsData.isFollow == true ? false : true;
                              _refreshCounts[index] =
                                  (_refreshCounts[index] ?? 0) + 1;
                              _updateState();
                            }
                          }
                          // // ✅ Log event locally
                          // unawaited(EventQueueProvider.instance.addEvent({
                          //   'type': EventType.follow.value,
                          //   'postId': reelsData.postId,
                          //   'userId': widget.loggedInUserId,
                          //   'isFollow': reelsData.isFollow,
                          //   'timestamp': DateTime.now().toUtc().toIso8601String(),
                          // }));
                        }
                      },
                      onPressLikeButton: () async {
                        if (reelsData.onPressLike != null) {
                          final result = await reelsData
                              .onPressLike!(reelsData.isLiked ?? false);
                          if (result == true) {
                            reelsData.isLiked = reelsData.isLiked == false;
                            if (reelsData.isLiked == true) {
                              reelsData.likesCount =
                                  (reelsData.likesCount ?? 0) + 1;
                            } else {
                              if ((reelsData.likesCount ?? 0) > 0) {
                                reelsData.likesCount =
                                    (reelsData.likesCount ?? 0) - 1;
                              }
                            }
                            _updateState();
                          }
                          // ✅ Log event locally
                          // unawaited(EventQueueProvider.instance.addEvent({
                          //   'type': EventType.like.value,
                          //   'postId': reelsData.postId,
                          //   'userId': widget.loggedInUserId,
                          //   'isLiked': reelsData.isLiked,
                          //   'timestamp': DateTime.now().toUtc().toIso8601String(),
                          // }));
                        }
                      },
                      onDoubleTap: () async {
                        if (reelsData.onDoubleTap != null &&
                            reelsData.isLiked == false) {
                          final result = await reelsData
                              .onDoubleTap!(reelsData.isLiked ?? false);
                          if (result == true) {
                            reelsData.isLiked = reelsData.isLiked == false;
                            if (reelsData.isLiked == true) {
                              reelsData.likesCount =
                                  (reelsData.likesCount ?? 0) + 1;
                            } else {
                              if ((reelsData.likesCount ?? 0) > 0) {
                                reelsData.likesCount =
                                    (reelsData.likesCount ?? 0) - 1;
                              }
                            }
                            _updateState();
                          }
                          // ✅ Log event locally
                          // unawaited(EventQueueProvider.instance.addEvent({
                          //   'type': EventType.like.value,
                          //   'postId': reelsData.postId,
                          //   'userId': widget.loggedInUserId,
                          //   'isLiked': reelsData.isLiked,
                          //   'timestamp': DateTime.now().toUtc().toIso8601String(),
                          // }));
                        }
                      },
                      onPressSaveButton: () async {
                        if (reelsData.onPressSave != null) {
                          final result = await reelsData
                              .onPressSave!(reelsData.isSavedPost ?? false);
                          if (result == true) {
                            reelsData.isSavedPost =
                                reelsData.isSavedPost == false;
                            _updateState();
                          }
                          // unawaited(EventQueueProvider.instance.addEvent({
                          //   'type': EventType.save.value,
                          //   'postId': reelsData.postId,
                          //   'isSaved': reelsData.isSavedPost,
                          //   'userId': widget.loggedInUserId,
                          //   'timestamp': DateTime.now().toUtc().toIso8601String(),
                          // }));
                        }
                      },
                      onTapMentionTag: (mentionedList) async {
                        if (reelsData.onTapMentionTag != null) {
                          final result =
                              await reelsData.onTapMentionTag!(mentionedList);
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

    // Preload posts 5-10 positions away (low priority)
    final startIndex = 5;
    final endIndex = math.min(_reelsDataList.length - 1, 10);

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

    // OPTIMIZATION: Only cache current post + 1 ahead/behind to reduce memory pressure
    final startIndex = math.max(0, index - 1); // Only 1 behind
    final endIndex =
        math.min(_reelsDataList.length - 1, index + 1); // Only 1 ahead

    // Collect media URLs for current post only (high priority)
    final currentPostMedia = <String>[];

    // Process current post with high priority
    for (var mediaItem in reelsData.mediaMetaDataList) {
      if (mediaItem.mediaUrl.isEmpty) continue;

      if (mediaItem.mediaType == MediaType.video.value) {
        // Video - cache both video and thumbnail
        currentPostMedia.add(mediaItem.mediaUrl);
        if (mediaItem.thumbnailUrl.isNotEmpty) {
          currentPostMedia.add(mediaItem.thumbnailUrl);
        }
      } else {
        // Image
        currentPostMedia.add(mediaItem.mediaUrl);
      }
    }

    // Cache current post with high priority (NON-BLOCKING)
    if (currentPostMedia.isNotEmpty) {
      // Use unawaited to prevent blocking the UI thread
      unawaited(MediaCacheFactory.precacheMedia(currentPostMedia,
          highPriority: true));

      // Preload critical images in background
      // unawaited(_preloadCriticalImages(reelsData));
    }

    // Background cache nearby posts (non-blocking)
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
      final imageUrl = mediaItem.mediaType == MediaType.image.value
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
            MediaCacheFactory.getCacheManager(MediaType.image);
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
